"""
BIOHERD Symptom Reporting & AI Disease Detection Endpoints
Handles multi-modal symptom intake, AI ensemble inference, case auto-escalation,
and historical diagnostic retrieval.
"""

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.disease_catalog import get_all_diseases, get_disease_by_id, get_diseases_for_species
from app.db.models import (
    Alert,
    Animal,
    Case,
    CaseStatusEnum,
    DetectionResult,
    HealthEvent,
    HealthEventType,
    SeverityLevelEnum,
    SymptomReport,
    User,
)
from app.db.session import get_db
from app.schemas.symptom import (
    AIDetectionRequest,
    AIDetectionResponse,
    DiseaseItem,
    DiseasePrediction,
    FirstAidPayload,
    SymptomReportCreate,
    SymptomReportResponse,
)
from app.services.ai_detector import AIDetectionService


router = APIRouter(prefix="/symptoms", tags=["symptoms-ai"])


@router.get("/diseases", response_model=List[DiseaseItem])
async def list_endemic_diseases(
    species: Optional[str] = Query(None, description="Filter diseases by animal species (cattle, buffalo, goat, sheep, pig)")
) -> Any:
    """Returns the authentic catalog of endemic livestock diseases in Maharashtra."""
    if species:
        diseases = get_diseases_for_species(species)
    else:
        diseases = get_all_diseases()

    return [
        DiseaseItem(
            id=d.id,
            name_en=d.name_en,
            name_mr=d.name_mr,
            species=d.species,
            causative_agent=d.causative_agent,
            severity_baseline=d.severity_baseline,
            incubation_period=d.incubation_period,
            cardinal_symptoms=d.cardinal_symptoms,
            symptom_system_map=d.symptom_system_map,
            isolation_required=d.isolation_required,
            zoonotic_risk=d.zoonotic_risk,
            first_aid_en=d.first_aid_en,
            first_aid_mr=d.first_aid_mr,
        )
        for d in diseases
    ]


@router.get("/diseases/{disease_id}", response_model=DiseaseItem)
async def get_disease_detail(disease_id: str) -> Any:
    """Returns full clinical details and first-aid protocols for a disease."""
    d = get_disease_by_id(disease_id)
    if not d:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Disease with ID '{disease_id}' not found in Maharashtra catalog.",
        )
    return DiseaseItem(
        id=d.id,
        name_en=d.name_en,
        name_mr=d.name_mr,
        species=d.species,
        causative_agent=d.causative_agent,
        severity_baseline=d.severity_baseline,
        incubation_period=d.incubation_period,
        cardinal_symptoms=d.cardinal_symptoms,
        symptom_system_map=d.symptom_system_map,
        isolation_required=d.isolation_required,
        zoonotic_risk=d.zoonotic_risk,
        first_aid_en=d.first_aid_en,
        first_aid_mr=d.first_aid_mr,
    )


@router.post("/analyze", response_model=AIDetectionResponse)
async def analyze_symptoms(
    payload: AIDetectionRequest,
    db: AsyncSession = Depends(get_db),
) -> Any:
    """
    Direct multi-modal AI inference endpoint.
    Processes species, symptoms checklist, vernacular description, and images.
    """
    species = payload.species
    # If animal_id is supplied, look up species if not explicitly specified
    if payload.animal_id and not species:
        result = await db.execute(select(Animal).where(Animal.id == payload.animal_id))
        animal = result.scalar_one_or_none()
        if animal:
            species = animal.species.value

    ai_result = AIDetectionService.analyze(
        species=species,
        symptoms_checklist=payload.symptoms_checklist,
        vernacular_description=payload.vernacular_description,
        images=payload.images,
    )

    return AIDetectionResponse(
        model_version=ai_result["model_version"],
        primary_diagnosis=DiseasePrediction(**ai_result["primary_diagnosis"]),
        differential_diagnoses=[DiseasePrediction(**d) for d in ai_result["differential_diagnoses"]],
        severity=ai_result["severity"],
        confidence=ai_result["confidence"],
        should_escalate_case=ai_result["should_escalate_case"],
        first_aid=FirstAidPayload(**ai_result["first_aid"]),
        inference_duration_ms=ai_result["inference_duration_ms"],
    )


