import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_root_endpoint(client: AsyncClient):
    """Test API root status endpoint."""
    response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "BIOHERD"
    assert "SIH26128" in data["problem_statement"]
    assert data["status"] == "online"

@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient):
    """Test multi-service health probe."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ["healthy", "degraded"]
    assert "services" in data
    assert "database" in data["services"]
    assert data["services"]["database"]["status"] == "up"
    assert "redis" in data["services"]
    assert "minio" in data["services"]

@pytest.mark.asyncio
async def test_liveness_probe(client: AsyncClient):
    """Test Kubernetes liveness probe."""
    response = await client.get("/api/v1/health/liveness")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "alive"

@pytest.mark.asyncio
async def test_readiness_probe(client: AsyncClient):
    """Test Kubernetes readiness probe."""
    response = await client.get("/api/v1/health/readiness")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"
    assert data["database"]["status"] == "up"
