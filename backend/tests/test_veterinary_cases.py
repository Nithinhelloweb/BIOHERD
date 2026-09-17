"""
Unit & Integration Tests for Veterinarian Case Management & Telemedicine
Verifies:
1. Curated Drug Formulary & Dosage Calculation Engine
2. Clinical Case Triage, Assignment, and Lifecycle State Transitions
3. Digital Prescription Issuance with Schedule-H, Withdrawal Periods, and Health Timeline Sync
4. WebRTC Telemedicine Session Signaling (Create, Relay Signal, End)
5. Case Resolution and Detailed Dossier Retrieval
"""

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.drug_catalog import DrugCatalog
from app.core.security import create_access_token
from app.db.models import (
    User,
    UserRole,
    District,
    Farm,
    Animal,
    AnimalSpecies,
    SymptomReport,
    DetectionResult,
    Case,
    CaseStatusEnum,
    SeverityLevelEnum,
    Prescription,
    HealthEvent,
    HealthEventType,
)


@pytest.mark.asyncio
async def test_drug_catalog_and_dosage_calculation():
    """Test Maharashtra Veterinary Formulary lookup and species/weight dosage computation."""
    all_drugs = DrugCatalog.get_all()
    assert len(all_drugs) >= 10

    # Test filtering by Schedule-H
    schedule_h_drugs = DrugCatalog.filter_by(schedule_h=True)
    assert len(schedule_h_drugs) >= 4
    for drug in schedule_h_drugs:
        assert drug["schedule_h"] is True

    # Test filtering by indication query
    mastitis_drugs = DrugCatalog.filter_by(disease_query="Mastitis")
    assert len(mastitis_drugs) >= 2

    # Test dosage calculation for Ceftriaxone on a 400 kg cow
    ceft_calc = DrugCatalog.calculate_dosage(
        drug_id="DRUG-CEFT",
        species="cattle",
        body_weight_kg=400.0,
    )
    assert ceft_calc["drug_id"] == "DRUG-CEFT"
    assert ceft_calc["schedule_h"] is True
    assert ceft_calc["milk_withdrawal_days"] == 7
    assert ceft_calc["meat_withdrawal_days"] == 28
    assert ceft_calc["calculated_volume_ml"] > 0
    assert "मराठी" not in ceft_calc["instructions_mr"]  # Contains authentic Marathi text
    assert len(ceft_calc["instructions_mr"]) > 10

    # Test dosage calculation for Meloxicam on a 300 kg buffalo
    melx_calc = DrugCatalog.calculate_dosage(
        drug_id="DRUG-MELX",
        species="buffalo",
        body_weight_kg=300.0,
    )
    assert melx_calc["drug_id"] == "DRUG-MELX"
    assert melx_calc["schedule_h"] is False
    assert melx_calc["milk_withdrawal_days"] == 2
    assert melx_calc["meat_withdrawal_days"] == 5

    # Test dosage calculation for Ivermectin SC injection on a 35 kg goat
    iver_calc = DrugCatalog.calculate_dosage(
        drug_id="DRUG-IVER",
        species="goat",
        body_weight_kg=35.0,
    )
    assert iver_calc["route"] == "Subcutaneous (SC) ONLY"
    assert iver_calc["milk_withdrawal_days"] == 28
    assert iver_calc["meat_withdrawal_days"] == 35


