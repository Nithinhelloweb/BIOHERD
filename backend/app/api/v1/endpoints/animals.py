from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.breeds_catalog import get_indigenous_breeds
from app.core.qr_engine import generate_animal_qr_base64, generate_animal_verification_hash
from app.db.models import Animal, AnimalSpecies, District, Farm, HealthEvent, HealthEventType, User, Vaccination
from app.db.session import get_db
from app.schemas.animal import (
    AnimalCreate,
    AnimalPassportResponse,
    AnimalQRCodeResponse,
    AnimalResponse,
    AnimalUpdate,
    BreedInfo,
    HealthEventCreate,
    HealthEventResponse,
)

router = APIRouter(prefix="/animals", tags=["Animal Registry"])

# 1. Indigenous Breed Catalog (placed before /{animal_id} to avoid path collision)
@router.get(
    "/breeds",
    response_model=List[BreedInfo],
    summary="Get indigenous livestock breeds of Maharashtra",
)
async def list_indigenous_breeds(
    species: Optional[AnimalSpecies] = Query(None, description="Filter breeds by animal species"),
):
    """Returns curated indigenous breeds originating or prominent in Maharashtra."""
    return get_indigenous_breeds(species=species)

# 2. List Animals
@router.get(
    "",
    response_model=List[AnimalResponse],
    summary="List registered livestock",
)
async def list_animals(
    species: Optional[AnimalSpecies] = Query(None, description="Filter by species"),
    farm_id: Optional[str] = Query(None, description="Filter by farm ID"),
    is_active: Optional[bool] = Query(True, description="Filter by active status"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(Animal)
    if is_active is not None:
        stmt = stmt.where(Animal.is_active == is_active)
    if species:
        stmt = stmt.where(Animal.species == species)
    if farm_id:
        stmt = stmt.where(Animal.farm_id == farm_id)
    stmt = stmt.order_by(Animal.created_at.desc()).limit(limit).offset(offset)
    res = await session.execute(stmt)
    return res.scalars().all()

# 3. Register Animal
@router.post(
    "",
    response_model=AnimalResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new animal",
)
async def create_animal(
    animal_in: AnimalCreate,
    session: AsyncSession = Depends(get_db),
):
    # Verify farm exists
    farm_stmt = select(Farm).where(Farm.id == animal_in.farm_id)
    farm_res = await session.execute(farm_stmt)
    if not farm_res.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Farm with ID {animal_in.farm_id} does not exist",
        )

    # Check for duplicate tag_id
    tag_stmt = select(Animal).where(Animal.tag_id == animal_in.tag_id)
    tag_res = await session.execute(tag_stmt)
    if tag_res.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Animal with ear tag ID '{animal_in.tag_id}' is already registered",
        )

    animal = Animal(**animal_in.model_dump())
    session.add(animal)
    await session.commit()
    await session.refresh(animal)

    # Automatically set qr_code_url verification link if not provided
    if not animal.qr_code_url:
        v_hash = generate_animal_verification_hash(animal.id, animal.tag_id, animal.created_at.isoformat())
        animal.qr_code_url = f"https://bioherd.gov.in/verify?tag={animal.tag_id}&id={animal.id}&v={v_hash}"
        await session.commit()
        await session.refresh(animal)

    return animal

# 4. Lookup by Tag ID (Ear tag / RFID)
@router.get(
    "/tag/{tag_id}",
    response_model=AnimalResponse,
    summary="Lookup animal by Ear Tag / RFID ID",
)
async def get_animal_by_tag(tag_id: str, session: AsyncSession = Depends(get_db)):
    stmt = select(Animal).where(Animal.tag_id == tag_id)
    res = await session.execute(stmt)
    animal = res.scalar_one_or_none()
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ear tag '{tag_id}' not found",
        )
    return animal

# 5. Get Animal by ID
@router.get(
    "/{animal_id}",
    response_model=AnimalResponse,
    summary="Get animal by ID",
)
async def get_animal(animal_id: str, session: AsyncSession = Depends(get_db)):
    stmt = select(Animal).where(Animal.id == animal_id)
    res = await session.execute(stmt)
    animal = res.scalar_one_or_none()
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ID {animal_id} not found",
        )
    return animal

# 6. Update Animal
@router.put(
    "/{animal_id}",
    response_model=AnimalResponse,
    summary="Update animal details",
)
async def update_animal(
    animal_id: str,
    animal_in: AnimalUpdate,
    session: AsyncSession = Depends(get_db),
):
    stmt = select(Animal).where(Animal.id == animal_id)
    res = await session.execute(stmt)
    animal = res.scalar_one_or_none()
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ID {animal_id} not found",
        )

    update_data = animal_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(animal, field, val)

    await session.commit()
    await session.refresh(animal)
    return animal

# 7. Soft Delete Animal
@router.delete(
    "/{animal_id}",
    status_code=status.HTTP_200_OK,
    summary="Soft-delete an animal from active registry",
)
async def delete_animal(animal_id: str, session: AsyncSession = Depends(get_db)):
    stmt = select(Animal).where(Animal.id == animal_id)
    res = await session.execute(stmt)
    animal = res.scalar_one_or_none()
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ID {animal_id} not found",
        )

    animal.is_active = False
    await session.commit()
    return {"message": f"Animal with ear tag '{animal.tag_id}' has been marked inactive", "id": animal.id}

