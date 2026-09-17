from datetime import datetime, timezone
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import District, Farm, OutbreakEvent, SeverityLevelEnum, User, UserRole
from app.services.outbreak_detector import (
    calculate_district_risk_score,
    calculate_r0,
    detect_spatial_clusters,
    generate_circle_polygon,
    generate_geojson_feature_collection,
    haversine_distance,
)


@pytest.mark.asyncio
async def test_spatial_analytics_haversine_and_clustering():
    """Test Haversine distance, circle generation, and spatial density clustering."""
    # Pune (18.5204, 73.8567) to Solapur (17.6599, 75.9064)
    dist_pune_solapur = haversine_distance(18.5204, 73.8567, 17.6599, 75.9064)
    assert 200.0 < dist_pune_solapur < 250.0

    # Circle polygon geometry
    circle_ring = generate_circle_polygon(18.5204, 73.8567, radius_km=5.0, num_points=16)
    assert len(circle_ring) == 17  # 16 + closed point
    assert circle_ring[0] == circle_ring[-1]

    # Cluster detection with synthetic farm points
    # Cluster A in Solapur: 3 farms within 4km
    # Isolated point in Nagpur: ~600km away
    points = [
        {"id": "c1", "latitude": 17.660, "longitude": 75.900, "disease": "Foot and Mouth Disease", "farm_id": "f1"},
        {"id": "c2", "latitude": 17.665, "longitude": 75.910, "disease": "Foot and Mouth Disease", "farm_id": "f2"},
        {"id": "c3", "latitude": 17.655, "longitude": 75.895, "disease": "Foot and Mouth Disease", "farm_id": "f3"},
        {"id": "c4", "latitude": 21.145, "longitude": 79.088, "disease": "Anthrax", "farm_id": "f4"},
    ]

    clusters = detect_spatial_clusters(points, eps_km=10.0, min_samples=2)
    assert len(clusters) == 1
    c = clusters[0]
    assert c["primary_disease"] == "Foot and Mouth Disease"
    assert c["case_count"] == 3
    assert c["affected_farms_count"] == 3
    assert c["containment_radius_km"] >= 5.0
    assert c["surveillance_radius_km"] >= 10.0

    # GeoJSON FeatureCollection generation
    geojson = generate_geojson_feature_collection(clusters)
    assert geojson["type"] == "FeatureCollection"
    assert geojson["total_clusters"] == 1
    # Check features contains epicenter, containment polygon, and surveillance polygon
    types = [f["properties"]["feature_type"] for f in geojson["features"]]
    assert "epicenter" in types
    assert "containment_zone" in types
    assert "surveillance_zone" in types


@pytest.mark.asyncio
async def test_r0_and_district_risk_index():
    """Test R0 transmission rate calculation and multi-parameter district risk score."""
    # R0 calculation
    r0_accelerating = calculate_r0(recent_cases_count=12, prior_cases_count=6)
    assert r0_accelerating >= 1.5

    r0_decaying = calculate_r0(recent_cases_count=2, prior_cases_count=8)
    assert r0_decaying < 1.0

    # District risk index calculation
    risk_high = calculate_district_risk_score(
        district_name="Solapur",
        active_cases=15,
        livestock_population=850000,
        primary_disease="Foot and Mouth Disease",
        recent_cases_7d=15,
        prior_cases_7d=6,
    )
    assert risk_high["risk_score"] > 40.0
    assert risk_high["severity"] in [SeverityLevelEnum.HIGH, SeverityLevelEnum.CRITICAL]
    assert risk_high["weather_factor"] >= 1.2

    risk_low = calculate_district_risk_score(
        district_name="Sindhudurg",
        active_cases=0,
        livestock_population=250000,
        primary_disease="Foot and Mouth Disease",
    )
    assert risk_low["risk_score"] <= 35.0
    assert risk_low["severity"] == SeverityLevelEnum.LOW


@pytest.mark.asyncio
async def test_outbreak_geojson_map_api(client: AsyncClient):
    """Test GET /api/v1/outbreak/map returns compliant GeoJSON."""
    resp = await client.get("/api/v1/outbreak/map")
    assert resp.status_code == 200
    data = resp.json()

    assert data["type"] == "FeatureCollection"
    assert "features" in data
    assert len(data["features"]) > 0

    # Verify presence of Polygon containment rings
    polygons = [f for f in data["features"] if f["geometry"]["type"] == "Polygon"]
    assert len(polygons) >= 2


@pytest.mark.asyncio
async def test_district_risk_rankings_api(client: AsyncClient):
    """Test GET /api/v1/outbreak/districts returns sorted 36 districts."""
    resp = await client.get("/api/v1/outbreak/districts")
    assert resp.status_code == 200
    districts = resp.json()

    assert len(districts) == 36
    # Verified descending order by risk score
    for i in range(len(districts) - 1):
        assert districts[i]["risk_score"] >= districts[i + 1]["risk_score"]

    # Test single district endpoint
    pune_resp = await client.get("/api/v1/outbreak/districts/Pune/risk")
    assert pune_resp.status_code == 200
    pune_data = pune_resp.json()
    assert pune_data["district_name"] == "Pune"
    assert "r0_estimate" in pune_data
    assert "weather_factor" in pune_data