@router.post("/reports", response_model=SymptomReportResponse, status_code=status.HTTP_201_CREATED)
async def submit_symptom_report(
    payload: SymptomReportCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Submits a comprehensive livestock symptom report.
    Executes AI inference, stores detection results, logs health events,
    and automatically escalates severe cases to district veterinarians.
    """
    # 1. Verify animal exists
    result = await db.execute(select(Animal).where(Animal.id == payload.animal_id))
    animal = result.scalar_one_or_none()
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ID '{payload.animal_id}' does not exist.",
        )

    # 2. Run multi-modal AI detection
    species_str = animal.species.value if hasattr(animal.species, "value") else str(animal.species)
    ai_result = AIDetectionService.analyze(
        species=species_str,
        symptoms_checklist=payload.symptoms_checklist,
        vernacular_description=payload.vernacular_description,
        images=payload.images,
    )

    # Map severity to enum
    severity_str = ai_result["severity"].lower()
    severity_enum_map = {
        "low": SeverityLevelEnum.LOW,
        "medium": SeverityLevelEnum.MEDIUM,
        "high": SeverityLevelEnum.HIGH,
        "critical": SeverityLevelEnum.CRITICAL,
    }
    severity_enum = severity_enum_map.get(severity_str, SeverityLevelEnum.MEDIUM)

    # Build stored symptoms payload
    stored_symptoms: Dict[str, Any] = {
        "checklist": payload.symptoms_checklist or {},
        "vernacular_description": payload.vernacular_description or "",
    }

    # 3. Create SymptomReport record
    symptom_report = SymptomReport(
        animal_id=animal.id,
        reported_by=current_user.id,
        symptoms_json=stored_symptoms,
        severity=severity_enum,
        status="submitted",
        voice_note_url=payload.voice_note_url,
        images_json=payload.images or [],
    )
    db.add(symptom_report)
    await db.flush()

    # 4. Create DetectionResult record
    top_predictions = [ai_result["primary_diagnosis"]] + ai_result["differential_diagnoses"]
    detection_result = DetectionResult(
        symptom_report_id=symptom_report.id,
        model_version=ai_result["model_version"],
        predictions_json=top_predictions,
        confidence=ai_result["confidence"],
        inference_duration_ms=ai_result["inference_duration_ms"],
    )
    db.add(detection_result)

    # 5. Automated Triage & Clinical Case Escalation for HIGH / CRITICAL conditions
    case_id: Optional[str] = None
    if ai_result["should_escalate_case"] or severity_enum in [SeverityLevelEnum.HIGH, SeverityLevelEnum.CRITICAL]:
        primary_name = ai_result["primary_diagnosis"]["name_en"]
        case = Case(
            symptom_report_id=symptom_report.id,
            status=CaseStatusEnum.SUBMITTED,
            notes=f"Auto-escalated by AI Detector. Primary suspect: {primary_name} ({ai_result['confidence']}% confidence). Immediate clinical review required.",
        )
        db.add(case)
        await db.flush()
        case_id = case.id

        # Generate alert record
        alert = Alert(
            recipient_user_id=current_user.id,
            alert_type="diagnosis",
            severity=severity_enum,
            title_multilingual_json={
                "en": f"URGENT: {primary_name} Suspected",
                "mr": f"तातडीचे: {ai_result['primary_diagnosis']['name_mr']} चा संशय",
            },
            body_multilingual_json={
                "en": f"AI diagnostic triage detected potential {primary_name} for tag {animal.tag_id}. Case #{case.id[:8]} opened.",
                "mr": f"टॅग {animal.tag_id} साठी {ai_result['primary_diagnosis']['name_mr']} आढळले आहे. केस #{case.id[:8]} उघडली आहे.",
            },
            channels=["push", "sms"],
        )
        db.add(alert)

    # 6. Record HealthEvent on animal timeline
    health_event = HealthEvent(
        animal_id=animal.id,
        event_type=HealthEventType.DISEASE,
        description=f"AI Screening: {ai_result['primary_diagnosis']['name_en']} ({ai_result['confidence']}%) - Severity: {severity_str.upper()}",
        recorded_by=current_user.id,
    )
    db.add(health_event)

    await db.commit()
    await db.refresh(symptom_report)

    ai_response = AIDetectionResponse(
        model_version=ai_result["model_version"],
        primary_diagnosis=DiseasePrediction(**ai_result["primary_diagnosis"]),
        differential_diagnoses=[DiseasePrediction(**d) for d in ai_result["differential_diagnoses"]],
        severity=ai_result["severity"],
        confidence=ai_result["confidence"],
        should_escalate_case=ai_result["should_escalate_case"],
        first_aid=FirstAidPayload(**ai_result["first_aid"]),
        inference_duration_ms=ai_result["inference_duration_ms"],
    )

    species_str = animal.species.value if hasattr(animal.species, "value") else str(animal.species)
    severity_str = symptom_report.severity.value if hasattr(symptom_report.severity, "value") else str(symptom_report.severity)

    return SymptomReportResponse(
        id=symptom_report.id,
        animal_id=animal.id,
        animal_tag_id=animal.tag_id,
        species=species_str,
        breed=animal.breed,
        reported_by=current_user.id,
        symptoms_json=symptom_report.symptoms_json,
        severity=severity_str,
        status=symptom_report.status,
        voice_note_url=symptom_report.voice_note_url,
        images_json=symptom_report.images_json,
        detection_result=ai_response,
        case_id=case_id,
        created_at=symptom_report.created_at,
    )


@router.get("/reports", response_model=List[SymptomReportResponse])
async def list_symptom_reports(
    animal_id: Optional[str] = Query(None, description="Filter by animal ID"),
    severity: Optional[str] = Query(None, description="Filter by severity level"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Lists historical symptom reports with AI diagnostics and case links."""
    query = (
        select(SymptomReport, Animal, DetectionResult, Case)
        .join(Animal, SymptomReport.animal_id == Animal.id)
        .outerjoin(DetectionResult, DetectionResult.symptom_report_id == SymptomReport.id)
        .outerjoin(Case, Case.symptom_report_id == SymptomReport.id)
    )

    if animal_id:
        query = query.where(SymptomReport.animal_id == animal_id)

    if severity:
        sev_upper = severity.upper()
        if sev_upper in SeverityLevelEnum.__members__:
            query = query.where(SymptomReport.severity == SeverityLevelEnum[sev_upper])

    query = query.order_by(desc(SymptomReport.created_at)).offset(skip).limit(limit)
    results = (await db.execute(query)).all()

    response_list = []
    for report, animal, detection, case in results:
        det_response = None
        if detection and detection.predictions_json:
            primary_data = detection.predictions_json[0]
            diffs = detection.predictions_json[1:] if len(detection.predictions_json) > 1 else []
            d_obj = get_disease_by_id(primary_data.get("disease_id", ""))
            first_aid = {
                "en": d_obj.first_aid_en if d_obj else {},
                "mr": d_obj.first_aid_mr if d_obj else {},
                "isolation_required": d_obj.isolation_required if d_obj else False,
                "zoonotic_risk": d_obj.zoonotic_risk if d_obj else False,
            }
            det_response = AIDetectionResponse(
                model_version=detection.model_version,
                primary_diagnosis=DiseasePrediction(**primary_data),
                differential_diagnoses=[DiseasePrediction(**d) for d in diffs],
                severity=primary_data.get("severity", "MEDIUM"),
                confidence=detection.confidence,
                should_escalate_case=case is not None,
                first_aid=FirstAidPayload(**first_aid),
                inference_duration_ms=detection.inference_duration_ms,
            )

        item_species = animal.species.value if hasattr(animal.species, "value") else str(animal.species)
        item_severity = report.severity.value if hasattr(report.severity, "value") else str(report.severity)

        response_list.append(
            SymptomReportResponse(
                id=report.id,
                animal_id=animal.id,
                animal_tag_id=animal.tag_id,
                species=item_species,
                breed=animal.breed,
                reported_by=report.reported_by,
                symptoms_json=report.symptoms_json,
                severity=item_severity,
                status=report.status,
                voice_note_url=report.voice_note_url,
                images_json=report.images_json,
                detection_result=det_response,
                case_id=case.id if case else None,
                created_at=report.created_at,
            )
        )

    return response_list


@router.get("/reports/{report_id}", response_model=SymptomReportResponse)
async def get_symptom_report_detail(
    report_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Retrieves a single symptom report by ID with full AI detection output."""
    query = (
        select(SymptomReport, Animal, DetectionResult, Case)
        .join(Animal, SymptomReport.animal_id == Animal.id)
        .outerjoin(DetectionResult, DetectionResult.symptom_report_id == SymptomReport.id)
        .outerjoin(Case, Case.symptom_report_id == SymptomReport.id)
        .where(SymptomReport.id == report_id)
    )

    res = (await db.execute(query)).first()
    if not res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Symptom report with ID '{report_id}' not found.",
        )

    report, animal, detection, case = res
    det_response = None
    if detection and detection.predictions_json:
        primary_data = detection.predictions_json[0]
        diffs = detection.predictions_json[1:] if len(detection.predictions_json) > 1 else []
        d_obj = get_disease_by_id(primary_data.get("disease_id", ""))
        first_aid = {
            "en": d_obj.first_aid_en if d_obj else {},
            "mr": d_obj.first_aid_mr if d_obj else {},
            "isolation_required": d_obj.isolation_required if d_obj else False,
            "zoonotic_risk": d_obj.zoonotic_risk if d_obj else False,
        }
        det_response = AIDetectionResponse(
            model_version=detection.model_version,
            primary_diagnosis=DiseasePrediction(**primary_data),
            differential_diagnoses=[DiseasePrediction(**d) for d in diffs],
            severity=primary_data.get("severity", "MEDIUM"),
            confidence=detection.confidence,
            should_escalate_case=case is not None,
            first_aid=FirstAidPayload(**first_aid),
            inference_duration_ms=detection.inference_duration_ms,
        )

    detail_species = animal.species.value if hasattr(animal.species, "value") else str(animal.species)
    detail_severity = report.severity.value if hasattr(report.severity, "value") else str(report.severity)

    return SymptomReportResponse(
        id=report.id,
        animal_id=animal.id,
        animal_tag_id=animal.tag_id,
        species=detail_species,
        breed=animal.breed,
        reported_by=report.reported_by,
        symptoms_json=report.symptoms_json,
        severity=detail_severity,
        status=report.status,
        voice_note_url=report.voice_note_url,
        images_json=report.images_json,
        detection_result=det_response,
        case_id=case.id if case else None,
        created_at=report.created_at,
    )
