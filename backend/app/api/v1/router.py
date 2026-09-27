from fastapi import APIRouter
from app.api.v1.endpoints import (
    advisories,
    animals,
    auth,
    cases,
    checkpoints,
    crisis,
    districts,
    health,
    ivr_sms,
    lab,
    mortality,
    movements,
    outbreak,
    seeder,
    symptoms,
    vaccination_drives,
)

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(health.router)
api_router.include_router(districts.router)
api_router.include_router(animals.router)
api_router.include_router(symptoms.router)
api_router.include_router(cases.router)
api_router.include_router(checkpoints.router)
api_router.include_router(crisis.router)
api_router.include_router(outbreak.router)
api_router.include_router(mortality.router)
api_router.include_router(lab.router)
api_router.include_router(vaccination_drives.router)
api_router.include_router(advisories.router)
api_router.include_router(movements.router)
api_router.include_router(ivr_sms.router)
api_router.include_router(seeder.router)



