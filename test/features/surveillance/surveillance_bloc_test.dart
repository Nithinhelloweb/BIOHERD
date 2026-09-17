import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/surveillance/bloc/surveillance_bloc.dart';
import 'package:bioherd/features/surveillance/data/surveillance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSurveillanceRepository repository;
  late SurveillanceBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstSurveillanceRepository.create();
    bloc = SurveillanceBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SurveillanceBloc Tests', () {
    test('Initial state has isLoading: true', () {
      expect(bloc.state.isLoading, isTrue);
      expect(bloc.state.districts.isEmpty, isTrue);
    });

    test('LoadSurveillanceDataEvent emits state with districts and clusters', () async {
      bloc.add(const LoadSurveillanceDataEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<SurveillanceState>((s) => s.isLoading == true),
          predicate<SurveillanceState>((s) =>
              s.isLoading == false &&
              s.districts.length >= 8 &&
              s.clusters.isNotEmpty &&
              s.alerts.isNotEmpty),
        ]),
      );

      final currentState = bloc.state;
      expect(currentState.selectedDiseaseFilter, 'All');
      expect(currentState.totalActiveCases, greaterThan(0));
    });

    test('FilterByDiseaseEvent updates active filter and clusters', () async {
      bloc.add(const LoadSurveillanceDataEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const FilterByDiseaseEvent('Foot and Mouth Disease (FMD)'));
      await Future.delayed(const Duration(milliseconds: 50));

      final state = bloc.state;
      expect(state.selectedDiseaseFilter, 'Foot and Mouth Disease (FMD)');
      expect(state.filteredClusters.every((c) => c.diseaseName.contains('FMD') || c.diseaseName.contains('Foot')), isTrue);
    });

    test('SelectClusterEvent and SelectDistrictEvent update selected items', () async {
      bloc.add(const LoadSurveillanceDataEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final stateBefore = bloc.state;
      final targetCluster = stateBefore.clusters.first;
      final targetDistrict = stateBefore.districts.first;

      bloc.add(SelectClusterEvent(targetCluster));
      await Future.delayed(const Duration(milliseconds: 20));

      var stateNow = bloc.state;
      expect(stateNow.selectedCluster?.id, targetCluster.id);

      bloc.add(SelectDistrictEvent(targetDistrict));
      await Future.delayed(const Duration(milliseconds: 20));

      stateNow = bloc.state;
      expect(stateNow.selectedDistrict?.districtId, targetDistrict.districtId);
    });

    test('DeclareQuarantineEvent updates cluster quarantine status in state', () async {
      bloc.add(const LoadSurveillanceDataEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final stateBefore = bloc.state;
      final nonQuarantined = stateBefore.clusters.firstWhere((c) => !c.quarantineDeclared);

      bloc.add(DeclareQuarantineEvent(nonQuarantined.id));
      await Future.delayed(const Duration(milliseconds: 100));

      final stateAfter = bloc.state;
      final updated = stateAfter.clusters.firstWhere((c) => c.id == nonQuarantined.id);
      expect(updated.quarantineDeclared, isTrue);
    });
  });
}
