from typing import Any, List, Union
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Core Application Settings
    PROJECT_NAME: str = "BIOHERD"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    PORT: int = Field(
        default=8000,
        description="Port for web server (Render automatically sets PORT env var)",
    )

    # Security & Tokens (RS256 / HS256 for dev fallback)
    SECRET_KEY: str = Field(
        default="bioherd-insecure-development-secret-key-change-in-production-2026",
        description="JWT encryption secret key",
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Primary Database: PostgreSQL 16 + PostGIS + TimescaleDB
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "bioherd_user"
    POSTGRES_PASSWORD: str = "bioherd_password"
    POSTGRES_DB: str = "bioherd_db"
    DATABASE_URL: str = Field(
        default="sqlite+aiosqlite:///./bioherd_dev.db",
        description="Async SQLAlchemy database connection string",
    )

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: Any) -> str:
        """Translate Render/Heroku postgres:// URL scheme to asyncpg driver."""
        if isinstance(v, str):
            if v.startswith("postgres://"):
                return v.replace("postgres://", "postgresql+asyncpg://", 1)
            elif v.startswith("postgresql://") and not v.startswith("postgresql+asyncpg://"):
                return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v

    # Cache & PubSub: Redis 7
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: str | None = None
    REDIS_URL: str = "redis://localhost:6379/0"

    # Object Store: MinIO (S3 compatible)
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    MINIO_SECURE: bool = False
    MINIO_BUCKET_NAME: str = "bioherd-assets"

    # CORS Whitelist (Flutter Web & Admin Dashboards)
    # Using Union[str, List[str]] prevents pydantic-settings from forcing json.loads on plain strings like "*"
    CORS_ORIGINS: Union[str, List[str]] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "http://localhost",
        "*",
    ]

    @field_validator("CORS_ORIGINS", mode="after")
    @classmethod
    def assemble_cors_origins(cls, v: Any) -> List[str]:
        """Support raw '*', comma-separated strings, or JSON arrays from cloud env vars."""
        if isinstance(v, str):
            v_str = v.strip()
            if not v_str or v_str == "*":
                return ["*"]
            if v_str.startswith("[") and v_str.endswith("]"):
                import json
                try:
                    return json.loads(v_str)
                except Exception:
                    pass
            return [origin.strip() for origin in v_str.split(",") if origin.strip()]
        elif isinstance(v, (list, tuple)):
            return list(v)
        return ["*"]

settings = Settings()
