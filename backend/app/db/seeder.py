from datetime import datetime, timezone, timedelta
from typing import List, Dict, Any
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.logging import get_logger
from app.core.security import get_password_hash
from app.db.models import (
    Advisory,
    AlertBroadcast,
    Animal,
    AnimalSpecies,
    Case,
    CaseStatusEnum,
    District,
    DrugInventory,
    Farm,
    HealthEvent,
    HealthEventType,
    LabSample,
    LivestockMovement,
    MortalityReport,
    OutbreakEvent,
    SeverityLevelEnum,
    SymptomReport,
    User,
    UserRole,
    VaccinationDrive,
)

logger = get_logger("seeder")

# All 36 official districts of Maharashtra with centroids and 20th Livestock Census figures
MAHARASHTRA_DISTRICTS: List[Dict[str, Any]] = [
    {"name": "Ahmednagar", "name_mr": "अहिल्यानगर (अहमदनगर)", "lat": 19.0948, "lon": 74.7480, "livestock": 2854000},
    {"name": "Akola", "name_mr": "अकोला", "lat": 20.7002, "lon": 77.0082, "livestock": 768000},
    {"name": "Amravati", "name_mr": "अमरावती", "lat": 20.9374, "lon": 77.7796, "livestock": 1120000},
    {"name": "Chhatrapati Sambhajinagar", "name_mr": "छत्रपती संभाजीनगर", "lat": 19.8762, "lon": 75.3433, "livestock": 1640000},
    {"name": "Beed", "name_mr": "बीड", "lat": 18.9891, "lon": 75.7601, "livestock": 1980000},
    {"name": "Bhandara", "name_mr": "भंडारा", "lat": 21.1667, "lon": 79.6500, "livestock": 530000},
    {"name": "Buldhana", "name_mr": "बुलढाणा", "lat": 20.5312, "lon": 76.1847, "livestock": 1280000},
    {"name": "Chandrapur", "name_mr": "चंद्रपूर", "lat": 19.9615, "lon": 79.2961, "livestock": 890000},
    {"name": "Dhule", "name_mr": "धुळे", "lat": 20.9042, "lon": 74.7749, "livestock": 980000},
    {"name": "Gadchiroli", "name_mr": "गडचिरोली", "lat": 20.1849, "lon": 80.0028, "livestock": 670000},
    {"name": "Gondia", "name_mr": "गोंदिया", "lat": 21.4604, "lon": 80.1961, "livestock": 490000},
    {"name": "Hingoli", "name_mr": "हिंगोली", "lat": 19.7196, "lon": 77.1485, "livestock": 610000},
    {"name": "Jalgaon", "name_mr": "जळगाव", "lat": 21.0077, "lon": 75.5626, "livestock": 1780000},
    {"name": "Jalna", "name_mr": "जालना", "lat": 19.8410, "lon": 75.8864, "livestock": 1150000},
    {"name": "Kolhapur", "name_mr": "कोल्हापूर", "lat": 16.7050, "lon": 74.2433, "livestock": 1890000},
    {"name": "Latur", "name_mr": "लातूर", "lat": 18.4088, "lon": 76.5604, "livestock": 1340000},
    {"name": "Mumbai City", "name_mr": "मुंबई शहर", "lat": 18.9388, "lon": 72.8354, "livestock": 25000},
    {"name": "Mumbai Suburban", "name_mr": "मुंबई उपनगर", "lat": 19.0760, "lon": 72.8777, "livestock": 45000},
    {"name": "Nagpur", "name_mr": "नागपूर", "lat": 21.1458, "lon": 79.0882, "livestock": 1250000},
    {"name": "Nanded", "name_mr": "नांदेड", "lat": 19.1383, "lon": 77.3210, "livestock": 1620000},
    {"name": "Nandurbar", "name_mr": "नंदुरबार", "lat": 21.3739, "lon": 74.2403, "livestock": 820000},
    {"name": "Nashik", "name_mr": "नाशिक", "lat": 19.9975, "lon": 73.7898, "livestock": 2450000},
    {"name": "Dharashiv", "name_mr": "धाराशिव (उस्मानाबाद)", "lat": 18.1861, "lon": 76.0419, "livestock": 1210000},
    {"name": "Palghar", "name_mr": "पालघर", "lat": 19.6967, "lon": 72.7699, "livestock": 680000},
    {"name": "Parbhani", "name_mr": "परभणी", "lat": 19.2608, "lon": 76.7748, "livestock": 1040000},
    {"name": "Pune", "name_mr": "पुणे", "lat": 18.5204, "lon": 73.8567, "livestock": 2720000},
    {"name": "Raigad", "name_mr": "रायगड", "lat": 18.5158, "lon": 73.1822, "livestock": 730000},
    {"name": "Ratnagiri", "name_mr": "रत्नागिरी", "lat": 16.9902, "lon": 73.3120, "livestock": 650000},
    {"name": "Sangli", "name_mr": "सांगली", "lat": 16.8524, "lon": 74.5815, "livestock": 1840000},
    {"name": "Satara", "name_mr": "सातारा", "lat": 17.6805, "lon": 73.9935, "livestock": 1950000},
    {"name": "Sindhudurg", "name_mr": "सिंधुदुर्ग", "lat": 16.1179, "lon": 73.7229, "livestock": 420000},
    {"name": "Solapur", "name_mr": "सोलापूर", "lat": 17.6599, "lon": 75.9064, "livestock": 2390000},
    {"name": "Thane", "name_mr": "ठाणे", "lat": 19.2183, "lon": 72.9781, "livestock": 580000},
    {"name": "Wardha", "name_mr": "वर्धा", "lat": 20.7453, "lon": 78.6022, "livestock": 710000},
    {"name": "Washim", "name_mr": "वाशीम", "lat": 20.1110, "lon": 77.1347, "livestock": 690000},
    {"name": "Yavatmal", "name_mr": "यवतमाळ", "lat": 20.3888, "lon": 78.1204, "livestock": 1410000},
]

