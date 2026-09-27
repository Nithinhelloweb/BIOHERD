from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class RapidResponseTeamResponse(BaseModel):
    id: str
    team_name: str
    base_depot: str
    lead_officer: str
    contact_number: str
    assigned_district: str
    assigned_epicenter: str
    status: str  # depot_staged, en_route, on_site_contained, vaccinating
    vehicle_id: str
    cold_box_temp_c: float
    lsd_doses_available: int
    fmd_doses_available: int
    pcr_cartridges: int
    ppe_kits: int
    eta_minutes: int


class RrtReassignRequest(BaseModel):
    new_status: str  # en_route, on_site_contained, vaccinating, depot_staged
    assigned_district: Optional[str] = None
    target_epicenter: Optional[str] = None


class SitRepQueryRequest(BaseModel):
    question: str
    context_district: Optional[str] = "Solapur"


class SitRepQueryResponse(BaseModel):
    question: str
    answer: str
    confidence: float = 0.96
    source_models: List[str] = Field(default_factory=lambda: ["SEIR-Epizootic-v3", "INSAT-3DR-LST", "INAPH-Central"])


class FarmerBroadcastRequest(BaseModel):
    district: str
    radius_km: float = 5.0
    channel: str = "all"  # ivr, sms, all


class FarmerBroadcastResponse(BaseModel):
    broadcast_id: str
    district: str
    radius_km: float
    recipient_count: int
    channels_engaged: List[str]
    delivery_status: str
    success_rate: float
    dispatched_timestamp: str


class SitRepBriefingResponse(BaseModel):
    id: str
    generated_timestamp: str
    threat_level: str
    executive_summary: str
    statutory_proclamation: str
    primary_epicenters: List[str]
    operational_checklist: Dict[str, bool]
