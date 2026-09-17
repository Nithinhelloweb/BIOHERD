import 'package:bioherd/core/widgets/severity_badge.dart';

/// Single clinical symptom selectable by the farmer/veterinarian
class SymptomItem {
  final String id;
  final String nameEn;
  final String nameMr;
  final String? description;

  const SymptomItem({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_en': nameEn,
        'name_mr': nameMr,
        if (description != null) 'description': description,
      };

  factory SymptomItem.fromJson(Map<String, dynamic> json) => SymptomItem(
        id: json['id'] as String,
        nameEn: json['name_en'] as String,
        nameMr: json['name_mr'] as String,
        description: json['description'] as String?,
      );
}

/// Body system grouping containing category name in English and Marathi
class BodySystemCategory {
  final String id;
  final String nameEn;
  final String nameMr;
  final String iconKey;
  final List<SymptomItem> symptoms;

  const BodySystemCategory({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.iconKey,
    required this.symptoms,
  });
}

/// Single disease candidate prediction returned by AI detector
class DiseasePredictionModel {
  final String diseaseId;
  final String nameEn;
  final String nameMr;
  final double confidence;
  final SeverityLevel severity;
  final String causativeAgent;
  final List<String> matchedSymptoms;
  final String clinicalReasoning;

  const DiseasePredictionModel({
    required this.diseaseId,
    required this.nameEn,
    required this.nameMr,
    required this.confidence,
    required this.severity,
    required this.causativeAgent,
    required this.matchedSymptoms,
    required this.clinicalReasoning,
  });

  String get diseaseNameEn => nameEn;
  String get diseaseNameMr => nameMr;

  Map<String, dynamic> toJson() => {
        'disease_id': diseaseId,
        'name_en': nameEn,
        'name_mr': nameMr,
        'confidence': confidence,
        'severity': severity.name.toUpperCase(),
        'causative_agent': causativeAgent,
        'matched_symptoms': matchedSymptoms,
        'clinical_reasoning': clinicalReasoning,
      };

