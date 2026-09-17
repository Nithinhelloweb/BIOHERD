from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.seeder import seed_all
from app.db.session import get_db

router = APIRouter(prefix="/seeder", tags=["System Seeder"])

@router.post(
    "/run",
    summary="Seed Maharashtra database",
    description="Seeds all 36 Maharashtra districts, authentic users, sample farms, and indigenous livestock breeds.",
)
async def trigger_seeder(session: AsyncSession = Depends(get_db)):
    result = await seed_all(session)
    return {
        "success": True,
        "message": "BIOHERD Maharashtra seed data loaded successfully",
        "details": result,
    }
