from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class LabSampleCreate(BaseModel):
    case_id: Optional[str] = None
    animal_id: Optional[str] = None
    district_id: str
    sample_type: str = Field(..., description="whole_blood, serum, nasal_swab, milk, tissue_biopsy, skin_scraping")
    suspected_disease: str = Field(..., description="Suspected disease pathogen")
    current_lab_name: str = Field(default="District Disease Diagnostic Lab Pune")


class LabSampleTransitUpdate(BaseModel):
    transit_status: str = Field(..., description="collected, in_transit, received_at_lab, processing, completed, referred")
    referred_to_lab: Optional[str] = None


class LabSampleResultUpdate(BaseModel):
    test_method: str = Field(..., description="RT-PCR, ELISA, Giemsa Microscopy, Bacterial Culture, Rapid Antigen")
    test_result: str = Field(..., description="positive, negative, inconclusive")
    pathogen_confirmed: Optional[str] = None
    result_notes: Optional[str] = None
    report_file_url: Optional[str] = None


class LabSampleResponse(BaseModel):
    id: str
    sample_code: str
    case_id: Optional[str] = None
    animal_id: Optional[str] = None
    district_id: str
    collected_by: str
    collection_date: datetime
    sample_type: str
    suspected_disease: str
    transit_status: str
    current_lab_name: str
    referred_to_lab: Optional[str] = None
    test_method: Optional[str] = None
    test_result: Optional[str] = None
    pathogen_confirmed: Optional[str] = None
    is_zoonotic: bool
    result_notes: Optional[str] = None
    lab_technician_id: Optional[str] = None
    result_date: Optional[datetime] = None
    report_file_url: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}
