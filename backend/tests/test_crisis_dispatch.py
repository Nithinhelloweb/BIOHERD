import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_sitrep_briefing(client: AsyncClient):
    response = await client.get("/api/v1/crisis/sitrep")
    assert response.status_code == 200
    data = response.json()
    assert "CRITICAL LEVEL 4" in data["threat_level"]
    assert "Solapur" in data["executive_summary"]
    assert "SECTION 6" in data["statutory_proclamation"]
    assert len(data["primary_epicenters"]) >= 3
    assert "Deploy 3-Tier Ring Containment Cordon (1km / 3km / 10km)" in data["operational_checklist"]


@pytest.mark.asyncio
async def test_query_sitrep_copilot_vaccine(client: AsyncClient):
    response = await client.post(
        "/api/v1/crisis/sitrep/query",
        json={"question": "What is the vaccine deficit in Solapur?", "context_district": "Solapur"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "CRISIS SUPPLY STATUS" in data["answer"]
    assert "3,850" in data["answer"]


@pytest.mark.asyncio
async def test_query_sitrep_copilot_mandi(client: AsyncClient):
    response = await client.post(
        "/api/v1/crisis/sitrep/query",
        json={"question": "Draft an APMC Mandi closure order", "context_district": "Solapur"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "STATUTORY MANDI DIRECTIVE" in data["answer"]
    assert "moratorium" in data["answer"].lower()


@pytest.mark.asyncio
async def test_query_sitrep_copilot_border(client: AsyncClient):
    response = await client.post(
        "/api/v1/crisis/sitrep/query",
        json={"question": "Analyze interstate Karnataka border risk", "context_district": "Solapur"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "INTERSTATE BORDER INTEL" in data["answer"]
    assert "Belagavi" in data["answer"] or "Bijapur" in data["answer"]


@pytest.mark.asyncio
async def test_list_rrt_teams(client: AsyncClient):
    response = await client.get("/api/v1/crisis/rrt-teams")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 3
    assert any(t["id"] == "RRT-MH-13-A" for t in data)
    assert any("Strike Team Alpha" in t["team_name"] for t in data)


@pytest.mark.asyncio
async def test_reassign_rrt_team(client: AsyncClient):
    response = await client.post(
        "/api/v1/crisis/rrt-teams/RRT-MH-13-A/reassign",
        json={
            "new_status": "vaccinating",
            "assigned_district": "Solapur",
            "target_epicenter": "Solapur South Sector 4",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "vaccinating"
    assert data["eta_minutes"] == 0
    assert data["assigned_epicenter"] == "Solapur South Sector 4"


@pytest.mark.asyncio
async def test_dispatch_farmer_broadcast(client: AsyncClient):
    response = await client.post(
        "/api/v1/crisis/broadcast/dispatch",
        json={"district": "Solapur", "radius_km": 5.0, "channel": "all"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["district"] == "Solapur"
    assert data["recipient_count"] == 4820
    assert "Voice IVR Outbound (1800)" in data["channels_engaged"]
    assert data["delivery_status"] == "dispatched"
