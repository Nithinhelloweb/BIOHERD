import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Animal, Case, District, Farm, HealthEvent, SymptomReport, User, UserRole


@pytest.mark.asyncio
async def test_disease_catalog_endpoints(client: AsyncClient):
    """Test retrieving endemic diseases catalog and details."""
    # 1. List all diseases
    res = await client.get("/api/v1/symptoms/diseases")
    assert res.status_code == 200
    diseases = res.json()
    assert len(diseases) >= 8
    assert any(d["id"] == "dis-lsd" for d in diseases)
    assert any(d["id"] == "dis-fmd" for d in diseases)
    assert any(d["id"] == "dis-bq" for d in diseases)
    assert any(d["id"] == "dis-mastitis" for d in diseases)

    # Check Marathi name and first aid
    lsd = next(d for d in diseases if d["id"] == "dis-lsd")
    assert "गाठींचा त्वचा रोग" in lsd["name_mr"]
    assert "first_aid_mr" in lsd
    assert "first_aid_en" in lsd
    assert lsd["isolation_required"] is True

    # 2. Filter diseases by species
    cattle_res = await client.get("/api/v1/symptoms/diseases?species=cattle")
    assert cattle_res.status_code == 200
    cattle_diseases = cattle_res.json()
    assert all("cattle" in d["species"] for d in cattle_diseases)

    # 3. Get single disease detail
    detail_res = await client.get("/api/v1/symptoms/diseases/dis-fmd")
    assert detail_res.status_code == 200
    fmd = detail_res.json()
    assert fmd["name_en"] == "Foot and Mouth Disease (FMD)"
    assert "लाळ्या खुरकूत" in fmd["name_mr"]

    # 4. Non-existent disease returns 404
    not_found = await client.get("/api/v1/symptoms/diseases/non-existent-dis")
    assert not_found.status_code == 404


@pytest.mark.asyncio
async def test_ai_analyze_lumpy_skin_disease(client: AsyncClient):
    """Test AI detection engine on Lumpy Skin Disease clinical presentation."""
    payload = {
        "species": "cattle",
        "symptoms_checklist": {
            "skin_coat": ["nodular_skin_lesions", "hard_nodules_all_over_body"],
            "vitality": ["high_fever", "loss_of_appetite"],
            "eyes_nasal": ["watery_eyes"],
        },
        "vernacular_description": "गाय चारा खात नाही, अंगावर मोठ्या गाठी आल्या आहेत आणि ताप आहे",
        "images": ["data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ=="],
    }
    res = await client.post("/api/v1/symptoms/analyze", json=payload)
    assert res.status_code == 200
    data = res.json()

    # Verify primary diagnosis is LSD
    primary = data["primary_diagnosis"]
    assert primary["disease_id"] == "dis-lsd"
    assert "Lumpy Skin" in primary["name_en"]
    assert "गाठींचा त्वचा रोग" in primary["name_mr"]
    assert primary["confidence"] >= 75.0
    assert data["severity"] in ["HIGH", "CRITICAL"]
    assert data["should_escalate_case"] is True
    assert "first_aid" in data
    assert "mr" in data["first_aid"]
    assert "en" in data["first_aid"]
    assert len(data["differential_diagnoses"]) >= 1


@pytest.mark.asyncio
async def test_ai_analyze_foot_and_mouth_disease(client: AsyncClient):
    """Test AI detection engine on Foot and Mouth Disease presentation."""
    payload = {
        "species": "cattle",
        "symptoms_checklist": {
            "oral_nasal": ["frothy_ropey_salivation", "blisters_on_tongue_gums"],
            "locomotion": ["severe_lameness", "ulcers_in_hoof_cleft"],
            "vitality": ["high_fever"],
        },
        "vernacular_description": "तोंडाला फेस येत आहे, जिभेवर फोड आले आहेत आणि खुरकूत झाल्यामुळे पाय लंगडत आहे",
    }
    res = await client.post("/api/v1/symptoms/analyze", json=payload)
    assert res.status_code == 200
    data = res.json()

    primary = data["primary_diagnosis"]
    assert primary["disease_id"] == "dis-fmd"
    assert "Foot and Mouth" in primary["name_en"]
    assert "लाळ्या खुरकूत" in primary["name_mr"]
    assert primary["confidence"] >= 70.0
    assert data["severity"] == "CRITICAL"
    assert data["should_escalate_case"] is True


