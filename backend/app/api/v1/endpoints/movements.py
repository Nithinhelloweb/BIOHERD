import random
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import check_geographic_scope, get_current_user, require_roles
from app.core.logging import get_logger
from app.db.models import District, LivestockMovement, OutbreakEvent, User, UserRole
from app.db.session import get_db
from app.schemas.movement import LivestockMovementCreate, LivestockMovementResponse

logger = get_logger("movements_endpoint")
router = APIRouter(prefix="/movements", tags=["Livestock Movement & Transit Tracking"])


def generate_permit_number() -> str:
    rnd = random.randint(10000, 99999)
    return f"MH-TRP-2026-{rnd}"


@router.post(
    "",
    response_model=LivestockMovementResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register livestock movement / migration permit",
)
async def create_movement_permit(
    req: LivestockMovementCreate,
    current_user: User = Depends(require_roles(UserRole.PARAVET, UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    # Verify origin and destination districts
    for dist_id in (req.origin_district_id, req.destination_district_id):
        res = await session.execute(select(District).where(District.id == dist_id))
        if not res.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"District {dist_id} not found")

    # Check if origin has an active quarantine outbreak
    ob_res = await session.execute(
        select(OutbreakEvent).where(
            OutbreakEvent.district_id == req.origin_district_id,
            OutbreakEvent.quarantine_declared == True,
            OutbreakEvent.resolved_at == None,
        )
    )
    quarantine_active = ob_res.scalar_one_or_none() is not None

    movement = LivestockMovement(
        permit_number=generate_permit_number(),
        animal_ids=req.animal_ids,
        origin_district_id=req.origin_district_id,
        origin_block=req.origin_block,
        destination_district_id=req.destination_district_id,
        destination_block=req.destination_block,
        purpose=req.purpose,
        health_certificate_issued=not quarantine_active,
        inspection_status="quarantined" if quarantine_active else "approved",
        quarantine_flag=quarantine_active,
        departed_at=datetime.now(timezone.utc),
    )
    session.add(movement)
    await session.commit()
    await session.refresh(movement)

    logger.info("livestock_movement_registered", permit=movement.permit_number, quarantine=quarantine_active)
    return LivestockMovementResponse.model_validate(movement)


@router.get(
    "",
    response_model=List[LivestockMovementResponse],
    summary="List active livestock movements and transit permits",
)
async def list_movements(
    origin_district_id: Optional[str] = Query(None),
    destination_district_id: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    quarantine_only: bool = Query(False),
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(LivestockMovement).order_by(desc(LivestockMovement.departed_at)).limit(limit)

    if origin_district_id:
        stmt = stmt.where(LivestockMovement.origin_district_id == origin_district_id)
    if destination_district_id:
        stmt = stmt.where(LivestockMovement.destination_district_id == destination_district_id)
    if status_filter:
        stmt = stmt.where(LivestockMovement.inspection_status == status_filter)
    if quarantine_only:
        stmt = stmt.where(LivestockMovement.quarantine_flag == True)

    res = await session.execute(stmt)
    records = res.scalars().all()
    return [LivestockMovementResponse.model_validate(r) for r in records]
