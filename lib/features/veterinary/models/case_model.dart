import 'package:flutter/material.dart';
import 'package:bioherd/core/theme/app_colors.dart';

enum CaseStatus {
  submitted,
  assigned,
  inReview,
  prescriptionIssued,
  followUp,
  closed;

  String get labelEn {
    switch (this) {
      case CaseStatus.submitted:
        return 'Triage Queue';
      case CaseStatus.assigned:
        return 'Assigned';
      case CaseStatus.inReview:
        return 'In Review';
      case CaseStatus.prescriptionIssued:
        return 'Rx Issued';
      case CaseStatus.followUp:
        return 'Follow Up';
      case CaseStatus.closed:
        return 'Resolved / Closed';
    }
  }

  String get labelMr {
    switch (this) {
      case CaseStatus.submitted:
        return 'तपासणी प्रतीक्षा';
      case CaseStatus.assigned:
        return 'डॉक्टरांकडे सोपवले';
      case CaseStatus.inReview:
        return 'तपासणी सुरू';
      case CaseStatus.prescriptionIssued:
        return 'औषधोपचार जारी';
      case CaseStatus.followUp:
        return 'पुनर्तपासणी';
      case CaseStatus.closed:
        return 'निवारण पूर्ण';
    }
  }

  Color get color {
    switch (this) {
      case CaseStatus.submitted:
        return AppColors.alertAmber;
      case CaseStatus.assigned:
        return Colors.blue;
      case CaseStatus.inReview:
        return Colors.purple;
      case CaseStatus.prescriptionIssued:
        return AppColors.forestGreen;
      case CaseStatus.followUp:
        return Colors.teal;
      case CaseStatus.closed:
        return Colors.grey;
    }
  }

  static CaseStatus fromString(String? val) {
    if (val == null) return CaseStatus.submitted;
    final normalized = val.toLowerCase().replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
    switch (normalized) {
      case 'assigned':
        return CaseStatus.assigned;
      case 'inreview':
        return CaseStatus.inReview;
      case 'prescriptionissued':
        return CaseStatus.prescriptionIssued;
      case 'followup':
        return CaseStatus.followUp;
      case 'closed':
        return CaseStatus.closed;
      default:
        return CaseStatus.submitted;
    }
  }
}

enum CasePriority {
  low,
  medium,
  high,
  critical;

  String get labelEn {
    switch (this) {
      case CasePriority.low:
        return 'Low';
      case CasePriority.medium:
        return 'Medium';
      case CasePriority.high:
        return 'High';
      case CasePriority.critical:
        return 'Critical Emergency';
    }
  }

  String get labelMr {
    switch (this) {
      case CasePriority.low:
        return 'कमी';
      case CasePriority.medium:
        return 'मध्यम';
      case CasePriority.high:
        return 'गंभीर';
      case CasePriority.critical:
        return 'तातडीची आणीबाणी';
    }
  }

  Color get color {
    switch (this) {
      case CasePriority.low:
        return Colors.blueGrey;
      case CasePriority.medium:
        return Colors.orange;
      case CasePriority.high:
        return Colors.deepOrange;
      case CasePriority.critical:
        return AppColors.alertRed;
    }
  }

  static CasePriority fromString(String? val) {
    if (val == null) return CasePriority.medium;
    switch (val.toLowerCase()) {
      case 'low':
        return CasePriority.low;
      case 'high':
        return CasePriority.high;
      case 'critical':
        return CasePriority.critical;
      default:
        return CasePriority.medium;
    }
  }
}

