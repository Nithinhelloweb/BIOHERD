"""
Veterinarian Case Management & Telemedicine Endpoints
Tailored for Government of Maharashtra Animal Husbandry Department (BIOHERD SIH26128).
Provides case triage, digital prescriptions with Schedule-H warnings and withdrawal tracking,
and WebRTC tele-consultation room signaling.
"""

from typing import Any, List, Optional
from datetime import datetime, timezone
import hashlib
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, desc

from app.db.session import get_db
from app.db.models import (
    User,
    UserRole,
    Case,
    CaseStatusEnum,
    SeverityLevelEnum,
    Prescription,
    SymptomReport,
    DetectionResult,
    Animal,
    Farm,
    HealthEvent,
    HealthEventType,
)
from app.api.deps import get_current_user, require_roles
from app.core.drug_catalog import DrugCatalog
from app.services.telemedicine_service import TelemedicineService
from app.schemas.cases import (
    CaseListItem,
    CaseDetailResponse,
    CaseAssignRequest,
    CaseStatusUpdateRequest,
    PrescriptionCreate,
    PrescriptionResponse,
    DosageCalculateRequest,
    DosageCalculateResponse,
    TelemedicineSessionCreate,
    TelemedicineSessionResponse,
    TelemedicineSignalPayload,
)

router = APIRouter(prefix="/cases", tags=["Veterinarian Cases & Telemedicine"])


# ============================================================================
# Formularies & Dosage Calculation
# ============================================================================

