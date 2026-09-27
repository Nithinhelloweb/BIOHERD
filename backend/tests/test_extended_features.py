import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import District, User, UserRole


@pytest.mark.asyncio
async def test_mortality_reporting_and_zoonotic_check(client: AsyncClient, test_session: AsyncSession):
    # 1. Register a Field Vet
    reg_vet = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919811122233", "password": "VetPassword@2026", "full_name": "Dr. Ramesh", "role": "veterinarian"},
    )
    assert reg_vet.status_code == 201
    token = reg_vet.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Get districts
    dist_res = await client.get("/api/v1/districts", headers=headers)
    assert dist_res.status_code == 200
    pune_dist = dist_res.json()[0]

    # 3. Report mortality with Anthrax symptoms (zoonotic trigger)
    mort_res = await client.post(
        "/api/v1/mortality",
        headers=headers,
        json={
            "district_id": pune_dist["id"],
            "block": "Haveli",
            "village": "Wagholi",
            "species": "cattle",
            "animal_count": 2,
            "probable_cause": "Sudden death with unclotted blood discharge (Suspected Anthrax)",
            "symptoms": ["sudden_death", "dark_non_clotting_blood"],
            "disposal_method": "deep_burial",
            "post_mortem_conducted": False,
        },
    )
    assert mort_res.status_code == 201
    mort_data = mort_res.json()
    assert mort_data["animal_count"] == 2
    assert mort_data["zoonotic_risk"] is True

    # 4. List mortality reports
    list_res = await client.get("/api/v1/mortality", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1


@pytest.mark.asyncio
async def test_lab_sample_workflow(client: AsyncClient, test_session: AsyncSession):
    # 1. Register vet and lab technician
    vet_res = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919822233301", "password": "VetPassword@2026", "full_name": "Dr. Vet", "role": "veterinarian"},
    )
    vet_token = vet_res.json()["access_token"]
    vet_headers = {"Authorization": f"Bearer {vet_token}"}

    lab_res = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919822233302", "password": "LabPassword@2026", "full_name": "Dr. LabTech", "role": "lab_technician"},
    )
    lab_token = lab_res.json()["access_token"]
    lab_headers = {"Authorization": f"Bearer {lab_token}"}

    dist_res = await client.get("/api/v1/districts", headers=vet_headers)
    pune_dist = dist_res.json()[0]

    # 2. Vet creates lab sample request
    sample_res = await client.post(
        "/api/v1/lab/samples",
        headers=vet_headers,
        json={
            "district_id": pune_dist["id"],
            "sample_type": "whole_blood",
            "suspected_disease": "Lumpy Skin Disease",
            "current_lab_name": "District Lab Pune",
        },
    )
    assert sample_res.status_code == 201
    sample_data = sample_res.json()
    sample_id = sample_data["id"]
    assert sample_data["transit_status"] == "collected"

    # 3. Update transit status
    transit_res = await client.put(
        f"/api/v1/lab/samples/{sample_id}/transit",
        headers=lab_headers,
        json={"transit_status": "received_at_lab"},
    )
    assert transit_res.status_code == 200
    assert transit_res.json()["transit_status"] == "received_at_lab"

    # 4. Lab Tech uploads result
    result_res = await client.put(
        f"/api/v1/lab/samples/{sample_id}/result",
        headers=lab_headers,
        json={
            "test_method": "RT-PCR",
            "test_result": "positive",
            "pathogen_confirmed": "Capripoxvirus",
            "result_notes": "Viral DNA confirmed via RT-PCR.",
        },
    )
    assert result_res.status_code == 200
    assert result_res.json()["test_result"] == "positive"
    assert result_res.json()["transit_status"] == "completed"


@pytest.mark.asyncio
async def test_vaccination_drive_and_coverage(client: AsyncClient, test_session: AsyncSession):
    reg = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919833344401", "password": "VetPassword@2026", "full_name": "Dr. DriveLeader", "role": "veterinarian"},
    )
    headers = {"Authorization": f"Bearer {reg.json()['access_token']}"}

    dist_res = await client.get("/api/v1/districts", headers=headers)
    pune_dist = dist_res.json()[0]

    # Create drive
    drive_res = await client.post(
        "/api/v1/vaccination-drives",
        headers=headers,
        json={
            "title": "Pune Block FMD Vaccination Drive",
            "target_disease": "FMD",
            "vaccine_name": "Raksha-Ovac",
            "district_id": pune_dist["id"],
            "block": "Haveli",
            "start_date": "2026-09-01T00:00:00Z",
            "end_date": "2026-09-30T00:00:00Z",
            "target_animals_count": 200,
        },
    )
    assert drive_res.status_code == 201
    drive_id = drive_res.json()["id"]

    # Record progress
    prog_res = await client.put(
        f"/api/v1/vaccination-drives/{drive_id}/progress",
        headers=headers,
        json={"additional_doses": 150},
    )
    assert prog_res.status_code == 200
    assert prog_res.json()["completed_doses"] == 150
    assert prog_res.json()["coverage_percentage"] == 75.0

    # Get coverage report
    cov_res = await client.get("/api/v1/vaccination-drives/coverage/report", headers=headers)
    assert cov_res.status_code == 200
    assert cov_res.json()["overall_completed"] >= 150


@pytest.mark.asyncio
async def test_telecom_ivr_and_sms(client: AsyncClient, test_session: AsyncSession):
    # 1. Simulate incoming IVR call
    ivr_call = await client.post(
        "/api/v1/telecom/ivr/call",
        json={"caller_phone": "+919988776655", "language": "mr"},
    )
    assert ivr_call.status_code == 200
    session_id = ivr_call.json()["call_session_id"]
    assert "मराठी" in ivr_call.json()["voice_prompt_text"]

    # 2. Select language
    step1 = await client.post(
        "/api/v1/telecom/ivr/input",
        json={
            "call_session_id": session_id,
            "caller_phone": "+919988776655",
            "digit_pressed": "1",
            "step_id": "language_select",
            "selected_language": "mr",
        },
    )
    assert step1.status_code == 200
    assert step1.json()["step_id"] == "menu_select"

    # 3. Inbound SMS reporting
    sms_res = await client.post(
        "/api/v1/telecom/sms/inbound",
        json={"from_phone": "+919988776655", "message_text": "DEATH CATTLE 2"},
    )
    assert sms_res.status_code == 200
    assert sms_res.json()["status"] == "success"
    assert "BIOHERD: Mortality report logged" in sms_res.json()["reply_message"]


@pytest.mark.asyncio
async def test_weather_and_kpis(client: AsyncClient, test_session: AsyncSession):
    reg = await client.post(
        "/api/v1/auth/register",
        json={"phone": "+919844455501", "password": "VetPassword@2026", "full_name": "Dr. Analyst", "role": "district_official"},
    )
    headers = {"Authorization": f"Bearer {reg.json()['access_token']}"}

    # Weather
    weather_res = await client.get("/api/v1/outbreak/weather?district_name=Pune", headers=headers)
    assert weather_res.status_code == 200
    w_data = weather_res.json()
    assert "relative_humidity_percentage" in w_data
    assert "vector_risk_indices" in w_data

    # KPIs
    kpi_res = await client.get("/api/v1/outbreak/kpis", headers=headers)
    assert kpi_res.status_code == 200
    kpi_data = kpi_res.json()
    assert "kpi_metrics" in kpi_data
    assert "active_suspected_cases" in kpi_data["kpi_metrics"]
