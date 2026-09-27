from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class IVRCallInitiateRequest(BaseModel):
    caller_phone: str = Field(..., description="Farmer phone number")
    language: Optional[str] = Field(default="mr", description="mr, hi, en")


class IVRInputStepRequest(BaseModel):
    call_session_id: str
    caller_phone: str
    digit_pressed: str = Field(..., description="DTMF pressed key: 1, 2, 3, etc.")
    step_id: str = Field(..., description="Current IVR menu step: language_select, menu_select, species_select, symptom_select, count_input")
    selected_language: str = Field(default="mr")


class IVRStepResponse(BaseModel):
    call_session_id: str
    step_id: str
    voice_prompt_text: str
    voice_prompt_audio_url: Optional[str] = None
    allowed_digits: List[str]
    is_terminal: bool = False
    report_created_id: Optional[str] = None
    sms_receipt_sent: bool = False


class InboundSMSRequest(BaseModel):
    from_phone: str
    message_text: str = Field(..., description="e.g. 'REPORT MH12AB1234 FEVER,SALIVATION' or 'DEATH CATTLE 2'")


class InboundSMSResponse(BaseModel):
    status: str
    ticket_id: Optional[str] = None
    reply_message: str
