"""
BIOHERD Symptom Reporting & AI Detection Schemas
Pydantic v2 schemas for multi-modal livestock disease reporting,
body-system checklists, vernacular descriptions, and AI predictions.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class DiseasePrediction(BaseModel):
    disease_id: str
    name_en: str
    name_mr: str
    confidence: float
    severity: str
    causative_agent: str
    matched_symptoms: List[str] = Field(default_factory=list)
    clinical_reasoning: str


class FirstAidPayload(BaseModel):
    en: Dict[str, Any]
    mr: Dict[str, Any]
    isolation_required: bool
    zoonotic_risk: bool


class AIDetectionRequest(BaseModel):
    animal_id: Optional[str] = None
    species: Optional[str] = None
    symptoms_checklist: Optional[Dict[str, List[str]]] = None
    vernacular_description: Optional[str] = None
    images: Optional[List[str]] = None


class AIDetectionResponse(BaseModel):
    model_version: str
    primary_diagnosis: DiseasePrediction
    differential_diagnoses: List[DiseasePrediction] = Field(default_factory=list)
    severity: str
    confidence: float
    should_escalate_case: bool
    first_aid: FirstAidPayload
    inference_duration_ms: int


class SymptomReportCreate(BaseModel):
    animal_id: str
    symptoms_checklist: Optional[Dict[str, List[str]]] = Field(default_factory=dict)
    vernacular_description: Optional[str] = None
    images: Optional[List[str]] = Field(default_factory=list)
    voice_note_url: Optional[str] = None


class SymptomReportResponse(BaseModel):
    id: str
    animal_id: str
    animal_tag_id: Optional[str] = None
    species: Optional[str] = None
    breed: Optional[str] = None
    reported_by: str
    symptoms_json: Dict[str, Any] = Field(default_factory=dict)
    severity: str
    status: str
    voice_note_url: Optional[str] = None
    images_json: List[str] = Field(default_factory=list)
    detection_result: Optional[AIDetectionResponse] = None
    case_id: Optional[str] = None
    created_at: datetime


class DiseaseItem(BaseModel):
    id: str
    name_en: str
    name_mr: str
    species: List[str]
    causative_agent: str
    severity_baseline: str
    incubation_period: str
    cardinal_symptoms: List[str]
    symptom_system_map: Dict[str, List[str]]
    isolation_required: bool
    zoonotic_risk: bool
    first_aid_en: Dict[str, Any]
    first_aid_mr: Dict[str, Any]
