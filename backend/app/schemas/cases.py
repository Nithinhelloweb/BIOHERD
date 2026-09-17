"""
Pydantic Schemas for Veterinarian Case Management & Telemedicine
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class PrescriptionCreate(BaseModel):
    drug_name: str = Field(..., min_length=2, max_length=150)
    drug_id: Optional[str] = None
    dosage: str = Field(..., min_length=2, max_length=100)
    duration_days: int = Field(default=5, ge=1, le=60)
    instructions_multilingual_json: Optional[Dict[str, str]] = Field(default_factory=dict)
    schedule_h_warning: bool = False
    milk_withdrawal_days: int = Field(default=0, ge=0)
    meat_withdrawal_days: int = Field(default=0, ge=0)


class PrescriptionResponse(BaseModel):
    id: str
    case_id: str
    issued_by: str
    issued_by_name: Optional[str] = None
    drug_name: str
    dosage: str
    duration_days: int
    instructions_multilingual_json: Dict[str, str] = Field(default_factory=dict)
    schedule_h_warning: bool = False
    milk_withdrawal_days: int = 0
    meat_withdrawal_days: int = 0
    digital_signature_hash: Optional[str] = None
    pdf_url: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CaseAssignRequest(BaseModel):
    vet_id: str
    notes: Optional[str] = None


class CaseStatusUpdateRequest(BaseModel):
    status: str = Field(..., description="submitted, assigned, in_review, prescription_issued, follow_up, closed")
    notes: Optional[str] = None
    resolution_summary: Optional[str] = None


class CaseListItem(BaseModel):
    id: str
    symptom_report_id: str
    assigned_vet_id: Optional[str] = None
    assigned_vet_name: Optional[str] = None
    status: str
    priority: str
    animal_id: Optional[str] = None
    animal_tag_id: Optional[str] = None
    animal_species: Optional[str] = None
    animal_breed: Optional[str] = None
    farmer_name: Optional[str] = None
    farmer_phone: Optional[str] = None
    district_name: Optional[str] = None
    primary_suspect: Optional[str] = None
    primary_suspect_mr: Optional[str] = None
    ai_confidence: Optional[float] = None
    has_prescription: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CaseDetailResponse(BaseModel):
    id: str
    symptom_report_id: str
    assigned_vet_id: Optional[str] = None
    assigned_vet_name: Optional[str] = None
    status: str
    priority: str
    telemedicine_session_id: Optional[str] = None
    resolution_summary: Optional[str] = None
    notes: Optional[str] = None
    animal_id: Optional[str] = None
    animal_tag_id: Optional[str] = None
    animal_species: Optional[str] = None
    animal_breed: Optional[str] = None
    animal_weight_kg: Optional[float] = None
    farmer_id: Optional[str] = None
    farmer_name: Optional[str] = None
    farmer_phone: Optional[str] = None
    district_name: Optional[str] = None
    primary_diagnosis: Optional[str] = None
    primary_diagnosis_mr: Optional[str] = None
    ai_confidence: Optional[float] = None
    symptoms_summary: List[str] = Field(default_factory=list)
    images: List[str] = Field(default_factory=list)
    voice_note_url: Optional[str] = None
    prescriptions: List[PrescriptionResponse] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DosageCalculateRequest(BaseModel):
    drug_id: str
    species: str
    body_weight_kg: float = Field(..., gt=0.0, le=2000.0)


class DosageCalculateResponse(BaseModel):
    drug_id: str
    drug_name: str
    category: str
    schedule_h: bool
    route: str
    body_weight_kg: float
    calculated_volume_ml: float
    display_dose: str
    display_dose_mr: str
    default_duration_days: int
    milk_withdrawal_days: int
    meat_withdrawal_days: int
    instructions_en: str
    instructions_mr: str
    contraindications: str


class TelemedicineSessionCreate(BaseModel):
    case_id: str


class TelemedicineSessionResponse(BaseModel):
    session_id: str
    case_id: str
    room_name: str
    ice_servers: List[Dict[str, Any]]
    status: str
    created_at: datetime


class TelemedicineSignalPayload(BaseModel):
    session_id: str
    sender_id: str
    signal_type: str = Field(..., description="offer, answer, ice-candidate")
    data: Dict[str, Any]
