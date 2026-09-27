from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class VaccinationDriveCreate(BaseModel):
    title: str = Field(..., max_length=200)
    target_disease: str = Field(..., description="FMD, LSD, Anthrax, Brucellosis, PPR")
    vaccine_name: str = Field(..., description="Commercial vaccine brand/formulation")
    district_id: str
    block: Optional[str] = None
    village: Optional[str] = None
    start_date: datetime
    end_date: datetime
    target_animals_count: int = Field(default=100, ge=1)
    assigned_vet_id: Optional[str] = None


class VaccinationDriveProgressUpdate(BaseModel):
    additional_doses: int = Field(default=1, ge=1)
    status: Optional[str] = None # scheduled, in_progress, completed, cancelled


class VaccinationDriveResponse(BaseModel):
    id: str
    title: str
    target_disease: str
    vaccine_name: str
    district_id: str
    block: Optional[str] = None
    village: Optional[str] = None
    start_date: datetime
    end_date: datetime
    target_animals_count: int
    completed_doses: int
    coverage_percentage: float = 0.0
    status: str
    created_by: str
    assigned_vet_id: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}
