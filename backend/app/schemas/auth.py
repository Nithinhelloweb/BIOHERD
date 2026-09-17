from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field
from app.db.models import UserRole
from app.schemas.user import UserResponse

class LoginRequest(BaseModel):
    phone: str = Field(..., description="10-digit mobile number (+91)")
    password: str = Field(..., min_length=6, description="Account password")
    device_fingerprint: str = Field(default="default_device", description="Device ID or user agent fingerprint")

class LoginResponse(BaseModel):
    requires_2fa: bool = False
    temp_token: Optional[str] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    expires_in: Optional[int] = None
    user: Optional[UserResponse] = None

class RegisterRequest(BaseModel):
    phone: str = Field(..., description="10-digit mobile number (+91)")
    password: str = Field(..., min_length=8, description="Password (min 8 chars)")
    full_name: str = Field(..., min_length=2, description="Full Name")
    role: UserRole = Field(default=UserRole.FARMER)
    preferred_language: str = Field(default="mr", description="'mr' (Marathi), 'hi' (Hindi), 'en' (English)")
    district_id: Optional[str] = None
    email: Optional[EmailStr] = None

class Verify2FARequest(BaseModel):
    temp_token: str = Field(..., description="Temporary 2FA session token returned from login")
    totp_code: str = Field(..., min_length=6, max_length=6, description="6-digit authenticator TOTP code")
    device_fingerprint: str = Field(default="default_device")

class Enable2FAResponse(BaseModel):
    secret: str = Field(..., description="Base32 TOTP secret")
    provisioning_uri: str = Field(..., description="otpauth:// URL for authenticator apps")
    qr_code_base64: str = Field(..., description="Base64 Data URI for QR code PNG image")

class Confirm2FARequest(BaseModel):
    totp_code: str = Field(..., min_length=6, max_length=6, description="6-digit TOTP code to confirm activation")

class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., description="Valid refresh token")
    device_fingerprint: str = Field(default="default_device")

class TokenRefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

class UserMeResponse(UserResponse):
    permissions: List[str] = []
    district_name: Optional[str] = None
