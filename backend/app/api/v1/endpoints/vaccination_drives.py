from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import check_geographic_scope, get_current_user, require_roles
from app.core.logging import get_logger
from app.db.models import District, User, UserRole, VaccinationDrive
from app.db.session import get_db
from app.schemas.vaccination_drive import (
    VaccinationDriveCreate,
    VaccinationDriveProgressUpdate,
    VaccinationDriveResponse,
)

logger = get_logger("vaccination_drives_endpoint")
router = APIRouter(prefix="/vaccination-drives", tags=["Vaccination Drives & Coverage"])


@router.post(
    "",
    response_model=VaccinationDriveResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Schedule vaccination drive campaign",
)
async def schedule_drive(
    req: VaccinationDriveCreate,
    current_user: User = Depends(require_roles(UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    dist_stmt = select(District).where(District.id == req.district_id)
    dist_res = await session.execute(dist_stmt)
    if not dist_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="District not found")

    drive = VaccinationDrive(
        title=req.title,
        target_disease=req.target_disease,
        vaccine_name=req.vaccine_name,
        district_id=req.district_id,
        block=req.block or current_user.block,
        village=req.village or current_user.village,
        start_date=req.start_date,
        end_date=req.end_date,
        target_animals_count=req.target_animals_count,
        completed_doses=0,
        status="scheduled",
        created_by=current_user.id,
        assigned_vet_id=req.assigned_vet_id or current_user.id,
    )
    session.add(drive)
    await session.commit()
    await session.refresh(drive)

    logger.info("vaccination_drive_scheduled", title=drive.title, target_disease=drive.target_disease)
    res = VaccinationDriveResponse.model_validate(drive)
    res.coverage_percentage = 0.0
    return res


@router.get(
    "",
    response_model=List[VaccinationDriveResponse],
    summary="List vaccination drives with coverage progress",
)
async def list_drives(
    district_id: Optional[str] = Query(None),
    target_disease: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(VaccinationDrive).order_by(desc(VaccinationDrive.created_at))

    if district_id:
        stmt = stmt.where(VaccinationDrive.district_id == district_id)
    elif current_user.role in (UserRole.VETERINARIAN, UserRole.PARAVET, UserRole.DISTRICT_OFFICIAL) and current_user.district_id:
        stmt = stmt.where(VaccinationDrive.district_id == current_user.district_id)

    if target_disease:
        stmt = stmt.where(VaccinationDrive.target_disease.ilike(f"%{target_disease}%"))
    if status_filter:
        stmt = stmt.where(VaccinationDrive.status == status_filter)

    res = await session.execute(stmt)
    drives = res.scalars().all()

    result = []
    for d in drives:
        r = VaccinationDriveResponse.model_validate(d)
        r.coverage_percentage = round((d.completed_doses / max(d.target_animals_count, 1)) * 100, 1)
        result.append(r)
    return result


@router.put(
    "/{drive_id}/progress",
    response_model=VaccinationDriveResponse,
    summary="Record vaccination drive progress (doses administered)",
)
async def update_drive_progress(
    drive_id: str,
    req: VaccinationDriveProgressUpdate,
    current_user: User = Depends(require_roles(UserRole.PARAVET, UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(VaccinationDrive).where(VaccinationDrive.id == drive_id)
    res = await session.execute(stmt)
    drive = res.scalar_one_or_none()
    if not drive:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vaccination drive not found")

    drive.completed_doses += req.additional_doses
    if req.status:
        drive.status = req.status
    elif drive.completed_doses >= drive.target_animals_count:
        drive.status = "completed"
    else:
        drive.status = "in_progress"

    await session.commit()
    await session.refresh(drive)

    r = VaccinationDriveResponse.model_validate(drive)
    r.coverage_percentage = round((drive.completed_doses / max(drive.target_animals_count, 1)) * 100, 1)
    return r


@router.get(
    "/coverage/report",
    summary="Get aggregated vaccination coverage reporting per village/block",
)
async def get_coverage_report(
    district_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    target_dist = district_id or current_user.district_id

    stmt = select(
        VaccinationDrive.target_disease,
        VaccinationDrive.block,
        func.sum(VaccinationDrive.target_animals_count).label("total_target"),
        func.sum(VaccinationDrive.completed_doses).label("total_completed"),
    ).group_by(VaccinationDrive.target_disease, VaccinationDrive.block)

    if target_dist:
        stmt = stmt.where(VaccinationDrive.district_id == target_dist)

    res = await session.execute(stmt)
    rows = res.all()

    breakdown = []
    overall_target = 0
    overall_completed = 0

    for row in rows:
        disease, block, target, completed = row
        t = target or 0
        c = completed or 0
        overall_target += t
        overall_completed += c
        pct = round((c / max(t, 1)) * 100, 1)
        breakdown.append({
            "target_disease": disease,
            "block": block or "All Blocks",
            "target_population": t,
            "completed_doses": c,
            "coverage_pct": pct,
        })

    return {
        "district_id": target_dist,
        "overall_target": overall_target,
        "overall_completed": overall_completed,
        "overall_coverage_pct": round((overall_completed / max(overall_target, 1)) * 100, 1) if overall_target > 0 else 0.0,
        "coverage_breakdown": breakdown,
    }
