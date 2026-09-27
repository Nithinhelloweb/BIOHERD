from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from app.core.logging import get_logger
from app.schemas.checkpoint import (
    CheckpointResponse,
    EdgeCameraFeedSchema,
    GateActuationRequest,
    LesionDetectionSchema,
)

logger = get_logger("checkpoints_endpoint")
router = APIRouter(prefix="/checkpoints", tags=["Edge Vision & Biosecurity Checkpoints"])

# Preseeded operational biosecurity checkpoints
CHECKPOINTS_DATABASE: Dict[str, Dict[str, Any]] = {
    "ckp-01": {
        "id": "ckp-01",
        "name": "MH-KA Border Checkpoint (Solapur - Bijapur)",
        "highway": "NH-52 (Solapur Trunk)",
        "latitude": 17.6599,
        "longitude": 75.9064,
        "district": "Solapur",
        "zone_type": "Interstate Border Post",
        "queue_count": 6,
        "today_inspected": 142,
        "today_intercepted": 7,
        "gate_barrier_status": "screening_divert",
        "disinfection_archway_active": True,
        "has_thermal_chute": True,
        "recent_alerts": [
            "MH-13-LS-9920: Febrile temperature (40.8°C) detected at Chute Gate 2.",
            "MH-25-TR-1802: Cutaneous nodules (94.2% LSD probability) flagged.",
            "Interstate alert: Karnataka Belagavi livestock diversion order active."
        ],
        "camera_feeds": [
            {
                "id": "cam-01-lat",
                "checkpoint_id": "ckp-01",
                "camera_name": "Chute Cam A (Lateral HD)",
                "angle_type": "lateral_chute",
                "resolution": "3840x2160 (4K UHD)",
                "fps": 30,
                "inference_latency_ms": 18,
                "yolo_model": "YOLOv8x-Epizootic-Bovine (v4.2-TRT)",
                "active_target_plate": "MH-13-LS-9920",
                "active_tag_id": "INAPH-MH-9481-2291",
                "species": "Bovine (Khillari Bull)",
                "thermal_core_temp": 40.8,
                "is_febrile": True,
                "lameness_score": 4,
                "stride_asymmetry_pct": 34.5,
                "overall_confidence": 0.942,
                "biosecurity_triage": "impound_quarantine_red",
                "timestamp": "LIVE 18:42:09 IST",
                "detections": [
                    {
                        "id": "det-01",
                        "lesion_type": "Circumscribed Cutaneous Nodule",
                        "confidence": 0.962,
                        "bounding_box": [0.24, 0.32, 0.22, 0.25],
                        "anatomical_region": "Dewlap & Left Shoulder",
                        "severity": "Critical"
                    },
                    {
                        "id": "det-02",
                        "lesion_type": "Pustular Scab Lesion",
                        "confidence": 0.884,
                        "bounding_box": [0.58, 0.40, 0.18, 0.20],
                        "anatomical_region": "Flank & Costal Arch",
                        "severity": "Moderate"
                    },
                    {
                        "id": "det-03",
                        "lesion_type": "Excessive Salivation Drool",
                        "confidence": 0.915,
                        "bounding_box": [0.12, 0.48, 0.14, 0.18],
                        "anatomical_region": "Oral Muzzle",
                        "severity": "Critical"
                    }
                ]
            },
            {
                "id": "cam-01-flir",
                "checkpoint_id": "ckp-01",
                "camera_name": "FLIR Thermal Core Sensor",
                "angle_type": "thermal_flir",
                "resolution": "1920x1080 (Thermal IR)",
                "fps": 60,
                "inference_latency_ms": 12,
                "yolo_model": "FLIR-Bovine-Thermal-Net",
                "active_target_plate": "MH-13-LS-9920",
                "active_tag_id": "INAPH-MH-9481-2291",
                "species": "Bovine (Khillari Bull)",
                "thermal_core_temp": 40.8,
                "is_febrile": True,
                "lameness_score": 4,
                "stride_asymmetry_pct": 0.0,
                "overall_confidence": 0.985,
                "biosecurity_triage": "impound_quarantine_red",
                "timestamp": "LIVE 18:42:09 IST",
                "detections": [
                    {
                        "id": "det-th-01",
                        "lesion_type": "Febrile Thermal Core Spike (40.8°C)",
                        "confidence": 0.985,
                        "bounding_box": [0.20, 0.28, 0.50, 0.45],
                        "anatomical_region": "Torso & Ocular Sinus",
                        "severity": "Critical"
                    }
                ]
            }
        ]
    },
    "ckp-02": {
        "id": "ckp-02",
        "name": "Pune-Solapur Expressway Barrier (Indapur Toll K-7)",
        "highway": "NH-65 (Pune-Solapur Highway)",
        "latitude": 18.1156,
        "longitude": 75.0253,
        "district": "Pune",
        "zone_type": "Expressway Biosecurity Bay",
        "queue_count": 3,
        "today_inspected": 198,
        "today_intercepted": 2,
        "gate_barrier_status": "operational",
        "disinfection_archway_active": True,
        "has_thermal_chute": True,
        "recent_alerts": [
            "Automatic disinfection mist archway completed 198 cycles.",
            "Clearance issued to MH-12-TR-4011 (Sahyadri Transport) - Green E-Pass."
        ],
        "camera_feeds": [
            {
                "id": "cam-02-lat",
                "checkpoint_id": "ckp-02",
                "camera_name": "Indapur Chute Optical Scanner",
                "angle_type": "lateral_chute",
                "resolution": "3840x2160 (4K UHD)",
                "fps": 30,
                "inference_latency_ms": 16,
                "yolo_model": "YOLOv8x-Epizootic-Bovine (v4.2-TRT)",
                "active_target_plate": "MH-12-TR-4011",
                "active_tag_id": "INAPH-MH-1120-4089",
                "species": "Crossbred Jersey Cow",
                "thermal_core_temp": 38.6,
                "is_febrile": False,
                "lameness_score": 1,
                "stride_asymmetry_pct": 2.1,
                "overall_confidence": 0.978,
                "biosecurity_triage": "auto_pass_green",
                "timestamp": "LIVE 18:41:55 IST",
                "detections": []
            }
        ]
    },
    "ckp-03": {
        "id": "ckp-03",
        "name": "MH-TS Border Checkpost (Nanded - Nizamabad)",
        "highway": "NH-161 (Telangana Corridor)",
        "latitude": 19.1558,
        "longitude": 77.3160,
        "district": "Nanded",
        "zone_type": "Interstate Border Post",
        "queue_count": 4,
        "today_inspected": 112,
        "today_intercepted": 4,
        "gate_barrier_status": "screening_divert",
        "disinfection_archway_active": True,
        "has_thermal_chute": True,
        "recent_alerts": [
            "Transit truck MH-26-AD-5510 flagged for secondary oral mucosa inspection.",
            "Telangana interstate advisory #TS-VET-09 logged."
        ],
        "camera_feeds": [
            {
                "id": "cam-03-lat",
                "checkpoint_id": "ckp-03",
                "camera_name": "Nanded Border Chute Sensor",
                "angle_type": "lateral_chute",
                "resolution": "3840x2160 (4K UHD)",
                "fps": 30,
                "inference_latency_ms": 19,
                "yolo_model": "YOLOv8x-Epizootic-Bovine (v4.2-TRT)",
                "active_target_plate": "MH-26-AD-5510",
                "active_tag_id": "INAPH-MH-3388-9012",
                "species": "Murrah Buffalo",
                "thermal_core_temp": 39.4,
                "is_febrile": True,
                "lameness_score": 2,
                "stride_asymmetry_pct": 14.8,
                "overall_confidence": 0.812,
                "biosecurity_triage": "secondary_amber",
                "timestamp": "LIVE 18:40:12 IST",
                "detections": [
                    {
                        "id": "det-03-a",
                        "lesion_type": "Superficial Papular Erythema",
                        "confidence": 0.812,
                        "bounding_box": [0.40, 0.35, 0.20, 0.22],
                        "anatomical_region": "Abdominal Wall",
                        "severity": "Moderate"
                    }
                ]
            }
        ]
    }
}


