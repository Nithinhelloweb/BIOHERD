from datetime import timedelta
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException, Request, Security, status
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user, get_permissions_for_role, security_bearer
from app.core.config import settings
from app.core.logging import get_logger
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_temp_2fa_token,
    decode_token,
    generate_qr_code_base64,
    generate_totp_secret,
    get_password_hash,
    get_totp_uri,
    verify_password,
    verify_totp_code,
)
from app.db.models import District, SecurityEvent, User, UserRole
from app.db.session import get_db
from app.schemas.auth import (
    Confirm2FARequest,
    Enable2FAResponse,
    LoginRequest,
    LoginResponse,
    RefreshTokenRequest,
    RegisterRequest,
    TokenRefreshResponse,
    UserMeResponse,
    Verify2FARequest,
)
from app.schemas.user import UserResponse
from app.services.redis_service import redis_service

logger = get_logger("auth_endpoint")
router = APIRouter(prefix="/auth", tags=["Authentication & Security"])

@router.post(
    "/register",
    response_model=LoginResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user (Farmer / Vet / Official)",
)
async def register(
    req: RegisterRequest,
    session: AsyncSession = Depends(get_db),
):
    # 1. Check if phone is already registered
    stmt = select(User).where(User.phone == req.phone)
    res = await session.execute(stmt)
    if res.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Phone number '{req.phone}' is already registered",
        )

    # 2. Check district if provided
    if req.district_id:
        dist_stmt = select(District).where(District.id == req.district_id)
        dist_res = await session.execute(dist_stmt)
        if not dist_res.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"District ID '{req.district_id}' not found",
            )

    # 3. Create user
    user = User(
        phone=req.phone,
        email=req.email,
        password_hash=get_password_hash(req.password),
        full_name=req.full_name,
        role=req.role,
        preferred_language=req.preferred_language,
        district_id=req.district_id,
        is_2fa_enabled=False,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)

    # 4. Issue tokens
    token_data = {"sub": user.id, "role": user.role.value, "phone": user.phone}
    access_token = create_access_token(token_data)
    refresh_tok, refresh_jti, ttl_sec = create_refresh_token(token_data)
    await redis_service.store_refresh_token(refresh_jti, user.id, "registration", ttl_seconds=ttl_sec)

    logger.info("user_registered", user_id=user.id, role=user.role.value)
    return LoginResponse(
        requires_2fa=False,
        access_token=access_token,
        refresh_token=refresh_tok,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(user),
    )

@router.post(
    "/login",
    response_model=LoginResponse,
    summary="User login with brute-force rate limit protection and 2FA challenge",
)
async def login(
    req: LoginRequest,
    session: AsyncSession = Depends(get_db),
):
    # 1. Brute-force rate limiting (5 attempts per minute per phone)
    rate_key = f"login:{req.phone}"
    allowed, count, retry_after = await redis_service.check_rate_limit(
        rate_key, max_requests=5, window_seconds=60
    )
    if not allowed:
        logger.warning("login_rate_limit_exceeded", phone=req.phone)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Too many login attempts. Please retry after {retry_after} seconds.",
        )

    # 2. Look up user
    stmt = select(User).where(User.phone == req.phone)
    res = await session.execute(stmt)
    user = res.scalar_one_or_none()

    if not user or not verify_password(req.password, user.password_hash):
        # Log security failed login event
        sec_event = SecurityEvent(
            event_type="FAILED_LOGIN",
            details_json={"phone": req.phone, "attempt_count": count},
        )
        session.add(sec_event)
        await session.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password",
        )

    # 3. Two-Factor Authentication Check
    if user.is_2fa_enabled:
        temp_token = create_temp_2fa_token({"sub": user.id, "phone": user.phone, "role": user.role.value})
        logger.info("login_2fa_required", user_id=user.id)
        return LoginResponse(
            requires_2fa=True,
            temp_token=temp_token,
        )

    # 4. Standard Token Generation
    token_data = {"sub": user.id, "role": user.role.value, "phone": user.phone}
    access_token = create_access_token(token_data)
    refresh_tok, refresh_jti, ttl_sec = create_refresh_token(token_data, device_fingerprint=req.device_fingerprint)
    await redis_service.store_refresh_token(refresh_jti, user.id, req.device_fingerprint, ttl_seconds=ttl_sec)

    logger.info("user_logged_in", user_id=user.id, role=user.role.value)
    return LoginResponse(
        requires_2fa=False,
        access_token=access_token,
        refresh_token=refresh_tok,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(user),
    )

