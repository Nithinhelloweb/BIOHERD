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
  });

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
      titleMr: titleJson['mr'] as String? ?? json['title_mr'] as String? ?? 'रोग प्रादुर्भाव दक्षता',
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
