import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bioherd/features/animals/data/animal_repository.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';

// --- Events ---
abstract class AnimalEvent {
  const AnimalEvent();
}

class LoadAnimalsEvent extends AnimalEvent {
  final AnimalSpeciesEnum? species;
  final String? searchQuery;
  const LoadAnimalsEvent({this.species, this.searchQuery});
}

class FilterAnimalsEvent extends AnimalEvent {
  final AnimalSpeciesEnum? species;
  final String? searchQuery;
  const FilterAnimalsEvent({this.species, this.searchQuery});
}

class RegisterAnimalEvent extends AnimalEvent {
  final Animal animal;
  const RegisterAnimalEvent(this.animal);
}

class UpdateAnimalEvent extends AnimalEvent {
  final Animal animal;
  const UpdateAnimalEvent(this.animal);
}

class DeleteAnimalEvent extends AnimalEvent {
  final String animalId;
  const DeleteAnimalEvent(this.animalId);
}

class LookupTagEvent extends AnimalEvent {
  final String tagId;
  const LookupTagEvent(this.tagId);
}

class ClearLookupTagEvent extends AnimalEvent {
  const ClearLookupTagEvent();
}

class AddHealthEventRecord extends AnimalEvent {
  final String animalId;
  final HealthTimelineEvent event;
  const AddHealthEventRecord(this.animalId, this.event);
}

class LoadPassportEvent extends AnimalEvent {
  final String animalId;
  const LoadPassportEvent(this.animalId);
}

// --- Stats helper ---
class AnimalStats {
  final int total;
  final int healthy;
  final int underObservation;
  final int sick;

  const AnimalStats({
    required this.total,
    required this.healthy,
    required this.underObservation,
    required this.sick,
  });

  factory AnimalStats.fromList(List<Animal> animals) {
    int h = 0;
    int o = 0;
    int s = 0;
    for (final a in animals) {
      if (!a.isActive) continue;
      switch (a.healthStatus) {
        case HealthStatus.healthy:
          h++;
          break;
        case HealthStatus.underObservation:
          o++;
          break;
        case HealthStatus.quarantined:
        case HealthStatus.sick:
          s++;
          break;
      }
    }
    return AnimalStats(
      total: animals.where((a) => a.isActive).length,
      healthy: h,
      underObservation: o,
      sick: s,
    );
  }
}

// --- States ---
abstract class AnimalState {
  const AnimalState();
}

class AnimalInitial extends AnimalState {
  const AnimalInitial();
}

class AnimalLoading extends AnimalState {
  const AnimalLoading();
}

class AnimalLoaded extends AnimalState {
  final List<Animal> allAnimals;
  final List<Animal> filteredAnimals;
  final AnimalSpeciesEnum? selectedSpecies;
  final String searchQuery;
  final List<Breed> breeds;
  final AnimalStats stats;
  final int pendingSyncCount;
  final Animal? lookedUpAnimal;
  final AnimalPassport? passport;

  const AnimalLoaded({
    required this.allAnimals,
    required this.filteredAnimals,
    this.selectedSpecies,
    this.searchQuery = '',
    required this.breeds,
    required this.stats,
    this.pendingSyncCount = 0,
    this.lookedUpAnimal,
    this.passport,
  });

  AnimalLoaded copyWith({
    List<Animal>? allAnimals,
    List<Animal>? filteredAnimals,
    AnimalSpeciesEnum? selectedSpecies,
    bool clearSpecies = false,
    String? searchQuery,
    List<Breed>? breeds,
    AnimalStats? stats,
    int? pendingSyncCount,
    Animal? lookedUpAnimal,
    bool clearLookedUpAnimal = false,
    AnimalPassport? passport,
  }) {
    return AnimalLoaded(
      allAnimals: allAnimals ?? this.allAnimals,
      filteredAnimals: filteredAnimals ?? this.filteredAnimals,
      selectedSpecies: clearSpecies ? null : (selectedSpecies ?? this.selectedSpecies),
      searchQuery: searchQuery ?? this.searchQuery,
      breeds: breeds ?? this.breeds,
      stats: stats ?? this.stats,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      lookedUpAnimal: clearLookedUpAnimal ? null : (lookedUpAnimal ?? this.lookedUpAnimal),
      passport: passport ?? this.passport,
    );
  }
}

class AnimalOperationSuccess extends AnimalState {
  final String message;
  final Animal? animal;
  const AnimalOperationSuccess(this.message, {this.animal});
}

class AnimalError extends AnimalState {
  final String message;
  const AnimalError(this.message);
}

// --- BLoC ---
class AnimalBloc extends Bloc<AnimalEvent, AnimalState> {
  final AnimalRepository repository;

