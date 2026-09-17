from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from app.db.models import HealthEventType, SeverityLevelEnum

class HealthEventBase(BaseModel):
    animal_id: str
    event_type: HealthEventType
    description: str
    occurred_at: datetime = Field(default_factory=datetime.utcnow)

class HealthEventCreate(HealthEventBase):
    pass

class HealthEventResponse(HealthEventBase):
    id: str
    recorded_by: str
    created_at: datetime

    model_config = {"from_attributes": True}

class SymptomReportCreate(BaseModel):
    animal_id: str
    symptoms: Dict[str, Any] = Field(..., description="Systematic symptom flags (body system, fever, blisters, etc.)")
    severity: SeverityLevelEnum = Field(default=SeverityLevelEnum.LOW)
    voice_note_url: Optional[str] = None
    images: List[str] = Field(default_factory=list, description="List of uploaded image URLs")

class DetectionPrediction(BaseModel):
    disease_name: str
    disease_name_mr: str
    confidence: float
    description: str
    recommended_action: str

class DetectionResultResponse(BaseModel):
    id: str
    symptom_report_id: str
    model_version: str
    predictions: List[DetectionPrediction]
    confidence: float
    inference_duration_ms: int
    created_at: datetime

class SymptomReportResponse(BaseModel):
    id: str
    animal_id: str
    reported_by: str
    symptoms_json: Dict[str, Any]
    severity: SeverityLevelEnum
    status: str
    voice_note_url: Optional[str] = None
    images_json: List[str] = []
    created_at: datetime
    detection_results: List[DetectionResultResponse] = []

    model_config = {"from_attributes": True}
