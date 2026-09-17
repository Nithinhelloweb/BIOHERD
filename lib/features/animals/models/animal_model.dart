import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';

enum AnimalSpeciesEnum {
  cattle('cattle', 'Cattle / गाय-बैल', 'गाय / गोवंश', PhosphorIconsRegular.cow),
  buffalo('buffalo', 'Buffalo / म्हैस', 'म्हैस', PhosphorIconsRegular.shieldChevron),
  goat('goat', 'Goat / शेळी', 'शेळी', PhosphorIconsRegular.pawPrint),
  sheep('sheep', 'Sheep / मेंढी', 'मेंढी', PhosphorIconsRegular.pawPrint),
  pig('pig', 'Pig / वराह', 'वराह', PhosphorIconsRegular.pawPrint),
  poultry('poultry', 'Poultry / कुक्कुट', 'कुक्कुट', PhosphorIconsRegular.egg);

  final String value;
  final String displayName;
  final String displayNameMr;
  final IconData icon;

  const AnimalSpeciesEnum(this.value, this.displayName, this.displayNameMr, this.icon);

  static AnimalSpeciesEnum fromString(String val) {
    return AnimalSpeciesEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => AnimalSpeciesEnum.cattle,
    );
  }
}

enum HealthStatus {
  healthy('healthy', 'Healthy', 'निरोगी', SeverityLevel.low, AppColors.success600, AppColors.success100),
  underObservation('under_observation', 'Under Observation', 'निरीक्षणाखाली', SeverityLevel.medium, AppColors.warning600, AppColors.warning100),
  quarantined('quarantined', 'Quarantined', 'विलगीकरणात', SeverityLevel.high, AppColors.warning600, AppColors.warning100),
  sick('sick', 'Sick / Alert', 'आजारी / दक्ष', SeverityLevel.critical, AppColors.danger600, AppColors.danger100);

  final String value;
  final String label;
  final String labelMr;
  final SeverityLevel severityLevel;
  final Color textColor;
  final Color bgColor;

  const HealthStatus(this.value, this.label, this.labelMr, this.severityLevel, this.textColor, this.bgColor);

  static HealthStatus fromString(String val) {
    return HealthStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => HealthStatus.healthy,
    );
  }
}

class Animal {
  final String id;
  final String farmId;
  final AnimalSpeciesEnum species;
  final String breed;
  final String sex;
  final DateTime? dob;
  final double weightKg;
  final String tagId;
  final String? qrCodeUrl;
  final bool isActive;
  final DateTime createdAt;
  final HealthStatus healthStatus;
  final String? lastCheckDate;
  final String? notes;

  const Animal({
    required this.id,
    required this.farmId,
    required this.species,
    required this.breed,
    required this.sex,
    this.dob,
    this.weightKg = 0.0,
    required this.tagId,
    this.qrCodeUrl,
    this.isActive = true,
    required this.createdAt,
    this.healthStatus = HealthStatus.healthy,
    this.lastCheckDate,
    this.notes,
  });

  int? get ageInMonths {
    if (dob == null) return null;
    final diffDays = DateTime.now().difference(dob!).inDays;
    return (diffDays / 30.44).floor();
  }

  String get formattedAge {
    final months = ageInMonths;
    if (months == null) return 'Unknown age';
    if (months < 12) return '$months mos';
    final years = months ~/ 12;
    final rem = months % 12;
    return rem == 0 ? '$years yrs' : '$years yrs $rem mos';
  }

  Animal copyWith({
    String? id,
    String? farmId,
    AnimalSpeciesEnum? species,
    String? breed,
    String? sex,
    DateTime? dob,
    double? weightKg,
    String? tagId,
    String? qrCodeUrl,
    bool? isActive,
    DateTime? createdAt,
    HealthStatus? healthStatus,
    String? lastCheckDate,
    String? notes,
  }) {
    return Animal(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      dob: dob ?? this.dob,
      weightKg: weightKg ?? this.weightKg,
      tagId: tagId ?? this.tagId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      healthStatus: healthStatus ?? this.healthStatus,
      lastCheckDate: lastCheckDate ?? this.lastCheckDate,
      notes: notes ?? this.notes,
    );
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String? ?? '',
      farmId: json['farm_id'] as String? ?? '',
      species: AnimalSpeciesEnum.fromString(json['species'] as String? ?? 'cattle'),
      breed: json['breed'] as String? ?? '',
      sex: json['sex'] as String? ?? 'female',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      tagId: json['tag_id'] as String? ?? '',
      qrCodeUrl: json['qr_code_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      healthStatus: HealthStatus.fromString(json['health_status'] as String? ?? 'healthy'),
      lastCheckDate: json['last_check_date'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'species': species.value,
      'breed': breed,
      'sex': sex,
      'dob': dob?.toIso8601String(),
      'weight_kg': weightKg,
      'tag_id': tagId,
      'qr_code_url': qrCodeUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'health_status': healthStatus.value,
      'last_check_date': lastCheckDate,
      'notes': notes,
    };
  }
}

class Breed {
  final String name;
  final String nameMr;
  final AnimalSpeciesEnum species;
  final String originRegion;
  final List<String> districts;
  final String description;
  final String descriptionMr;

