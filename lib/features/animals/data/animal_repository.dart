import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';

abstract class AnimalRepository {
  Future<List<Animal>> getAnimals({AnimalSpeciesEnum? species, String? searchQuery});
  Future<Animal> registerAnimal(Animal animal);
  Future<Animal> updateAnimal(Animal animal);
  Future<void> deleteAnimal(String animalId);
  Future<Animal?> lookupByTag(String tagId);
  Future<List<Breed>> getBreeds({AnimalSpeciesEnum? species});
  Future<List<HealthTimelineEvent>> getHealthEvents(String animalId);
  Future<HealthTimelineEvent> addHealthEvent(String animalId, HealthTimelineEvent event);
  Future<AnimalPassport> getAnimalPassport(String animalId);
  Future<int> getPendingSyncCount();
}

class OfflineFirstAnimalRepository implements AnimalRepository {
  static const String _animalsCacheKey = 'bioherd_cached_animals';
  static const String _eventsCacheKey = 'bioherd_cached_events';
  static const String _pendingSyncKey = 'bioherd_pending_animal_syncs';

  final SharedPreferences _prefs;

  OfflineFirstAnimalRepository(this._prefs);

  static Future<OfflineFirstAnimalRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = OfflineFirstAnimalRepository(prefs);
    await repo._ensureInitialDataSeeded();
    return repo;
  }

  Future<void> _ensureInitialDataSeeded() async {
    final existingData = _prefs.getString(_animalsCacheKey);
    if (existingData == null || existingData.isEmpty) {
      final initialAnimals = [
        Animal(
          id: 'anim-gir-001',
          farmId: 'farm-shinde-01',
          species: AnimalSpeciesEnum.cattle,
          breed: 'Gir',
          sex: 'female',
          dob: DateTime.now().subtract(const Duration(days: 1095)), // 3 years
          weightKg: 425.0,
          tagId: 'MH-PUN-GIR-104',
          qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-PUN-GIR-104&id=anim-gir-001&v=7A2F8B9C1E3D5A4F',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          healthStatus: HealthStatus.healthy,
          lastCheckDate: '2 weeks ago',
          notes: 'High yield A2 milk, vaccinated for FMD and Lumpy Skin Disease.',
        ),
        Animal(
          id: 'anim-khl-002',
          farmId: 'farm-patil-02',
          species: AnimalSpeciesEnum.cattle,
          breed: 'Khillari',
          sex: 'male',
          dob: DateTime.now().subtract(const Duration(days: 1460)), // 4 years
          weightKg: 490.5,
          tagId: 'MH-SOL-KHL-201',
          qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-SOL-KHL-201&id=anim-khl-002&v=3E9D2C8A7B6F1C4E',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          healthStatus: HealthStatus.healthy,
          lastCheckDate: '1 month ago',
          notes: 'Champion draught bull, Solapur breed certificate verified.',
        ),
        Animal(
          id: 'anim-pnd-003',
          farmId: 'farm-kol-03',
          species: AnimalSpeciesEnum.buffalo,
          breed: 'Pandharpuri',
          sex: 'female',
          dob: DateTime.now().subtract(const Duration(days: 1825)), // 5 years
          weightKg: 535.0,
          tagId: 'MH-KOL-PND-305',
          qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-KOL-PND-305&id=anim-pnd-003&v=9B1E4D6F8A2C7E3A',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          healthStatus: HealthStatus.healthy,
          lastCheckDate: '3 weeks ago',
          notes: 'Butterfat 8.2%, twisted horns, Bhima basin native.',
        ),
        Animal(
          id: 'anim-osm-004',
          farmId: 'farm-dharashiv-04',
          species: AnimalSpeciesEnum.goat,
          breed: 'Osmanabadi',
          sex: 'female',
          dob: DateTime.now().subtract(const Duration(days: 420)), // 14 months
          weightKg: 36.5,
          tagId: 'MH-OSM-OSM-402',
          qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-OSM-OSM-402&id=anim-osm-004&v=5C8A1D3F9E7B2F6E',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          healthStatus: HealthStatus.underObservation,
          lastCheckDate: 'Yesterday',
          notes: 'Mild hoof irritation after heavy rainfall; antiseptic spray applied.',
        ),
        Animal(
          id: 'anim-kdk-005',
          farmId: 'farm-nan-05',
          species: AnimalSpeciesEnum.poultry,
          breed: 'Kadaknath',
          sex: 'female',
          dob: DateTime.now().subtract(const Duration(days: 240)), // 8 months
          weightKg: 1.85,
          tagId: 'MH-NAN-KDK-501',
          qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-NAN-KDK-501&id=anim-kdk-005&v=2F7C9E1B4A6D8F3A',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          healthStatus: HealthStatus.healthy,
          lastCheckDate: '5 days ago',
          notes: 'Pure black plumage, Ranikhet (Newcastle) vaccinated.',
        ),
        Animal(
          id: 'anim-dng-006',
          farmId: 'farm-nsk-06',
          species: AnimalSpeciesEnum.cattle,
          breed: 'Dangi',
          sex: 'female',
          dob: DateTime.now().subtract(const Duration(days: 730)), // 2 years
          weightKg: 345.0,
          tagId: 'MH-NSK-DNG-608',
          qrCodeUrl: 'https://bioherd.gov.in/verify?tag=MH-NSK-DNG-608&id=anim-dng-006&v=8E3A7C1F2B9D4E6A',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          healthStatus: HealthStatus.healthy,
          lastCheckDate: '10 days ago',
          notes: 'Western Ghats hardy breed, black speckled on white.',
        ),
      ];

      final raw = jsonEncode(initialAnimals.map((a) => a.toJson()).toList());
      await _prefs.setString(_animalsCacheKey, raw);

      // Seed initial health events
      final initialEvents = {
        'anim-gir-001': [
          HealthTimelineEvent(
            id: 'ev-01',
            animalId: 'anim-gir-001',
            eventType: 'vaccination',
            description: 'Foot and Mouth Disease (FMD) Bi-annual vaccination administered.',
            recordedBy: 'Dr. Ramesh Kulkarni (LDO Pune)',
            occurredAt: DateTime.now().subtract(const Duration(days: 90)),
            createdAt: DateTime.now().subtract(const Duration(days: 90)),
          ),
          HealthTimelineEvent(
            id: 'ev-02',
            animalId: 'anim-gir-001',
            eventType: 'routine_checkup',
            description: 'Routine lactation health examination; body temperature 38.6°C normal.',
            recordedBy: 'Dr. Ramesh Kulkarni (LDO Pune)',
            occurredAt: DateTime.now().subtract(const Duration(days: 14)),
            createdAt: DateTime.now().subtract(const Duration(days: 14)),
          ),
        ],
        'anim-osm-004': [
          HealthTimelineEvent(
            id: 'ev-03',
            animalId: 'anim-osm-004',
            eventType: 'routine_checkup',
            description: 'Left rear hoof inspected; mild moisture irritation, dry bedding recommended.',
            recordedBy: 'Dr. Anjali Patil (Dharashiv)',
            occurredAt: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      };

      await _prefs.setString(_eventsCacheKey, jsonEncode(initialEvents.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
    }
  }

  @override
  Future<List<Animal>> getAnimals({AnimalSpeciesEnum? species, String? searchQuery}) async {
    final raw = _prefs.getString(_animalsCacheKey);
    if (raw == null || raw.isEmpty) return [];

    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .where((a) => a.isActive)
        .toList();

    return list.where((a) {
      if (species != null && a.species != species) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchesTag = a.tagId.toLowerCase().contains(q);
        final matchesBreed = a.breed.toLowerCase().contains(q);
        final matchesNotes = a.notes?.toLowerCase().contains(q) ?? false;
        return matchesTag || matchesBreed || matchesNotes;
      }
      return true;
    }).toList();
  }

  @override
  Future<Animal> registerAnimal(Animal animal) async {
    final raw = _prefs.getString(_animalsCacheKey);
    final animals = raw != null && raw.isNotEmpty
        ? (jsonDecode(raw) as List<dynamic>)
            .map((e) => Animal.fromJson(e as Map<String, dynamic>))
            .toList()
        : <Animal>[];

    // Check duplicate tag
    final dup = animals.any((a) => a.tagId.toUpperCase() == animal.tagId.toUpperCase());
    if (dup) {
      throw Exception('Ear tag ${animal.tagId} is already registered in the system.');
    }

    final newAnimal = animal.copyWith(
      qrCodeUrl: animal.qrCodeUrl ??
          'https://bioherd.gov.in/verify?tag=${animal.tagId}&id=${animal.id}&v=${animal.tagId.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );

    animals.insert(0, newAnimal);
    await _prefs.setString(_animalsCacheKey, jsonEncode(animals.map((a) => a.toJson()).toList()));

    // Record registration health event
    await addHealthEvent(
      newAnimal.id,
      HealthTimelineEvent(
        id: 'ev-reg-${DateTime.now().millisecondsSinceEpoch}',
        animalId: newAnimal.id,
        eventType: 'routine_checkup',
        description: 'Livestock registered into BIOHERD state registry; ear tag tag ID ${newAnimal.tagId} affixed.',
        recordedBy: 'BIOHERD Field Officer',
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    // Increment pending sync count for offline sync queue
    final pending = _prefs.getInt(_pendingSyncKey) ?? 0;
    await _prefs.setInt(_pendingSyncKey, pending + 1);

    return newAnimal;
  }

  @override
  Future<Animal> updateAnimal(Animal animal) async {
    final raw = _prefs.getString(_animalsCacheKey);
    if (raw == null) throw Exception('Animal registry is empty');

    final animals = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .toList();

    final idx = animals.indexWhere((a) => a.id == animal.id);
    if (idx == -1) throw Exception('Animal ${animal.id} not found');

    animals[idx] = animal;
    await _prefs.setString(_animalsCacheKey, jsonEncode(animals.map((a) => a.toJson()).toList()));
    return animal;
  }

  @override
  Future<void> deleteAnimal(String animalId) async {
    final raw = _prefs.getString(_animalsCacheKey);
    if (raw == null) return;

    final animals = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .toList();

    final idx = animals.indexWhere((a) => a.id == animalId);
    if (idx != -1) {
      // Soft-delete
      animals[idx] = animals[idx].copyWith(isActive: false);
      await _prefs.setString(_animalsCacheKey, jsonEncode(animals.map((a) => a.toJson()).toList()));
    }
  }

  @override
  Future<Animal?> lookupByTag(String tagId) async {
    final raw = _prefs.getString(_animalsCacheKey);
    if (raw == null || raw.isEmpty) return null;

    final animals = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .toList();

    final cleanTag = tagId.trim().toUpperCase();
    try {
      return animals.firstWhere(
        (a) => a.tagId.toUpperCase() == cleanTag && a.isActive,
      );
    } catch (_) {
      // Fallback to substring matching if exact match not found
      try {
        return animals.firstWhere(
          (a) => a.tagId.toUpperCase().contains(cleanTag) && a.isActive,
        );
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<List<Breed>> getBreeds({AnimalSpeciesEnum? species}) async {
    // 18 authentic Maharashtra indigenous breeds
    const List<Breed> allBreeds = [
      // Cattle
      Breed(
        name: 'Khillari',
        nameMr: 'Khillari',
        species: AnimalSpeciesEnum.cattle,
        originRegion: 'Solapur / Western Maharashtra',
        districts: ['Solapur', 'Sangli', 'Kolhapur', 'Satara'],
        description: 'Hardy grey-white draught breed with high heat resilience.',
        descriptionMr: 'Hardy drought-resilient cattle breed.',
      ),
      Breed(
        name: 'Dangi',
        nameMr: 'Dangi',
        species: AnimalSpeciesEnum.cattle,
        originRegion: 'Western Ghats / Sahyadri Foothills',
        districts: ['Nashik', 'Ahmednagar', 'Thane'],
        description: 'Oiled skin secretes protection against extreme monsoon rainfall.',
        descriptionMr: 'Oiled skin breed resilient to heavy monsoon rain.',
      ),
      Breed(
        name: 'Deoni',
        nameMr: 'Deoni',
        species: AnimalSpeciesEnum.cattle,
        originRegion: 'Marathwada',
        districts: ['Latur', 'Nanded', 'Dharashiv'],
        description: 'Prized dual purpose breed, black and white spotted.',
        descriptionMr: 'Dual purpose spotted cattle breed from Marathwada.',
      ),
      Breed(
        name: 'Gaolao',
        nameMr: 'Gaolao',
        species: AnimalSpeciesEnum.cattle,
        originRegion: 'Vidarbha',
        districts: ['Wardha', 'Nagpur', 'Amravati'],
        description: 'Fast-trotting draught breed with convex forehead.',
        descriptionMr: 'Fast-trotting draught breed from Vidarbha.',
      ),
      Breed(
        name: 'Gir',
        nameMr: 'Gir',
        species: AnimalSpeciesEnum.cattle,
        originRegion: 'Western Maharashtra Dairy Belt',
        districts: ['Pune', 'Kolhapur', 'Sangli'],
        description: 'High-yield A2 milk breed with pendulous ears.',
        descriptionMr: 'High-yield A2 dairy breed.',
      ),
      Breed(
        name: 'Red Kandhari',
        nameMr: 'Red Kandhari',
        species: AnimalSpeciesEnum.cattle,
        originRegion: 'Marathwada',
        districts: ['Nanded', 'Latur', 'Hingoli'],
        description: 'Uniform dark red, compact and muscular.',
        descriptionMr: 'Compact, muscular dark red cattle breed.',
      ),

      // Buffalo
      Breed(
        name: 'Pandharpuri',
        nameMr: 'Pandharpuri',
        species: AnimalSpeciesEnum.buffalo,
        originRegion: 'Bhima River Basin',
        districts: ['Solapur', 'Kolhapur', 'Sangli'],
        description: 'Long sword-shaped horns reaching back to shoulders, high butterfat.',
        descriptionMr: 'Long sword-horned buffalo breed with high butterfat milk.',
      ),
      Breed(
        name: 'Nagpuri',
        nameMr: 'Nagpuri',
        species: AnimalSpeciesEnum.buffalo,
        originRegion: 'Eastern Vidarbha',
        districts: ['Nagpur', 'Wardha', 'Chandrapur'],
        description: 'Flat swept-back horns, well suited to Vidarbha climate.',
        descriptionMr: 'Hardy buffalo suited to Vidarbha climate.',
      ),
      Breed(
        name: 'Murrah',
        nameMr: 'Murrah',
        species: AnimalSpeciesEnum.buffalo,
        originRegion: 'Dairy Cooperatives',
        districts: ['Pune', 'Kolhapur', 'Nashik'],
        description: 'Jet black coat, curled horns, highest milk production.',
        descriptionMr: 'Curled horns high milk-yield dairy buffalo.',
      ),
      Breed(
        name: 'Marathwadi',
        nameMr: 'Marathwadi',
        species: AnimalSpeciesEnum.buffalo,
        originRegion: 'Marathwada',
        districts: ['Beed', 'Parbhani', 'Jalna'],
        description: 'Drought-tolerant, low fodder requirement.',
        descriptionMr: 'Drought-tolerant, low-fodder buffalo breed.',
      ),

      // Goat
      Breed(
        name: 'Osmanabadi',
        nameMr: 'Osmanabadi',
        species: AnimalSpeciesEnum.goat,
        originRegion: 'Dharashiv / Marathwada',
        districts: ['Dharashiv', 'Latur', 'Solapur'],
        description: 'Black coat, twin kidding rate >60%, disease resistant.',
        descriptionMr: 'High twinning rate hardy black goat breed.',
      ),
      Breed(
        name: 'Sangamneri',
        nameMr: 'Sangamneri',
        species: AnimalSpeciesEnum.goat,
        originRegion: 'Ahmednagar',
        districts: ['Ahmednagar', 'Pune', 'Nashik'],
        description: 'Prized dual purpose milk and meat goat.',
        descriptionMr: 'Dual purpose milk and meat goat.',
      ),
      Breed(
        name: 'Konkan Kanyal',
        nameMr: 'Konkan Kanyal',
        species: AnimalSpeciesEnum.goat,
        originRegion: 'Konkan Coastal Belt',
        districts: ['Sindhudurg', 'Ratnagiri', 'Raigad'],
        description: 'Bronze coat with white face stripes, humidity-hardy.',
        descriptionMr: 'Humidity-hardy coastal goat breed.',
      ),

      // Sheep
      Breed(
        name: 'Deccani',
        nameMr: 'Deccani',
        species: AnimalSpeciesEnum.sheep,
        originRegion: 'Deccan Plateau',
        districts: ['Pune', 'Solapur', 'Satara'],
        description: 'Hardy coarse-wool sheep, well-adapted to pastoral migration.',
        descriptionMr: 'Hardy coarse-wool pastoral sheep.',
      ),
      Breed(
        name: 'Madgyal',
        nameMr: 'Madgyal',
        species: AnimalSpeciesEnum.sheep,
        originRegion: 'Southern Maharashtra',
        districts: ['Sangli', 'Solapur'],
        description: 'Roman nose, heavy meat conformation.',
        descriptionMr: 'Roman-nosed heavy meat sheep breed.',
      ),

      // Poultry
      Breed(
        name: 'Kadaknath',
        nameMr: 'Kadaknath',
        species: AnimalSpeciesEnum.poultry,
        originRegion: 'Satpura foothills / Maharashtra',
        districts: ['Nandurbar', 'Dhule', 'Pune'],
        description: 'Black feathers, bone, and meat; high protein, medicinal.',
        descriptionMr: 'Black meat and bone high-protein poultry breed.',
      ),
      Breed(
        name: 'Aseel',
        nameMr: 'Aseel',
        species: AnimalSpeciesEnum.poultry,
        originRegion: 'Rural Maharashtra',
        districts: ['Kolhapur', 'Satara', 'Nagpur'],
        description: 'Muscular, majestic stance, superior natural disease immunity.',
        descriptionMr: 'Muscular indigenous gamefowl with high natural immunity.',
      ),
    ];

    if (species != null) {
      return allBreeds.where((b) => b.species == species).toList();
    }
    return allBreeds;
  }

  @override
  Future<List<HealthTimelineEvent>> getHealthEvents(String animalId) async {
    final raw = _prefs.getString(_eventsCacheKey);
    if (raw == null || raw.isEmpty) return [];

    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (!map.containsKey(animalId)) return [];

    final list = (map[animalId] as List<dynamic>)
        .map((e) => HealthTimelineEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  @override
  Future<HealthTimelineEvent> addHealthEvent(String animalId, HealthTimelineEvent event) async {
    final raw = _prefs.getString(_eventsCacheKey);
    final map = raw != null && raw.isNotEmpty
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : <String, dynamic>{};

    final list = map.containsKey(animalId)
        ? (map[animalId] as List<dynamic>)
            .map((e) => HealthTimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList()
        : <HealthTimelineEvent>[];

    list.insert(0, event);
    map[animalId] = list.map((e) => e.toJson()).toList();
    await _prefs.setString(_eventsCacheKey, jsonEncode(map));

    return event;
  }

  @override
  Future<AnimalPassport> getAnimalPassport(String animalId) async {
    final animals = await getAnimals();
    final animal = animals.firstWhere(
      (a) => a.id == animalId,
      orElse: () => throw Exception('Animal $animalId not found'),
    );

    final events = await getHealthEvents(animalId);
    final vacCount = events.where((e) => e.eventType == 'vaccination').length;
    final hash = (animal.tagId.hashCode ^ animal.id.hashCode).abs().toRadixString(16).padLeft(16, '0').toUpperCase();

    return AnimalPassport(
      animalId: animal.id,
      tagId: animal.tagId,
      species: animal.species.displayName,
      breed: animal.breed,
      sex: animal.sex,
      weightKg: animal.weightKg,
      dob: animal.dob,
      ageMonths: animal.ageInMonths,
      farmId: animal.farmId,
      farmName: 'Shinde Dairy & Livestock Farm',
      districtName: 'Pune, Maharashtra',
      ownerName: 'Vitthal Shinde',
      ownerPhone: '+91 98765 00001',
      qrCodeUrl: animal.qrCodeUrl,
      isActive: animal.isActive,
      registeredAt: animal.createdAt,
      healthEventsCount: events.length,
      vaccinationsCount: vacCount,
      recentEvents: events.take(5).toList(),
      verificationHash: hash,
    );
  }

  @override
  Future<int> getPendingSyncCount() async {
    return _prefs.getInt(_pendingSyncKey) ?? 0;
  }
}
