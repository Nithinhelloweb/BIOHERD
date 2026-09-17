from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from app.db.models import UserRole

class UserBase(BaseModel):
    phone: str = Field(..., description="10-digit mobile number (+91)")
    email: Optional[EmailStr] = None
    full_name: str = Field(default="")
    role: UserRole = Field(default=UserRole.FARMER)
    preferred_language: str = Field(default="mr", description="'mr' (Marathi), 'hi' (Hindi), 'en' (English)")
    district_id: Optional[str] = None

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, description="Password min 8 characters")

class UserLogin(BaseModel):
    phone: str = Field(..., description="Phone number")
    password: str = Field(..., description="Account password")

class UserResponse(UserBase):
    id: str
    is_2fa_enabled: bool
    created_at: datetime

    model_config = {"from_attributes": True}

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_token: Optional[str] = None
    user: UserResponse
