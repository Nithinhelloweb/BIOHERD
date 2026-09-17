import 'package:flutter_test/flutter_test.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';

void main() {
  group('Animal Models & Enums Tests', () {
    test('AnimalSpeciesEnum parsing and properties', () {
      expect(AnimalSpeciesEnum.fromString('cattle'), AnimalSpeciesEnum.cattle);
      expect(AnimalSpeciesEnum.fromString('BUFFALO'), AnimalSpeciesEnum.buffalo);
      expect(AnimalSpeciesEnum.fromString('goat'), AnimalSpeciesEnum.goat);
      expect(AnimalSpeciesEnum.fromString('sheep'), AnimalSpeciesEnum.sheep);
      expect(AnimalSpeciesEnum.fromString('poultry'), AnimalSpeciesEnum.poultry);
      expect(AnimalSpeciesEnum.fromString('unknown_species'), AnimalSpeciesEnum.cattle);

      expect(AnimalSpeciesEnum.cattle.displayName, contains('गाय'));
      expect(AnimalSpeciesEnum.buffalo.displayName, contains('म्हैस'));
    });

    test('HealthStatus triage levels and color mappings', () {
      expect(HealthStatus.healthy.severityLevel, SeverityLevel.low);
      expect(HealthStatus.underObservation.severityLevel, SeverityLevel.medium);
      expect(HealthStatus.quarantined.severityLevel, SeverityLevel.high);
      expect(HealthStatus.sick.severityLevel, SeverityLevel.critical);

      expect(HealthStatus.fromString('healthy'), HealthStatus.healthy);
      expect(HealthStatus.fromString('under_observation'), HealthStatus.underObservation);
      expect(HealthStatus.fromString('quarantined'), HealthStatus.quarantined);
      expect(HealthStatus.fromString('sick'), HealthStatus.sick);
    });

    test('Animal JSON serialization and age calculations', () {
      final dob = DateTime.now().subtract(const Duration(days: 750)); // ~2 years
      final animal = Animal(
        id: 'anim-101',
        farmId: 'farm-01',
        species: AnimalSpeciesEnum.cattle,
        breed: 'Khillari',
        sex: 'male',
        dob: dob,
        weightKg: 460.0,
        tagId: 'MH-SOL-KHL-101',
        qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-SOL-KHL-101',
        isActive: true,
        createdAt: DateTime.now(),
        healthStatus: HealthStatus.healthy,
      );

      final json = animal.toJson();
      expect(json['tag_id'], 'MH-SOL-KHL-101');
      expect(json['breed'], 'Khillari');
      expect(json['weight_kg'], 460.0);

      final reconstructed = Animal.fromJson(json);
      expect(reconstructed.id, 'anim-101');
      expect(reconstructed.species, AnimalSpeciesEnum.cattle);
      expect(reconstructed.formattedAge, contains('yrs'));
      expect(reconstructed.healthStatus, HealthStatus.healthy);
    });

    test('Breed JSON serialization', () {
      const breed = Breed(
        name: 'Pandharpuri',
        nameMr: 'पंढरपुरी',
        species: AnimalSpeciesEnum.buffalo,
        originRegion: 'Bhima Basin',
        districts: ['Solapur', 'Kolhapur'],
        description: 'Sword shaped horns',
        descriptionMr: 'लांब तलवारीसारखी शिंगे',
      );

      final json = breed.toJson();
      expect(json['name'], 'Pandharpuri');
      expect(json['name_mr'], 'पंढरपुरी');

      final reconstructed = Breed.fromJson(json);
      expect(reconstructed.name, 'Pandharpuri');
      expect(reconstructed.districts, contains('Solapur'));
    });

    test('HealthTimelineEvent serialization', () {
      final now = DateTime.now();
      final event = HealthTimelineEvent(
        id: 'ev-99',
        animalId: 'anim-101',
        eventType: 'vaccination',
        description: 'FMD vaccine administered',
        recordedBy: 'Dr. Patil',
        occurredAt: now,
        createdAt: now,
      );

      final json = event.toJson();
      expect(json['description'], 'FMD vaccine administered');

      final reconstructed = HealthTimelineEvent.fromJson(json);
      expect(reconstructed.id, 'ev-99');
      expect(reconstructed.recordedBy, 'Dr. Patil');
    });
  });
}
