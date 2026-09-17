import io
import pytest
from PIL import Image
from app.core.security import (
    create_access_token,
    decode_access_token,
    decrypt_field,
    encrypt_field,
    get_password_hash,
    verify_password,
)
from app.services.minio_service import minio_service
from app.services.redis_service import redis_service

@pytest.mark.asyncio
async def test_redis_service_operations():
    """Test Redis key-value, TTL, and JSON helpers."""
    # Test string get/set
    await redis_service.set("test:greeting", "namaste", ttl_seconds=60)
    val = await redis_service.get("test:greeting")
    assert val == "namaste"

    # Test JSON get/set
    data = {"district": "Pune", "livestock": 2720000}
    await redis_service.set_json("test:json", data)
    retrieved = await redis_service.get_json("test:json")
    assert retrieved == data

    # Test delete
    await redis_service.delete("test:greeting")
    assert await redis_service.get("test:greeting") is None

@pytest.mark.asyncio
async def test_redis_rate_limiter():
    """Test sliding window rate limiting."""
    identifier = "farmer_123"
    # Allow 3 requests per 10 seconds
    for i in range(3):
        allowed, count, _ = await redis_service.check_rate_limit(identifier, max_requests=3, window_seconds=10)
        assert allowed is True
        assert count == i + 1

    # 4th request must be rejected
    allowed, count, retry_after = await redis_service.check_rate_limit(identifier, max_requests=3, window_seconds=10)
    assert allowed is False
    assert count == 4
    assert retry_after > 0

def test_minio_exif_stripping_and_upload():
    """Test image EXIF metadata stripping for farmer privacy."""
    # Create test image with dummy EXIF metadata
    img = Image.new("RGB", (100, 100), color=(73, 109, 137))
    exif = img.getexif()
    exif[0x010F] = "Camera Manufacturer Test" # Make tag
    exif[0x0110] = "Camera Model Test"       # Model tag

    buf = io.BytesIO()
    img.save(buf, format="JPEG", exif=exif)
    raw_bytes = buf.getvalue()

    # Upload with EXIF stripping
    uri = minio_service.upload_bytes("test/cow_disease.jpg", raw_bytes, content_type="image/jpeg", strip_image_exif=True)
    assert uri is not None

    # Retrieve and verify EXIF is stripped
    stored = minio_service.get_object_bytes("test/cow_disease.jpg")
    assert stored is not None
    stored_bytes, ctype = stored
    assert ctype == "image/jpeg"

    # Check that stored image has no remaining camera metadata tags
    with Image.open(io.BytesIO(stored_bytes)) as cleaned_img:
        cleaned_exif = cleaned_img.getexif()
        assert 0x010F not in cleaned_exif
        assert 0x0110 not in cleaned_exif

def test_security_cryptography():
    """Test password hashing, JWT tokens, and AES-256 field encryption."""
    # 1. Password hashing
    pw = "SuperSecure@2026"
    pw_hash = get_password_hash(pw)
    assert verify_password(pw, pw_hash) is True
    assert verify_password("WrongPassword", pw_hash) is False

    # 2. JWT token generation & decode
    token = create_access_token(data={"sub": "user-uuid-123", "role": "farmer"})
    payload = decode_access_token(token)
    assert payload is not None
    assert payload["sub"] == "user-uuid-123"
    assert payload["role"] == "farmer"

    # 3. Field encryption & decryption (AES-256 Fernet)
    secret_text = "Sensitive Aadhaar / Health Identifier"
    encrypted = encrypt_field(secret_text)
    assert encrypted != secret_text
    decrypted = decrypt_field(encrypted)
    assert decrypted == secret_text
