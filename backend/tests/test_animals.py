import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import District, Farm, HealthEventType, User, UserRole

@pytest.mark.asyncio
async def test_animal_api_flow(client: AsyncClient, test_session: AsyncSession):
    """Test registering animal, duplicate detection, listing, and tag lookup."""
    # 1. Setup district, farmer, farm
    stmt = select(District).where(District.name == "Pune")
    res = await test_session.execute(stmt)
    pune = res.scalar_one()

    farmer = User(phone="+919876500001", password_hash="dummy", full_name="Vitthal Shinde", role=UserRole.FARMER)
    test_session.add(farmer)
    await test_session.flush()

    farm = Farm(owner_user_id=farmer.id, name="Shinde Dairy Farm", district_id=pune.id, latitude=18.5, longitude=73.8)
    test_session.add(farm)
    await test_session.commit()

    # 2. Register animal
    animal_payload = {
        "farm_id": farm.id,
        "species": "cattle",
        "breed": "Gir",
        "sex": "female",
        "weight_kg": 435.5,
        "tag_id": "MH-PUN-2026-999",
        "is_active": True,
    }
    create_res = await client.post("/api/v1/animals", json=animal_payload)
    assert create_res.status_code == 201
    created_animal = create_res.json()
    assert created_animal["tag_id"] == "MH-PUN-2026-999"
    assert created_animal["species"] == "cattle"
    assert "bioherd.gov.in/verify" in created_animal["qr_code_url"]

    # 3. Duplicate tag registration should fail with 409 Conflict
    dup_res = await client.post("/api/v1/animals", json=animal_payload)
    assert dup_res.status_code == 409
    assert "already registered" in dup_res.json()["detail"]

    # 4. Lookup by Tag ID
    lookup_res = await client.get("/api/v1/animals/tag/MH-PUN-2026-999")
    assert lookup_res.status_code == 200
    assert lookup_res.json()["breed"] == "Gir"
    assert lookup_res.json()["weight_kg"] == 435.5

    # 5. List animals with filter
    list_res = await client.get("/api/v1/animals?species=cattle")
    assert list_res.status_code == 200
    animals = list_res.json()
    assert len(animals) >= 1
    assert any(a["tag_id"] == "MH-PUN-2026-999" for a in animals)

@pytest.mark.asyncio
async def test_indigenous_breeds_catalog(client: AsyncClient):
    """Test retrieving Maharashtra indigenous breeds catalog."""
    res = await client.get("/api/v1/animals/breeds")
    assert res.status_code == 200
    breeds = res.json()
    assert len(breeds) >= 10
    # Must have authentic breeds like Khillari, Dangi, Osmanabadi
    breed_names = [b["name"] for b in breeds]
    assert "Khillari" in breed_names
    assert "Dangi" in breed_names
    assert "Pandharpuri" in breed_names
    assert "Osmanabadi" in breed_names

    # Test filtering by species
    goat_res = await client.get("/api/v1/animals/breeds?species=goat")
    assert goat_res.status_code == 200
    goat_breeds = goat_res.json()
    assert all(b["species"] == "goat" for b in goat_breeds)
    assert any(b["name"] == "Osmanabadi" for b in goat_breeds)

@pytest.mark.asyncio
async def test_animal_lifecycle_qr_and_passport(client: AsyncClient, test_session: AsyncSession):
    """Test updating animal, recording health events, generating QR, passport, and soft-delete."""
    # 1. Setup district, farmer, farm
    stmt = select(District).where(District.name == "Solapur")
    res = await test_session.execute(stmt)
    solapur = res.scalar_one()

    farmer = User(phone="+919876500002", password_hash="dummy", full_name="Sanjay Patil", role=UserRole.FARMER)
    test_session.add(farmer)
    await test_session.flush()

    farm = Farm(owner_user_id=farmer.id, name="Patil Khillari Rearing", district_id=solapur.id, latitude=17.65, longitude=75.9)
    test_session.add(farm)
    await test_session.commit()

    # 2. Register Khillari Bull
    animal_data = {
        "farm_id": farm.id,
        "species": "cattle",
        "breed": "Khillari",
        "sex": "male",
        "weight_kg": 480.0,
        "tag_id": "MH-SOL-KHL-001",
        "is_active": True,
    }
    reg_res = await client.post("/api/v1/animals", json=animal_data)
    assert reg_res.status_code == 201
    animal_id = reg_res.json()["id"]

    # 3. Update animal weight
    update_res = await client.put(f"/api/v1/animals/{animal_id}", json={"weight_kg": 495.2})
    assert update_res.status_code == 200
    assert update_res.json()["weight_kg"] == 495.2

    # 4. Record health timeline events
    event_data = {
        "event_type": "vaccination",
        "description": "FMD (Foot & Mouth Disease) Bi-Annual Booster Dose administered",
    }
    ev_res = await client.post(f"/api/v1/animals/{animal_id}/events", json=event_data)
    assert ev_res.status_code == 201
    assert ev_res.json()["event_type"] == "vaccination"

    # List events
    list_ev_res = await client.get(f"/api/v1/animals/{animal_id}/events")
    assert list_ev_res.status_code == 200
    events = list_ev_res.json()
    assert len(events) == 1
    assert "Foot & Mouth" in events[0]["description"]

    # 5. Generate Verifiable QR Code
    qr_res = await client.get(f"/api/v1/animals/{animal_id}/qr")
    assert qr_res.status_code == 200
    qr_json = qr_res.json()
    assert qr_json["tag_id"] == "MH-SOL-KHL-001"
    assert qr_json["qr_base64"].startswith("data:image/png;base64,")
    assert "https://bioherd.gov.in/verify" in qr_json["verification_url"]

    # 6. Animal Passport
    passport_res = await client.get(f"/api/v1/animals/{animal_id}/passport")
    assert passport_res.status_code == 200
    passport = passport_res.json()
    assert passport["tag_id"] == "MH-SOL-KHL-001"
    assert passport["breed"] == "Khillari"
    assert passport["owner_name"] == "Sanjay Patil"
    assert "Solapur" in passport["district_name"]
    assert passport["health_events_count"] >= 1
    assert len(passport["verification_hash"]) == 16

    # 7. Soft Delete
    del_res = await client.delete(f"/api/v1/animals/{animal_id}")
    assert del_res.status_code == 200
    assert "inactive" in del_res.json()["message"]

    # Inactive animal should not appear in default list
    list_active = await client.get(f"/api/v1/animals?farm_id={farm.id}")
    assert list_active.status_code == 200
    active_animals = list_active.json()
    assert not any(a["id"] == animal_id for a in active_animals)