async def seed_districts(session: AsyncSession) -> Dict[str, District]:
    """Seed all 36 districts of Maharashtra idempotently."""
    district_map: Dict[str, District] = {}
    for d_data in MAHARASHTRA_DISTRICTS:
        stmt = select(District).where(District.name == d_data["name"])
        res = await session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing:
            existing.name_mr = d_data["name_mr"]
            existing.latitude = d_data["lat"]
            existing.longitude = d_data["lon"]
            existing.livestock_population = d_data["livestock"]
            district_map[existing.name] = existing
        else:
            district = District(
                name=d_data["name"],
                name_mr=d_data["name_mr"],
                state="Maharashtra",
                latitude=d_data["lat"],
                longitude=d_data["lon"],
                livestock_population=d_data["livestock"],
            )
            session.add(district)
            district_map[district.name] = district

    await session.flush()
    logger.info("districts_seeded", total=len(district_map))
    return district_map

async def seed_users(session: AsyncSession, district_map: Dict[str, District]) -> Dict[str, User]:
    """Seed initial role personas (all 7 RBAC roles with authentic geographical scopes)."""
    users_data = [
        {
            "phone": "+919876543210",
            "email": "farmer.ramesh@bioherd.in",
            "full_name": "Ramesh Patil",
            "role": UserRole.FARMER,
            "district": "Pune",
            "block": "Haveli",
            "village": "Wagholi",
            "lang": "mr",
        },
        {
            "phone": "+919876543214",
            "email": "paravet.ganesh@bioherd.in",
            "full_name": "Ganesh More (Pashu Sakha)",
            "role": UserRole.PARAVET,
            "district": "Pune",
            "block": "Haveli",
            "village": "Wagholi",
            "lang": "mr",
        },
        {
            "phone": "+919876543211",
            "email": "dr.anjali@bioherd.in",
            "full_name": "Dr. Anjali Deshmukh",
            "role": UserRole.VETERINARIAN,
            "district": "Pune",
            "block": "Haveli",
            "village": None,
            "lang": "mr",
        },
        {
            "phone": "+919876543215",
            "email": "lab.vikram@bioherd.in",
            "full_name": "Dr. Vikram Joshi (Lab Tech)",
            "role": UserRole.LAB_TECHNICIAN,
            "district": "Pune",
            "block": "Haveli",
            "village": None,
            "lab_id": "DIS-LAB-PUNE-01",
            "lang": "en",
        },
        {
            "phone": "+919876543212",
            "email": "official.ahmednagar@bioherd.in",
            "full_name": "Rajesh Shinde",
            "role": UserRole.DISTRICT_OFFICIAL,
            "district": "Ahmednagar",
            "block": None,
            "village": None,
            "lang": "mr",
        },
        {
            "phone": "+919876543213",
            "email": "state.admin@bioherd.in",
            "full_name": "Dr. Suresh Kulkarni",
            "role": UserRole.STATE_ADMIN,
            "district": "Pune",
            "block": None,
            "village": None,
            "lang": "en",
        },
        {
            "phone": "+919876543299",
            "email": "superadmin@bioherd.in",
            "full_name": "BIOHERD Super Administrator",
            "role": UserRole.SUPER_ADMIN,
            "district": "Pune",
            "block": None,
            "village": None,
            "lang": "en",
        },
    ]

    pw_hash = get_password_hash("Bioherd@2026")
    user_map: Dict[str, User] = {}

    for u in users_data:
        stmt = select(User).where(User.phone == u["phone"])
        res = await session.execute(stmt)
        existing = res.scalar_one_or_none()

        dist = district_map.get(u["district"])
        dist_id = dist.id if dist else None

        if existing:
            existing.full_name = u["full_name"]
            existing.role = u["role"]
            existing.district_id = dist_id
            existing.block = u.get("block")
            existing.village = u.get("village")
            existing.lab_id = u.get("lab_id")
            user_map[u["role"].value] = existing
        else:
            user = User(
                phone=u["phone"],
                email=u["email"],
                password_hash=pw_hash,
                full_name=u["full_name"],
                role=u["role"],
                preferred_language=u["lang"],
                district_id=dist_id,
                block=u.get("block"),
                village=u.get("village"),
                lab_id=u.get("lab_id"),
            )
            session.add(user)
            user_map[u["role"].value] = user

    await session.flush()
    logger.info("users_seeded", total=len(user_map))
    return user_map