class CaseModel {
  final String id;
  final String symptomReportId;
  final String? assignedVetId;
  final String? assignedVetName;
  final CaseStatus status;
  final CasePriority priority;
  final String? telemedicineSessionId;
  final String? resolutionSummary;
  final String? notes;
  final String? animalId;
  final String? animalTagId;
  final String? animalSpecies;
  final String? animalBreed;
  final double animalWeightKg;
  final String? farmerId;
  final String? farmerName;
  final String? farmerPhone;
  final String districtName;
  final String? primarySuspect;
  final String? primarySuspectMr;
  final double? aiConfidence;
  final bool hasPrescription;
  final List<String> symptomsSummary;
  final List<String> images;
  final String? voiceNoteUrl;
  final List<PrescriptionModel> prescriptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseModel({
    required this.id,
    required this.symptomReportId,
    this.assignedVetId,
    this.assignedVetName,
    required this.status,
    required this.priority,
    this.telemedicineSessionId,
    this.resolutionSummary,
    this.notes,
    this.animalId,
    this.animalTagId,
    this.animalSpecies,
    this.animalBreed,
    this.animalWeightKg = 350.0,
    this.farmerId,
    this.farmerName,
    this.farmerPhone,
    this.districtName = 'Maharashtra',
    this.primarySuspect,
    this.primarySuspectMr,
    this.aiConfidence,
    this.hasPrescription = false,
    this.symptomsSummary = const [],
    this.images = const [],
    this.voiceNoteUrl,
    this.prescriptions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCritical => priority == CasePriority.critical;
  bool get isUnassigned => assignedVetId == null;
  String get species => animalSpecies ?? 'Livestock';
  String get breed => animalBreed ?? 'Local';
  double get weightKg => animalWeightKg;
  String get district => districtName;
  String get taluka => districtName;
  String get primaryDiagnosis => primarySuspect ?? 'Suspected Disease';
  List<String> get symptoms => symptomsSummary;
  List<String> get differentialDiagnoses => const [];
  double get ageYears => 3.5;

  CaseModel copyWith({
    String? id,
    String? symptomReportId,
    String? assignedVetId,
    String? assignedVetName,
    CaseStatus? status,
    CasePriority? priority,
    String? telemedicineSessionId,
    String? resolutionSummary,
    String? notes,
    String? animalId,
    String? animalTagId,
    String? animalSpecies,
    String? animalBreed,
    double? animalWeightKg,
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    String? districtName,
    String? primarySuspect,
    String? primarySuspectMr,
    double? aiConfidence,
    bool? hasPrescription,
    List<String>? symptomsSummary,
    List<String>? images,
    String? voiceNoteUrl,
    List<PrescriptionModel>? prescriptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaseModel(
      id: id ?? this.id,
      symptomReportId: symptomReportId ?? this.symptomReportId,
      assignedVetId: assignedVetId ?? this.assignedVetId,
      assignedVetName: assignedVetName ?? this.assignedVetName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      telemedicineSessionId: telemedicineSessionId ?? this.telemedicineSessionId,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
      notes: notes ?? this.notes,
      animalId: animalId ?? this.animalId,
      animalTagId: animalTagId ?? this.animalTagId,
      animalSpecies: animalSpecies ?? this.animalSpecies,
      animalBreed: animalBreed ?? this.animalBreed,
      animalWeightKg: animalWeightKg ?? this.animalWeightKg,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      districtName: districtName ?? this.districtName,
      primarySuspect: primarySuspect ?? this.primarySuspect,
      primarySuspectMr: primarySuspectMr ?? this.primarySuspectMr,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      hasPrescription: hasPrescription ?? this.hasPrescription,
      symptomsSummary: symptomsSummary ?? this.symptomsSummary,
      images: images ?? this.images,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      prescriptions: prescriptions ?? this.prescriptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String? ?? '',
      symptomReportId: json['symptom_report_id'] as String? ?? '',
      assignedVetId: json['assigned_vet_id'] as String?,
      assignedVetName: json['assigned_vet_name'] as String?,
      status: CaseStatus.fromString(json['status'] as String?),
      priority: CasePriority.fromString(json['priority'] as String?),
      telemedicineSessionId: json['telemedicine_session_id'] as String?,
      resolutionSummary: json['resolution_summary'] as String?,
      notes: json['notes'] as String?,
      animalId: json['animal_id'] as String?,
      animalTagId: json['animal_tag_id'] as String?,
      animalSpecies: json['animal_species'] as String?,
      animalBreed: json['animal_breed'] as String?,
      animalWeightKg: (json['animal_weight_kg'] as num?)?.toDouble() ?? 350.0,
      farmerId: json['farmer_id'] as String?,
      farmerName: json['farmer_name'] as String?,
      farmerPhone: json['farmer_phone'] as String?,
      districtName: json['district_name'] as String? ?? 'Maharashtra',
      primarySuspect: json['primary_suspect'] as String? ?? json['primary_diagnosis'] as String?,
      primarySuspectMr: json['primary_suspect_mr'] as String? ?? json['primary_diagnosis_mr'] as String?,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      hasPrescription: json['has_prescription'] as bool? ?? false,
      symptomsSummary: (json['symptoms_summary'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      voiceNoteUrl: json['voice_note_url'] as String?,
      prescriptions: (json['prescriptions'] as List<dynamic>?)
              ?.map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symptom_report_id': symptomReportId,
      'assigned_vet_id': assignedVetId,
      'assigned_vet_name': assignedVetName,
      'status': status.name,
      'priority': priority.name,
      'telemedicine_session_id': telemedicineSessionId,
      'resolution_summary': resolutionSummary,
      'notes': notes,
      'animal_id': animalId,
      'animal_tag_id': animalTagId,
      'animal_species': animalSpecies,
      'animal_breed': animalBreed,
      'animal_weight_kg': animalWeightKg,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'district_name': districtName,
      'primary_suspect': primarySuspect,
      'primary_suspect_mr': primarySuspectMr,
      'ai_confidence': aiConfidence,
      'has_prescription': hasPrescription,
      'symptoms_summary': symptomsSummary,
      'images': images,
      'voice_note_url': voiceNoteUrl,
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PrescriptionModel {
  final String id;
  final String caseId;
  final String issuedBy;
  final String? issuedByName;
  final String drugName;
  final String dosage;
  final int durationDays;
  final Map<String, String> instructionsMultilingual;
  final bool scheduleHWarning;
  final int milkWithdrawalDays;
  final int meatWithdrawalDays;
  final String? digitalSignatureHash;
  final String? pdfUrl;
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.caseId,
    required this.issuedBy,
    this.issuedByName,
    required this.drugName,
    required this.dosage,
    this.durationDays = 5,
    this.instructionsMultilingual = const {},
    this.scheduleHWarning = false,
    this.milkWithdrawalDays = 0,
    this.meatWithdrawalDays = 0,
    this.digitalSignatureHash,
    this.pdfUrl,
    required this.createdAt,
  });

  String get instructionEn => instructionsMultilingual['en'] ?? 'Take as directed.';
  String get instructionMr => instructionsMultilingual['mr'] ?? 'डॉक्टरांच्या सल्ल्यानुसार द्यावे.';

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String? ?? '',
      caseId: json['case_id'] as String? ?? '',
      issuedBy: json['issued_by'] as String? ?? '',
      issuedByName: json['issued_by_name'] as String?,
      drugName: json['drug_name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      durationDays: json['duration_days'] as int? ?? 5,
      instructionsMultilingual: (json['instructions_multilingual_json'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const {},
      scheduleHWarning: json['schedule_h_warning'] as bool? ?? false,
      milkWithdrawalDays: json['milk_withdrawal_days'] as int? ?? 0,
      meatWithdrawalDays: json['meat_withdrawal_days'] as int? ?? 0,
      digitalSignatureHash: json['digital_signature_hash'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'issued_by': issuedBy,
      'issued_by_name': issuedByName,
      'drug_name': drugName,
      'dosage': dosage,
      'duration_days': durationDays,
      'instructions_multilingual_json': instructionsMultilingual,
      'schedule_h_warning': scheduleHWarning,
      'milk_withdrawal_days': milkWithdrawalDays,
      'meat_withdrawal_days': meatWithdrawalDays,
      'digital_signature_hash': digitalSignatureHash,
      'pdf_url': pdfUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DrugItem {
  final String id;
  final String name;
  final List<String> tradeNames;
  final String category;
  final bool scheduleH;
  final List<String> targetSpecies;
  final List<String> indications;
  final String route;
  final double dosePerKgMg;
  final double concentrationMgMl;
  final int defaultDurationDays;
  final int milkWithdrawalDays;
  final int meatWithdrawalDays;
  final String instructionsEn;
  final String instructionsMr;
  final String contraindications;

  const DrugItem({
    required this.id,
    required this.name,
    this.tradeNames = const [],
    required this.category,
    this.scheduleH = false,
    this.targetSpecies = const [],
    this.indications = const [],
    required this.route,
    this.dosePerKgMg = 0.0,
    this.concentrationMgMl = 0.0,
    this.defaultDurationDays = 3,
    this.milkWithdrawalDays = 0,
    this.meatWithdrawalDays = 0,
    required this.instructionsEn,
    required this.instructionsMr,
    required this.contraindications,
  });

  factory DrugItem.fromJson(Map<String, dynamic> json) {
    return DrugItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tradeNames: (json['trade_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      category: json['category'] as String? ?? '',
      scheduleH: json['schedule_h'] as bool? ?? false,
      targetSpecies: (json['target_species'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      indications: (json['indications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      route: json['route'] as String? ?? '',
      dosePerKgMg: (json['dose_per_kg_mg'] as num?)?.toDouble() ?? 0.0,
      concentrationMgMl: (json['concentration_mg_ml'] as num?)?.toDouble() ?? 0.0,
      defaultDurationDays: json['default_duration_days'] as int? ?? 3,
      milkWithdrawalDays: json['milk_withdrawal_days'] as int? ?? 0,
      meatWithdrawalDays: json['meat_withdrawal_days'] as int? ?? 0,
      instructionsEn: json['instructions_en'] as String? ?? '',
      instructionsMr: json['instructions_mr'] as String? ?? '',
      contraindications: json['contraindications'] as String? ?? '',
    );
  }
}

class DosageCalculationResult {
  final String drugId;
  final String drugName;
  final String category;
  final bool scheduleH;
  final String route;
  final double bodyWeightKg;
  final double calculatedVolumeMl;
  final String displayDose;
  final String displayDoseMr;
  final int defaultDurationDays;
  final int milkWithdrawalDays;
  final int meatWithdrawalDays;
  final String instructionsEn;
  final String instructionsMr;
  final String contraindications;

  const DosageCalculationResult({
    required this.drugId,
    required this.drugName,
    required this.category,
    required this.scheduleH,
    required this.route,
    required this.bodyWeightKg,
    required this.calculatedVolumeMl,
    required this.displayDose,
    required this.displayDoseMr,
    required this.defaultDurationDays,
    required this.milkWithdrawalDays,
    required this.meatWithdrawalDays,
    required this.instructionsEn,
    required this.instructionsMr,
    required this.contraindications,
  });

  factory DosageCalculationResult.fromJson(Map<String, dynamic> json) {
    return DosageCalculationResult(
      drugId: json['drug_id'] as String? ?? '',
      drugName: json['drug_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      scheduleH: json['schedule_h'] as bool? ?? false,
      route: json['route'] as String? ?? '',
      bodyWeightKg: (json['body_weight_kg'] as num?)?.toDouble() ?? 0.0,
      calculatedVolumeMl: (json['calculated_volume_ml'] as num?)?.toDouble() ?? 0.0,
      displayDose: json['display_dose'] as String? ?? '',
      displayDoseMr: json['display_dose_mr'] as String? ?? '',
      defaultDurationDays: json['default_duration_days'] as int? ?? 3,
      milkWithdrawalDays: json['milk_withdrawal_days'] as int? ?? 0,
      meatWithdrawalDays: json['meat_withdrawal_days'] as int? ?? 0,
      instructionsEn: json['instructions_en'] as String? ?? '',
      instructionsMr: json['instructions_mr'] as String? ?? '',
      contraindications: json['contraindications'] as String? ?? '',
    );
  }

  bool get scheduleHWarning => scheduleH;
  double get totalActiveIngredientMg => calculatedVolumeMl * 5.0;
  String get frequency => 'Once Daily (OD)';
}

class TelemedicineSessionModel {
  final String sessionId;
  final String caseId;
  final String roomName;
  final List<dynamic> iceServers;
  final String status;
  final DateTime createdAt;

  const TelemedicineSessionModel({
    required this.sessionId,
    required this.caseId,
    required this.roomName,
    this.iceServers = const [],
    required this.status,
    required this.createdAt,
  });

  String get roomId => roomName;
  bool get isLowBandwidthMode => true;

  factory TelemedicineSessionModel.fromJson(Map<String, dynamic> json) {
    return TelemedicineSessionModel(
      sessionId: json['session_id'] as String? ?? '',
      caseId: json['case_id'] as String? ?? '',
      roomName: json['room_name'] as String? ?? '',
      iceServers: json['ice_servers'] as List<dynamic>? ?? const [],
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}
