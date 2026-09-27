from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import check_geographic_scope, get_current_user, require_reporting_roles
from app.core.logging import get_logger
from app.db.models import District, MortalityReport, User, UserRole
from app.db.session import get_db
from app.schemas.mortality import MortalityReportCreate, MortalityReportResponse
from app.services.triage_engine import TriageRuleEngine

logger = get_logger("mortality_endpoint")
router = APIRouter(prefix="/mortality", tags=["Mortality & Incident Capture"])


@router.post(
    "",
    response_model=MortalityReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Report livestock mortality incident",
)
async def create_mortality_report(
    req: MortalityReportCreate,
    current_user: User = Depends(require_reporting_roles),
    session: AsyncSession = Depends(get_db),
):
    # Verify district exists
    dist_stmt = select(District).where(District.id == req.district_id)
    dist_res = await session.execute(dist_stmt)
    dist = dist_res.scalar_one_or_none()
    if not dist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"District ID '{req.district_id}' not found",
        )

    # Evaluate zoonotic risk from symptoms or probable cause
    zoonotic_eval = TriageRuleEngine.evaluate_zoonotic_risk(req.probable_cause or " ".join(req.symptoms))
    is_zoonotic = zoonotic_eval.is_zoonotic

    # If Anthrax or high-consequence suspected, post-mortem is strictly forbidden
    if is_zoonotic and "anthrax" in (req.probable_cause or "").lower() and req.post_mortem_conducted:
        logger.warning("dangerous_post_mortem_flagged", user_id=current_user.id)

    report = MortalityReport(
        reported_by=current_user.id,
        district_id=req.district_id,
        block=req.block or current_user.block,
        village=req.village or current_user.village,
        species=req.species,
        animal_count=req.animal_count,
        probable_cause=req.probable_cause,
        symptoms=req.symptoms,
        mortality_date=req.mortality_date or datetime.now(timezone.utc),
        latitude=req.latitude,
        longitude=req.longitude,
        disposal_method=req.disposal_method,
        post_mortem_conducted=req.post_mortem_conducted,
        post_mortem_notes=req.post_mortem_notes,
        zoonotic_risk=is_zoonotic,
        status="submitted",
    )
    session.add(report)
    await session.commit()
    await session.refresh(report)

    logger.info(
        "mortality_reported",
        report_id=report.id,
        species=report.species.value,
        count=report.animal_count,
        zoonotic=is_zoonotic,
    )
    return MortalityReportResponse.model_validate(report)


@router.get(
    "",
    response_model=List[MortalityReportResponse],
    summary="List mortality reports with geographical scoping",
)
async def list_mortality_reports(
    district_id: Optional[str] = Query(None),
    block: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(MortalityReport).order_by(desc(MortalityReport.created_at)).limit(limit)

    # Apply geographical scope
    if current_user.role == UserRole.FARMER:
        stmt = stmt.where(MortalityReport.reported_by == current_user.id)
    elif current_user.role == UserRole.PARAVET:
        if current_user.district_id:
            stmt = stmt.where(MortalityReport.district_id == current_user.district_id)
        if current_user.village:
            stmt = stmt.where(MortalityReport.village == current_user.village)
    elif current_user.role == UserRole.VETERINARIAN:
        if current_user.district_id:
            stmt = stmt.where(MortalityReport.district_id == current_user.district_id)
        if current_user.block:
            stmt = stmt.where(MortalityReport.block == current_user.block)
    elif current_user.role == UserRole.DISTRICT_OFFICIAL:
        if current_user.district_id:
            stmt = stmt.where(MortalityReport.district_id == current_user.district_id)

    if district_id and (current_user.role in (UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL, UserRole.SUPER_ADMIN)):
        stmt = stmt.where(MortalityReport.district_id == district_id)
    if block:
        stmt = stmt.where(MortalityReport.block == block)

    res = await session.execute(stmt)
    records = res.scalars().all()
    return [MortalityReportResponse.model_validate(r) for r in records]


@router.get(
    "/{report_id}",
    response_model=MortalityReportResponse,
    summary="Get mortality report details",
)
async def get_mortality_report(
    report_id: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(MortalityReport).where(MortalityReport.id == report_id)
    res = await session.execute(stmt)
    report = res.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mortality report not found")

    if not check_geographic_scope(
        current_user,
        resource_district_id=report.district_id,
        resource_block=report.block,
        resource_village=report.village,
        resource_owner_id=report.reported_by,
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Geographic scope access denied")

    return MortalityReportResponse.model_validate(report)