async def seed_farms_and_animals(
    session: AsyncSession,
    user_map: Dict[str, User],
    district_map: Dict[str, District],
) -> List[Animal]:
    """Seed demo farms and authentic indigenous livestock breeds."""
    farmer = user_map.get(UserRole.FARMER.value)
    pune_dist = district_map.get("Pune")
    if not farmer or not pune_dist:
        return []

    # 1. Farm
    farm_stmt = select(Farm).where(Farm.owner_user_id == farmer.id)
    farm_res = await session.execute(farm_stmt)
    farm = farm_res.scalar_one_or_none()
    if not farm:
        farm = Farm(
            owner_user_id=farmer.id,
            name="Patil Dairy & Livestock Farm",
            district_id=pune_dist.id,
            latitude=18.5310,
            longitude=73.8440,
            address="Village Khed, Taluka Haveli, Pune, Maharashtra 410501",
        )
        session.add(farm)
        await session.flush()

    # 2. Animals (Gir cow, Murrah buffalo, Osmanabadi goat)
    animals_seed = [
        {
            "species": AnimalSpecies.CATTLE,
            "breed": "Gir",
            "sex": "female",
            "weight_kg": 420.0,
            "tag_id": "MH-PUN-2026-001",
        },
        {
            "species": AnimalSpecies.BUFFALO,
            "breed": "Murrah",
            "sex": "female",
            "weight_kg": 540.0,
            "tag_id": "MH-PUN-2026-002",
        },
        {
            "species": AnimalSpecies.GOAT,
            "breed": "Osmanabadi",
            "sex": "female",
            "weight_kg": 38.5,
            "tag_id": "MH-PUN-2026-003",
        },
    ]

    created_animals: List[Animal] = []
    for a_data in animals_seed:
        stmt = select(Animal).where(Animal.tag_id == a_data["tag_id"])
        res = await session.execute(stmt)
        existing = res.scalar_one_or_none()
        if existing:
            created_animals.append(existing)
        else:
            animal = Animal(
                farm_id=farm.id,
                species=a_data["species"],
                breed=a_data["breed"],
                sex=a_data["sex"],
                weight_kg=a_data["weight_kg"],
                tag_id=a_data["tag_id"],
                dob=datetime.now(timezone.utc) - timedelta(days=730),
            )
            session.add(animal)
            created_animals.append(animal)

    await session.flush()
    logger.info("farms_and_animals_seeded", animals_count=len(created_animals))
    return created_animals

