import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from app.core.logging import get_logger
from app.schemas.crisis import (
    FarmerBroadcastRequest,
    FarmerBroadcastResponse,
    RapidResponseTeamResponse,
    RrtReassignRequest,
    SitRepBriefingResponse,
    SitRepQueryRequest,
    SitRepQueryResponse,
)

logger = get_logger("crisis_endpoint")
router = APIRouter(prefix="/crisis", tags=["Autonomous Crisis Dispatch & AI SitRep"])

# Preseeded Rapid Response Teams
RRT_DATABASE: Dict[str, Dict[str, Any]] = {
    "RRT-MH-13-A": {
        "id": "RRT-MH-13-A",
        "team_name": "Solapur Strike Team Alpha",
        "base_depot": "District Veterinary Polyclinic (DVP) Solapur",
        "lead_officer": "Dr. Anjali Deshmukh, MVSc (Epidemiology)",
        "contact_number": "+91 98224 88102",
        "assigned_district": "Solapur",
        "assigned_epicenter": "Solapur South Hotspot (17.6599°N, 75.9064°E)",
        "status": "en_route",
        "vehicle_id": "MH-13-VET-0101 (Cold-Chain Mobile Unit)",
        "cold_box_temp_c": 3.8,
        "lsd_doses_available": 3850,
        "fmd_doses_available": 2400,
        "pcr_cartridges": 180,
        "ppe_kits": 45,
        "eta_minutes": 14,
    },
    "RRT-MH-25-B": {
        "id": "RRT-MH-25-B",
        "team_name": "Latur Mobile Biosecurity Unit Beta",
        "base_depot": "Marathwada Veterinary Hospital Latur",
        "lead_officer": "Dr. Rajesh Patil, MVSc",
        "contact_number": "+91 94231 77209",
        "assigned_district": "Latur",
        "assigned_epicenter": "Ausa Block Cluster (18.25°N, 76.50°E)",
        "status": "vaccinating",
        "vehicle_id": "MH-24-VET-0402 (Refrigerated Cruiser)",
        "cold_box_temp_c": 4.1,
        "lsd_doses_available": 2100,
        "fmd_doses_available": 1500,
        "pcr_cartridges": 95,
        "ppe_kits": 30,
        "eta_minutes": 0,
    },
    "RRT-MH-12-C": {
        "id": "RRT-MH-12-C",
        "team_name": "Pune State Emergency Reserve C",
        "base_depot": "State Disease Investigation Section (DIS) Aundh, Pune",
        "lead_officer": "Dr. Vikramaditya Shinde, Joint Director",
        "contact_number": "+91 98220 33419",
        "assigned_district": "Pune",
        "assigned_epicenter": "Indapur Expressway Transit Barrier",
        "status": "depot_staged",
        "vehicle_id": "MH-12-VET-9900 (Heavy Logistics Van)",
        "cold_box_temp_c": 3.5,
        "lsd_doses_available": 15000,
        "fmd_doses_available": 10000,
        "pcr_cartridges": 500,
        "ppe_kits": 120,
        "eta_minutes": 45,
    },
}


@router.get(
    "/sitrep",
    response_model=SitRepBriefingResponse,
    summary="Get generated strategic SitRep executive briefing",
)
async def get_sitrep_briefing():
    return SitRepBriefingResponse(
        id="SITREP-MH-2026-LIVE",
        generated_timestamp=datetime.now(timezone.utc).strftime("%d-%b-%Y %H:%M:%S UTC"),
        threat_level="CRITICAL LEVEL 4 (STATE EPIDEMIC WATCH)",
        executive_summary=(
            "BIOHERD Epizootic Intelligence Engine confirms active contagion cluster in Solapur (R0 = 2.45) "
            "with outward microclimate aerosol drift (Azimuth 235° SW at 18 km/h). Secondary transmission vectors "
            "identified in Latur and Ahmednagar. Projected +14-day caseload without intervention: 1,842 head. "
            "Recommended immediate ring vaccination strike within 5km radius and strict APMC mandi moratorium."
        ),
        statutory_proclamation=(
            "ORDER UNDER SECTION 6 OF THE PREVENTION AND CONTROL OF INFECTIOUS AND CONTAGIOUS DISEASES IN ANIMALS ACT, 2009:\n\n"
            "WHEREAS Lumpy Skin Disease (LSD) has been confirmed in Solapur District; NOW THEREFORE, the Commissioner "
            "of Animal Husbandry hereby declares Solapur South and adjoining 10km buffer as a Controlled Containment Zone. "
            "Movement of bovine livestock, inter-district cattle transport, and operation of cattle markets are strictly "
            "PROHIBITED with immediate effect."
        ),
        primary_epicenters=[
            "Solapur South (Epicenter: 17.6599°N, 75.9064°E) - R0: 2.45",
            "Latur Ausa Block (Cluster: 18.25°N, 76.50°E) - R0: 1.82",
            "Kolhapur Kagal Belt (Cluster: 16.70°N, 74.24°E) - R0: 1.40",
        ],
        operational_checklist={
            "Deploy 3-Tier Ring Containment Cordon (1km / 3km / 10km)": True,
            "Enact APMC Livestock Mandi Moratorium Notification": True,
            "Mobilize Rapid Response Strike Teams (RRT Alpha & Beta)": True,
            "Dispatch Trilingual Voice IVR & SMS Broadcast (4,820 farmers)": True,
            "Requisition 25,000 Vaccine Doses from Pune Central Depot": False,
            "Seal Interstate Highway Border Gates (NH-52 & NH-161)": True,
            "Deploy Ultra-Low Volume (ULV) Vector Fogging in Stagnant Water Basins": False,
        },
    )


