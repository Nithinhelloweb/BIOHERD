import os
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.logging import get_logger, setup_logging
from app.db.base import Base
from app.db.seeder import seed_districts
from app.db.session import async_session_maker, engine
from app.services.minio_service import minio_service
from app.services.redis_service import redis_service

setup_logging()
logger = get_logger("main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Startup
    logger.info("bioherd_api_starting", version=settings.VERSION, env=settings.ENVIRONMENT)
    
    # Create tables if they do not exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("db_schema_synchronized")

    # Seed districts if empty
    async with async_session_maker() as session:
        try:
            await seed_districts(session)
            await session.commit()
            logger.info("districts_startup_check_complete")
        except Exception as e:
            logger.warning("districts_startup_seed_error", error=str(e))

    # Test Redis & MinIO connections
    await redis_service.ping()
    minio_service.ping()

    yield

    # 2. Shutdown
    logger.info("bioherd_api_shutting_down")
    await redis_service.close()
    await engine.dispose()

app = FastAPI(
    title="BIOHERD API — Livestock Disease Early Detection System",
    description=(
        "Production backend for BIOHERD (SIH26128 — Smart India Hackathon 2026, "
        "Govt. of Maharashtra). Real-time disease reporting, multi-modal AI diagnostics, "
        "epidemiological surveillance, and veterinary telemedicine."
    ),
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Structured Request Logging Middleware
@app.middleware("http")
async def structlog_request_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration_ms = round((time.time() - start_time) * 1000, 2)
    logger.info(
        "http_request_handled",
        method=request.method,
        path=request.url.path,
        status_code=response.status_code,
        duration_ms=duration_ms,
    )
    return response

# Include V1 Router
app.include_router(api_router, prefix=settings.API_V1_STR)

# Determine static frontend directory (Flutter Web build)
static_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "static"))
has_static_frontend = os.path.isdir(static_dir) and os.path.exists(os.path.join(static_dir, "index.html"))

if has_static_frontend:
    logger.info("flutter_web_frontend_enabled", path=static_dir)

    @app.middleware("http")
    async def spa_fallback_middleware(request: Request, call_next):
        """Serve Flutter Web SPA assets and client-side route fallbacks on 404."""
        response = await call_next(request)
        if response.status_code == 404 and request.method == "GET":
            path = request.url.path.lstrip("/")
            # Do not intercept API, documentation, or OpenAPI paths
            if not (path.startswith("api/") or path.startswith("docs") or path.startswith("redoc") or path == "openapi.json"):
                target_file = os.path.join(static_dir, path)
                if path and os.path.isfile(target_file):
                    return FileResponse(target_file)
                # Client-side SPA navigation fallback
                if "text/html" in request.headers.get("accept", ""):
                    return FileResponse(os.path.join(static_dir, "index.html"))
        return response

@app.get("/", tags=["Root"])
async def root(request: Request):
    """Serve Flutter Web app to web browsers, and project metadata JSON to API clients."""
    accept = request.headers.get("accept", "")
    if has_static_frontend and "text/html" in accept and "application/json" not in accept:
        return FileResponse(os.path.join(static_dir, "index.html"))
    return {
        "project": "BIOHERD",
        "description": "Livestock Disease Early Detection & Management System",
        "problem_statement": "SIH26128 (Govt. of Maharashtra)",
        "version": settings.VERSION,
        "status": "online",
        "api_docs": "/docs",
        "health_check": f"{settings.API_V1_STR}/health",
    }