async def seed_drug_inventory_and_outbreaks(
    session: AsyncSession,
    district_map: Dict[str, District],
) -> None:
    """Seed veterinary drug dispensaries and realistic outbreak incidents."""
    pune_dist = district_map.get("Pune")
    jalgaon_dist = district_map.get("Jalgaon")

    if pune_dist:
        drugs = [
            ("FMD Vaccine (Raksha-Ovac)", 500.0, "vials"),
            ("Meloxicam Injection 5mg/ml", 120.0, "bottles"),
            ("Oxytetracycline 200mg/ml", 85.0, "bottles"),
            ("Ivermectin 1% Solution", 150.0, "bottles"),
        ]
        now = datetime.now(timezone.utc)
        for drug_name, qty, unit in drugs:
            stmt = select(DrugInventory).where(
                DrugInventory.district_id == pune_dist.id,
                DrugInventory.drug_name == drug_name,
            )
            res = await session.execute(stmt)
            if not res.scalar_one_or_none():
                inv = DrugInventory(
                    district_id=pune_dist.id,
                    drug_name=drug_name,
                    quantity=qty,
                    unit=unit,
                    expiry_date=now + timedelta(days=365),
                )
                session.add(inv)

    if jalgaon_dist:
        # Sample outbreak record for geo-surveillance & early warning
        outbreak_stmt = select(OutbreakEvent).where(
            OutbreakEvent.district_id == jalgaon_dist.id,
            OutbreakEvent.disease_name == "Lumpy Skin Disease",
        )
        outbreak_res = await session.execute(outbreak_stmt)
        if not outbreak_res.scalar_one_or_none():
            outbreak = OutbreakEvent(
                district_id=jalgaon_dist.id,
                disease_name="Lumpy Skin Disease",
                case_count=14,
                risk_level=SeverityLevelEnum.HIGH,
                declared_at=datetime.now(timezone.utc) - timedelta(days=2),
            )
            session.add(outbreak)

    await session.flush()
    logger.info("inventory_and_outbreaks_seeded")


