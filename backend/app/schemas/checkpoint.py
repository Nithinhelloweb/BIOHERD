from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class LesionDetectionSchema(BaseModel):
    id: str
    lesion_type: str
    confidence: float
    bounding_box: List[float] = Field(description="[ymin, xmin, ymax, xmax] normalized")
    anatomical_region: str
    severity: str  # Mild, Moderate, Critical


class EdgeCameraFeedSchema(BaseModel):
    id: str
    checkpoint_id: str
    camera_name: str
    angle_type: str  # lateral_chute, dorsal_chute, thermal_flir, gait_locomotion
    resolution: str = "3840x2160 (4K UHD)"
    fps: int = 30
    inference_latency_ms: int = 18
    yolo_model: str = "YOLOv8x-Epizootic-Bovine (v4.2-TRT)"
    active_target_plate: str
    active_tag_id: str
    species: str
    thermal_core_temp: float
    is_febrile: bool
    lameness_score: int
    stride_asymmetry_pct: float = 0.0
    detections: List[LesionDetectionSchema] = Field(default_factory=list)
    overall_confidence: float
    biosecurity_triage: str  # auto_pass_green, secondary_amber, impound_quarantine_red
    timestamp: str


class GateActuationRequest(BaseModel):
    action: str = Field(description="clamp_lockdown, secondary_divert, grant_clearance")
    reason: Optional[str] = None
    operator_notes: Optional[str] = None


class CheckpointResponse(BaseModel):
    id: str
    name: str
    highway: str
    latitude: float
    longitude: float
    district: str
    zone_type: str
    queue_count: int
    today_inspected: int
    today_intercepted: int
    gate_barrier_status: str  # operational, screening_divert, locked_down
    disinfection_archway_active: bool
    has_thermal_chute: bool
    recent_alerts: List[str] = Field(default_factory=list)
    camera_feeds: List[EdgeCameraFeedSchema] = Field(default_factory=list)
