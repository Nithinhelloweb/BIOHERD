import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_checkpoints(client: AsyncClient):
    response = await client.get("/api/v1/checkpoints")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 3
    assert any(c["id"] == "ckp-01" for c in data)
    assert any(c["district"] == "Solapur" for c in data)


@pytest.mark.asyncio
async def test_filter_checkpoints_by_district(client: AsyncClient):
    response = await client.get("/api/v1/checkpoints?district=Solapur")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == "ckp-01"
    assert data[0]["highway"] == "NH-52 (Solapur Trunk)"


@pytest.mark.asyncio
async def test_get_single_checkpoint_details(client: AsyncClient):
    response = await client.get("/api/v1/checkpoints/ckp-01")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "MH-KA Border Checkpoint (Solapur - Bijapur)"
    assert data["has_thermal_chute"] is True
    assert data["disinfection_archway_active"] is True
    assert len(data["camera_feeds"]) >= 2


@pytest.mark.asyncio
async def test_get_checkpoint_camera_feeds(client: AsyncClient):
    response = await client.get("/api/v1/checkpoints/ckp-01/feeds")
    assert response.status_code == 200
    feeds = response.json()
    assert len(feeds) >= 2

    # Check lateral chute feed
    lat_feed = next(f for f in feeds if f["angle_type"] == "lateral_chute")
    assert lat_feed["active_target_plate"] == "MH-13-LS-9920"
    assert lat_feed["is_febrile"] is True
    assert lat_feed["thermal_core_temp"] == 40.8
    assert len(lat_feed["detections"]) >= 2
    assert any("Cutaneous Nodule" in d["lesion_type"] for d in lat_feed["detections"])


@pytest.mark.asyncio
async def test_actuate_checkpoint_gate_clamp(client: AsyncClient):
    # Actuate gate clamp lockdown
    response = await client.post(
        "/api/v1/checkpoints/ckp-01/actuate",
        json={
            "action": "clamp_lockdown",
            "reason": "YOLOv8x flagged 96.2% LSD circumscribed nodule",
            "operator_notes": "Immediate impound to containment pen B",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["gate_barrier_status"] == "locked_down"
    assert any("Hydraulic gate clamp engaged" in alert for alert in data["recent_alerts"])


@pytest.mark.asyncio
async def test_actuate_checkpoint_grant_clearance(client: AsyncClient):
    # Actuate gate clearance
    response = await client.post(
        "/api/v1/checkpoints/ckp-02/actuate",
        json={
            "action": "grant_clearance",
            "reason": "All 18 cattle scanned clean. E-seal generated.",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["gate_barrier_status"] == "operational"
    assert any("clearance QR seal issued" in alert for alert in data["recent_alerts"])


@pytest.mark.asyncio
async def test_checkpoint_not_found(client: AsyncClient):
    response = await client.get("/api/v1/checkpoints/invalid-ckp-999")
    assert response.status_code == 404
