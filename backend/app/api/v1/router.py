from fastapi import APIRouter
from app.api.v1.endpoints import animals, auth, cases, districts, health, outbreak, seeder, symptoms


api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(health.router)
api_router.include_router(districts.router)
api_router.include_router(animals.router)
api_router.include_router(symptoms.router)
api_router.include_router(cases.router)
api_router.include_router(outbreak.router)
api_router.include_router(seeder.router)


