from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class DistrictRiskSummary(BaseModel):
    district_id: str
    district_name: str
    district_name_mr: str
    latitude: float
    longitude: float
    livestock_population: int
    active_cases: int
    risk_score: float
    severity: str
    r0_estimate: float
    weather_factor: float
    case_density_per_10k: float
    primary_disease: str


class OutbreakClusterResponse(BaseModel):
    id: str
    district_id: str
    district_name: str
    disease_name: str
    case_count: int
    risk_level: str
    latitude: float
    longitude: float
    containment_radius_km: float = 5.0
    surveillance_radius_km: float = 10.0
    r0_estimate: float = 1.5
    transmission_rate: float = 0.25
    affected_farms_count: int = 1
    quarantine_declared: bool = False
    declared_at: datetime
    resolved_at: Optional[datetime] = None
    notes_multilingual_json: Dict[str, str] = Field(default_factory=dict)


class OutbreakEventCreate(BaseModel):
    district_id: str
    disease_name: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    case_count: int = 1
    risk_level: Optional[str] = "high"
    containment_radius_km: float = 5.0
    surveillance_radius_km: float = 10.0
    quarantine_declared: bool = False
    notes_en: Optional[str] = None
    notes_mr: Optional[str] = None


class QuarantineDeclarationRequest(BaseModel):
    outbreak_id: Optional[str] = None
    district_id: str
    disease_name: str
    latitude: float
    longitude: float
    containment_radius_km: float = 5.0
    surveillance_radius_km: float = 10.0
    broadcast_alert: bool = True
    notes_en: Optional[str] = None
    notes_mr: Optional[str] = None


class AlertResponse(BaseModel):
    id: str
    recipient_user_id: str
    alert_type: str
    severity: str
    title_multilingual_json: Dict[str, str]
    body_multilingual_json: Dict[str, str]
    channels: List[str]
    is_read: bool
    created_at: datetime
