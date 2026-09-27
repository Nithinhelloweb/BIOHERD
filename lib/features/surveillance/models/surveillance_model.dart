import 'dart:ui';
import '../../../core/widgets/severity_badge.dart';

class DistrictRiskModel {
  final String districtId;
  final String districtName;
  final String districtNameMr;
  final double latitude;
  final double longitude;
  final int livestockPopulation;
  final int activeCases;
  final double riskScore;
  final SeverityLevel severity;
  final double r0Estimate;
  final double weatherFactor;
  final double caseDensityPer10k;
  final String primaryDisease;
  final double riskScoreDelta;
  final List<double> recentRiskHistory;

  const DistrictRiskModel({
    required this.districtId,
    required this.districtName,
    required this.districtNameMr,
    required this.latitude,
    required this.longitude,
    required this.livestockPopulation,
    required this.activeCases,
    required this.riskScore,
    required this.severity,
    required this.r0Estimate,
    required this.weatherFactor,
    required this.caseDensityPer10k,
    required this.primaryDisease,
    this.riskScoreDelta = 0.0,
    this.recentRiskHistory = const [],
  });

  DistrictRiskModel copyWith({
    String? districtId,
    String? districtName,
    String? districtNameMr,
    double? latitude,
    double? longitude,
    int? livestockPopulation,
    int? activeCases,
    double? riskScore,
    SeverityLevel? severity,
    double? r0Estimate,
    double? weatherFactor,
    double? caseDensityPer10k,
    String? primaryDisease,
    double? riskScoreDelta,
    List<double>? recentRiskHistory,
  }) {
    return DistrictRiskModel(
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      districtNameMr: districtNameMr ?? this.districtNameMr,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      livestockPopulation: livestockPopulation ?? this.livestockPopulation,
      activeCases: activeCases ?? this.activeCases,
      riskScore: riskScore ?? this.riskScore,
      severity: severity ?? this.severity,
      r0Estimate: r0Estimate ?? this.r0Estimate,
      weatherFactor: weatherFactor ?? this.weatherFactor,
      caseDensityPer10k: caseDensityPer10k ?? this.caseDensityPer10k,
      primaryDisease: primaryDisease ?? this.primaryDisease,
      riskScoreDelta: riskScoreDelta ?? this.riskScoreDelta,
      recentRiskHistory: recentRiskHistory ?? this.recentRiskHistory,
    );
  }

  factory DistrictRiskModel.fromJson(Map<String, dynamic> json) {
    SeverityLevel parseSeverity(String? val) {
      switch (val?.toLowerCase()) {
        case 'critical':
          return SeverityLevel.critical;
        case 'high':
          return SeverityLevel.high;
        case 'medium':
          return SeverityLevel.medium;
        case 'low':
        default:
          return SeverityLevel.low;
      }
    }

    return DistrictRiskModel(
      districtId: json['district_id'] as String? ?? '',
      districtName: json['district_name'] as String? ?? '',
      districtNameMr: json['district_name_mr'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
      livestockPopulation: (json['livestock_population'] as num?)?.toInt() ?? 0,
      activeCases: (json['active_cases'] as num?)?.toInt() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      severity: parseSeverity(json['severity'] as String?),
      r0Estimate: (json['r0_estimate'] as num?)?.toDouble() ?? 1.0,
      weatherFactor: (json['weather_factor'] as num?)?.toDouble() ?? 1.0,
      caseDensityPer10k: (json['case_density_per_10k'] as num?)?.toDouble() ?? 0.0,
      primaryDisease: json['primary_disease'] as String? ?? 'Foot and Mouth Disease',
    );
  }

  Map<String, dynamic> toJson() => {
    'district_id': districtId,
    'district_name': districtName,
    'district_name_mr': districtNameMr,
    'latitude': latitude,
    'longitude': longitude,
    'livestock_population': livestockPopulation,
    'active_cases': activeCases,
    'risk_score': riskScore,
    'severity': severity.name,
    'r0_estimate': r0Estimate,
    'weather_factor': weatherFactor,
    'case_density_per_10k': caseDensityPer10k,
    'primary_disease': primaryDisease,
  };
}

class OutbreakClusterModel {
  final String id;
  final String districtId;
  final String districtName;
  final String districtNameMr;
  final String diseaseName;
  final String diseaseNameMr;
  final int caseCount;
  final SeverityLevel riskLevel;
  final double latitude;
  final double longitude;
  final double containmentRadiusKm;
  final double surveillanceRadiusKm;
  final double r0Estimate;
  final int affectedFarmsCount;
  final bool quarantineDeclared;
  final DateTime declaredAt;
  final String notesEn;
  final String notesMr;

