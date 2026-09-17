from typing import List, Optional
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.logging import get_logger
from app.core.security import decode_token
from app.db.models import SecurityEvent, User, UserRole
from app.db.session import get_db
from app.services.redis_service import redis_service

logger = get_logger("auth_deps")
security_bearer = HTTPBearer(auto_error=True)

# Role-to-Permissions Mapping for BIOHERD
ROLE_PERMISSIONS = {
    UserRole.FARMER: [
        "animal:read_own",
        "animal:create",
        "symptom:report",
        "prescription:read_own",
        "telemedicine:request",
    ],
    UserRole.VETERINARIAN: [
        "animal:read_district",
        "case:review",
        "case:accept",
        "prescription:issue",
        "telemedicine:consult",
        "drug_inventory:read_district",
    ],
    UserRole.DISTRICT_OFFICIAL: [
        "district:read",
        "outbreak:read_district",
        "outbreak:declare",
        "drug_inventory:manage",
        "analytics:read_district",
    ],
    UserRole.STATE_ADMIN: [
        "district:read_all",
        "outbreak:read_state",
        "outbreak:escalate",
        "analytics:read_state",
        "user:manage",
        "inventory:allocate",
    ],
    UserRole.SUPER_ADMIN: [
        "*",
    ],
}

def get_permissions_for_role(role: UserRole) -> List[str]:
    return ROLE_PERMISSIONS.get(role, [])

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security_bearer),
    session: AsyncSession = Depends(get_db),
) -> User:
    """Extract and validate JWT access token, verify revocation in Redis, and load User."""
    token = credentials.credentials
    try:
        payload = decode_token(token)
    except Exception as e:
        logger.warning("jwt_decode_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Validate token type
    token_type = payload.get("type")
    if token_type != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token type '{token_type}', expected 'access'",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check JTI revocation in Redis
    jti = payload.get("jti")
    if jti and await redis_service.is_token_revoked(jti):
        logger.warning("revoked_token_presented", jti=jti)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="This token has been revoked. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token subject missing",
            headers={"WWW-Authenticate": "Bearer"},
        )

    stmt = select(User).where(User.id == user_id)
    res = await session.execute(stmt)
    user = res.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with token no longer exists",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user

def require_roles(*allowed_roles: Any):
    """Dependency factory enforcing Role-Based Access Control (RBAC)."""
    flat_roles: List[UserRole] = []
    for r in allowed_roles:
        if isinstance(r, (list, tuple, set)):
            flat_roles.extend(r)
        else:
            flat_roles.append(r)

    async def role_checker(
        current_user: User = Depends(get_current_user),
        session: AsyncSession = Depends(get_db),
    ) -> User:
        # SUPER_ADMIN has access to everything
        if current_user.role == UserRole.SUPER_ADMIN:
            return current_user

        if current_user.role not in flat_roles:
            logger.warning(
                "rbac_access_denied",
                user_id=current_user.id,
                user_role=current_user.role.value,
                required_roles=[r.value for r in flat_roles],
            )
            # Log security event to database
            sec_event = SecurityEvent(
                event_type="UNAUTHORIZED_ROLE_ACCESS",
                details_json={
                    "user_id": current_user.id,
                    "user_role": current_user.role.value,
                    "attempted_access_to": [r.value for r in flat_roles],
                },
            )
            session.add(sec_event)
            await session.commit()

            allowed_names = [r.value for r in flat_roles]
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: requires one of {allowed_names} roles",
            )
        return current_user

    return role_checker

# Convenience RBAC dependencies
require_farmer = require_roles(UserRole.FARMER)
require_veterinarian = require_roles(UserRole.VETERINARIAN)
require_district_official = require_roles(UserRole.DISTRICT_OFFICIAL)
require_state_admin = require_roles(UserRole.STATE_ADMIN)
require_official_or_vet = require_roles(
    UserRole.VETERINARIAN,
    UserRole.DISTRICT_OFFICIAL,
    UserRole.STATE_ADMIN,
)