@pytest.mark.asyncio
async def test_declare_outbreak_and_quarantine_broadcast(
    client: AsyncClient, test_session: AsyncSession
):
    """Test full workflow: declare outbreak, issue quarantine, and verify geo-fenced alert broadcast."""
    # Find Solapur district
    res = await test_session.execute(select(District).where(District.name == "Solapur"))
    solapur = res.scalar_one()

    # 1. Create Vet User
    vet = User(
        phone="+919888800001",
        full_name="Dr. Nilesh Shinde",
        password_hash="dummy_hash",
        role=UserRole.VETERINARIAN,
        district_id=solapur.id,
    )
    test_session.add(vet)

    # 2. Create District Official
    official = User(
        phone="+919888800002",
        full_name="Officer Deshmukh",
        password_hash="dummy_hash",
        role=UserRole.DISTRICT_OFFICIAL,
        district_id=solapur.id,
    )
    test_session.add(official)

    # 3. Create Farmer with a Farm near epicenter (within 3km)
    farmer = User(
        phone="+919888800003",
        full_name="Baburao Patil",
        password_hash="dummy_hash",
        role=UserRole.FARMER,
        district_id=solapur.id,
    )
    test_session.add(farmer)
    await test_session.flush()

    farm = Farm(
        owner_user_id=farmer.id,
        name="Patil Dairy Farm",
        district_id=solapur.id,
        latitude=17.6620,  # ~0.3km from 17.6600
        longitude=75.9070,
        address="Mohol Road, Solapur",
    )
    test_session.add(farm)
    await test_session.flush()

    # Log in as official to get JWT token
    from app.core.security import create_access_token
    token_official = create_access_token(data={"sub": official.id, "role": official.role.value})
    headers_official = {"Authorization": f"Bearer {token_official}"}

    token_vet = create_access_token(data={"sub": vet.id, "role": vet.role.value})
    headers_vet = {"Authorization": f"Bearer {token_vet}"}

    token_farmer = create_access_token(data={"sub": farmer.id, "role": farmer.role.value})
    headers_farmer = {"Authorization": f"Bearer {token_farmer}"}

    # 4. Vet declares an outbreak
    declare_resp = await client.post(
        "/api/v1/outbreak/declare",
        json={
            "district_id": solapur.id,
            "disease_name": "Foot and Mouth Disease",
            "latitude": 17.6600,
            "longitude": 75.9060,
            "case_count": 8,
            "risk_level": "critical",
            "containment_radius_km": 5.0,
            "surveillance_radius_km": 10.0,
            "notes_en": "Severe FMD cluster in Mohol.",
            "notes_mr": "मोहोळ तालुक्यात लाळ्या खुरकूत प्रादुर्भाव.",
        },
        headers=headers_vet,
    )
    assert declare_resp.status_code == 201
    outbreak_data = declare_resp.json()
    assert outbreak_data["disease_name"] == "Foot and Mouth Disease"
    assert outbreak_data["case_count"] == 8

    # 5. Official declares quarantine and triggers alert broadcast
    quarantine_resp = await client.post(
        "/api/v1/outbreak/quarantine",
        json={
            "outbreak_id": outbreak_data["id"],
            "district_id": solapur.id,
            "disease_name": "Foot and Mouth Disease",
            "latitude": 17.6600,
            "longitude": 75.9060,
            "containment_radius_km": 5.0,
            "surveillance_radius_km": 10.0,
            "broadcast_alert": True,
            "notes_en": "Mandatory quarantine within 5km. Movement restricted.",
            "notes_mr": "५ किमी परिघात जनावरांच्या हालचालीस बंदी.",
        },
        headers=headers_official,
    )
    assert quarantine_resp.status_code == 200
    q_data = quarantine_resp.json()
    assert q_data["status"] == "quarantine_enacted"
    assert q_data["quarantine_declared"] is True
    assert q_data["broadcast_metrics"]["recipients_count"] >= 1

    # 6. Farmer checks their alerts
    alerts_resp = await client.get("/api/v1/outbreak/alerts", headers=headers_farmer)
    assert alerts_resp.status_code == 200
    farmer_alerts = alerts_resp.json()
    assert len(farmer_alerts) >= 1

    fmd_alert = farmer_alerts[0]
    assert "Foot and Mouth Disease" in fmd_alert["title_multilingual_json"]["en"]
    assert "लाळ्या खुरकूत" in fmd_alert["title_multilingual_json"]["mr"]
    assert "५ किमी" in fmd_alert["body_multilingual_json"]["mr"]