@pytest.mark.asyncio
async def test_ai_analyze_mastitis_udder(client: AsyncClient):
    """Test AI detection engine on Mastitis presentation."""
    payload = {
        "species": "cattle",
        "symptoms_checklist": {
            "udder_milk": ["hard_swollen_teat_quarter", "curd_like_clots_in_milk", "hot_painful_udder"],
        },
        "vernacular_description": "कास फार सुजली आहे, गरम लागते आणि दुधात गाठी पडत आहेत",
    }
    res = await client.post("/api/v1/symptoms/analyze", json=payload)
    assert res.status_code == 200
    data = res.json()

    primary = data["primary_diagnosis"]
    assert primary["disease_id"] == "dis-mastitis"
    assert "Mastitis" in primary["name_en"]
    assert "स्तनदाह" in primary["name_mr"]


@pytest.mark.asyncio
async def test_submit_symptom_report_and_auto_escalation(
    client: AsyncClient, test_session: AsyncSession
):
    """Test full authenticated symptom report submission with automatic case escalation."""
    # 1. Register a test farmer and obtain JWT token
    user_payload = {
        "phone": "+919822334455",
        "password": "Password@123",
        "full_name": "Pandurang Jadhav",
        "role": "farmer",
        "preferred_language": "mr",
    }
    reg_res = await client.post("/api/v1/auth/register", json=user_payload)
    assert reg_res.status_code == 201
    auth_token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 2. Setup district, farm, and animal in DB
    pune = (await test_session.execute(select(District).where(District.name == "Pune"))).scalar_one()
    farmer = (await test_session.execute(select(User).where(User.phone == "+919822334455"))).scalar_one()

    farm = Farm(
        owner_user_id=farmer.id,
        name="Jadhav Khillari Farm",
        district_id=pune.id,
        latitude=18.52,
        longitude=73.85,
    )
    test_session.add(farm)
    await test_session.flush()

    animal = Animal(
        farm_id=farm.id,
        species="cattle",
        breed="Khillari",
        sex="female",
        weight_kg=420.0,
        tag_id="MH-PUN-KHL-888",
    )
    test_session.add(animal)
    await test_session.commit()

    # 3. Submit symptom report
    report_payload = {
        "animal_id": animal.id,
        "symptoms_checklist": {
            "skin_coat": ["nodular_skin_lesions", "hard_nodules_all_over_body"],
            "vitality": ["high_fever"],
        },
        "vernacular_description": "अंगावर भरपूर गाठी आल्या आहेत, लंपी असल्यासारखे वाटते",
        "images": ["https://minio.bioherd.gov.in/symptoms/photo1.jpg"],
    }
    create_res = await client.post(
        "/api/v1/symptoms/reports", json=report_payload, headers=headers
    )
    assert create_res.status_code == 201
    report_data = create_res.json()

    assert report_data["animal_id"] == animal.id
    assert report_data["animal_tag_id"] == "MH-PUN-KHL-888"
    assert report_data["detection_result"] is not None
    assert report_data["detection_result"]["primary_diagnosis"]["disease_id"] == "dis-lsd"
    assert report_data["case_id"] is not None  # Auto-escalated into a veterinary case!

    # 4. Verify Case record exists in database
    case_stmt = select(Case).where(Case.id == report_data["case_id"])
    case_res = await test_session.execute(case_stmt)
    case = case_res.scalar_one_or_none()
    assert case is not None
    assert "Auto-escalated by AI Detector" in case.notes

    # 5. Verify HealthEvent was logged on animal timeline
    ev_stmt = select(HealthEvent).where(HealthEvent.animal_id == animal.id)
    events = (await test_session.execute(ev_stmt)).scalars().all()
    assert len(events) >= 1
    assert any("AI Screening" in ev.description for ev in events)

    # 6. Query reports list
    list_res = await client.get("/api/v1/symptoms/reports", headers=headers)
    assert list_res.status_code == 200
    reports = list_res.json()
    assert len(reports) >= 1
    assert any(r["id"] == report_data["id"] for r in reports)

    # 7. Query specific report detail
    detail_res = await client.get(
        f"/api/v1/symptoms/reports/{report_data['id']}", headers=headers
    )
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert detail["id"] == report_data["id"]
    assert detail["detection_result"]["confidence"] >= 70.0
    assert "first_aid" in detail["detection_result"]