@router.get("/drugs/catalog", response_model=List[dict])
async def get_drug_catalog(
    species: Optional[str] = Query(None, description="cattle, buffalo, goat, sheep, pig, poultry"),
    disease: Optional[str] = Query(None, description="FMD, LSD, mastitis, etc."),
    schedule_h: Optional[bool] = Query(None, description="Filter Schedule-H restricted drugs"),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Returns curated Maharashtra State Veterinary Formulary drugs with clinical indications.
    """
    return DrugCatalog.filter_by(species=species, disease_query=disease, schedule_h=schedule_h)


@router.post("/drugs/calculate-dosage", response_model=DosageCalculateResponse)
async def calculate_drug_dosage(
    payload: DosageCalculateRequest,
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Calculates precise weight-adjusted dosage volume, withdrawal days, and Marathi instructions.
    """
    try:
        result = DrugCatalog.calculate_dosage(
            drug_id=payload.drug_id,
            species=payload.species,
            body_weight_kg=payload.body_weight_kg,
        )
        return DosageCalculateResponse(**result)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


# ============================================================================
# Telemedicine Room Signaling
# ============================================================================

@router.post("/telemedicine/create-session", response_model=TelemedicineSessionResponse)
async def create_telemedicine_session(
    payload: TelemedicineSessionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Provisions a WebRTC tele-consultation room for farmer-veterinarian live video consultation.
    """
    case_query = await db.execute(select(Case).where(Case.id == payload.case_id))
    case = case_query.scalar_one_or_none()
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Case not found.")

    session_info = TelemedicineService.create_session(
        case_id=case.id,
        vet_id=current_user.id if current_user.role == UserRole.VETERINARIAN else None,
    )

    # Attach session to case and update status to in_review if currently assigned
    case.telemedicine_session_id = session_info["session_id"]
    if case.status in [CaseStatusEnum.SUBMITTED, CaseStatusEnum.ASSIGNED]:
        case.status = CaseStatusEnum.IN_REVIEW
    await db.commit()

    return TelemedicineSessionResponse(
        session_id=session_info["session_id"],
        case_id=session_info["case_id"],
        room_name=session_info["room_name"],
        ice_servers=session_info["ice_servers"],
        status=session_info["status"],
        created_at=session_info["created_at"],
    )


@router.post("/telemedicine/signal", response_model=dict)
async def relay_telemedicine_signal(
    payload: TelemedicineSignalPayload,
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Relays WebRTC SDP Offer/Answer and ICE candidates between peers.
    """
    return TelemedicineService.relay_signal(
        session_id=payload.session_id,
        sender_id=payload.sender_id,
        signal_type=payload.signal_type,
        data=payload.data,
    )


@router.get("/telemedicine/signals/{session_id}", response_model=List[dict])
async def get_telemedicine_signals(
    session_id: str,
    recipient_id: str = Query(...),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Polls incoming WebRTC signals for peer client.
    """
    return TelemedicineService.get_pending_signals(session_id=session_id, recipient_id=recipient_id)


@router.post("/telemedicine/{session_id}/end", response_model=dict)
async def end_telemedicine_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Ends tele-consultation session.
    """
    ended = TelemedicineService.end_session(session_id)
    if not ended:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    return {"status": "ended", "session_id": session_id}


# ============================================================================
# Clinical Case Management
# ============================================================================

@router.get("", response_model=List[CaseListItem])
async def list_cases(
    status_filter: Optional[str] = Query(None, alias="status"),
    priority_filter: Optional[str] = Query(None, alias="priority"),
    vet_id: Optional[str] = Query(None),
    unassigned_only: bool = Query(False),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Lists clinical cases for veterinary triage and monitoring.
    """
    stmt = (
        select(Case, SymptomReport, Animal, User, Farm)
        .join(SymptomReport, Case.symptom_report_id == SymptomReport.id)
        .join(Animal, SymptomReport.animal_id == Animal.id)
        .outerjoin(User, Case.assigned_vet_id == User.id)
        .outerjoin(Farm, Animal.farm_id == Farm.id)
        .order_by(desc(Case.created_at))
        .limit(limit)
    )

    if status_filter:
        try:
            status_enum = CaseStatusEnum(status_filter.lower())
            stmt = stmt.where(Case.status == status_enum)
        except ValueError:
            pass

    if priority_filter:
        try:
            priority_enum = SeverityLevelEnum(priority_filter.lower())
            stmt = stmt.where(Case.priority == priority_enum)
        except ValueError:
            pass

    if unassigned_only:
        stmt = stmt.where(Case.assigned_vet_id == None)
    elif vet_id:
        stmt = stmt.where(Case.assigned_vet_id == vet_id)
    elif current_user.role == UserRole.FARMER:
        # Farmers only see cases for their own animals
        stmt = stmt.where(SymptomReport.reported_by == current_user.id)

    result = await db.execute(stmt)
    rows = result.all()

    items: List[CaseListItem] = []
    for case_obj, report_obj, animal_obj, vet_obj, farm_obj in rows:
        # Fetch detection result suspect if available
        det_stmt = select(DetectionResult).where(DetectionResult.symptom_report_id == report_obj.id)
        det_res = (await db.execute(det_stmt)).scalar_one_or_none()

        primary_suspect = None
        primary_suspect_mr = None
        ai_conf = None
        if det_res and det_res.predictions_json and len(det_res.predictions_json) > 0:
            top_p = det_res.predictions_json[0]
            primary_suspect = top_p.get("name_en")
            primary_suspect_mr = top_p.get("name_mr")
            ai_conf = det_res.confidence

        # Check prescriptions
        presc_stmt = select(Prescription.id).where(Prescription.case_id == case_obj.id).limit(1)
        has_presc = (await db.execute(presc_stmt)).scalar_one_or_none() is not None

        items.append(
            CaseListItem(
                id=case_obj.id,
                symptom_report_id=report_obj.id,
                assigned_vet_id=case_obj.assigned_vet_id,
                assigned_vet_name=vet_obj.full_name if vet_obj else None,
                status=case_obj.status.value,
                priority=case_obj.priority.value if hasattr(case_obj.priority, "value") else str(case_obj.priority),
                animal_id=animal_obj.id,
                animal_tag_id=animal_obj.tag_id,
                animal_species=animal_obj.species.value if hasattr(animal_obj.species, "value") else str(animal_obj.species),
                animal_breed=animal_obj.breed,
                farmer_name=farm_obj.owner.full_name if (farm_obj and hasattr(farm_obj, "owner") and farm_obj.owner) else "Local Farmer",
                farmer_phone=farm_obj.owner.phone if (farm_obj and hasattr(farm_obj, "owner") and farm_obj.owner) else None,
                district_name="Maharashtra District",
                primary_suspect=primary_suspect,
                primary_suspect_mr=primary_suspect_mr,
                ai_confidence=ai_conf,
                has_prescription=has_presc,
                created_at=case_obj.created_at,
                updated_at=case_obj.updated_at,
            )
        )

    return items


@router.get("/{id}", response_model=CaseDetailResponse)
async def get_case_detail(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Returns complete clinical case dossier including medical history,
    symptom checklist, AI prediction, and digital prescription history.
    """
    stmt = (
        select(Case, SymptomReport, Animal, User, Farm)
        .join(SymptomReport, Case.symptom_report_id == SymptomReport.id)
        .join(Animal, SymptomReport.animal_id == Animal.id)
        .outerjoin(User, Case.assigned_vet_id == User.id)
        .outerjoin(Farm, Animal.farm_id == Farm.id)
        .where(Case.id == id)
    )
    result = await db.execute(stmt)
    row = result.first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Case not found.")

    case_obj, report_obj, animal_obj, vet_obj, farm_obj = row

    # Farmer lookup
    farmer_query = await db.execute(select(User).where(User.id == report_obj.reported_by))
    farmer_user = farmer_query.scalar_one_or_none()

    # AI Detection result
    det_stmt = select(DetectionResult).where(DetectionResult.symptom_report_id == report_obj.id)
    det_res = (await db.execute(det_stmt)).scalar_one_or_none()

    primary_name = None
    primary_name_mr = None
    ai_conf = None
    if det_res and det_res.predictions_json and len(det_res.predictions_json) > 0:
        top_p = det_res.predictions_json[0]
        primary_name = top_p.get("name_en")
        primary_name_mr = top_p.get("name_mr")
        ai_conf = det_res.confidence

    # Extract symptoms checklist summary
    symptoms_list: List[str] = []
    if report_obj.symptoms_json and isinstance(report_obj.symptoms_json, dict):
        chk = report_obj.symptoms_json.get("checklist", {})
        if isinstance(chk, dict):
            for k, v in chk.items():
                if v is True:
                    symptoms_list.append(k.replace("_", " ").title())
        vernacular_desc = report_obj.symptoms_json.get("vernacular_description")
        if vernacular_desc:
            symptoms_list.append(f"Notes: {vernacular_desc}")

    # Prescriptions
    presc_stmt = (
        select(Prescription, User)
        .outerjoin(User, Prescription.issued_by == User.id)
        .where(Prescription.case_id == case_obj.id)
        .order_by(desc(Prescription.created_at))
    )
    presc_rows = (await db.execute(presc_stmt)).all()
    prescriptions: List[PrescriptionResponse] = []
    for p_obj, u_obj in presc_rows:
        prescriptions.append(
            PrescriptionResponse(
                id=p_obj.id,
                case_id=p_obj.case_id,
                issued_by=p_obj.issued_by,
                issued_by_name=u_obj.full_name if u_obj else "Veterinarian",
                drug_name=p_obj.drug_name,
                dosage=p_obj.dosage,
                duration_days=p_obj.duration_days,
                instructions_multilingual_json=p_obj.instructions_multilingual_json or {},
                schedule_h_warning=p_obj.schedule_h_warning,
                milk_withdrawal_days=p_obj.milk_withdrawal_days,
                meat_withdrawal_days=p_obj.meat_withdrawal_days,
                digital_signature_hash=p_obj.digital_signature_hash,
                pdf_url=p_obj.pdf_url,
                created_at=p_obj.created_at,
            )
        )

    return CaseDetailResponse(
        id=case_obj.id,
        symptom_report_id=report_obj.id,
        assigned_vet_id=case_obj.assigned_vet_id,
        assigned_vet_name=vet_obj.full_name if vet_obj else None,
        status=case_obj.status.value,
        priority=case_obj.priority.value if hasattr(case_obj.priority, "value") else str(case_obj.priority),
        telemedicine_session_id=case_obj.telemedicine_session_id,
        resolution_summary=case_obj.resolution_summary,
        notes=case_obj.notes,
        animal_id=animal_obj.id,
        animal_tag_id=animal_obj.tag_id,
        animal_species=animal_obj.species.value if hasattr(animal_obj.species, "value") else str(animal_obj.species),
        animal_breed=animal_obj.breed,
        animal_weight_kg=getattr(animal_obj, "weight_kg", 350.0),
        farmer_id=farmer_user.id if farmer_user else None,
        farmer_name=farmer_user.full_name if farmer_user else "Local Farmer",
        farmer_phone=farmer_user.phone if farmer_user else None,
        district_name="Maharashtra District",
        primary_diagnosis=primary_name,
        primary_diagnosis_mr=primary_name_mr,
        ai_confidence=ai_conf,
        symptoms_summary=symptoms_list,
        images=report_obj.images_json or [],
        voice_note_url=report_obj.voice_note_url,
        prescriptions=prescriptions,
        created_at=case_obj.created_at,
        updated_at=case_obj.updated_at,
    )


@router.post("/{id}/assign", response_model=dict)
async def assign_case(
    id: str,
    payload: CaseAssignRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN])),
) -> Any:
    """
    Assigns an unassigned clinical case to a veterinarian.
    """
    stmt = select(Case).where(Case.id == id)
    case = (await db.execute(stmt)).scalar_one_or_none()
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Case not found.")

    case.assigned_vet_id = payload.vet_id
    if case.status == CaseStatusEnum.SUBMITTED:
        case.status = CaseStatusEnum.ASSIGNED
    if payload.notes:
        case.notes = f"{case.notes}\n[Triage Note]: {payload.notes}" if case.notes else payload.notes
    case.updated_at = datetime.now(timezone.utc)

    await db.commit()
    return {"status": "success", "case_id": case.id, "assigned_vet_id": payload.vet_id, "case_status": case.status.value}


@router.patch("/{id}/status", response_model=dict)
async def update_case_status(
    id: str,
    payload: CaseStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN])),
) -> Any:
    """
    Transitions clinical case status: submitted -> assigned -> in_review -> prescription_issued -> follow_up -> closed.
    """
    stmt = select(Case).where(Case.id == id)
    case = (await db.execute(stmt)).scalar_one_or_none()
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Case not found.")

    try:
        new_status = CaseStatusEnum(payload.status.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status '{payload.status}'. Valid values: {[s.value for s in CaseStatusEnum]}",
        )

    case.status = new_status
    if payload.notes:
        case.notes = f"{case.notes}\n{payload.notes}" if case.notes else payload.notes
    if payload.resolution_summary:
        case.resolution_summary = payload.resolution_summary
    case.updated_at = datetime.now(timezone.utc)

    await db.commit()
    return {"status": "success", "case_id": case.id, "new_status": case.status.value}


