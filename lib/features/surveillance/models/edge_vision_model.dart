import 'package:flutter/material.dart';

enum GateBarrierStatus {
  operational,
  screeningDivert,
  lockedDown,
}

enum BiosecurityTriage {
  autoPassGreen,
  secondaryAmber,
  impoundQuarantineRed,
}

enum CameraAngleType {
  lateralChute,
  dorsalChute,
  thermalFlir,
  gaitLocomotion,
}

class EdgeLesionDetection {
  final String id;
  final String lesionType;
  final double confidence; // 0.0 to 1.0
  final Rect boundingBox; // Normalized [0.0 - 1.0] [left, top, width, height]
  final String anatomicalRegion;
  final String severity; // Mild, Moderate, Critical

  const EdgeLesionDetection({
    required this.id,
    required this.lesionType,
    required this.confidence,
    required this.boundingBox,
    required this.anatomicalRegion,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesionType': lesionType,
    'confidence': confidence,
    'boundingBox': [boundingBox.left, boundingBox.top, boundingBox.width, boundingBox.height],
    'anatomicalRegion': anatomicalRegion,
    'severity': severity,
  };
}

class EdgeCameraFeed {
  final String id;
  final String checkpointId;
  final String cameraName;
  final CameraAngleType angleType;
  final String resolution;
  final int fps;
  final int inferenceLatencyMs;
  final String yoloModel;
  final String activeTargetPlate;
  final String activeTagId;
  final String species;
  final double thermalCoreTemp; // Celsius
  final bool isFebrile;
  final int lamenessScore; // 1 (sound) to 5 (severely lame)
  final double strideAsymmetryPct;
  final List<EdgeLesionDetection> detections;
  final double overallConfidence;
  final BiosecurityTriage biosecurityTriage;
  final String timestamp;

  const EdgeCameraFeed({
    required this.id,
    required this.checkpointId,
    required this.cameraName,
    required this.angleType,
    this.resolution = '3840x2160 (4K UHD)',
    this.fps = 30,
    this.inferenceLatencyMs = 18,
    this.yoloModel = 'YOLOv8x-Epizootic-Bovine (v4.2-TRT)',
    required this.activeTargetPlate,
    required this.activeTagId,
    required this.species,
    required this.thermalCoreTemp,
    required this.isFebrile,
    required this.lamenessScore,
    this.strideAsymmetryPct = 0.0,
    required this.detections,
    required this.overallConfidence,
    required this.biosecurityTriage,
    required this.timestamp,
  });

  String get angleName {
    switch (angleType) {
      case CameraAngleType.lateralChute:
        return 'Chute Cam A (Lateral)';
      case CameraAngleType.dorsalChute:
        return 'Chute Cam B (Dorsal)';
      case CameraAngleType.thermalFlir:
        return 'FLIR Thermal Core';
      case CameraAngleType.gaitLocomotion:
        return 'Optical Gait Analyzer';
    }
  }

  Color get triageColor {
    switch (biosecurityTriage) {
      case BiosecurityTriage.autoPassGreen:
        return const Color(0xFF10B981);
      case BiosecurityTriage.secondaryAmber:
        return const Color(0xFFF59E0B);
      case BiosecurityTriage.impoundQuarantineRed:
        return const Color(0xFFEF4444);
    }
  }

  String get triageLabel {
    switch (biosecurityTriage) {
      case BiosecurityTriage.autoPassGreen:
        return 'AUTO-PASS CLEAR';
      case BiosecurityTriage.secondaryAmber:
        return 'SECONDARY SCREENING';
      case BiosecurityTriage.impoundQuarantineRed:
        return 'IMPOUND & QUARANTINE';
    }
  }
}

class BiosecurityCheckpoint {
  final String id;
  final String name;
  final String highway;
  final double latitude;
  final double longitude;
  final String district;
  final String zoneType; // Interstate Border, State Expressway, APMC Mandi
  final int queueCount;
  final int todayInspected;
  final int todayIntercepted;
  GateBarrierStatus gateBarrierStatus;
  final bool disinfectionArchwayActive;
  final bool hasThermalChute;
  final List<EdgeCameraFeed> cameraFeeds;
  final List<String> recentAlerts;