@pytest.mark.asyncio
async def test_case_lifecycle_triage_and_assignment(
    client: AsyncClient, test_session: AsyncSession
):
    """Test full case lifecycle from symptom submission to vet assignment and review."""
    # Find district
    res = await test_session.execute(select(District).where(District.name == "Solapur"))
    district = res.scalar_one()

    # 1. Create Vet & Farmer
    vet = User(
        phone="+919876543210",
        full_name="Dr. Anjali Patil",
        password_hash="dummy_hash",
        role=UserRole.VETERINARIAN,
        district_id=district.id,
    )
    farmer = User(
        phone="+919876543211",
        full_name="Tukaram Shinde",
        password_hash="dummy_hash",
        role=UserRole.FARMER,
        district_id=district.id,
    )
    test_session.add_all([vet, farmer])
    await test_session.flush()

    farm = Farm(
        name="Shinde Dairy Farm",
        owner_user_id=farmer.id,
        district_id=district.id,
        latitude=17.6599,
        longitude=75.9064,
    )
    test_session.add(farm)
    await test_session.flush()

    cow = Animal(
        farm_id=farm.id,
        species=AnimalSpecies.CATTLE,
        breed="Khillari",
        sex="female",
        weight_kg=380.0,
        tag_id="MH-SOL-KHIL-9901",
    )
    test_session.add(cow)
    await test_session.flush()

    # 2. Create Symptom Report
    report = SymptomReport(
        animal_id=cow.id,
        reported_by=farmer.id,
        symptoms_json={"checklist": {"fever": True, "salivation": True, "hoof_lesions": True}},
        severity=SeverityLevelEnum.HIGH,
        status="submitted",
    )
    test_session.add(report)
    await test_session.flush()

    detection = DetectionResult(
        symptom_report_id=report.id,
        model_version="ensemble-v1.0",
        predictions_json=[
            {"name_en": "Foot and Mouth Disease", "name_mr": "लाळ्या खुरकूत", "confidence": 92.5}
        ],
        confidence=92.5,
    )
    test_session.add(detection)

    # 3. Create Case auto-escalated
    case = Case(
        symptom_report_id=report.id,
        status=CaseStatusEnum.SUBMITTED,
        priority=SeverityLevelEnum.HIGH,
        notes="Suspected acute FMD with excessive salivation and oral blisters.",
    )
    test_session.add(case)
    await test_session.commit()

    # Vet Auth Token
    vet_token = create_access_token({"sub": vet.id, "role": vet.role.value})
    vet_headers = {"Authorization": f"Bearer {vet_token}"}

    # 4. List cases via API
    list_resp = await client.get("/api/v1/cases", headers=vet_headers)
    assert list_resp.status_code == 200
    case_list = list_resp.json()
    assert len(case_list) >= 1
    target_case = next(c for c in case_list if c["id"] == case.id)
    assert target_case["status"] == "submitted"
    assert target_case["priority"] == "high"
    assert target_case["animal_tag_id"] == "MH-SOL-KHIL-9901"
    assert target_case["primary_suspect"] == "Foot and Mouth Disease"

    # 5. Vet assigns case to herself
    assign_resp = await client.post(
        f"/api/v1/cases/{case.id}/assign",
        json={"vet_id": vet.id, "notes": "Accepting priority triage for Solapur farm."},
        headers=vet_headers,
    )
    assert assign_resp.status_code == 200
    assert assign_resp.json()["case_status"] == "assigned"

    # 6. Update status to in_review
    status_resp = await client.patch(
        f"/api/v1/cases/{case.id}/status",
        json={"status": "in_review", "notes": "Commencing clinical examination."},
        headers=vet_headers,
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["new_status"] == "in_review"


@pytest.mark.asyncio
async def test_issue_digital_prescription_and_health_timeline(
    client: AsyncClient, test_session: AsyncSession
):
    """Test digital prescription issuance with Schedule-H, withdrawal days, and health timeline sync."""
    res = await test_session.execute(select(District).where(District.name == "Kolhapur"))
    district = res.scalar_one()

    vet = User(
        phone="+919876543220",
        full_name="Dr. Sachin Deshmukh",
        password_hash="dummy_hash",
        role=UserRole.VETERINARIAN,
        district_id=district.id,
    )
    farmer = User(
        phone="+919876543221",
        full_name="Mahadev Powar",
        password_hash="dummy_hash",
        role=UserRole.FARMER,
        district_id=district.id,
    )
    test_session.add_all([vet, farmer])
    await test_session.flush()

    farm = Farm(
        name="Powar Buffalo Dairy",
        owner_user_id=farmer.id,
        district_id=district.id,
        latitude=16.7050,
        longitude=74.2433,
    )
    test_session.add(farm)
    await test_session.flush()

    buffalo = Animal(
        farm_id=farm.id,
        species=AnimalSpecies.BUFFALO,
        breed="Pandharpuri",
        sex="female",
        weight_kg=450.0,
        tag_id="MH-KOL-PAND-8802",
    )
    test_session.add(buffalo)
    await test_session.flush()

    report = SymptomReport(
        animal_id=buffalo.id,
        reported_by=farmer.id,
        symptoms_json={"checklist": {"skin_nodules": True, "high_fever": True}},
        severity=SeverityLevelEnum.CRITICAL,
        status="submitted",
    )
    test_session.add(report)
    await test_session.flush()

    case = Case(
        symptom_report_id=report.id,
        assigned_vet_id=vet.id,
        status=CaseStatusEnum.IN_REVIEW,
        priority=SeverityLevelEnum.CRITICAL,
    )
    test_session.add(case)
    await test_session.commit()

    vet_token = create_access_token({"sub": vet.id, "role": vet.role.value})
    vet_headers = {"Authorization": f"Bearer {vet_token}"}

    # Issue Prescription for Melonex Plus and Enrofloxacin
    presc_payload = {
        "drug_name": "Enrofloxacin 10%",
        "dosage": "15 ml deep IM once daily",
        "duration_days": 4,
        "instructions_multilingual_json": {
            "en": "Deep IM once daily for 4 days.",
            "mr": "दररोज एकदा खोल स्नायूत ४ दिवस द्या. दूध ४ दिवस वापरू नका.",
        },
        "schedule_h_warning": True,
        "milk_withdrawal_days": 4,
        "meat_withdrawal_days": 14,
    }

    resp = await client.post(
        f"/api/v1/cases/{case.id}/prescriptions",
        json=presc_payload,
        headers=vet_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["drug_name"] == "Enrofloxacin 10%"
    assert data["schedule_h_warning"] is True
    assert data["milk_withdrawal_days"] == 4
    assert data["meat_withdrawal_days"] == 14
    assert data["digital_signature_hash"] is not None
    assert len(data["digital_signature_hash"]) == 64

    # Verify case status automatically updated to prescription_issued
    case_query = await test_session.execute(select(Case).where(Case.id == case.id))
    updated_case = case_query.scalar_one()
    assert updated_case.status == CaseStatusEnum.PRESCRIPTION_ISSUED

    # Verify HealthEvent logged on Animal timeline
    event_stmt = select(HealthEvent).where(
        HealthEvent.animal_id == buffalo.id,
        HealthEvent.event_type == HealthEventType.MEDICATION,
    )
    events = (await test_session.execute(event_stmt)).scalars().all()
    assert len(events) >= 1
    assert "Enrofloxacin" in events[0].description

    # Verify prescriptions list endpoint
    list_presc_resp = await client.get(f"/api/v1/cases/{case.id}/prescriptions", headers=vet_headers)
    assert list_presc_resp.status_code == 200
    assert len(list_presc_resp.json()) == 1


@pytest.mark.asyncio
async def test_telemedicine_session_signaling(
    client: AsyncClient, test_session: AsyncSession
):
    """Test WebRTC tele-consultation room creation and SDP/ICE candidate relay."""
    res = await test_session.execute(select(District).where(District.name == "Pune"))
    district = res.scalar_one()

    vet = User(
        phone="+919876543230",
        full_name="Dr. Vinayak Jadhav",
        password_hash="dummy_hash",
        role=UserRole.VETERINARIAN,
        district_id=district.id,
    )
    farmer = User(
        phone="+919876543231",
        full_name="Ramesh Gaikwad",
        password_hash="dummy_hash",
        role=UserRole.FARMER,
        district_id=district.id,
    )
    test_session.add_all([vet, farmer])
    await test_session.flush()

    farm = Farm(
        name="Gaikwad Farm",
        owner_user_id=farmer.id,
        district_id=district.id,
        latitude=18.5204,
        longitude=73.8567,
    )
    test_session.add(farm)
    await test_session.flush()

    goat = Animal(
        farm_id=farm.id,
        species=AnimalSpecies.GOAT,
        breed="Osmanabadi",
        sex="female",
        weight_kg=35.0,
        tag_id="MH-PUN-OSM-3301",
    )
    test_session.add(goat)
    await test_session.flush()

    report = SymptomReport(animal_id=goat.id, reported_by=farmer.id, symptoms_json={}, severity=SeverityLevelEnum.MEDIUM)
    test_session.add(report)
    await test_session.flush()

    case = Case(symptom_report_id=report.id, assigned_vet_id=vet.id, status=CaseStatusEnum.ASSIGNED)
    test_session.add(case)
    await test_session.commit()

    vet_token = create_access_token({"sub": vet.id, "role": vet.role.value})
    vet_headers = {"Authorization": f"Bearer {vet_token}"}

    # 1. Create Telemedicine Session
    session_resp = await client.post(
        "/api/v1/cases/telemedicine/create-session",
        json={"case_id": case.id},
        headers=vet_headers,
    )
    assert session_resp.status_code == 200
    s_data = session_resp.json()
    session_id = s_data["session_id"]
    assert session_id.startswith("telemed-")
    assert len(s_data["ice_servers"]) >= 1

    # 2. Relay SDP Offer from Vet
    offer_resp = await client.post(
        "/api/v1/cases/telemedicine/signal",
        json={
            "session_id": session_id,
            "sender_id": vet.id,
            "signal_type": "offer",
            "data": {"sdp": "v=0\r\no=- 1234 2 IN IP4 127.0.0.1..."},
        },
        headers=vet_headers,
    )
    assert offer_resp.status_code == 200
    assert offer_resp.json()["status"] == "relayed"

    # 3. Farmer polls pending signals
    farmer_token = create_access_token({"sub": farmer.id, "role": farmer.role.value})
    farmer_headers = {"Authorization": f"Bearer {farmer_token}"}

    signals_resp = await client.get(
        f"/api/v1/cases/telemedicine/signals/{session_id}?recipient_id={farmer.id}",
        headers=farmer_headers,
    )
    assert signals_resp.status_code == 200
    signals = signals_resp.json()
    assert len(signals) >= 1
    assert signals[0]["signal_type"] == "offer"

    # 4. End Session
    end_resp = await client.post(
        f"/api/v1/cases/telemedicine/{session_id}/end",
        headers=vet_headers,
    )
    assert end_resp.status_code == 200
    assert end_resp.json()["status"] == "ended"


@pytest.mark.asyncio
async def test_case_detail_and_closure(
    client: AsyncClient, test_session: AsyncSession
):
    """Test retrieving complete case dossier and closing case with resolution summary."""
    res = await test_session.execute(select(District).where(District.name == "Ahmednagar"))
    district = res.scalar_one()

    vet = User(phone="+919876543240", full_name="Dr. Pradip Kadam", password_hash="dummy_hash", role=UserRole.VETERINARIAN, district_id=district.id)
    farmer = User(phone="+919876543241", full_name="Sanjay Kale", password_hash="dummy_hash", role=UserRole.FARMER, district_id=district.id)
    test_session.add_all([vet, farmer])
    await test_session.flush()

    farm = Farm(
        name="Kale Dairy",
        owner_user_id=farmer.id,
        district_id=district.id,
        latitude=19.0948,
        longitude=74.7480,
    )
    test_session.add(farm)
    await test_session.flush()

    cow = Animal(
        farm_id=farm.id,
        species=AnimalSpecies.CATTLE,
        breed="Dangi",
        sex="female",
        weight_kg=360.0,
        tag_id="MH-AHM-DANG-5501",
    )
    test_session.add(cow)
    await test_session.flush()

    report = SymptomReport(animal_id=cow.id, reported_by=farmer.id, symptoms_json={"checklist": {"coughing": True}}, severity=SeverityLevelEnum.LOW)
    test_session.add(report)
    await test_session.flush()

    case = Case(symptom_report_id=report.id, assigned_vet_id=vet.id, status=CaseStatusEnum.IN_REVIEW)
    test_session.add(case)
    await test_session.commit()

    vet_token = create_access_token({"sub": vet.id, "role": vet.role.value})
    vet_headers = {"Authorization": f"Bearer {vet_token}"}

    # Close case
    close_resp = await client.patch(
        f"/api/v1/cases/{case.id}/status",
        json={
            "status": "closed",
            "notes": "Animal fully recovered after course of supportive therapy.",
            "resolution_summary": "Resolved: Routine seasonal cough cleared. No further antibiotics needed.",
        },
        headers=vet_headers,
    )
    assert close_resp.status_code == 200
    assert close_resp.json()["new_status"] == "closed"

    # Detail view
    detail_resp = await client.get(f"/api/v1/cases/{case.id}", headers=vet_headers)
    assert detail_resp.status_code == 200
    detail = detail_resp.json()
    assert detail["status"] == "closed"
    assert "Routine seasonal cough cleared" in detail["resolution_summary"]
    assert detail["animal_tag_id"] == "MH-AHM-DANG-5501"
