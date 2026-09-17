import base64
import io
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
import bcrypt
import jwt
import pyotp
import qrcode
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from app.core.config import settings

def generate_uuid() -> str:
    return str(uuid.uuid4())

def get_password_hash(password: str) -> str:
    """Hash password with bcrypt."""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against bcrypt hash."""
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create signed access token (15m default TTL) with unique JTI."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({
        "exp": expire,
        "type": "access",
        "jti": to_encode.get("jti", generate_uuid()),
    })
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def create_refresh_token(
    data: Dict[str, Any],
    device_fingerprint: str = "default_device",
    expires_delta: Optional[timedelta] = None,
) -> tuple[str, str, int]:
    """Create signed refresh token (7d default TTL). Returns (token, jti, expire_seconds)."""
    to_encode = data.copy()
    jti = generate_uuid()
    ttl = expires_delta or timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    expire = datetime.now(timezone.utc) + ttl
    to_encode.update({
        "exp": expire,
        "type": "refresh",
        "jti": jti,
        "dev": device_fingerprint,
    })
    token = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return token, jti, int(ttl.total_seconds())

def create_temp_2fa_token(data: Dict[str, Any]) -> str:
    """Create short-lived 2FA challenge token (5 min TTL)."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=5)
    to_encode.update({
        "exp": expire,
        "type": "2fa_challenge",
        "jti": generate_uuid(),
    })
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def decode_token(token: str) -> Dict[str, Any]:
    """Decode and validate JWT token."""
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

decode_access_token = decode_token

# Two-Factor Authentication (TOTP via PyOTP)
def generate_totp_secret() -> str:
    """Generate base32 secret for TOTP."""
    return pyotp.random_base32()

def get_totp_uri(secret: str, user_identifier: str, issuer: str = "BIOHERD") -> str:
    """Get otpauth:// URI for authenticator applications."""
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(name=user_identifier, issuer_name=issuer)

def verify_totp_code(secret: str, code: str, valid_window: int = 1) -> bool:
    """Verify 6-digit TOTP code with time drift window."""
    if not secret or not code:
        return False
    totp = pyotp.TOTP(secret)
    return totp.verify(code.strip(), valid_window=valid_window)

def generate_qr_code_base64(data: str) -> str:
    """Generate base64 encoded PNG QR code image."""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=8,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")

    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    img_str = base64.b64encode(buffer.getvalue()).decode("utf-8")
    return f"data:image/png;base64,{img_str}"

# AES-256 Symmetric Field Encryptor for Sensitive Data
def _get_fernet_cipher() -> Fernet:
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=b"bioherd_sih_2026_salt",
        iterations=100_000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(settings.SECRET_KEY.encode("utf-8")))
    return Fernet(key)

def encrypt_field(plain_text: str) -> str:
    """Encrypt sensitive string field (AES-256)."""
    if not plain_text:
        return plain_text
    cipher = _get_fernet_cipher()
    return cipher.encrypt(plain_text.encode("utf-8")).decode("utf-8")

def decrypt_field(cipher_text: str) -> str:
    """Decrypt sensitive string field."""
    if not cipher_text:
        return cipher_text
    cipher = _get_fernet_cipher()
    return cipher.decrypt(cipher_text.encode("utf-8")).decode("utf-8")
