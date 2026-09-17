import pyotp
import pytest
from fastapi import Depends
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import require_veterinarian
from app.db.models import District, SecurityEvent, User, UserRole
from app.main import app


# Add a test-only route to test RBAC role restrictions
@app.get("/api/v1/test-vet-only", tags=["Test"])
async def endpoint_vet_only(current_user: User = Depends(require_veterinarian)):
    return {"message": "Welcome Dr. " + current_user.full_name}


@pytest.mark.asyncio
async def test_register_and_login_flow(client: AsyncClient, test_session: AsyncSession):
    """Test user registration and subsequent login."""
    # 1. Register a new farmer
    reg_payload = {
        "phone": "+919811122233",
        "password": "Password@1234",
        "full_name": "Balasaheb Thorat",
        "role": "farmer",
        "preferred_language": "mr",
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201
    reg_data = reg_res.json()
    assert reg_data["access_token"] is not None
    assert reg_data["refresh_token"] is not None
    assert reg_data["user"]["phone"] == "+919811122233"
    assert reg_data["user"]["role"] == "farmer"

    # 2. Duplicate registration fails with 409
    dup_res = await client.post("/api/v1/auth/register", json=reg_payload)
    assert dup_res.status_code == 409
    assert "already registered" in dup_res.json()["detail"]

    # 3. Login with correct password
    login_payload = {
        "phone": "+919811122233",
        "password": "Password@1234",
        "device_fingerprint": "test_device_pixel_8",
    }
    login_res = await client.post("/api/v1/auth/login", json=login_payload)
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert login_data["requires_2fa"] is False
    assert login_data["access_token"] is not None
    assert login_data["refresh_token"] is not None

    # 4. Login with incorrect password fails with 401
    bad_login_payload = {
        "phone": "+919811122233",
        "password": "WrongPassword",
    }
    bad_res = await client.post("/api/v1/auth/login", json=bad_login_payload)
    assert bad_res.status_code == 401
    assert "Invalid phone number or password" in bad_res.json()["detail"]

@pytest.mark.asyncio
async def test_login_brute_force_rate_limiting(client: AsyncClient):
    """Ensure brute force login attempts are rate limited after 5 tries."""
    phone = "+919800000099"
    payload = {"phone": phone, "password": "WrongPassword"}

    # Fire 5 attempts
    for _ in range(5):
        await client.post("/api/v1/auth/login", json=payload)

    # 6th attempt must trigger HTTP 429 Too Many Requests
    rate_res = await client.post("/api/v1/auth/login", json=payload)
    assert rate_res.status_code == 429
    assert "Too many login attempts" in rate_res.json()["detail"]

@pytest.mark.asyncio
async def test_two_factor_authentication_flow(client: AsyncClient, test_session: AsyncSession):
    """Test full 2FA setup, challenge, verification, and rejection."""
    # 1. Register a veterinarian
    reg_payload = {
        "phone": "+919822233344",
        "password": "VetPassword@2026",
        "full_name": "Dr. Pradeep Jadhav",
        "role": "veterinarian",
        "preferred_language": "en",
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    access_token = reg_res.json()["access_token"]
    auth_headers = {"Authorization": f"Bearer {access_token}"}

    # 2. Initiate 2FA enrollment
    enable_res = await client.post("/api/v1/auth/enable-2fa", headers=auth_headers)
    assert enable_res.status_code == 200
    enable_data = enable_res.json()
    secret = enable_data["secret"]
    assert len(secret) == 32
    assert "otpauth://" in enable_data["provisioning_uri"]
    assert "data:image/png;base64," in enable_data["qr_code_base64"]

    # 3. Confirm with valid TOTP code
    totp = pyotp.TOTP(secret)
    valid_code = totp.now()
    confirm_res = await client.post(
        "/api/v1/auth/confirm-2fa",
        headers=auth_headers,
        json={"totp_code": valid_code},
    )
    assert confirm_res.status_code == 200
    assert confirm_res.json()["success"] is True

    # 4. Login now requires 2FA
    login_res = await client.post(
        "/api/v1/auth/login",
        json={"phone": "+919822233344", "password": "VetPassword@2026"},
    )
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert login_data["requires_2fa"] is True
    assert login_data["temp_token"] is not None
    temp_token = login_data["temp_token"]

    # 5. Verify 2FA with invalid code fails
    invalid_verify_res = await client.post(
        "/api/v1/auth/verify-2fa",
        json={"temp_token": temp_token, "totp_code": "000000"},
    )
    assert invalid_verify_res.status_code == 401

    # 6. Verify 2FA with valid code succeeds
    fresh_code = totp.now()
    valid_verify_res = await client.post(
        "/api/v1/auth/verify-2fa",
        json={"temp_token": temp_token, "totp_code": fresh_code},
    )
    assert valid_verify_res.status_code == 200
    verify_data = valid_verify_res.json()
    assert verify_data["requires_2fa"] is False
    assert verify_data["access_token"] is not None
    assert verify_data["user"]["is_2fa_enabled"] is True

@pytest.mark.asyncio
async def test_token_refresh_and_rotation(client: AsyncClient):
    """Test refresh token rotation and revocation of previous token."""
    # 1. Register user to get tokens
    reg_payload = {
        "phone": "+919833344455",
        "password": "Password@777",
        "full_name": "Ganesh Gaikwad",
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    old_refresh = reg_res.json()["refresh_token"]

    # 2. Refresh token
    refresh_res = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh, "device_fingerprint": "mobile_app"},
    )
    assert refresh_res.status_code == 200
    refresh_data = refresh_res.json()
    new_access = refresh_data["access_token"]
    new_refresh = refresh_data["refresh_token"]
    assert new_access is not None
    assert new_refresh != old_refresh

    # 3. Attempt to reuse old rotated refresh token fails with 401
    reuse_res = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh},
    )
    assert reuse_res.status_code == 401
    assert "revoked or expired" in reuse_res.json()["detail"]

