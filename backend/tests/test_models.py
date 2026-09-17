from datetime import datetime, timezone, timedelta
import pytest
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import (
    Animal,
    AnimalSpecies,
    Case,
    CaseStatusEnum,
    District,
    DrugInventory,
    Farm,
    HealthEvent,
    HealthEventType,
    OutbreakEvent,
    Prescription,
    SeverityLevelEnum,
    SymptomReport,
    User,
    UserRole,
)

@pytest.mark.asyncio
async def test_create_user_and_farm(test_session: AsyncSession):
    """Test creating user with role and associating with a farm."""
    # Find Pune district
    stmt = select(District).where(District.name == "Pune")
    res = await test_session.execute(stmt)
    pune = res.scalar_one()

    # Create farmer
    user = User(
        phone="+919999900001",
        email="farmer.test@bioherd.in",
        password_hash="hashed_pw_test",
        full_name="Santosh Jadhav",
        role=UserRole.FARMER,
        district_id=pune.id,
    )
    test_session.add(user)
    await test_session.flush()

    assert user.id is not None
    assert user.role == UserRole.FARMER

    # Create farm
    farm = Farm(
        owner_user_id=user.id,
        name="Jadhav Livestock Farm",
        district_id=pune.id,
        latitude=18.52,
        longitude=73.85,
        address="Baramati, Pune",
    )
    test_session.add(farm)
    await test_session.flush()

    assert farm.id is not None
    assert farm.owner_user_id == user.id

@pytest.mark.asyncio
async def test_animal_unique_tag_id_constraint(test_session: AsyncSession):
    """Ensure duplicate animal ear tag IDs raise an error."""
    stmt = select(District).where(District.name == "Pune")
    res = await test_session.execute(stmt)
    pune = res.scalar_one()

    user = User(phone="+919999900002", password_hash="dummy", full_name="User 2")
    test_session.add(user)
    await test_session.flush()

    farm = Farm(owner_user_id=user.id, name="Test Farm", district_id=pune.id, latitude=18.0, longitude=73.0)
    test_session.add(farm)
    await test_session.flush()

    animal1 = Animal(
        farm_id=farm.id,
        species=AnimalSpecies.CATTLE,
        breed="Gir",
        sex="female",
        tag_id="MH-PUN-TEST-001",
    )
    test_session.add(animal1)
    await test_session.flush()

    # Attempting to add duplicate tag_id
    animal2 = Animal(
        farm_id=farm.id,
        species=AnimalSpecies.BUFFALO,
        breed="Murrah",
        sex="female",
        tag_id="MH-PUN-TEST-001",
    )
    test_session.add(animal2)

    with pytest.raises(IntegrityError):
        await test_session.flush()

    await test_session.rollback()

@pytest.mark.asyncio
async def test_symptom_report_and_case_lifecycle(test_session: AsyncSession):
    """Test full workflow from symptom reporting to clinical case and prescription."""
    stmt = select(District).where(District.name == "Pune")
    res = await test_session.execute(stmt)
    pune = res.scalar_one()

    # 1. User & Farm & Animal
    farmer = User(phone="+919999900003", password_hash="dummy", full_name="Farmer Babu", role=UserRole.FARMER)
    vet = User(phone="+919999900004", password_hash="dummy", full_name="Dr. Kulkarni", role=UserRole.VETERINARIAN)
    test_session.add_all([farmer, vet])
    await test_session.flush()

    farm = Farm(owner_user_id=farmer.id, name="Babu Farm", district_id=pune.id, latitude=18.5, longitude=73.8)
    test_session.add(farm)
    await test_session.flush()

    animal = Animal(farm_id=farm.id, species=AnimalSpecies.CATTLE, breed="Khillari", sex="male", tag_id="MH-TAG-999")
    test_session.add(animal)
    await test_session.flush()

    # 2. Symptom Report
    report = SymptomReport(
        animal_id=animal.id,
        reported_by=farmer.id,
        symptoms_json={"fever": True, "blisters_mouth": True, "limping": True},
        severity=SeverityLevelEnum.HIGH,
        status="submitted",
    )
    test_session.add(report)
    await test_session.flush()

    # 3. Clinical Case
    clinical_case = Case(
        symptom_report_id=report.id,
        assigned_vet_id=vet.id,
        status=CaseStatusEnum.IN_REVIEW,
        notes="Suspected Foot and Mouth Disease (FMD). Administered antipyretic.",
    )
    test_session.add(clinical_case)
    await test_session.flush()

    # 4. Prescription
    rx = Prescription(
        case_id=clinical_case.id,
        issued_by=vet.id,
        drug_name="Meloxicam Injection",
        dosage="15ml IM OD",
        duration_days=3,
        instructions_multilingual_json={
            "en": "Inject 15ml into neck muscle once daily for 3 days.",
            "mr": "दररोज १५ मिली मानेच्या स्नायूमध्ये ३ दिवस द्या.",
        },
    )
    test_session.add(rx)
    await test_session.flush()
    await test_session.refresh(clinical_case)

    assert rx.id is not None
    assert len(clinical_case.prescriptions) == 1
    assert clinical_case.prescriptions[0].drug_name == "Meloxicam Injection"
