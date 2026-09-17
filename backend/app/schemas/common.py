from typing import Any, Dict, Generic, List, Optional, TypeVar
from pydantic import BaseModel, Field

T = TypeVar("T")

class PaginationMeta(BaseModel):
    total: int = Field(description="Total records available")
    page: int = Field(default=1, description="Current page number")
    per_page: int = Field(default=20, description="Items per page")
    total_pages: int = Field(description="Total calculated pages")

class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T] = Field(description="List of records")
    pagination: PaginationMeta

class StandardResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Operation completed successfully"
    data: Optional[T] = None

class HealthCheckServiceStatus(BaseModel):
    status: str
    latency_ms: float
    engine: Optional[str] = None
    mode: Optional[str] = None
    bucket: Optional[str] = None
    error: Optional[str] = None

class HealthCheckResponse(BaseModel):
    status: str = Field(description="'healthy', 'degraded', or 'unhealthy'")
    timestamp: str
    uptime_seconds: int
    project: str
    version: str
    environment: str
    services: Dict[str, HealthCheckServiceStatus]