@pytest.mark.asyncio
async def test_logout_and_revocation(client: AsyncClient):
    """Test token revocation upon logout."""
    reg_payload = {
        "phone": "+919844455566",
        "password": "Password@888",
        "full_name": "Sunita Shinde",
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    access_token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # Verify access to /me before logout
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    assert me_res.status_code == 200

    # Logout
    logout_res = await client.post("/api/v1/auth/logout", headers=headers)
    assert logout_res.status_code == 200
    assert logout_res.json()["success"] is True

    # Subsequent access with revoked token is rejected with 401
    after_logout_res = await client.get("/api/v1/auth/me", headers=headers)
    assert after_logout_res.status_code == 401
    assert "revoked" in after_logout_res.json()["detail"]

@pytest.mark.asyncio
async def test_rbac_permissions_and_route_guards(client: AsyncClient, test_session: AsyncSession):
    """Verify role-based access control and 403 Forbidden enforcement."""
    # 1. Farmer user
    farmer_res = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919855566677", "password": "Password@999", "full_name": "Farmer Ram", "role": "farmer"},
    )
    farmer_token = farmer_res.json()["access_token"]
    farmer_headers = {"Authorization": f"Bearer {farmer_token}"}

    # Farmer checking /me has farmer permissions
    me_farmer = await client.get("/api/v1/auth/me", headers=farmer_headers)
    assert me_farmer.status_code == 200
    assert "animal:create" in me_farmer.json()["permissions"]
    assert "prescription:issue" not in me_farmer.json()["permissions"]

    # Farmer attempting to access Vet-only route should be rejected with 403 Forbidden
    vet_route_res = await client.get("/api/v1/test-vet-only", headers=farmer_headers)
    assert vet_route_res.status_code == 403
    assert "Access forbidden" in vet_route_res.json()["detail"]

    # Verify security audit event was recorded in the database
    sec_stmt = select(SecurityEvent).where(SecurityEvent.event_type == "UNAUTHORIZED_ROLE_ACCESS")
    sec_res = await test_session.execute(sec_stmt)
    event = sec_res.scalars().first()
    assert event is not None
    assert event.details_json["user_role"] == "farmer"

    # 2. Veterinarian user accessing the same route should succeed
    vet_res = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919866677788", "password": "Password@999", "full_name": "Dr. Vikas", "role": "veterinarian"},
    )
    vet_token = vet_res.json()["access_token"]
    vet_headers = {"Authorization": f"Bearer {vet_token}"}

    vet_route_success = await client.get("/api/v1/test-vet-only", headers=vet_headers)
    assert vet_route_success.status_code == 200
    assert "Welcome Dr. Dr. Vikas" in vet_route_success.json()["message"]