# 8. Generate Verifiable QR Code
@router.get(
    "/{animal_id}/qr",
    response_model=AnimalQRCodeResponse,
    summary="Generate verifiable QR Code for animal ear tag",
)
async def get_animal_qr(animal_id: str, session: AsyncSession = Depends(get_db)):
    stmt = select(Animal).where(Animal.id == animal_id)
    res = await session.execute(stmt)
    animal = res.scalar_one_or_none()
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ID {animal_id} not found",
        )

    v_hash = generate_animal_verification_hash(
        animal.id,
        animal.tag_id,
        animal.created_at.isoformat() if animal.created_at else "2026-01-01",
    )
    qr_data = generate_animal_qr_base64(
        animal_id=animal.id,
        tag_id=animal.tag_id,
        species=animal.species.value,
        breed=animal.breed,
        verification_hash=v_hash,
    )
    verification_url = f"https://bioherd.gov.in/verify?tag={animal.tag_id}&id={animal.id}&v={v_hash}"

    return AnimalQRCodeResponse(
        animal_id=animal.id,
        tag_id=animal.tag_id,
        verification_url=verification_url,
        qr_base64=qr_data,
        generated_at=datetime.now(timezone.utc),
    )

# 9. Animal Health Passport
@router.get(
    "/{animal_id}/passport",
    response_model=AnimalPassportResponse,
    summary="Get animal health passport for printing and inspection",
)
async def get_animal_passport(animal_id: str, session: AsyncSession = Depends(get_db)):
    # Join Animal with Farm, District, Owner
    stmt = (
        select(Animal, Farm, District, User)
        .join(Farm, Animal.farm_id == Farm.id)
        .join(District, Farm.district_id == District.id)
        .join(User, Farm.owner_user_id == User.id)
        .where(Animal.id == animal_id)
    )
    res = await session.execute(stmt)
    row = res.first()
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Animal with ID {animal_id} not found",
        )

    animal, farm, district, owner = row

    # Count health events and vaccinations
    he_count_stmt = select(func.count()).select_from(HealthEvent).where(HealthEvent.animal_id == animal.id)
    he_count = (await session.execute(he_count_stmt)).scalar() or 0

    vac_count_stmt = select(func.count()).select_from(Vaccination).where(Vaccination.animal_id == animal.id)
    vac_count = (await session.execute(vac_count_stmt)).scalar() or 0

    # Recent health events
    events_stmt = (
        select(HealthEvent)
        .where(HealthEvent.animal_id == animal.id)
        .order_by(HealthEvent.occurred_at.desc())
        .limit(5)
    )
    recent_events_res = await session.execute(events_stmt)
    recent_events = recent_events_res.scalars().all()

    # Calculate age in months if dob exists
    age_months = None
    if animal.dob:
        diff_days = (datetime.now(timezone.utc) - animal.dob).days
        age_months = max(0, diff_days // 30)

    v_hash = generate_animal_verification_hash(
        animal.id,
        animal.tag_id,
        animal.created_at.isoformat() if animal.created_at else "2026-01-01",
    )

    return AnimalPassportResponse(
        animal_id=animal.id,
        tag_id=animal.tag_id,
        species=animal.species.value,
        breed=animal.breed,
        sex=animal.sex,
        weight_kg=animal.weight_kg,
        dob=animal.dob,
        age_months=age_months,
        farm_id=farm.id,
        farm_name=farm.name,
        district_name=f"{district.name} ({district.name_mr})" if district.name_mr else district.name,
        owner_name=owner.full_name,
        owner_phone=owner.phone,
        qr_code_url=animal.qr_code_url,
        is_active=animal.is_active,
        registered_at=animal.created_at,
        health_events_count=he_count,
        vaccinations_count=vac_count,
        recent_events=[HealthEventResponse.model_validate(e) for e in recent_events],
        verification_hash=v_hash,
    )

# 10. List Health Timeline Events
@router.get(
    "/{animal_id}/events",
    response_model=List[HealthEventResponse],
    summary="Get chronological health timeline for animal",
)
async def list_animal_events(
    animal_id: str,
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_db),
):
    # Verify animal exists
    check_stmt = select(Animal.id).where(Animal.id == animal_id)
    if not (await session.execute(check_stmt)).scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Animal with ID {animal_id} not found")

    stmt = (
        select(HealthEvent)
        .where(HealthEvent.animal_id == animal_id)
        .order_by(HealthEvent.occurred_at.desc())
        .limit(limit)
    )
    res = await session.execute(stmt)
    return res.scalars().all()

# 11. Add Health Event (Vaccination, Checkup, Quarantine, etc.)
@router.post(
    "/{animal_id}/events",
    response_model=HealthEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record a new health event on animal timeline",
)
async def create_health_event(
    animal_id: str,
    event_in: HealthEventCreate,
    session: AsyncSession = Depends(get_db),
):
    stmt = (
        select(Animal, Farm)
        .join(Farm, Animal.farm_id == Farm.id)
        .where(Animal.id == animal_id)
    )
    res = await session.execute(stmt)
    row = res.first()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Animal with ID {animal_id} not found")

    animal, farm = row
    recorded_by = event_in.recorded_by or farm.owner_user_id
    occurred_at = event_in.occurred_at or datetime.now(timezone.utc)

    event = HealthEvent(
        animal_id=animal.id,
        event_type=event_in.event_type,
        description=event_in.description,
        recorded_by=recorded_by,
        occurred_at=occurred_at,
    )
    session.add(event)
    await session.commit()
    await session.refresh(event)
    return event