  const OutbreakClusterModel({
    required this.id,
    required this.districtId,
    required this.districtName,
    required this.districtNameMr,
    required this.diseaseName,
    required this.diseaseNameMr,
    required this.caseCount,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
    required this.containmentRadiusKm,
    required this.surveillanceRadiusKm,
    required this.r0Estimate,
    required this.affectedFarmsCount,
    required this.quarantineDeclared,
    required this.declaredAt,
    required this.notesEn,
    required this.notesMr,
  });

  factory OutbreakClusterModel.fromJson(Map<String, dynamic> json) {
    SeverityLevel parseSeverity(String? val) {
      switch (val?.toLowerCase()) {
        case 'critical':
          return SeverityLevel.critical;
        case 'high':
          return SeverityLevel.high;
        case 'medium':
          return SeverityLevel.medium;
        case 'low':
        default:
          return SeverityLevel.low;
      }
    }

    final notes = json['notes_multilingual_json'] as Map<String, dynamic>? ?? {};

    return OutbreakClusterModel(
      id: json['id'] as String? ?? json['cluster_id'] as String? ?? '',
      districtId: json['district_id'] as String? ?? '',
      districtName: json['district_name'] as String? ?? '',
      districtNameMr: json['district_name_mr'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? json['primary_disease'] as String? ?? '',
      diseaseNameMr: json['disease_name_mr'] as String? ?? '',
      caseCount: (json['case_count'] as num?)?.toInt() ?? 1,
      riskLevel: parseSeverity(json['risk_level'] as String? ?? json['severity'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['epicenter_latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['epicenter_longitude'] as num?)?.toDouble() ?? 73.8567,
      containmentRadiusKm: (json['containment_radius_km'] as num?)?.toDouble() ?? 5.0,
      surveillanceRadiusKm: (json['surveillance_radius_km'] as num?)?.toDouble() ?? 10.0,
      r0Estimate: (json['r0_estimate'] as num?)?.toDouble() ?? 1.5,
      affectedFarmsCount: (json['affected_farms_count'] as num?)?.toInt() ?? (json['affected_farms'] as num?)?.toInt() ?? 1,
      quarantineDeclared: json['quarantine_declared'] as bool? ?? false,
      declaredAt: json['declared_at'] != null ? DateTime.tryParse(json['declared_at'].toString()) ?? DateTime.now() : DateTime.now(),
      notesEn: notes['en'] as String? ?? json['notes_en'] as String? ?? '',
      notesMr: notes['mr'] as String? ?? json['notes_mr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'district_id': districtId,
    'district_name': districtName,
    'district_name_mr': districtNameMr,
    'disease_name': diseaseName,
    'disease_name_mr': diseaseNameMr,
    'case_count': caseCount,
    'risk_level': riskLevel.name,
    'latitude': latitude,
    'longitude': longitude,
    'containment_radius_km': containmentRadiusKm,
    'surveillance_radius_km': surveillanceRadiusKm,
    'r0_estimate': r0Estimate,
    'affected_farms_count': affectedFarmsCount,
    'quarantine_declared': quarantineDeclared,
    'declared_at': declaredAt.toIso8601String(),
    'notes_multilingual_json': {
      'en': notesEn,
      'mr': notesMr,
    },
  };
}

class SurveillanceAlertModel {
  final String id;
  final String alertType;
  final SeverityLevel severity;
  final String titleEn;
  final String titleMr;
  final String bodyEn;
  final String bodyMr;
  final List<String> channels;
  final bool isRead;
  final DateTime createdAt;
  final double? distanceKm;

  const SurveillanceAlertModel({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.titleEn,
    required this.titleMr,
    required this.bodyEn,
    required this.bodyMr,
    required this.channels,
    required this.isRead,
    required this.createdAt,
    this.distanceKm,
  });

  factory SurveillanceAlertModel.fromJson(Map<String, dynamic> json) {
    SeverityLevel parseSeverity(String? val) {
      switch (val?.toLowerCase()) {
        case 'critical':
          return SeverityLevel.critical;
        case 'high':
          return SeverityLevel.high;
        case 'medium':
          return SeverityLevel.medium;
        case 'low':
        default:
          return SeverityLevel.low;
      }
    }

    final titleJson = json['title_multilingual_json'] as Map<String, dynamic>? ?? {};
    final bodyJson = json['body_multilingual_json'] as Map<String, dynamic>? ?? {};

    return SurveillanceAlertModel(
      id: json['id'] as String? ?? '',
      alertType: json['alert_type'] as String? ?? 'outbreak',
      severity: parseSeverity(json['severity'] as String?),
      titleEn: titleJson['en'] as String? ?? json['title_en'] as String? ?? 'Outbreak Alert',
      titleMr: titleJson['mr'] as String? ?? json['title_mr'] as String? ?? 'Outbreak Alert',
      bodyEn: bodyJson['en'] as String? ?? json['body_en'] as String? ?? '',
      bodyMr: bodyJson['mr'] as String? ?? json['body_mr'] as String? ?? '',
      channels: (json['channels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['push'],
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alert_type': alertType,
    'severity': severity.name,
    'title_multilingual_json': {'en': titleEn, 'mr': titleMr},
    'body_multilingual_json': {'en': bodyEn, 'mr': bodyMr},
    'channels': channels,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'distance_km': distanceKm,
  };
}

/// Represents an auto-moving livestock transport vehicle on Maharashtra highways.
class LivestockTransitVehicle {
  final String id;
  final String licensePlate;
  final String carrierName;
  final String originDistrict;
  final String destinationDistrict;
  final double originLat;
  final double originLon;
  final double destLat;
  final double destLon;
  final double currentLat;
  final double currentLon;
  final double progress; // 0.0 to 1.0
  final double speedKmH;
  final int animalHeadCount;
  final String species;
  final String biosecurityStatus; // 'cleared', 'screening_required', 'containment_intercepted'
  final SeverityLevel hazardLevel;
  final String driverContact;
  final DateTime dispatchedAt;

  const LivestockTransitVehicle({
    required this.id,
    required this.licensePlate,
    required this.carrierName,
    required this.originDistrict,
    required this.destinationDistrict,
    required this.originLat,
    required this.originLon,
    required this.destLat,
    required this.destLon,
    required this.currentLat,
    required this.currentLon,
    required this.progress,
    required this.speedKmH,
    required this.animalHeadCount,
    required this.species,
    required this.biosecurityStatus,
    required this.hazardLevel,
    required this.driverContact,
    required this.dispatchedAt,
  });

  LivestockTransitVehicle copyWith({
    String? id,
    String? licensePlate,
    String? carrierName,
    String? originDistrict,
    String? destinationDistrict,
    double? originLat,
    double? originLon,
    double? destLat,
    double? destLon,
    double? currentLat,
    double? currentLon,
    double? progress,
    double? speedKmH,
    int? animalHeadCount,
    String? species,
    String? biosecurityStatus,
    SeverityLevel? hazardLevel,
    String? driverContact,
    DateTime? dispatchedAt,
  }) {
    return LivestockTransitVehicle(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      carrierName: carrierName ?? this.carrierName,
      originDistrict: originDistrict ?? this.originDistrict,
      destinationDistrict: destinationDistrict ?? this.destinationDistrict,
      originLat: originLat ?? this.originLat,
      originLon: originLon ?? this.originLon,
      destLat: destLat ?? this.destLat,
      destLon: destLon ?? this.destLon,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      progress: progress ?? this.progress,
      speedKmH: speedKmH ?? this.speedKmH,
      animalHeadCount: animalHeadCount ?? this.animalHeadCount,
      species: species ?? this.species,
      biosecurityStatus: biosecurityStatus ?? this.biosecurityStatus,
      hazardLevel: hazardLevel ?? this.hazardLevel,
      driverContact: driverContact ?? this.driverContact,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
    );
  }

  String get statusDisplay {
    switch (biosecurityStatus) {
      case 'containment_intercepted':
        return 'Quarantine Intercepted';
      case 'screening_required':
        return 'Screening Required';
      case 'cleared':
      default:
        return 'Biosecure Clearance Verified';
    }
  }
}

/// Real-time live simulation surveillance event/log entry.
class LiveSurveillanceLog {
  final String id;
  final DateTime timestamp;
  final String district;
  final String message;
  final SeverityLevel severity;
  final String eventType; // 'outbreak_surge', 'transit_screened', 'containment_active', 'telemetry_update'

  const LiveSurveillanceLog({
    required this.id,
    required this.timestamp,
    required this.district,
    required this.message,
    required this.severity,
    required this.eventType,
  });
}

/// Simulation tick package delivered every real-time tick to the BLoC.
class SimulationTickData {
  final List<DistrictRiskModel> districts;
  final List<OutbreakClusterModel> clusters;
  final List<LivestockTransitVehicle> vehicles;
  final List<LiveSurveillanceLog> recentLogs;
  final List<SurveillanceAlertModel> newAlerts;
  final int totalTicks;
  final double averageRiskIndex;
  final int totalTransitInterceptions;

  const SimulationTickData({
    required this.districts,
    required this.clusters,
    required this.vehicles,
    required this.recentLogs,
    this.newAlerts = const [],
    required this.totalTicks,
    required this.averageRiskIndex,
    required this.totalTransitInterceptions,
  });
}

/// Supported map rendering visual styles.
enum MapViewStyle {
  standard,
  satellite,
}

extension MapViewStyleExtension on MapViewStyle {
  String get label {
    switch (this) {
      case MapViewStyle.standard:
        return 'Normal Map';
      case MapViewStyle.satellite:
        return 'Satellite View';
    }
  }

  String get shortLabel {
    switch (this) {
      case MapViewStyle.standard:
        return 'Normal Map';
      case MapViewStyle.satellite:
        return 'Satellite View';
    }
  }
}

/// Real-time Earth Observation satellite in the eStream constellation.
class OrbitalSatellite {
  final String id;
  final String name;
  final String code;
  final String noradCatalog;
  final String agency;
  final double altitudeKm;
  final double velocityKmS;
  final double currentLat;
  final double currentLon;
  final double headingDeg;
  final double swathRadiusKm;
  final String sensorType;
  final String streamBandwidth;
  final double snrDb;
  final int colorValue;
  final List<List<double>> trajectoryPoints;
  final String targetLockName;
  final bool isTargetLocked;

  const OrbitalSatellite({
    required this.id,
    required this.name,
    required this.code,
    required this.noradCatalog,
    required this.agency,
    required this.altitudeKm,
    required this.velocityKmS,
    required this.currentLat,
    required this.currentLon,
    required this.headingDeg,
    required this.swathRadiusKm,
    required this.sensorType,
    required this.streamBandwidth,
    required this.snrDb,
    required this.colorValue,
    this.trajectoryPoints = const [],
    this.targetLockName = '',
    this.isTargetLocked = false,
  });

  Color get color => Color(colorValue);

  OrbitalSatellite copyWith({
    String? id,
    String? name,
    String? code,
    String? noradCatalog,
    String? agency,
    double? altitudeKm,
    double? velocityKmS,
    double? currentLat,
    double? currentLon,
    double? headingDeg,
    double? swathRadiusKm,
    String? sensorType,
    String? streamBandwidth,
    double? snrDb,
    int? colorValue,
    List<List<double>>? trajectoryPoints,
    String? targetLockName,
    bool? isTargetLocked,
  }) {
    return OrbitalSatellite(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      noradCatalog: noradCatalog ?? this.noradCatalog,
      agency: agency ?? this.agency,
      altitudeKm: altitudeKm ?? this.altitudeKm,
      velocityKmS: velocityKmS ?? this.velocityKmS,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      headingDeg: headingDeg ?? this.headingDeg,
      swathRadiusKm: swathRadiusKm ?? this.swathRadiusKm,
      sensorType: sensorType ?? this.sensorType,
      streamBandwidth: streamBandwidth ?? this.streamBandwidth,
      snrDb: snrDb ?? this.snrDb,
      colorValue: colorValue ?? this.colorValue,
      trajectoryPoints: trajectoryPoints ?? this.trajectoryPoints,
      targetLockName: targetLockName ?? this.targetLockName,
      isTargetLocked: isTargetLocked ?? this.isTargetLocked,
    );
  }

  /// Default eStream active satellite constellation orbiting Maharashtra / India
  static List<OrbitalSatellite> defaultConstellation() {
    return const [
      OrbitalSatellite(
        id: 'sat-sentinel-2a',
        name: 'SENTINEL-2A (ESA)',
        code: 'S2A',
        noradCatalog: 'NORAD 40697',
        agency: 'ESA / Copernicus',
        altitudeKm: 786.0,
        velocityKmS: 7.45,
        currentLat: 19.8,
        currentLon: 75.8,
        headingDeg: 212.0,
        swathRadiusKm: 145.0,
        sensorType: 'Multispectral MSI (10m Optical/NIR)',
        streamBandwidth: '840 Mbps (eStream 4K Live)',
        snrDb: 26.4,
        colorValue: 0xFF00E5FF, // Cyan
        trajectoryPoints: [
          [22.8, 77.8],
          [21.2, 76.6],
          [19.6, 75.4],
          [18.0, 74.2],
          [16.4, 73.0],
          [14.8, 71.8],
        ],
        targetLockName: 'Solapur Outbreak Corridor',
        isTargetLocked: true,
      ),
      OrbitalSatellite(
        id: 'sat-landsat-9',
        name: 'LANDSAT-9 (NASA)',
        code: 'LD9',
        noradCatalog: 'NORAD 49260',
        agency: 'NASA / USGS',
        altitudeKm: 705.0,
        velocityKmS: 7.50,
        currentLat: 18.2,
        currentLon: 76.5,
        headingDeg: 145.0,
        swathRadiusKm: 92.5,
        sensorType: 'Thermal TIRS-2 & OLI-2 (FLIR Heatmap)',
        streamBandwidth: '620 Mbps (Radiometric Downlink)',
        snrDb: 23.8,
        colorValue: 0xFFFF9100, // Amber
        trajectoryPoints: [
          [22.5, 73.5],
          [20.8, 75.0],
          [19.0, 76.6],
          [17.3, 78.1],
          [15.5, 79.6],
        ],
        targetLockName: 'Osmanabad Containment Zone',
        isTargetLocked: true,
      ),
      OrbitalSatellite(
        id: 'sat-risat-1a',
        name: 'RISAT-1A / EOS-04 (ISRO)',
        code: 'EOS4',
        noradCatalog: 'NORAD 51656',
        agency: 'ISRO (India)',
        altitudeKm: 529.0,
        velocityKmS: 7.60,
        currentLat: 17.5,
        currentLon: 75.6,
        headingDeg: 18.0,
        swathRadiusKm: 110.0,
        sensorType: 'C-Band Synthetic Aperture Radar (SAR)',
        streamBandwidth: '950 Mbps (All-Weather SAR Beam)',
        snrDb: 28.2,
        colorValue: 0xFF00E676, // Laser Green
        trajectoryPoints: [
          [15.2, 75.0],
          [16.8, 75.5],
          [18.5, 76.0],
          [20.2, 76.5],
          [22.0, 77.0],
        ],
        targetLockName: 'Kolhapur Buffer Zone',
        isTargetLocked: true,
      ),
      OrbitalSatellite(
        id: 'sat-insat-3dr',
        name: 'INSAT-3DR (ISRO)',
        code: 'I3DR',
        noradCatalog: 'NORAD 41752',
        agency: 'ISRO (India)',
        altitudeKm: 35786.0,
        velocityKmS: 3.07,
        currentLat: 19.5,
        currentLon: 76.2,
        headingDeg: 0.0,
        swathRadiusKm: 280.0,
        sensorType: 'Atmospheric Sounder & Imager (Aerosol Dispersal)',
        streamBandwidth: '320 Mbps (Full-Disc GIS)',
        snrDb: 21.5,
        colorValue: 0xFFE040FB, // Magenta
        trajectoryPoints: [
          [19.5, 76.2],
          [19.6, 76.3],
          [19.5, 76.4],
          [19.4, 76.3],
          [19.5, 76.2],
        ],
        targetLockName: 'Maharashtra State Airspace',
        isTargetLocked: false,
      ),
    ];
  }
}
