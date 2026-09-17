import time
from datetime import datetime, timezone
from typing import Any, Dict
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.logging import get_logger
from app.services.minio_service import minio_service
from app.services.redis_service import redis_service

logger = get_logger("health_service")
_START_TIME = time.time()

class HealthService:
    """Multi-service health checker probing PostgreSQL, Redis 7, and MinIO."""

    async def check_database(self, session: AsyncSession) -> Dict[str, Any]:
        start = time.time()
        try:
            result = await session.execute(text("SELECT 1"))
            val = result.scalar()
            latency_ms = round((time.time() - start) * 1000, 2)
            return {
                "status": "up" if val == 1 else "down",
                "latency_ms": latency_ms,
                "engine": "postgresql" if "postgresql" in settings.DATABASE_URL else "sqlite",
            }
        except Exception as e:
            latency_ms = round((time.time() - start) * 1000, 2)
            logger.error("db_health_check_failed", error=str(e))
            return {
                "status": "down",
                "latency_ms": latency_ms,
                "error": str(e),
            }

    async def check_redis(self) -> Dict[str, Any]:
        start = time.time()
        is_live = await redis_service.ping()
        latency_ms = round((time.time() - start) * 1000, 2)
        return {
            "status": "up" if is_live else "fallback_memory",
            "latency_ms": latency_ms,
            "mode": "live" if is_live else "resilient_memory",
        }

    def check_minio(self) -> Dict[str, Any]:
        start = time.time()
        is_live = minio_service.ping()
        latency_ms = round((time.time() - start) * 1000, 2)
        return {
            "status": "up" if is_live else "fallback_memory",
            "latency_ms": latency_ms,
            "mode": "live" if is_live else "resilient_memory",
            "bucket": settings.MINIO_BUCKET_NAME,
        }

    async def get_system_health(self, session: AsyncSession) -> Dict[str, Any]:
        db_status = await self.check_database(session)
        redis_status = await self.check_redis()
        minio_status = self.check_minio()

        uptime_seconds = int(time.time() - _START_TIME)

        # Status determination:
        # If DB is down -> unhealthy (critical)
        # If DB is up and Redis/Minio in fallback -> degraded
        # If all up -> healthy
        if db_status.get("status") != "up":
            overall_status = "unhealthy"
        elif redis_status.get("status") == "fallback_memory" or minio_status.get("status") == "fallback_memory":
            overall_status = "degraded"
        else:
            overall_status = "healthy"

        return {
            "status": overall_status,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "uptime_seconds": uptime_seconds,
            "project": settings.PROJECT_NAME,
            "version": settings.VERSION,
            "environment": settings.ENVIRONMENT,
            "services": {
                "database": db_status,
                "redis": redis_status,
                "minio": minio_status,
            },
        }

health_service = HealthService()
