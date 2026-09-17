import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/animals/data/animal_repository.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstAnimalRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstAnimalRepository.create();
  });

  group('OfflineFirstAnimalRepository Tests', () {
    test('Initial seeding populates authentic Maharashtra livestock', () async {
      final animals = await repository.getAnimals();
      expect(animals.length, greaterThanOrEqualTo(5));

      final tagIds = animals.map((a) => a.tagId).toList();
      expect(tagIds, contains('MH-PUN-GIR-104'));
      expect(tagIds, contains('MH-SOL-KHL-201'));
      expect(tagIds, contains('MH-KOL-PND-305'));
      expect(tagIds, contains('MH-OSM-OSM-402'));
      expect(tagIds, contains('MH-NAN-KDK-501'));
    });

    test('Filter animals by species', () async {
      final cattle = await repository.getAnimals(species: AnimalSpeciesEnum.cattle);
      expect(cattle.every((a) => a.species == AnimalSpeciesEnum.cattle), isTrue);
      expect(cattle.any((a) => a.breed == 'Gir'), isTrue);

      final goats = await repository.getAnimals(species: AnimalSpeciesEnum.goat);
      expect(goats.length, 1);
      expect(goats.first.breed, 'Osmanabadi');
    });

    test('Search animals by tag or breed query', () async {
      final results = await repository.getAnimals(searchQuery: 'KHL');
      expect(results.length, 1);
      expect(results.first.tagId, 'MH-SOL-KHL-201');

      final girResults = await repository.getAnimals(searchQuery: 'gir');
      expect(girResults.any((a) => a.breed == 'Gir'), isTrue);
    });

    test('Lookup animal by Ear Tag', () async {
      final found = await repository.lookupByTag('mh-pun-gir-104');
      expect(found, isNotNull);
      expect(found!.breed, 'Gir');
      expect(found.species, AnimalSpeciesEnum.cattle);

      final notFound = await repository.lookupByTag('NON-EXISTENT-TAG');
      expect(notFound, isNull);
    });

    test('Register new animal and prevent duplicate ear tag', () async {
      final newAnimal = Animal(
        id: 'test-anim-99',
        farmId: 'farm-01',
        species: AnimalSpeciesEnum.buffalo,
        breed: 'Nagpuri',
        sex: 'female',
        dob: DateTime.now().subtract(const Duration(days: 365)),
        weightKg: 490.0,
        tagId: 'MH-NAG-NGP-999',
        createdAt: DateTime.now(),
      );

      final registered = await repository.registerAnimal(newAnimal);
      expect(registered.tagId, 'MH-NAG-NGP-999');

      // Duplicate tag registration should throw exception
      expect(
        () => repository.registerAnimal(newAnimal),
        throwsA(isA<Exception>()),
      );
    });

    test('Update animal health status and details', () async {
      final animals = await repository.getAnimals();
      final target = animals.first;

      final updated = target.copyWith(
        healthStatus: HealthStatus.quarantined,
        weightKg: target.weightKg + 10,
      );

      final result = await repository.updateAnimal(updated);
      expect(result.healthStatus, HealthStatus.quarantined);
      expect(result.weightKg, target.weightKg + 10);

      // Verify in refreshed list
      final refreshed = await repository.lookupByTag(target.tagId);
      expect(refreshed!.healthStatus, HealthStatus.quarantined);
    });

    test('Soft delete animal from active registry', () async {
      final animals = await repository.getAnimals();
      final target = animals.first;

      await repository.deleteAnimal(target.id);

      final activeList = await repository.getAnimals();
      expect(activeList.any((a) => a.id == target.id), isFalse);
    });

    test('Maharashtra breeds catalog returns authentic local breeds', () async {
      final allBreeds = await repository.getBreeds();
      expect(allBreeds.length, greaterThanOrEqualTo(10));

      final cattleBreeds = await repository.getBreeds(species: AnimalSpeciesEnum.cattle);
      expect(cattleBreeds.any((b) => b.name == 'Khillari'), isTrue);
      expect(cattleBreeds.any((b) => b.name == 'Dangi'), isTrue);
      expect(cattleBreeds.any((b) => b.name == 'Deoni'), isTrue);
    });

    test('Health timeline events and passport generation', () async {
      final animals = await repository.getAnimals();
      final target = animals.first;

      final event = HealthTimelineEvent(
        id: 'ev-test-1',
        animalId: target.id,
        eventType: 'vaccination',
        description: 'Lumpy Skin Disease (LSD) booster dose',
        recordedBy: 'Dr. Deshmukh',
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await repository.addHealthEvent(target.id, event);
      final events = await repository.getHealthEvents(target.id);
      expect(events.any((e) => e.description.contains('Lumpy Skin')), isTrue);

      final passport = await repository.getAnimalPassport(target.id);
      expect(passport.tagId, target.tagId);
      expect(passport.verificationHash.length, 16);
      expect(passport.healthEventsCount, greaterThanOrEqualTo(1));
    });
  });
}