  BiosecurityCheckpoint({
    required this.id,
    required this.name,
    required this.highway,
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.zoneType,
    required this.queueCount,
    required this.todayInspected,
    required this.todayIntercepted,
    this.gateBarrierStatus = GateBarrierStatus.operational,
    required this.disinfectionArchwayActive,
    required this.hasThermalChute,
    required this.cameraFeeds,
    required this.recentAlerts,
  });

  Color get statusColor {
    switch (gateBarrierStatus) {
      case GateBarrierStatus.operational:
        return const Color(0xFF10B981);
      case GateBarrierStatus.screeningDivert:
        return const Color(0xFFF59E0B);
      case GateBarrierStatus.lockedDown:
        return const Color(0xFFEF4444);
    }
  }

  String get statusText {
    switch (gateBarrierStatus) {
      case GateBarrierStatus.operational:
        return 'OPERATIONAL (AUTO-FLOW)';
      case GateBarrierStatus.screeningDivert:
        return 'DIVERTING TO SECONDARY BAY';
      case GateBarrierStatus.lockedDown:
        return 'GATE CLAMP ENGAGED (LOCKDOWN)';
    }
  }

  static List<BiosecurityCheckpoint> getPreseededCheckpoints() {
    return [
      BiosecurityCheckpoint(
        id: 'ckp-01',
        name: 'MH-KA Border Checkpoint (Solapur - Bijapur)',
        highway: 'NH-52 (Solapur Trunk)',
        latitude: 17.6599,
        longitude: 75.9064,
        district: 'Solapur',
        zoneType: 'Interstate Border Post',
        queueCount: 6,
        todayInspected: 142,
        todayIntercepted: 7,
        gateBarrierStatus: GateBarrierStatus.screeningDivert,
        disinfectionArchwayActive: true,
        hasThermalChute: true,
        recentAlerts: [
          'MH-13-LS-9920: Febrile temperature (40.8°C) detected at Chute Gate 2.',
          'MH-25-TR-1802: Cutaneous nodules (94.2% LSD probability) flagged.',
          'Interstate alert: Karnataka Belagavi livestock diversion order active.'
        ],
        cameraFeeds: [
          const EdgeCameraFeed(
            id: 'cam-01-lat',
            checkpointId: 'ckp-01',
            cameraName: 'Chute Cam A (Lateral HD)',
            angleType: CameraAngleType.lateralChute,
            activeTargetPlate: 'MH-13-LS-9920',
            activeTagId: 'INAPH-MH-9481-2291',
            species: 'Bovine (Khillari Bull)',
            thermalCoreTemp: 40.8,
            isFebrile: true,
            lamenessScore: 4,
            strideAsymmetryPct: 34.5,
            overallConfidence: 0.942,
            biosecurityTriage: BiosecurityTriage.impoundQuarantineRed,
            timestamp: 'LIVE 18:42:09 IST',
            detections: [
              EdgeLesionDetection(
                id: 'det-01',
                lesionType: 'Circumscribed Cutaneous Nodule',
                confidence: 0.962,
                boundingBox: Rect.fromLTWH(0.24, 0.32, 0.22, 0.25),
                anatomicalRegion: 'Dewlap & Left Shoulder',
                severity: 'Critical',
              ),
              EdgeLesionDetection(
                id: 'det-02',
                lesionType: 'Pustular Scab Lesion',
                confidence: 0.884,
                boundingBox: Rect.fromLTWH(0.58, 0.40, 0.18, 0.20),
                anatomicalRegion: 'Flank & Costal Arch',
                severity: 'Moderate',
              ),
              EdgeLesionDetection(
                id: 'det-03',
                lesionType: 'Excessive Salivation Drool',
                confidence: 0.915,
                boundingBox: Rect.fromLTWH(0.12, 0.48, 0.14, 0.18),
                anatomicalRegion: 'Oral Muzzle',
                severity: 'Critical',
              ),
            ],
          ),
          const EdgeCameraFeed(
            id: 'cam-01-flir',
            checkpointId: 'ckp-01',
            cameraName: 'FLIR Thermal Core Sensor',
            angleType: CameraAngleType.thermalFlir,
            activeTargetPlate: 'MH-13-LS-9920',
            activeTagId: 'INAPH-MH-9481-2291',
            species: 'Bovine (Khillari Bull)',
            thermalCoreTemp: 40.8,
            isFebrile: true,
            lamenessScore: 4,
            overallConfidence: 0.985,
            biosecurityTriage: BiosecurityTriage.impoundQuarantineRed,
            timestamp: 'LIVE 18:42:09 IST',
            detections: [
              EdgeLesionDetection(
                id: 'det-th-01',
                lesionType: 'Febrile Thermal Core Spike (40.8°C)',
                confidence: 0.985,
                boundingBox: Rect.fromLTWH(0.20, 0.28, 0.50, 0.45),
                anatomicalRegion: 'Torso & Ocular Sinus',
                severity: 'Critical',
              ),
            ],
          ),
          const EdgeCameraFeed(
            id: 'cam-01-dorsal',
            checkpointId: 'ckp-01',
            cameraName: 'Chute Cam B (Dorsal Overhead)',
            angleType: CameraAngleType.dorsalChute,
            activeTargetPlate: 'MH-13-LS-9920',
            activeTagId: 'INAPH-MH-9481-2291',
            species: 'Bovine (Khillari Bull)',
            thermalCoreTemp: 40.8,
            isFebrile: true,
            lamenessScore: 4,
            overallConfidence: 0.895,
            biosecurityTriage: BiosecurityTriage.impoundQuarantineRed,
            timestamp: 'LIVE 18:42:09 IST',
            detections: [
              EdgeLesionDetection(
                id: 'det-dorsal-01',
                lesionType: 'Dorsal Midline Nodular Cluster',
                confidence: 0.895,
                boundingBox: Rect.fromLTWH(0.35, 0.25, 0.30, 0.35),
                anatomicalRegion: 'Withers & Spine',
                severity: 'Moderate',
              ),
            ],
          ),
          const EdgeCameraFeed(
            id: 'cam-01-gait',
            checkpointId: 'ckp-01',
            cameraName: 'Optical Gait & Stride Sensor',
            angleType: CameraAngleType.gaitLocomotion,
            activeTargetPlate: 'MH-13-LS-9920',
            activeTagId: 'INAPH-MH-9481-2291',
            species: 'Bovine (Khillari Bull)',
            thermalCoreTemp: 40.8,
            isFebrile: true,
            lamenessScore: 4,
            strideAsymmetryPct: 42.1,
            overallConfidence: 0.930,
            biosecurityTriage: BiosecurityTriage.impoundQuarantineRed,
            timestamp: 'LIVE 18:42:09 IST',
            detections: [
              EdgeLesionDetection(
                id: 'det-gait-01',
                lesionType: 'Interdigital Cloven Lesion (Lameness: 4)',
                confidence: 0.930,
                boundingBox: Rect.fromLTWH(0.28, 0.65, 0.20, 0.25),
                anatomicalRegion: 'Right Forefoot Hoof',
                severity: 'Critical',
              ),
            ],
          ),
        ],
      ),

      BiosecurityCheckpoint(
        id: 'ckp-02',
        name: 'Pune-Solapur Expressway Barrier (Indapur Toll K-7)',
        highway: 'NH-65 (Pune-Solapur Highway)',
        latitude: 18.1156,
        longitude: 75.0253,
        district: 'Pune',
        zoneType: 'Expressway Biosecurity Bay',
        queueCount: 3,
        todayInspected: 198,
        todayIntercepted: 2,
        gateBarrierStatus: GateBarrierStatus.operational,
        disinfectionArchwayActive: true,
        hasThermalChute: true,
        recentAlerts: [
          'Automatic disinfection mist archway completed 198 cycles.',
          'Clearance issued to MH-12-TR-4011 (Sahyadri Transport) - Green E-Pass.',
        ],
        cameraFeeds: [
          const EdgeCameraFeed(
            id: 'cam-02-lat',
            checkpointId: 'ckp-02',
            cameraName: 'Indapur Chute Optical Scanner',
            angleType: CameraAngleType.lateralChute,
            activeTargetPlate: 'MH-12-TR-4011',
            activeTagId: 'INAPH-MH-1120-4089',
            species: 'Crossbred Jersey Cow',
            thermalCoreTemp: 38.6,
            isFebrile: false,
            lamenessScore: 1,
            strideAsymmetryPct: 2.1,
            overallConfidence: 0.978,
            biosecurityTriage: BiosecurityTriage.autoPassGreen,
            timestamp: 'LIVE 18:41:55 IST',
            detections: [],
          ),
        ],
      ),

      BiosecurityCheckpoint(
        id: 'ckp-03',
        name: 'MH-TS Border Checkpost (Nanded - Nizamabad)',
        highway: 'NH-161 (Telangana Corridor)',
        latitude: 19.1558,
        longitude: 77.3160,
        district: 'Nanded',
        zoneType: 'Interstate Border Post',
        queueCount: 4,
        todayInspected: 112,
        todayIntercepted: 4,
        gateBarrierStatus: GateBarrierStatus.screeningDivert,
        disinfectionArchwayActive: true,
        hasThermalChute: true,
        recentAlerts: [
          'Transit truck MH-26-AD-5510 flagged for secondary oral mucosa inspection.',
          'Telangana interstate advisory #TS-VET-09 logged.',
        ],
        cameraFeeds: [
          const EdgeCameraFeed(
            id: 'cam-03-lat',
            checkpointId: 'ckp-03',
            cameraName: 'Nanded Border Chute Sensor',
            angleType: CameraAngleType.lateralChute,
            activeTargetPlate: 'MH-26-AD-5510',
            activeTagId: 'INAPH-MH-3388-9012',
            species: 'Murrah Buffalo',
            thermalCoreTemp: 39.4,
            isFebrile: true,
            lamenessScore: 2,
            strideAsymmetryPct: 14.8,
            overallConfidence: 0.812,
            biosecurityTriage: BiosecurityTriage.secondaryAmber,
            timestamp: 'LIVE 18:40:12 IST',
            detections: [
              EdgeLesionDetection(
                id: 'det-03-a',
                lesionType: 'Superficial Papular Erythema',
                confidence: 0.812,
                boundingBox: Rect.fromLTWH(0.40, 0.35, 0.20, 0.22),
                anatomicalRegion: 'Abdominal Wall',
                severity: 'Moderate',
              ),
            ],
          ),
        ],
      ),

      BiosecurityCheckpoint(
        id: 'ckp-04',
        name: 'Nashik APMC Livestock Trading Gateway',
        highway: 'APMC Market Chute 1',
        latitude: 19.9975,
        longitude: 73.7898,
        district: 'Nashik',
        zoneType: 'APMC Mandi Auction Gate',
        queueCount: 8,
        todayInspected: 310,
        todayIntercepted: 1,
        gateBarrierStatus: GateBarrierStatus.operational,
        disinfectionArchwayActive: true,
        hasThermalChute: true,
        recentAlerts: [
          'Pre-auction mandatory scanning active. 310 animals cleared through gate.',
          'One suspected sheep pox case segregated to isolated pen C.',
        ],
        cameraFeeds: [
          const EdgeCameraFeed(
            id: 'cam-04-lat',
            checkpointId: 'ckp-04',
            cameraName: 'APMC Entry Chute Lateral',
            angleType: CameraAngleType.lateralChute,
            activeTargetPlate: 'MH-15-EM-7741',
            activeTagId: 'INAPH-MH-5544-1011',
            species: 'Deoni Cattle',
            thermalCoreTemp: 38.7,
            isFebrile: false,
            lamenessScore: 1,
            strideAsymmetryPct: 3.0,
            overallConfidence: 0.991,
            biosecurityTriage: BiosecurityTriage.autoPassGreen,
            timestamp: 'LIVE 18:38:50 IST',
            detections: [],
          ),
        ],
      ),

      BiosecurityCheckpoint(
        id: 'ckp-05',
        name: 'Kolhapur - Belagavi Border Post',
        highway: 'NH-48 (Golden Quadrilateral)',
        latitude: 16.7050,
        longitude: 74.2433,
        district: 'Kolhapur',
        zoneType: 'Interstate Border Post',
        queueCount: 2,
        todayInspected: 165,
        todayIntercepted: 0,
        gateBarrierStatus: GateBarrierStatus.operational,
        disinfectionArchwayActive: true,
        hasThermalChute: true,
        recentAlerts: [
          'Dairy transit green channel active. Zero interceptions in last 24h.',
        ],
        cameraFeeds: [
          const EdgeCameraFeed(
            id: 'cam-05-lat',
            checkpointId: 'ckp-05',
            cameraName: 'Kolhapur Expressway Chute',
            angleType: CameraAngleType.lateralChute,
            activeTargetPlate: 'MH-09-CK-3104',
            activeTagId: 'INAPH-MH-7721-6603',
            species: 'Holstein Friesian Cross',
            thermalCoreTemp: 38.5,
            isFebrile: false,
            lamenessScore: 1,
            strideAsymmetryPct: 1.5,
            overallConfidence: 0.984,
            biosecurityTriage: BiosecurityTriage.autoPassGreen,
            timestamp: 'LIVE 18:35:20 IST',
            detections: [],
          ),
        ],
      ),

      BiosecurityCheckpoint(
        id: 'ckp-06',
        name: 'Latur APMC Marathwada Terminal',
        highway: 'Mandi Gate West (SH-158)',
        latitude: 18.4088,
        longitude: 76.5604,
        district: 'Latur',
        zoneType: 'APMC Mandi Auction Gate',
        queueCount: 5,
        todayInspected: 245,
        todayIntercepted: 5,
        gateBarrierStatus: GateBarrierStatus.screeningDivert,
        disinfectionArchwayActive: true,
        hasThermalChute: true,
        recentAlerts: [
          'High vector index in Latur block. All incoming livestock subjected to thermal chute.',
          '5 animals diverted to isolation pen #2 for mucosal swab test.',
        ],
        cameraFeeds: [
          const EdgeCameraFeed(
            id: 'cam-06-lat',
            checkpointId: 'ckp-06',
            cameraName: 'Marathwada Chute Cam',
            angleType: CameraAngleType.lateralChute,
            activeTargetPlate: 'MH-24-AZ-8812',
            activeTagId: 'INAPH-MH-6611-3094',
            species: 'Osmanabadi Goat Herd',
            thermalCoreTemp: 40.2,
            isFebrile: true,
            lamenessScore: 3,
            strideAsymmetryPct: 22.4,
            overallConfidence: 0.887,
            biosecurityTriage: BiosecurityTriage.secondaryAmber,
            timestamp: 'LIVE 18:32:44 IST',
            detections: [
              EdgeLesionDetection(
                id: 'det-06-a',
                lesionType: 'Perioral Scab & Pustule',
                confidence: 0.887,
                boundingBox: Rect.fromLTWH(0.20, 0.42, 0.16, 0.18),
                anatomicalRegion: 'Oral Lips & Nostrils',
                severity: 'Moderate',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