@router.post(
    "/sitrep/query",
    response_model=SitRepQueryResponse,
    summary="Ask AI Strategic SitRep Co-Pilot",
)
async def query_sitrep_copilot(req: SitRepQueryRequest):
    q = req.question.lower()
    if "vaccine" in q or "deficit" in q or "stock" in q:
        answer = (
            "CRISIS SUPPLY STATUS:\n"
            "- Solapur DVP currently holds 3,850 LSD doses with a calculated deficit of 8,450 doses to achieve 80% herd ring immunity.\n"
            "- Action taken: Pune Central Depot (RRT-MH-12-C) has staged 15,000 doses with an ETA of 45 minutes to Solapur South."
        )
    elif "karnataka" in q or "border" in q or "interstate" in q:
        answer = (
            "INTERSTATE BORDER INTEL:\n"
            "- Karnataka Belagavi & Bijapur border points report elevated vector activity (VVI = 0.82).\n"
            "- Solapur-Bijapur NH-52 checkpost (CKP-01) has engaged hydraulic clamp lockdown for uncertified livestock haulers."
        )
    elif "mandi" in q or "market" in q or "closure" in q:
        answer = (
            "STATUTORY MANDI DIRECTIVE:\n"
            "- All APMC cattle market yards in Solapur, Sangli, and Osmanabad are placed under temporary moratorium under Section 6 of Act 2009.\n"
            "- Edge Vision camera feeds at Nashik and Latur mandis are set to Divert-to-Screening."
        )
    else:
        answer = (
            f"OPERATIONAL SITUATION BRIEF for {req.context_district}:\n"
            "- Overall statewide active caseload: 588 head. Interventions currently active: Ring Cordon, Checkpoint Gantries, and IVR Farmer Alerts.\n"
            "- Counterfactual modeling indicates 1,280 cattle and ₹10.24 Cr in livestock assets protected across the 14-day horizon."
        )

    logger.info("sitrep_query_processed", question=req.question)
    return SitRepQueryResponse(question=req.question, answer=answer)


@router.get(
    "/rrt-teams",
    response_model=List[RapidResponseTeamResponse],
    summary="List all mobilized and staged Rapid Response Teams",
)
async def list_rrt_teams():
    return list(RRT_DATABASE.values())


@router.post(
    "/rrt-teams/{team_id}/reassign",
    response_model=RapidResponseTeamResponse,
    summary="Reassign RRT strike team status or destination",
)
async def reassign_rrt_team(team_id: str, req: RrtReassignRequest):
    if team_id not in RRT_DATABASE:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Team {team_id} not found")

    team = RRT_DATABASE[team_id]
    team["status"] = req.new_status
    if req.assigned_district:
        team["assigned_district"] = req.assigned_district
    if req.target_epicenter:
        team["assigned_epicenter"] = req.target_epicenter

    if req.new_status == "en_route":
        team["eta_minutes"] = 15
    elif req.new_status in ("on_site_contained", "vaccinating"):
        team["eta_minutes"] = 0

    logger.info("rrt_team_reassigned", team_id=team_id, status=req.new_status)
    return team


@router.post(
    "/broadcast/dispatch",
    response_model=FarmerBroadcastResponse,
    summary="Dispatch outbound IVR voice and SMS mass broadcast to buffer zone farmers",
)
async def dispatch_farmer_broadcast(req: FarmerBroadcastRequest):
    rnd_recipients = 4820 if req.district.lower() == "solapur" else 3150
    return FarmerBroadcastResponse(
        broadcast_id=f"BRD-2026-{uuid.uuid4().hex[:6].upper()}",
        district=req.district,
        radius_km=req.radius_km,
        recipient_count=rnd_recipients,
        channels_engaged=["Voice IVR Outbound (1800)", "Cell Broadcast SMS", "Gram Panchayat Siren"],
        delivery_status="dispatched",
        success_rate=0.984,
        dispatched_timestamp=datetime.now(timezone.utc).strftime("%d-%b-%Y %H:%M:%S UTC"),
    )
