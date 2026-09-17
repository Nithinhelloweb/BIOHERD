import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/data/animal_repository.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstAnimalRepository repository;
  late AnimalBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstAnimalRepository.create();
    bloc = AnimalBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AnimalBloc Tests', () {
    test('Initial state is AnimalInitial', () {
      expect(bloc.state, isA<AnimalInitial>());
    });

    test('LoadAnimalsEvent loads all animals and calculates stats correctly', () async {
      bloc.add(const LoadAnimalsEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AnimalLoading>(),
          predicate<AnimalLoaded>((state) {
            return state.allAnimals.length >= 5 &&
                state.filteredAnimals.length >= 5 &&
                state.stats.total >= 5 &&
                state.stats.healthy >= 1 &&
                state.breeds.isNotEmpty;
          }),
        ]),
      );
    });

    test('FilterAnimalsEvent filters by species', () async {
      bloc.add(const LoadAnimalsEvent());
      await bloc.stream.firstWhere((s) => s is AnimalLoaded);

      bloc.add(const FilterAnimalsEvent(species: AnimalSpeciesEnum.goat));

      await expectLater(
        bloc.stream,
        emits(
          predicate<AnimalLoaded>((state) {
            return state.selectedSpecies == AnimalSpeciesEnum.goat &&
                state.filteredAnimals.length == 1 &&
                state.filteredAnimals.first.breed == 'Osmanabadi';
          }),
        ),
      );
    });

    test('LookupTagEvent emits updated state with lookedUpAnimal', () async {
      bloc.add(const LoadAnimalsEvent());
      await bloc.stream.firstWhere((s) => s is AnimalLoaded);

      bloc.add(const LookupTagEvent('MH-PUN-GIR-104'));

      await expectLater(
        bloc.stream,
        emits(
          predicate<AnimalLoaded>((state) {
            return state.lookedUpAnimal != null && state.lookedUpAnimal!.tagId == 'MH-PUN-GIR-104';
          }),
        ),
      );
    });

    test('LookupTagEvent for non-existent tag emits AnimalError', () async {
      bloc.add(const LoadAnimalsEvent());
      await bloc.stream.firstWhere((s) => s is AnimalLoaded);

      bloc.add(const LookupTagEvent('INVALID-TAG-999'));

      await expectLater(
        bloc.stream,
        emits(isA<AnimalError>()),
      );
    });
  });
}
