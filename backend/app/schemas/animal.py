from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from app.db.models import AnimalSpecies, HealthEventType

class BreedInfo(BaseModel):
    name: str
    name_mr: str
    species: AnimalSpecies
    origin_region: str
    districts: List[str]
    description: str
    description_mr: str

class AnimalBase(BaseModel):
    species: AnimalSpecies = Field(default=AnimalSpecies.CATTLE)
    breed: str = Field(..., description="Breed name, e.g. Gir, Khillari, Murrah, Osmanabadi")
    sex: str = Field(..., description="Sex: male or female")
    dob: Optional[datetime] = None
    weight_kg: float = Field(default=0.0, ge=0.0)
    tag_id: str = Field(..., description="Unique ear tag or RFID identifier")
    qr_code_url: Optional[str] = None
    is_active: bool = True

class AnimalCreate(AnimalBase):
    farm_id: str = Field(..., description="Farm ID where animal is housed")

class AnimalUpdate(BaseModel):
    species: Optional[AnimalSpecies] = None
    breed: Optional[str] = None
    sex: Optional[str] = None
    dob: Optional[datetime] = None
    weight_kg: Optional[float] = None
    is_active: Optional[bool] = None

class AnimalResponse(AnimalBase):
    id: str
    farm_id: str
    created_at: datetime

    model_config = {"from_attributes": True}

class HealthEventCreate(BaseModel):
    event_type: HealthEventType = Field(default=HealthEventType.ROUTINE_CHECKUP)
    description: str = Field(..., min_length=2)
    recorded_by: Optional[str] = None
    occurred_at: Optional[datetime] = None

class HealthEventResponse(BaseModel):
    id: str
    animal_id: str
    event_type: HealthEventType
    description: str
    recorded_by: str
    occurred_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}

class AnimalQRCodeResponse(BaseModel):
    animal_id: str
    tag_id: str
    verification_url: str
    qr_base64: str
    generated_at: datetime

class AnimalPassportResponse(BaseModel):
    animal_id: str
    tag_id: str
    species: str
    breed: str
    sex: str
    weight_kg: float
    dob: Optional[datetime] = None
    age_months: Optional[int] = None
    farm_id: str
    farm_name: str
    district_name: str
    owner_name: str
    owner_phone: str
    qr_code_url: Optional[str] = None
    is_active: bool
    registered_at: datetime
    health_events_count: int
    vaccinations_count: int
    recent_events: List[HealthEventResponse] = []
    verification_hash: str
