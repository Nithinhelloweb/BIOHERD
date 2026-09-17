import pytest
from httpx import AsyncClient
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import District
from app.db.seeder import MAHARASHTRA_DISTRICTS, seed_all

@pytest.mark.asyncio
async def test_36_districts_seeded(test_session: AsyncSession):
    """Verify exactly 36 Maharashtra districts are seeded with coordinates and names."""
    stmt = select(func.count(District.id))
    res = await test_session.execute(stmt)
    count = res.scalar()
    assert count == 36

    # Verify key districts exist
    for key_dist in ["Pune", "Kolhapur", "Nashik", "Ahmednagar", "Chhatrapati Sambhajinagar", "Nagpur"]:
        dist_stmt = select(District).where(District.name == key_dist)
        dist_res = await test_session.execute(dist_stmt)
        d = dist_res.scalar_one_or_none()
        assert d is not None, f"District {key_dist} was not found"
        assert d.name_mr != ""
        assert d.latitude > 0
        assert d.longitude > 0
        assert d.livestock_population > 0

@pytest.mark.asyncio
async def test_list_districts_api(client: AsyncClient):
    """Test GET /api/v1/districts returns 36 districts."""
    response = await client.get("/api/v1/districts")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 36

@pytest.mark.asyncio
async def test_search_districts_api(client: AsyncClient):
    """Test searching districts by English and Marathi names."""
    # Search by English
    res1 = await client.get("/api/v1/districts?search=Pune")
    assert res1.status_code == 200
    items1 = res1.json()
    assert len(items1) >= 1
    assert any(d["name"] == "Pune" for d in items1)

    # Search by Marathi
    res2 = await client.get("/api/v1/districts?search=सातारा")
    assert res2.status_code == 200
    items2 = res2.json()
    assert len(items2) >= 1
    assert items2[0]["name"] == "Satara"

@pytest.mark.asyncio
async def test_district_summary_api(client: AsyncClient):
    """Test GET /api/v1/districts/{id}/summary."""
    # First get Pune district id
    list_res = await client.get("/api/v1/districts?search=Pune")
    pune_id = list_res.json()[0]["id"]

    summary_res = await client.get(f"/api/v1/districts/{pune_id}/summary")
    assert summary_res.status_code == 200
    data = summary_res.json()
    assert data["district_id"] == pune_id
    assert data["district_name"] == "Pune"
    assert data["total_livestock"] > 0
