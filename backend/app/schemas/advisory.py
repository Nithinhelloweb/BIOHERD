from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from app.db.models import SeverityLevelEnum


class AdvisoryCreate(BaseModel):
    title_multilingual: Dict[str, str] = Field(..., description="Dict with en, mr, hi keys")
    content_multilingual: Dict[str, str] = Field(..., description="Dict with en, mr, hi keys")
    category: str = Field(default="prevention", description="prevention, first_aid, biosecurity, seasonal, feed_nutrition")
    disease_target: Optional[str] = None
    target_district_id: Optional[str] = None


class AdvisoryResponse(BaseModel):
    id: str
    title_multilingual_json: Dict[str, str]
    content_multilingual_json: Dict[str, str]
    category: str
    disease_target: Optional[str] = None
    author_id: str
    status: str
    target_district_id: Optional[str] = None
    published_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class AlertBroadcastCreate(BaseModel):
    target_level: str = Field(default="district", description="block, district, state, all")
    target_district_id: Optional[str] = None
    target_block: Optional[str] = None
    disease_name: Optional[str] = None
    severity: SeverityLevelEnum = SeverityLevelEnum.HIGH
    title: Dict[str, str] = Field(..., description="Multilingual title (en, mr, hi)")
    message: Dict[str, str] = Field(..., description="Multilingual message (en, mr, hi)")
    channels: List[str] = Field(default_factory=lambda: ["push", "sms"])


class AlertBroadcastResponse(BaseModel):
    id: str
    sender_id: str
    target_level: str
    target_district_id: Optional[str] = None
    target_block: Optional[str] = None
    disease_name: Optional[str] = None
    severity: SeverityLevelEnum
    title: Dict[str, str]
    message: Dict[str, str]
    channels: List[str]
    total_recipients: int
    acknowledged_count: int
    created_at: datetime

    model_config = {"from_attributes": True}