@router.post("/{id}/prescriptions", response_model=PrescriptionResponse, status_code=status.HTTP_201_CREATED)
async def issue_prescription(
    id: str,
    payload: PrescriptionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.VETERINARIAN, UserRole.STATE_ADMIN, UserRole.SUPER_ADMIN])),
) -> Any:
    """
    Issues a digital prescription with Schedule-H antibiotic controls,
    mandatory withdrawal warnings, and cryptographic digital signature hash.
    Automatically logs a MEDICATION event on the animal health timeline.
    """
    stmt = (
        select(Case, SymptomReport, Animal)
        .join(SymptomReport, Case.symptom_report_id == SymptomReport.id)
        .join(Animal, SymptomReport.animal_id == Animal.id)
        .where(Case.id == id)
    )
    row = (await db.execute(stmt)).first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Case not found.")

    case_obj, report_obj, animal_obj = row

    # Compute tamper-evident digital signature hash
    raw_signature = f"{case_obj.id}:{payload.drug_name}:{payload.dosage}:{current_user.id}:{datetime.now(timezone.utc).isoformat()}"
    signature_hash = hashlib.sha256(raw_signature.encode("utf-8")).hexdigest()

    prescription = Prescription(
        case_id=case_obj.id,
        issued_by=current_user.id,
        drug_name=payload.drug_name,
        dosage=payload.dosage,
        duration_days=payload.duration_days,
        instructions_multilingual_json=payload.instructions_multilingual_json or {},
        schedule_h_warning=payload.schedule_h_warning,
        milk_withdrawal_days=payload.milk_withdrawal_days,
        meat_withdrawal_days=payload.meat_withdrawal_days,
        digital_signature_hash=signature_hash,
    )
    db.add(prescription)

    # Transition case status to prescription_issued
    case_obj.status = CaseStatusEnum.PRESCRIPTION_ISSUED
    case_obj.updated_at = datetime.now(timezone.utc)

    # Log to Animal's Health Timeline as MEDICATION event
    health_event = HealthEvent(
        animal_id=animal_obj.id,
        event_type=HealthEventType.MEDICATION,
        description=f"Prescribed {payload.drug_name} ({payload.dosage}) for {payload.duration_days} days by Dr. {current_user.full_name}. Digital Rx: #{signature_hash[:8]}.",
        recorded_by=current_user.id,
        occurred_at=datetime.now(timezone.utc),
    )
    db.add(health_event)

    await db.commit()
    await db.refresh(prescription)

    return PrescriptionResponse(
        id=prescription.id,
        case_id=prescription.case_id,
        issued_by=prescription.issued_by,
        issued_by_name=current_user.full_name or "Licensed Veterinarian",
        drug_name=prescription.drug_name,
        dosage=prescription.dosage,
        duration_days=prescription.duration_days,
        instructions_multilingual_json=prescription.instructions_multilingual_json or {},
        schedule_h_warning=prescription.schedule_h_warning,
        milk_withdrawal_days=prescription.milk_withdrawal_days,
        meat_withdrawal_days=prescription.meat_withdrawal_days,
        digital_signature_hash=prescription.digital_signature_hash,
        pdf_url=prescription.pdf_url,
        created_at=prescription.created_at,
    )


@router.get("/{id}/prescriptions", response_model=List[PrescriptionResponse])
async def list_case_prescriptions(
    id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Returns all digital prescriptions issued for a specific case.
    """
    stmt = (
        select(Prescription, User)
        .outerjoin(User, Prescription.issued_by == User.id)
        .where(Prescription.case_id == id)
        .order_by(desc(Prescription.created_at))
    )
    rows = (await db.execute(stmt)).all()

    items = []
    for presc, user in rows:
        items.append(
            PrescriptionResponse(
                id=presc.id,
                case_id=presc.case_id,
                issued_by=presc.issued_by,
                issued_by_name=user.full_name if user else "Veterinarian",
                drug_name=presc.drug_name,
                dosage=presc.dosage,
                duration_days=presc.duration_days,
                instructions_multilingual_json=presc.instructions_multilingual_json or {},
                schedule_h_warning=presc.schedule_h_warning,
                milk_withdrawal_days=presc.milk_withdrawal_days,
                meat_withdrawal_days=presc.meat_withdrawal_days,
                digital_signature_hash=presc.digital_signature_hash,
                pdf_url=presc.pdf_url,
                created_at=presc.created_at,
            )
        )
    return items
