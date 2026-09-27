from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class LivestockMovementCreate(BaseModel):
    animal_ids: List[str] = Field(default_factory=list, description="Tag IDs or Animal IDs")
    origin_district_id: str
    origin_block: Optional[str] = None
    destination_district_id: str
    destination_block: Optional[str] = None
    purpose: str = Field(default="mandi_sale", description="mandi_sale, seasonal_grazing, breeding, slaughter")


class LivestockMovementResponse(BaseModel):
    id: str
    permit_number: str
    animal_ids: List[str]
    origin_district_id: str
    origin_block: Optional[str] = None
    destination_district_id: str
    destination_block: Optional[str] = None
    purpose: str
    health_certificate_issued: bool
    inspection_status: str
    quarantine_flag: bool
    departed_at: datetime
    arrived_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}
