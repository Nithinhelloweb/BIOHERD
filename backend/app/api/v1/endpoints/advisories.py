from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import check_geographic_scope, get_current_user, require_roles
from app.core.logging import get_logger
from app.db.models import Advisory, Alert, AlertBroadcast, District, User, UserRole
from app.db.session import get_db
from app.schemas.advisory import (
    AdvisoryCreate,
    AdvisoryResponse,
    AlertBroadcastCreate,
    AlertBroadcastResponse,
)

logger = get_logger("advisories_endpoint")
router = APIRouter(prefix="/advisories", tags=["Alerts & Advisories Hub"])


@router.get(
    "",
    response_model=List[AdvisoryResponse],
    summary="List disease prevention and first aid advisories",
)
async def list_advisories(
    category: Optional[str] = Query(None),
    disease: Optional[str] = Query(None),
    status_filter: Optional[str] = Query("published", alias="status"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(Advisory).order_by(desc(Advisory.created_at))

    # Farmers and paravets see published advisories
    if current_user.role in (UserRole.FARMER, UserRole.PARAVET):
        stmt = stmt.where(Advisory.status == "published")
    elif status_filter:
        stmt = stmt.where(Advisory.status == status_filter)

    if category:
        stmt = stmt.where(Advisory.category == category)
    if disease:
        stmt = stmt.where(Advisory.disease_target.ilike(f"%{disease}%"))

    res = await session.execute(stmt)
    records = res.scalars().all()
    return [AdvisoryResponse.model_validate(r) for r in records]


@router.post(
    "",
    response_model=AdvisoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Contribute / draft advisory (DVO or State Official)",
)
async def create_advisory(
    req: AdvisoryCreate,
    current_user: User = Depends(require_roles(UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    # State officials can publish directly; DVOs submit for approval
    is_admin = current_user.role in (UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL, UserRole.SUPER_ADMIN)
    advisory_status = "published" if is_admin else "pending_approval"

    adv = Advisory(
        title_multilingual_json=req.title_multilingual,
        content_multilingual_json=req.content_multilingual,
        category=req.category,
        disease_target=req.disease_target,
        author_id=current_user.id,
        status=advisory_status,
        target_district_id=req.target_district_id or current_user.district_id,
        published_at=datetime.now(timezone.utc) if is_admin else None,
    )
    session.add(adv)
    await session.commit()
    await session.refresh(adv)
    logger.info("advisory_created", id=adv.id, status=adv.status)
    return AdvisoryResponse.model_validate(adv)


@router.put(
    "/{advisory_id}/publish",
    response_model=AdvisoryResponse,
    summary="Approve and publish advisory (State Official / Admin only)",
)
async def publish_advisory(
    advisory_id: str,
    current_user: User = Depends(require_roles(UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(Advisory).where(Advisory.id == advisory_id)
    res = await session.execute(stmt)
    adv = res.scalar_one_or_none()
    if not adv:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Advisory not found")

    adv.status = "published"
    adv.published_at = datetime.now(timezone.utc)
    await session.commit()
    await session.refresh(adv)
    return AdvisoryResponse.model_validate(adv)


# ── Broadcast Alerts ─────────────────────────────────────────────────────────

@router.post(
    "/broadcast",
    response_model=AlertBroadcastResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Broadcast emergency mass alert to a geographic zone",
)
async def broadcast_alert(
    req: AlertBroadcastCreate,
    current_user: User = Depends(require_roles(UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    # Enforce role-level broadcast limits:
    # Field Vet can broadcast to block; DVO to district; State to state/all
    if current_user.role == UserRole.VETERINARIAN and req.target_level != "block":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Field Veterinarians can only broadcast at the block level")
    if current_user.role == UserRole.DISTRICT_OFFICIAL and req.target_level not in ("block", "district"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="District Officers can only broadcast up to district level")

    # Estimate recipient count based on users in target area
    recipient_stmt = select(User)
    if req.target_district_id:
        recipient_stmt = recipient_stmt.where(User.district_id == req.target_district_id)
    if req.target_block:
        recipient_stmt = recipient_stmt.where(User.block == req.target_block)

    rec_res = await session.execute(recipient_stmt)
    recipients = rec_res.scalars().all()
    count = max(len(recipients), 1)

    broadcast = AlertBroadcast(
        sender_id=current_user.id,
        target_level=req.target_level,
        target_district_id=req.target_district_id or current_user.district_id,
        target_block=req.target_block or current_user.block,
        disease_name=req.disease_name,
        severity=req.severity,
        title=req.title,
        message=req.message,
        channels=req.channels,
        total_recipients=count,
        acknowledged_count=0,
    )
    session.add(broadcast)

    # Fan out alert items to individual recipient feeds
    for u in recipients[:50]:  # Cap fanout to top 50 in dev
        user_alert = Alert(
            recipient_user_id=u.id,
            alert_type="outbreak_broadcast",
            severity=req.severity,
            title_multilingual_json=req.title,
            body_multilingual_json=req.message,
            channels=req.channels,
            is_read=False,
        )
        session.add(user_alert)

    await session.commit()
    await session.refresh(broadcast)
    logger.info("emergency_alert_broadcasted", id=broadcast.id, recipients=count)
    return AlertBroadcastResponse.model_validate(broadcast)


@router.post(
    "/broadcast/{broadcast_id}/acknowledge",
    summary="Track alert acknowledgment by recipient farmer/vet",
)
async def acknowledge_alert(
    broadcast_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    stmt = select(AlertBroadcast).where(AlertBroadcast.id == broadcast_id)
    res = await session.execute(stmt)
    broadcast = res.scalar_one_or_none()
    if not broadcast:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Broadcast not found")

    broadcast.acknowledged_count += 1
    await session.commit()

    return {
        "status": "acknowledged",
        "broadcast_id": broadcast_id,
        "total_acknowledged": broadcast.acknowledged_count,
        "total_recipients": broadcast.total_recipients,
    }
