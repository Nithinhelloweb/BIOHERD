from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from app.db.models import AnimalSpecies


class MortalityReportCreate(BaseModel):
    district_id: str
    block: Optional[str] = None
    village: Optional[str] = None
    species: AnimalSpecies = AnimalSpecies.CATTLE
    animal_count: int = Field(default=1, ge=1)
    probable_cause: Optional[str] = None
    symptoms: List[str] = Field(default_factory=list)
    mortality_date: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    disposal_method: str = Field(default="deep_burial")
    post_mortem_conducted: bool = False
    post_mortem_notes: Optional[str] = None


class MortalityReportResponse(BaseModel):
    id: str
    reported_by: str
    district_id: str
    block: Optional[str] = None
    village: Optional[str] = None
    species: AnimalSpecies
    animal_count: int
    probable_cause: Optional[str] = None
    symptoms: List[str] = Field(default_factory=list)
    mortality_date: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    disposal_method: str
    post_mortem_conducted: bool
    post_mortem_notes: Optional[str] = None
    zoonotic_risk: bool
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
