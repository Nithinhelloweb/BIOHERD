from datetime import datetime
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field

class DistrictBase(BaseModel):
    name: str = Field(..., description="English district name, e.g. Pune, Satara")
    name_mr: str = Field(default="", description="Marathi district name, e.g. पुणे, सातारा")
    state: str = Field(default="Maharashtra")
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    livestock_population: int = Field(default=0, description="Total livestock count from census")
    boundary_geojson: Optional[Dict[str, Any]] = None

class DistrictCreate(DistrictBase):
    pass

class DistrictResponse(DistrictBase):
    id: str
    created_at: datetime

    model_config = {"from_attributes": True}

class DistrictLivestockSummary(BaseModel):
    district_id: str
    district_name: str
    district_name_mr: str
    total_livestock: int
    active_farms_count: int = 0
    registered_animals_count: int = 0
    active_outbreaks_count: int = 0