  AnimalBloc({required this.repository}) : super(const AnimalInitial()) {
    on<LoadAnimalsEvent>(_onLoadAnimals);
    on<FilterAnimalsEvent>(_onFilterAnimals);
    on<RegisterAnimalEvent>(_onRegisterAnimal);
    on<UpdateAnimalEvent>(_onUpdateAnimal);
    on<DeleteAnimalEvent>(_onDeleteAnimal);
    on<LookupTagEvent>(_onLookupTag);
    on<ClearLookupTagEvent>(_onClearLookupTag);
    on<AddHealthEventRecord>(_onAddHealthEvent);
    on<LoadPassportEvent>(_onLoadPassport);
  }

  Future<void> _onLoadAnimals(LoadAnimalsEvent event, Emitter<AnimalState> emit) async {
    emit(const AnimalLoading());
    try {
      final all = await repository.getAnimals();
      final breeds = await repository.getBreeds();
      final syncCount = await repository.getPendingSyncCount();

      final filtered = _applyFilter(all, event.species, event.searchQuery);
      final stats = AnimalStats.fromList(all);

      emit(AnimalLoaded(
        allAnimals: all,
        filteredAnimals: filtered,
        selectedSpecies: event.species,
        searchQuery: event.searchQuery ?? '',
        breeds: breeds,
        stats: stats,
        pendingSyncCount: syncCount,
      ));
    } catch (e) {
      emit(AnimalError('Failed to load animals: $e'));
    }
  }

  void _onFilterAnimals(FilterAnimalsEvent event, Emitter<AnimalState> emit) {
    if (state is AnimalLoaded) {
      final cur = state as AnimalLoaded;
      final filtered = _applyFilter(cur.allAnimals, event.species, event.searchQuery ?? cur.searchQuery);
      emit(cur.copyWith(
        filteredAnimals: filtered,
        selectedSpecies: event.species,
        clearSpecies: event.species == null,
        searchQuery: event.searchQuery ?? cur.searchQuery,
      ));
    }
  }

  List<Animal> _applyFilter(List<Animal> list, AnimalSpeciesEnum? species, String? query) {
    return list.where((a) {
      if (species != null && a.species != species) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchesTag = a.tagId.toLowerCase().contains(q);
        final matchesBreed = a.breed.toLowerCase().contains(q);
        final matchesNotes = a.notes?.toLowerCase().contains(q) ?? false;
        return matchesTag || matchesBreed || matchesNotes;
      }
      return true;
    }).toList();
  }

  Future<void> _onRegisterAnimal(RegisterAnimalEvent event, Emitter<AnimalState> emit) async {
    try {
      final registered = await repository.registerAnimal(event.animal);
      emit(AnimalOperationSuccess('Successfully registered ${registered.tagId}', animal: registered));
      add(const LoadAnimalsEvent());
    } catch (e) {
      emit(AnimalError('Registration failed: $e'));
    }
  }

  Future<void> _onUpdateAnimal(UpdateAnimalEvent event, Emitter<AnimalState> emit) async {
    try {
      final updated = await repository.updateAnimal(event.animal);
      emit(AnimalOperationSuccess('Updated status for ${updated.tagId}', animal: updated));
      add(const LoadAnimalsEvent());
    } catch (e) {
      emit(AnimalError('Update failed: $e'));
    }
  }

  Future<void> _onDeleteAnimal(DeleteAnimalEvent event, Emitter<AnimalState> emit) async {
    try {
      await repository.deleteAnimal(event.animalId);
      emit(const AnimalOperationSuccess('Animal record removed'));
      add(const LoadAnimalsEvent());
    } catch (e) {
      emit(AnimalError('Deletion failed: $e'));
    }
  }

  Future<void> _onLookupTag(LookupTagEvent event, Emitter<AnimalState> emit) async {
    try {
      final found = await repository.lookupByTag(event.tagId);
      if (found == null) {
        emit(AnimalError('No active animal found with ear tag "${event.tagId}"'));
      } else {
        if (state is AnimalLoaded) {
          emit((state as AnimalLoaded).copyWith(lookedUpAnimal: found));
        } else {
          emit(AnimalOperationSuccess('Found animal ${found.tagId}', animal: found));
        }
      }
    } catch (e) {
      emit(AnimalError('Tag lookup error: $e'));
    }
  }

  void _onClearLookupTag(ClearLookupTagEvent event, Emitter<AnimalState> emit) {
    if (state is AnimalLoaded) {
      emit((state as AnimalLoaded).copyWith(clearLookedUpAnimal: true));
    }
  }

  Future<void> _onAddHealthEvent(AddHealthEventRecord event, Emitter<AnimalState> emit) async {
    try {
      await repository.addHealthEvent(event.animalId, event.event);
      emit(const AnimalOperationSuccess('Health event recorded on timeline'));
      add(const LoadAnimalsEvent());
    } catch (e) {
      emit(AnimalError('Failed to record health event: $e'));
    }
  }

  Future<void> _onLoadPassport(LoadPassportEvent event, Emitter<AnimalState> emit) async {
    try {
      final pass = await repository.getAnimalPassport(event.animalId);
      if (state is AnimalLoaded) {
        emit((state as AnimalLoaded).copyWith(passport: pass));
      }
    } catch (e) {
      emit(AnimalError('Failed to load passport: $e'));
    }
  }
}