@router.get(
    "",
    response_model=List[CheckpointResponse],
    summary="List all operational biosecurity border checkpoints & APMC gates",
)
async def list_checkpoints(
    district: Optional[str] = Query(None, description="Filter by district name"),
    zone_type: Optional[str] = Query(None, description="Filter by zone type"),
):
    results = list(CHECKPOINTS_DATABASE.values())
    if district:
        results = [c for c in results if c["district"].lower() == district.lower()]
    if zone_type:
        results = [c for c in results if c["zone_type"].lower() == zone_type.lower()]
    return results


@router.get(
    "/{checkpoint_id}",
    response_model=CheckpointResponse,
    summary="Get single checkpoint telemetry and gate status",
)
async def get_checkpoint(checkpoint_id: str):
    if checkpoint_id not in CHECKPOINTS_DATABASE:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Checkpoint {checkpoint_id} not found",
        )
    return CHECKPOINTS_DATABASE[checkpoint_id]


@router.get(
    "/{checkpoint_id}/feeds",
    response_model=List[EdgeCameraFeedSchema],
    summary="Get live YOLOv8 Edge Vision feeds with detections for a checkpoint",
)
async def get_checkpoint_feeds(checkpoint_id: str):
    if checkpoint_id not in CHECKPOINTS_DATABASE:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Checkpoint {checkpoint_id} not found",
        )
    return CHECKPOINTS_DATABASE[checkpoint_id]["camera_feeds"]


@router.post(
    "/{checkpoint_id}/actuate",
    response_model=CheckpointResponse,
    summary="Actuate physical checkpoint gate barrier (clamp lockdown, secondary divert, or clearance)",
)
async def actuate_checkpoint_gate(checkpoint_id: str, req: GateActuationRequest):
    if checkpoint_id not in CHECKPOINTS_DATABASE:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Checkpoint {checkpoint_id} not found",
        )

    ckp = CHECKPOINTS_DATABASE[checkpoint_id]

    if req.action == "clamp_lockdown":
        ckp["gate_barrier_status"] = "locked_down"
        ckp["today_intercepted"] += 1
        msg = f"EMERGENCY: Hydraulic gate clamp engaged. Intercept logged. Reason: {req.reason or 'AI Lesion Detection'}"
    elif req.action == "secondary_divert":
        ckp["gate_barrier_status"] = "screening_divert"
        msg = f"Vehicle diverted to secondary inspection bay. Notes: {req.operator_notes or 'Swab verification'}"
    elif req.action == "grant_clearance":
        ckp["gate_barrier_status"] = "operational"
        if ckp["queue_count"] > 0:
            ckp["queue_count"] -= 1
        ckp["today_inspected"] += 1
        msg = "Biosecurity digital transit clearance QR seal issued. Gate opened."
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid gate action: {req.action}. Expected clamp_lockdown, secondary_divert, or grant_clearance",
        )

    ckp["recent_alerts"].insert(0, msg)
    logger.info("gate_actuated", checkpoint_id=checkpoint_id, action=req.action)
    return ckp
