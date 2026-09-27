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

# Role-to-Permissions Mapping for BIOHERD (Comprehensive SIH 26128 RBAC Matrix)
ROLE_PERMISSIONS = {
    UserRole.FARMER: [
        "animal:read_own",
        "animal:create",
        "animal:create_own",
        "symptom:report",
        "symptom:report_own",
        "prescription:read_own",
        "mortality:report_own",
        "photo_gps:attach",
        "offline:sync",
        "ivr:report",
        "ai_triage:view_simple",
        "outbreak:receive",
        "zoonotic:receive",
        "vaccination:read_own",
        "treatment:read_own",
        "sample:initiate_request",
        "lab:view_own_result",
        "alert:receive",
        "advisory:read",
        "telemedicine:request",
    ],
    UserRole.PARAVET: [
        "animal:read_own",
        "animal:read_area",
        "animal:create_area",
        "animal:edit_area",
        "symptom:report_area",
        "symptom:view_area",
        "mortality:report_area",
        "photo_gps:attach",
        "offline:sync",
        "ivr:report",
        "ai_triage:view_simple",
        "outbreak:receive",
        "outbreak:flag",
        "zoonotic:receive",
        "heatmap:view_block",
        "vaccination:record_area",
        "treatment:create_first_aid",
        "drive:participate",
        "inventory:view_dispensary",
        "sample:initiate",
        "case:flag_for_vet",
        "alert:receive",
        "advisory:read",
        "dashboard:view_area",
    ],
    UserRole.VETERINARIAN: [
        "animal:read_district",
        "animal:create",
        "animal:edit",
        "animal:verify",
        "symptom:report",
        "symptom:verify",
        "mortality:report",
        "mortality:verify",
        "photo_gps:attach",
        "offline:sync",
        "ai_triage:view",
        "ai_triage:override",
        "outbreak:create",
        "outbreak:receive",
        "zoonotic:create_flag",
        "heatmap:view_block",
        "historical:view",
        "weather:view",
        "vaccination:record",
        "vaccination:verify",
        "treatment:prescribe",
        "drive:create_local",
        "inventory:manage_dispensary",
        "sample:create_track",
        "lab:view_result",
        "case:review",
        "case:accept",
        "case:escalate",
        "prescription:issue",
        "telemedicine:consult",
        "alert:receive",
        "alert:broadcast_block",
        "dashboard:view_block",
        "kpi:view_own",
    ],
    UserRole.LAB_TECHNICIAN: [
        "sample:track",
        "sample:receive",
        "lab:enter_result",
        "lab:upload_report",
        "lab:refer_higher",
        "case:flag_lab_confirmation",
        "outbreak:receive",
        "alert:receive",
        "dashboard:view_lab",
        "kpi:view_lab",
    ],
    UserRole.DISTRICT_OFFICIAL: [
        "district:read",
        "animal:view_audit",
        "symptom:view_district",
        "symptom:override",
        "mortality:view_district",
        "mortality:override",
        "photo_gps:view",
        "ai_triage:view_override",
        "outbreak:read_district",
        "outbreak:create",
        "outbreak:manage",
        "outbreak:declare_quarantine",
        "zoonotic:manage",
        "heatmap:view_district",
        "historical:view",
        "weather:view",
        "vaccination:audit",
        "treatment:audit",
        "drive:create_manage",
        "inventory:manage",
        "inventory:audit",
        "sample:view_district",
        "lab:view_audit",
        "case:manage",
        "alert:receive",
        "alert:broadcast_district",
        "advisory:contribute",
        "dashboard:view_district",
        "kpi:export_district",
        "user:manage_district",
        "audit:view_district",
    ],
    UserRole.STATE_ADMIN: [
        "*",
    ],
    UserRole.STATE_OFFICIAL: [
        "district:read_all",
        "animal:view_all",
        "symptom:view_state",
        "mortality:view_state",
        "photo_gps:view",
        "ai_triage:view",
        "outbreak:read_state",
        "outbreak:create_manage",
        "outbreak:escalate",
        "outbreak:declare_quarantine",
        "zoonotic:manage",
        "heatmap:view_state",
        "historical:view_export",
        "weather:view",
        "drive:approve_manage",
        "inventory:view_all",
        "sample:view_all",
        "case:manage",
        "alert:broadcast_state",
        "advisory:publish",
        "dashboard:view_state",
        "kpi:export_state",
        "user:manage_state",
        "audit:view_state",
        "config:partial",
    ],
    UserRole.SUPER_ADMIN: [
        "*",
    ],
}

def get_permissions_for_role(role: UserRole) -> List[str]:
    return ROLE_PERMISSIONS.get(role, [])

def check_geographic_scope(
    user: User,
    resource_district_id: Optional[str] = None,
    resource_block: Optional[str] = None,
    resource_village: Optional[str] = None,
    resource_owner_id: Optional[str] = None,
) -> bool:
    """Enforce Multi-tenant Geographically-Scoped RBAC access rules.
    Roles evaluate scope down from State -> District -> Block -> Village -> Owner.
    """
    if user.role in (UserRole.SUPER_ADMIN, UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL):
        return True

    if user.role == UserRole.DISTRICT_OFFICIAL:
        if not resource_district_id:
            return True
        return user.district_id == resource_district_id

    if user.role == UserRole.VETERINARIAN:
        if resource_district_id and user.district_id != resource_district_id:
            return False
        if user.block and resource_block:
            return user.block.strip().lower() == resource_block.strip().lower()
        return True

    if user.role == UserRole.PARAVET:
        if resource_district_id and user.district_id != resource_district_id:
            return False
        if user.village and resource_village:
            return user.village.strip().lower() == resource_village.strip().lower()
        return True

    if user.role == UserRole.FARMER:
        if resource_owner_id:
            return user.id == resource_owner_id
        return True

    if user.role == UserRole.LAB_TECHNICIAN:
        return True

    return True

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
require_paravet = require_roles(UserRole.PARAVET)
require_veterinarian = require_roles(UserRole.VETERINARIAN)
require_lab_technician = require_roles(UserRole.LAB_TECHNICIAN)
require_district_official = require_roles(UserRole.DISTRICT_OFFICIAL)
require_state_admin = require_roles(UserRole.STATE_ADMIN, UserRole.STATE_OFFICIAL)
require_super_admin = require_roles(UserRole.SUPER_ADMIN)

require_official_or_vet = require_roles(
    UserRole.VETERINARIAN,
    UserRole.DISTRICT_OFFICIAL,
    UserRole.STATE_ADMIN,
    UserRole.STATE_OFFICIAL,
)

require_field_workers = require_roles(
    UserRole.FARMER,
    UserRole.PARAVET,
    UserRole.VETERINARIAN,
)

require_reporting_roles = require_roles(
    UserRole.FARMER,
    UserRole.PARAVET,
    UserRole.VETERINARIAN,
    UserRole.DISTRICT_OFFICIAL,
    UserRole.STATE_ADMIN,
    UserRole.STATE_OFFICIAL,
)

