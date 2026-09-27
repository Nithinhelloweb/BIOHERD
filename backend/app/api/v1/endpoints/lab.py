import random
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import check_geographic_scope, get_current_user, require_roles
from app.core.logging import get_logger
from app.db.models import Case, CaseStatusEnum, District, LabSample, OutbreakEvent, SeverityLevelEnum, User, UserRole
from app.db.session import get_db
from app.schemas.lab import LabSampleCreate, LabSampleResponse, LabSampleResultUpdate, LabSampleTransitUpdate
from app.services.triage_engine import TriageRuleEngine

logger = get_logger("lab_endpoint")
router = APIRouter(prefix="/lab", tags=["Laboratory & Diagnostic Samples"])


def generate_sample_code() -> str:
    rnd = random.randint(1000, 9999)
    return f"SMP-2026-{rnd}"


@router.post(
    "/samples",
    response_model=LabSampleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Initiate laboratory sample collection request",
)
async def create_sample_request(
    req: LabSampleCreate,
    current_user: User = Depends(require_roles(UserRole.PARAVET, UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    dist_stmt = select(District).where(District.id == req.district_id)
    dist_res = await session.execute(dist_stmt)
    if not dist_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="District not found")

    zoonotic_eval = TriageRuleEngine.evaluate_zoonotic_risk(req.suspected_disease)

    sample = LabSample(
        sample_code=generate_sample_code(),
        case_id=req.case_id,
        animal_id=req.animal_id,
        district_id=req.district_id,
        collected_by=current_user.id,
        collection_date=datetime.now(timezone.utc),
        sample_type=req.sample_type,
        suspected_disease=req.suspected_disease,
        transit_status="collected",
        current_lab_name=req.current_lab_name,
        is_zoonotic=zoonotic_eval.is_zoonotic,
        test_result="pending",
    )
    session.add(sample)
    await session.commit()
    await session.refresh(sample)

    logger.info("sample_collection_initiated", sample_code=sample.sample_code, disease=req.suspected_disease)
    return LabSampleResponse.model_validate(sample)


@router.get(
    "/samples",
    response_model=List[LabSampleResponse],
    summary="List laboratory samples with transit and diagnostic status",
)
async def list_samples(
    transit_status: Optional[str] = Query(None),
    test_result: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(LabSample).order_by(desc(LabSample.created_at)).limit(limit)

    if transit_status:
        stmt = stmt.where(LabSample.transit_status == transit_status)
    if test_result:
        stmt = stmt.where(LabSample.test_result == test_result)

    # Scoping
    if current_user.role == UserRole.FARMER:
        stmt = stmt.where(LabSample.collected_by == current_user.id)
    elif current_user.role in (UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL):
        if current_user.district_id:
            stmt = stmt.where(LabSample.district_id == current_user.district_id)

    res = await session.execute(stmt)
    records = res.scalars().all()
    return [LabSampleResponse.model_validate(r) for r in records]


@router.put(
    "/samples/{sample_id}/transit",
    response_model=LabSampleResponse,
    summary="Update sample transit status (cold chain & logistics)",
)
async def update_sample_transit(
    sample_id: str,
    req: LabSampleTransitUpdate,
    current_user: User = Depends(require_roles(UserRole.PARAVET, UserRole.VETERINARIAN, UserRole.LAB_TECHNICIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(LabSample).where(LabSample.id == sample_id)
    res = await session.execute(stmt)
    sample = res.scalar_one_or_none()
    if not sample:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lab sample not found")

    sample.transit_status = req.transit_status
    if req.referred_to_lab:
        sample.referred_to_lab = req.referred_to_lab

    await session.commit()
    await session.refresh(sample)
    logger.info("sample_transit_updated", sample_id=sample.id, status=sample.transit_status)
    return LabSampleResponse.model_validate(sample)


@router.put(
    "/samples/{sample_id}/result",
    response_model=LabSampleResponse,
    summary="Enter and upload laboratory test result (Lab Technician)",
)
async def enter_lab_result(
    sample_id: str,
    req: LabSampleResultUpdate,
    current_user: User = Depends(require_roles(UserRole.LAB_TECHNICIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(LabSample).where(LabSample.id == sample_id)
    res = await session.execute(stmt)
    sample = res.scalar_one_or_none()
    if not sample:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lab sample not found")

    sample.test_method = req.test_method
    sample.test_result = req.test_result
    sample.pathogen_confirmed = req.pathogen_confirmed or sample.suspected_disease
    sample.result_notes = req.result_notes
    sample.report_file_url = req.report_file_url
    sample.lab_technician_id = current_user.id
    sample.result_date = datetime.now(timezone.utc)
    sample.transit_status = "completed"

    # Automated Escalation on Lab Confirmation of High-Threat or Zoonotic Pathogen
    if req.test_result == "positive" and sample.is_zoonotic:
        logger.warning(
            "zoonotic_lab_confirmation_escalated",
            sample_code=sample.sample_code,
            disease=sample.pathogen_confirmed,
        )
        # Auto-create or escalate outbreak event if not already present
        ob_stmt = select(OutbreakEvent).where(
            OutbreakEvent.district_id == sample.district_id,
            OutbreakEvent.disease_name == sample.pathogen_confirmed,
        )
        ob_res = await session.execute(ob_stmt)
        existing_ob = ob_res.scalar_one_or_none()
        if not existing_ob:
            new_ob = OutbreakEvent(
                district_id=sample.district_id,
                disease_name=sample.pathogen_confirmed or sample.suspected_disease,
                case_count=1,
                risk_level=SeverityLevelEnum.CRITICAL,
                quarantine_declared=True,
                notes_multilingual_json={
                    "en": f"Laboratory confirmed {sample.pathogen_confirmed} via {req.test_method} by {current_user.full_name}.",
                    "mr": f"प्रयोगशाळेत {req.test_method} द्वारे {sample.pathogen_confirmed} रोगाची खात्री झाली आहे.",
                },
            )
            session.add(new_ob)

    await session.commit()
    await session.refresh(sample)
    return LabSampleResponse.model_validate(sample)


@router.post(
    "/samples/{sample_id}/refer",
    response_model=LabSampleResponse,
    summary="Refer sample to higher reference laboratory (SDDL / NIHSAD)",
)
async def refer_sample(
    sample_id: str,
    target_lab: str = Query(..., description="e.g. State Disease Diagnostic Lab (SDDL) Pune or NIHSAD Bhopal"),
    current_user: User = Depends(require_roles(UserRole.LAB_TECHNICIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN)),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(LabSample).where(LabSample.id == sample_id)
    res = await session.execute(stmt)
    sample = res.scalar_one_or_none()
    if not sample:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lab sample not found")

    sample.transit_status = "referred"
    sample.referred_to_lab = target_lab
    await session.commit()
    await session.refresh(sample)
    logger.info("sample_referred", sample_id=sample.id, target_lab=target_lab)
    return LabSampleResponse.model_validate(sample)
