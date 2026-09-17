from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.common import HealthCheckResponse
from app.services.health_service import health_service

router = APIRouter(prefix="/health", tags=["Health & Observability"])

@router.get(
    "",
    response_model=HealthCheckResponse,
    summary="Multi-service health probe",
    description="Probes PostgreSQL, Redis 7, and MinIO object store with latency metrics.",
)
async def check_health(session: AsyncSession = Depends(get_db)):
    health_data = await health_service.get_system_health(session)
    return health_data

@router.get(
    "/liveness",
    summary="Kubernetes liveness probe",
    description="Returns 200 immediately to signify the API process is alive and responsive.",
)
async def liveness_probe():
    return {"status": "alive"}

@router.get(
    "/readiness",
    summary="Kubernetes readiness probe",
    description="Ensures core database connection is ready to accept user traffic.",
)
async def readiness_probe(session: AsyncSession = Depends(get_db)):
    db_check = await health_service.check_database(session)
    if db_check.get("status") != "up":
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not_ready", "database": db_check},
        )
    return {"status": "ready", "database": db_check}
