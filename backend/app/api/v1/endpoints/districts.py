from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import District, Farm, OutbreakEvent
from app.db.session import get_db
from app.schemas.district import DistrictLivestockSummary, DistrictResponse

router = APIRouter(prefix="/districts", tags=["Districts & Demographics"])

@router.get(
    "",
    response_model=List[DistrictResponse],
    summary="List all Maharashtra districts",
    description="Returns all 36 Maharashtra districts with names in English and Marathi, coordinates, and livestock counts.",
)
async def list_districts(
    search: Optional[str] = Query(None, description="Filter by English or Marathi district name"),
    session: AsyncSession = Depends(get_db),
):
    stmt = select(District).order_by(District.name)
    if search:
        search_term = f"%{search.strip()}%"
        stmt = stmt.where(
            (District.name.ilike(search_term)) | (District.name_mr.ilike(search_term))
        )
    result = await session.execute(stmt)
    districts = result.scalars().all()
    return districts

@router.get(
    "/{district_id}",
    response_model=DistrictResponse,
    summary="Get district by ID",
)
async def get_district(district_id: str, session: AsyncSession = Depends(get_db)):
    stmt = select(District).where(District.id == district_id)
    res = await session.execute(stmt)
    district = res.scalar_one_or_none()
    if not district:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"District with ID {district_id} not found",
        )
    return district

@router.get(
    "/{district_id}/summary",
    response_model=DistrictLivestockSummary,
    summary="Get district livestock and outbreak summary",
)
async def get_district_summary(district_id: str, session: AsyncSession = Depends(get_db)):
    # 1. District info
    dist_stmt = select(District).where(District.id == district_id)
    dist_res = await session.execute(dist_stmt)
    district = dist_res.scalar_one_or_none()
    if not district:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"District with ID {district_id} not found",
        )

    # 2. Count active farms
    farm_stmt = select(func.count(Farm.id)).where(Farm.district_id == district_id)
    farm_res = await session.execute(farm_stmt)
    farms_count = farm_res.scalar() or 0

    # 3. Count active outbreaks
    outbreak_stmt = select(func.count(OutbreakEvent.id)).where(
        OutbreakEvent.district_id == district_id,
        OutbreakEvent.resolved_at.is_(None),
    )
    outbreak_res = await session.execute(outbreak_stmt)
    outbreaks_count = outbreak_res.scalar() or 0

    return DistrictLivestockSummary(
        district_id=district.id,
        district_name=district.name,
        district_name_mr=district.name_mr,
        total_livestock=district.livestock_population,
        active_farms_count=farms_count,
        registered_animals_count=0,
        active_outbreaks_count=outbreaks_count,
    )