@router.post(
    "/verify-2fa",
    response_model=LoginResponse,
    summary="Validate 2FA TOTP code and issue session tokens",
)
async def verify_2fa(
    req: Verify2FARequest,
    session: AsyncSession = Depends(get_db),
):
    # 1. Decode temporary challenge token
    try:
        payload = decode_token(req.temp_token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired 2FA session token",
        )

    if payload.get("type") != "2fa_challenge":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is not a 2FA challenge token",
        )

    user_id = payload.get("sub")
    stmt = select(User).where(User.id == user_id)
    res = await session.execute(stmt)
    user = res.scalar_one_or_none()

    if not user or not user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or 2FA secret not configured",
        )

    # 2. Verify TOTP code
    is_valid = verify_totp_code(user.totp_secret, req.totp_code)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid 6-digit authenticator code. Please check and try again.",
        )

    # 3. Issue tokens
    token_data = {"sub": user.id, "role": user.role.value, "phone": user.phone}
    access_token = create_access_token(token_data)
    refresh_tok, refresh_jti, ttl_sec = create_refresh_token(token_data, device_fingerprint=req.device_fingerprint)
    await redis_service.store_refresh_token(refresh_jti, user.id, req.device_fingerprint, ttl_seconds=ttl_sec)

    logger.info("2fa_verified_successfully", user_id=user.id)
    return LoginResponse(
        requires_2fa=False,
        access_token=access_token,
        refresh_token=refresh_tok,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(user),
    )

@router.post(
    "/enable-2fa",
    response_model=Enable2FAResponse,
    summary="Initiate 2FA TOTP enrollment (generate secret and QR code)",
)
async def enable_2fa(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    secret = generate_totp_secret()
    current_user.totp_secret = secret
    await session.commit()

    totp_uri = get_totp_uri(secret, user_identifier=current_user.phone)
    qr_data = generate_qr_code_base64(totp_uri)

    logger.info("2fa_enrollment_initiated", user_id=current_user.id)
    return Enable2FAResponse(
        secret=secret,
        provisioning_uri=totp_uri,
        qr_code_base64=qr_data,
    )

@router.post(
    "/confirm-2fa",
    summary="Confirm 2FA activation with a valid 6-digit code",
)
async def confirm_2fa(
    req: Confirm2FARequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    if not current_user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="2FA secret not initialized. Call /enable-2fa first.",
        )

    if not verify_totp_code(current_user.totp_secret, req.totp_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid 6-digit verification code.",
        )

    current_user.is_2fa_enabled = True
    await session.commit()
    logger.info("2fa_activated", user_id=current_user.id)
    return {"success": True, "message": "Two-Factor Authentication is now enabled for your account."}

@router.post(
    "/refresh",
    response_model=TokenRefreshResponse,
    summary="Rotate refresh token and issue new access token",
)
async def refresh_token(req: RefreshTokenRequest):
    try:
        payload = decode_token(req.refresh_token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type, expected refresh",
        )

    old_jti = payload.get("jti")
    if not old_jti or not await redis_service.is_refresh_token_valid(old_jti):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has been revoked or expired",
        )

    user_id = payload.get("sub")
    role = payload.get("role")
    phone = payload.get("phone")

    # Rotate token: Revoke old JTI and issue new refresh token
    await redis_service.revoke_token(old_jti)

    token_data = {"sub": user_id, "role": role, "phone": phone}
    new_access = create_access_token(token_data)
    new_refresh, new_jti, ttl_sec = create_refresh_token(token_data, device_fingerprint=req.device_fingerprint)
    await redis_service.store_refresh_token(new_jti, user_id, req.device_fingerprint, ttl_seconds=ttl_sec)

    return TokenRefreshResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

@router.post(
    "/logout",
    summary="Logout user and revoke current tokens in Redis",
)
async def logout(
    credentials: HTTPAuthorizationCredentials = Security(security_bearer),
    current_user: User = Depends(get_current_user),
):
    try:
        payload = decode_token(credentials.credentials)
        jti = payload.get("jti")
        if jti:
            await redis_service.revoke_token(jti)
    except Exception:
        pass

    logger.info("user_logged_out", user_id=current_user.id)
    return {"success": True, "message": "Logged out successfully"}

@router.get(
    "/me",
    response_model=UserMeResponse,
    summary="Get current user profile and permissions",
)
async def get_me(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    district_name = None
    if current_user.district_id:
        stmt = select(District.name).where(District.id == current_user.district_id)
        res = await session.execute(stmt)
        district_name = res.scalar()

    permissions = get_permissions_for_role(current_user.role)
    user_dict = UserResponse.model_validate(current_user).model_dump()
    return UserMeResponse(
        **user_dict,
        permissions=permissions,
        district_name=district_name,
    )