  factory DiseasePredictionModel.fromJson(Map<String, dynamic> json) {
    final sevStr = (json['severity'] as String? ?? 'MEDIUM').toLowerCase();
    SeverityLevel level;
    switch (sevStr) {
      case 'low':
        level = SeverityLevel.low;
        break;
      case 'medium':
        level = SeverityLevel.medium;
        break;
      case 'high':
        level = SeverityLevel.high;
        break;
      case 'critical':
      default:
        level = SeverityLevel.critical;
        break;
    }

    return DiseasePredictionModel(
      diseaseId: json['disease_id'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameMr: json['name_mr'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: level,
      causativeAgent: json['causative_agent'] as String? ?? '',
      matchedSymptoms: (json['matched_symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      clinicalReasoning: json['clinical_reasoning'] as String? ?? '',
    );
  }
}

/// Bilingual emergency bio-security first-aid protocol
class FirstAidModel {
  final Map<String, dynamic> en;
  final Map<String, dynamic> mr;
  final bool isolationRequired;
  final bool zoonoticRisk;

  const FirstAidModel({
    required this.en,
    required this.mr,
    required this.isolationRequired,
    required this.zoonoticRisk,
  });

  String get immediateActionEn => (en['immediate_action'] as String?) ?? 'Isolate animal and contact veterinarian.';
  String get immediateActionMr => (mr['immediate_action'] as String?) ?? 'बाधित जनावराला वेगळे ठेवा आणि पशुवैद्यांशी संपर्क साधा.';
  String get sanitationEn => (en['sanitation'] as String?) ?? (en['disinfection'] as String?) ?? 'Disinfect cattle stall thoroughly.';
  String get sanitationMr => (mr['sanitation'] as String?) ?? (mr['disinfection'] as String?) ?? 'गोठा चुना व जंतुनाशकाने स्वच्छ करा.';
  String get isolationProtocolsMr => (mr['isolation'] as String?) ?? immediateActionMr;
  String get disinfectionMr => sanitationMr;
  String get emergencyHotline => (en['hotline'] as String?) ?? '1962';
  String get supportiveCareMr => (mr['care'] as String?) ?? immediateActionMr;

  Map<String, dynamic> toJson() => {
        'en': en,
        'mr': mr,
        'isolation_required': isolationRequired,
        'zoonotic_risk': zoonoticRisk,
      };

  factory FirstAidModel.fromJson(Map<String, dynamic> json) => FirstAidModel(
        en: (json['en'] as Map<String, dynamic>?) ?? {},
        mr: (json['mr'] as Map<String, dynamic>?) ?? {},
        isolationRequired: json['isolation_required'] as bool? ?? true,
        zoonoticRisk: json['zoonotic_risk'] as bool? ?? false,
      );
}

/// AI Diagnostic response payload
class AIDiagnosisResult {
  final String modelVersion;
  final DiseasePredictionModel primaryDiagnosis;
  final List<DiseasePredictionModel> differentialDiagnoses;
  final SeverityLevel severity;
  final double confidence;
  final bool shouldEscalateCase;
  final FirstAidModel firstAid;
  final int inferenceDurationMs;

  bool get escalatedToVet => shouldEscalateCase;

  const AIDiagnosisResult({
    required this.modelVersion,
    required this.primaryDiagnosis,
    required this.differentialDiagnoses,
    required this.severity,
    required this.confidence,
    required this.shouldEscalateCase,
    required this.firstAid,
    required this.inferenceDurationMs,
  });

  Map<String, dynamic> toJson() => {
        'model_version': modelVersion,
        'primary_diagnosis': primaryDiagnosis.toJson(),
        'differential_diagnoses':
            differentialDiagnoses.map((d) => d.toJson()).toList(),
        'severity': severity.name.toUpperCase(),
        'confidence': confidence,
        'should_escalate_case': shouldEscalateCase,
        'first_aid': firstAid.toJson(),
        'inference_duration_ms': inferenceDurationMs,
      };

  factory AIDiagnosisResult.fromJson(Map<String, dynamic> json) {
    final sevStr = (json['severity'] as String? ?? 'MEDIUM').toLowerCase();
    SeverityLevel level;
    switch (sevStr) {
      case 'low':
        level = SeverityLevel.low;
        break;
      case 'medium':
        level = SeverityLevel.medium;
        break;
      case 'high':
        level = SeverityLevel.high;
        break;
      case 'critical':
      default:
        level = SeverityLevel.critical;
        break;
    }

    return AIDiagnosisResult(
      modelVersion: json['model_version'] as String? ?? 'bioherd-ai-v2.1',
      primaryDiagnosis: DiseasePredictionModel.fromJson(
          json['primary_diagnosis'] as Map<String, dynamic>),
      differentialDiagnoses: (json['differential_diagnoses'] as List<dynamic>?)
              ?.map((d) =>
                  DiseasePredictionModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      severity: level,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      shouldEscalateCase: json['should_escalate_case'] as bool? ?? false,
      firstAid: FirstAidModel.fromJson(
          (json['first_aid'] as Map<String, dynamic>?) ?? {}),
      inferenceDurationMs: json['inference_duration_ms'] as int? ?? 50,
    );
  }
}

/// Complete Livestock Symptom Report record
class SymptomReportModel {
  final String id;
  final String animalId;
  final String? animalTagId;
  final String? species;
  final String? breed;
  final String reportedBy;
  final Map<String, dynamic> symptomsJson;
  final SeverityLevel severity;
  final String status;
  final String? voiceNoteUrl;
  final List<String> images;
  final AIDiagnosisResult? detectionResult;
  final String? caseId;
  final DateTime createdAt;

  const SymptomReportModel({
    required this.id,
    required this.animalId,
    this.animalTagId,
    this.species,
    this.breed,
    required this.reportedBy,
    required this.symptomsJson,
    required this.severity,
    required this.status,
    this.voiceNoteUrl,
    required this.images,
    this.detectionResult,
    this.caseId,
    required this.createdAt,
  });

  String? get escalatedCaseId => caseId;
  String get animalTagIdSafe => animalTagId ?? 'MH-ANIMAL';

  Map<String, dynamic> toJson() => {
        'id': id,
        'animal_id': animalId,
        'animal_tag_id': animalTagId,
        'species': species,
        'breed': breed,
        'reported_by': reportedBy,
        'symptoms_json': symptomsJson,
        'severity': severity.name.toUpperCase(),
        'status': status,
        'voice_note_url': voiceNoteUrl,
        'images_json': images,
        if (detectionResult != null)
          'detection_result': detectionResult!.toJson(),
        if (caseId != null) 'case_id': caseId,
        'created_at': createdAt.toIso8601String(),
      };

  factory SymptomReportModel.fromJson(Map<String, dynamic> json) {
    final sevStr = (json['severity'] as String? ?? 'MEDIUM').toLowerCase();
    SeverityLevel level;
    switch (sevStr) {
      case 'low':
        level = SeverityLevel.low;
        break;
      case 'medium':
        level = SeverityLevel.medium;
        break;
      case 'high':
        level = SeverityLevel.high;
        break;
      case 'critical':
      default:
        level = SeverityLevel.critical;
        break;
    }

    return SymptomReportModel(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      animalTagId: json['animal_tag_id'] as String?,
      species: json['species'] as String?,
      breed: json['breed'] as String?,
      reportedBy: json['reported_by'] as String? ?? 'Farmer',
      symptomsJson: (json['symptoms_json'] as Map<String, dynamic>?) ?? {},
      severity: level,
      status: json['status'] as String? ?? 'submitted',
      voiceNoteUrl: json['voice_note_url'] as String?,
      images: (json['images_json'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      detectionResult: json['detection_result'] != null
          ? AIDiagnosisResult.fromJson(
              json['detection_result'] as Map<String, dynamic>)
          : null,
      caseId: json['case_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