  const Breed({
    required this.name,
    required this.nameMr,
    required this.species,
    required this.originRegion,
    required this.districts,
    required this.description,
    required this.descriptionMr,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      name: json['name'] as String? ?? '',
      nameMr: json['name_mr'] as String? ?? '',
      species: AnimalSpeciesEnum.fromString(json['species'] as String? ?? 'cattle'),
      originRegion: json['origin_region'] as String? ?? '',
      districts: (json['districts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] as String? ?? '',
      descriptionMr: json['description_mr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_mr': nameMr,
      'species': species.value,
      'origin_region': originRegion,
      'districts': districts,
      'description': description,
      'description_mr': descriptionMr,
    };
  }
}

class HealthTimelineEvent {
  final String id;
  final String animalId;
  final String eventType;
  final String description;
  final String recordedBy;
  final DateTime occurredAt;
  final DateTime createdAt;

  const HealthTimelineEvent({
    required this.id,
    required this.animalId,
    required this.eventType,
    required this.description,
    required this.recordedBy,
    required this.occurredAt,
    required this.createdAt,
  });

  factory HealthTimelineEvent.fromJson(Map<String, dynamic> json) {
    return HealthTimelineEvent(
      id: json['id'] as String? ?? '',
      animalId: json['animal_id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'routine_checkup',
      description: json['description'] as String? ?? '',
      recordedBy: json['recorded_by'] as String? ?? '',
      occurredAt: json['occurred_at'] != null
          ? DateTime.tryParse(json['occurred_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'event_type': eventType,
      'description': description,
      'recorded_by': recordedBy,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AnimalPassport {
  final String animalId;
  final String tagId;
  final String species;
  final String breed;
  final String sex;
  final double weightKg;
  final DateTime? dob;
  final int? ageMonths;
  final String farmId;
  final String farmName;
  final String districtName;
  final String ownerName;
  final String ownerPhone;
  final String? qrCodeUrl;
  final bool isActive;
  final DateTime registeredAt;
  final int healthEventsCount;
  final int vaccinationsCount;
  final List<HealthTimelineEvent> recentEvents;
  final String verificationHash;

  const AnimalPassport({
    required this.animalId,
    required this.tagId,
    required this.species,
    required this.breed,
    required this.sex,
    required this.weightKg,
    this.dob,
    this.ageMonths,
    required this.farmId,
    required this.farmName,
    required this.districtName,
    required this.ownerName,
    required this.ownerPhone,
    this.qrCodeUrl,
    required this.isActive,
    required this.registeredAt,
    required this.healthEventsCount,
    required this.vaccinationsCount,
    required this.recentEvents,
    required this.verificationHash,
  });

  factory AnimalPassport.fromJson(Map<String, dynamic> json) {
    return AnimalPassport(
      animalId: json['animal_id'] as String? ?? '',
      tagId: json['tag_id'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      sex: json['sex'] as String? ?? '',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      ageMonths: json['age_months'] as int?,
      farmId: json['farm_id'] as String? ?? '',
      farmName: json['farm_name'] as String? ?? '',
      districtName: json['district_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      ownerPhone: json['owner_phone'] as String? ?? '',
      qrCodeUrl: json['qr_code_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      healthEventsCount: json['health_events_count'] as int? ?? 0,
      vaccinationsCount: json['vaccinations_count'] as int? ?? 0,
      recentEvents: (json['recent_events'] as List<dynamic>?)
              ?.map((e) => HealthTimelineEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      verificationHash: json['verification_hash'] as String? ?? '',
    );
  }
}

typedef AnimalModel = Animal;