async def seed_extended_features(
    session: AsyncSession,
    district_map: Dict[str, District],
    user_map: Dict[str, User],
    animals: List[Animal],
) -> None:
    """Seed vaccination drives, laboratory samples, advisories, livestock movements, and mortality incidents."""
    pune_dist = district_map.get("Pune")
    ahmednagar_dist = district_map.get("Ahmednagar")
    vet = user_map.get(UserRole.VETERINARIAN.value)
    paravet = user_map.get(UserRole.PARAVET.value)
    farmer = user_map.get(UserRole.FARMER.value)
    dvo = user_map.get(UserRole.DISTRICT_OFFICIAL.value)
    admin = user_map.get(UserRole.STATE_ADMIN.value)

    if not pune_dist or not vet:
        return

    now = datetime.now(timezone.utc)

    # 1. Update first animal with pregnancy reproductive status
    if animals:
        animals[0].reproductive_status = "pregnant"
        animals[0].last_insemination_date = now - timedelta(days=120)
        animals[0].expected_calving_date = now + timedelta(days=160)
        animals[0].lactation_count = 2

    # 2. Vaccination Drive (FMD Mission 2026)
    drive_stmt = select(VaccinationDrive).where(VaccinationDrive.title == "Pune District FMD Ring Vaccination Campaign 2026")
    if not (await session.execute(drive_stmt)).scalar_one_or_none():
        drive = VaccinationDrive(
            title="Pune District FMD Ring Vaccination Campaign 2026",
            target_disease="Foot and Mouth Disease (FMD)",
            vaccine_name="Raksha-Ovac Polyvalent (FMD)",
            district_id=pune_dist.id,
            block="Haveli",
            village="Wagholi",
            start_date=now - timedelta(days=5),
            end_date=now + timedelta(days=25),
            target_animals_count=500,
            completed_doses=380,
            status="in_progress",
            created_by=vet.id,
            assigned_vet_id=vet.id,
        )
        session.add(drive)

    # 3. Lab Sample (PCR test for Lumpy Skin Disease)
    sample_stmt = select(LabSample).where(LabSample.sample_code == "SMP-2026-4412")
    if not (await session.execute(sample_stmt)).scalar_one_or_none():
        first_animal_id = animals[0].id if animals else None
        lab_sample = LabSample(
            sample_code="SMP-2026-4412",
            animal_id=first_animal_id,
            district_id=pune_dist.id,
            collected_by=vet.id,
            collection_date=now - timedelta(days=1),
            sample_type="whole_blood",
            suspected_disease="Lumpy Skin Disease",
            transit_status="completed",
            current_lab_name="District Disease Diagnostic Lab Pune",
            test_method="Real-Time PCR",
            test_result="positive",
            pathogen_confirmed="Capripoxvirus (LSD)",
            is_zoonotic=False,
            result_notes="High viral titer detected in whole blood EDTA tube. Ring vaccination recommended.",
            result_date=now,
        )
        session.add(lab_sample)

    # 4. Multilingual Advisory (LSD Biosecurity & Prevention)
    adv_stmt = select(Advisory).where(Advisory.disease_target == "Lumpy Skin Disease")
    if not (await session.execute(adv_stmt)).scalar_one_or_none():
        author_id = admin.id if admin else vet.id
        adv = Advisory(
            title_multilingual_json={
                "en": "Advisory: Monsoon Prevention of Lumpy Skin Disease (LSD)",
                "mr": "सल्ला: पावसाळ्यातील गाठींचा त्वचा रोग (लम्पी स्कीन) प्रतिबंधात्मक उपाय",
                "hi": "सलाह: लंपी त्वचा रोग की रोकथाम एवं लक्षण",
            },
            content_multilingual_json={
                "en": "Isolate cattle with skin lumps immediately. Apply neem-turmeric paste on lesions. Smoke cattle sheds at dusk to deter vector mosquitoes and biting flies. Report to Pashu Chikitsalaya immediately.",
                "mr": "अंगावर गाठी दिसणाऱ्या जनावराला इतर जनावरांपासून तात्काळ वेगळे करा. फुटलेल्या गाठींवर कडुलिंब व हळदीचा लेप लावा. गोठ्यात धूर करून डास व माश्यांचा उपद्रव थांबवा. पशुवैद्यकीय दवाखान्यात तात्काळ कळवा.",
                "hi": "गांठ वाले पशुओं को तुरंत अलग करें। नीम और हल्दी का लेप लगाएं। गोशाला में धुआं करके मक्खी-मच्छरों से बचाव करें।",
            },
            category="prevention",
            disease_target="Lumpy Skin Disease",
            author_id=author_id,
            status="published",
            target_district_id=pune_dist.id,
            published_at=now,
        )
        session.add(adv)

    # 5. Livestock Movement Permit
    mov_stmt = select(LivestockMovement).where(LivestockMovement.permit_number == "MH-TRP-2026-88124")
    if not (await session.execute(mov_stmt)).scalar_one_or_none() and ahmednagar_dist:
        first_tag = animals[0].tag_id if animals else "MH-PUN-2026-001"
        movement = LivestockMovement(
            permit_number="MH-TRP-2026-88124",
            animal_ids=[first_tag],
            origin_district_id=pune_dist.id,
            origin_block="Haveli",
            destination_district_id=ahmednagar_dist.id,
            destination_block="Sangamner",
            purpose="mandi_sale",
            health_certificate_issued=True,
            inspection_status="approved",
            quarantine_flag=False,
            departed_at=now - timedelta(hours=6),
        )
        session.add(movement)

    # 6. Mortality Report
    reporter_id = paravet.id if paravet else (farmer.id if farmer else vet.id)
    mort_stmt = select(MortalityReport).where(MortalityReport.reported_by == reporter_id)
    if not (await session.execute(mort_stmt)).scalar_one_or_none():
        mort = MortalityReport(
            reported_by=reporter_id,
            district_id=pune_dist.id,
            block="Haveli",
            village="Wagholi",
            species=AnimalSpecies.CATTLE,
            animal_count=1,
            probable_cause="Suspected Acute Hemorrhagic Septicaemia",
            symptoms=["throat_swelling", "high_fever", "respiratory_distress"],
            mortality_date=now - timedelta(days=2),
            disposal_method="deep_burial",
            post_mortem_conducted=False,
            zoonotic_risk=False,
            status="verified",
        )
        session.add(mort)

    await session.flush()
    logger.info("extended_features_seeded")


async def seed_all(session: AsyncSession) -> Dict[str, Any]:
    """Execute complete database seeding."""
    logger.info("beginning_bioherd_database_seed")
    district_map = await seed_districts(session)
    user_map = await seed_users(session, district_map)
    animals = await seed_farms_and_animals(session, user_map, district_map)
    await seed_drug_inventory_and_outbreaks(session, district_map)
    await seed_extended_features(session, district_map, user_map, animals)
    await session.commit()
    logger.info("bioherd_database_seed_complete")
    return {
        "districts_count": len(district_map),
        "users_count": len(user_map),
        "animals_count": len(animals),
    }

