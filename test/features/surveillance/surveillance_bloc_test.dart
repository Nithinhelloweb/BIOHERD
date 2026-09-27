import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/surveillance/bloc/surveillance_bloc.dart';
import 'package:bioherd/features/surveillance/data/surveillance_repository.dart';
import 'package:bioherd/features/surveillance/models/surveillance_model.dart';

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

    test('SetSimulationSpeedEvent updates simulation speed and service multiplier', () async {
      bloc.add(const SetSimulationSpeedEvent(2.0));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.simulationSpeed, 2.0);
    });

    test('ToggleAutoPatrolEvent toggles auto-patrol mode', () async {
      expect(bloc.state.autoPatrolEnabled, isFalse);

      bloc.add(const ToggleAutoPatrolEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.autoPatrolEnabled, isTrue);

      bloc.add(const ToggleAutoPatrolEvent());
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.autoPatrolEnabled, isFalse);
    });

    test('SelectTransitVehicleEvent sets and clears active transit vehicle', () async {
      bloc.add(const LoadSurveillanceDataEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final testVehicle = LivestockTransitVehicle(
        id: 'truck-test-1',
        licensePlate: 'MH-12-TEST',
        carrierName: 'Kisan Logistics Test',
        originDistrict: 'Pune',
        destinationDistrict: 'Solapur',
        originLat: 18.5204,
        originLon: 73.8567,
        destLat: 17.6599,
        destLon: 75.9064,
        currentLat: 18.1,
        currentLon: 74.5,
        progress: 0.35,
        speedKmH: 45.0,
        animalHeadCount: 40,
        species: 'Bovine',
        biosecurityStatus: 'Clear',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 98765 43210',
        dispatchedAt: DateTime.now(),
      );

      bloc.add(SelectTransitVehicleEvent(testVehicle));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.selectedVehicle?.id, 'truck-test-1');

      bloc.add(const SelectTransitVehicleEvent(null));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.selectedVehicle, isNull);
    });

    test('ToggleSurveillanceLayerEvent toggles layer visibility set', () async {
      expect(bloc.state.visibleLayers.contains('heatmap'), isTrue);

      bloc.add(const ToggleSurveillanceLayerEvent('heatmap'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.visibleLayers.contains('heatmap'), isFalse);

      bloc.add(const ToggleSurveillanceLayerEvent('heatmap'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.visibleLayers.contains('heatmap'), isTrue);
    });

    test('TriggerMockOutbreakEvent triggers outbreak spike and updates district state', () async {
      bloc.add(const LoadSurveillanceDataEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const TriggerMockOutbreakEvent(
        'dist-kolhapur',
        disease: 'Lumpy Skin Disease (LSD)',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      final target = bloc.state.districts.firstWhere((d) => d.districtId == 'dist-kolhapur');
      expect(target.riskScore, greaterThan(70.0));
      expect(bloc.state.telemetryLogs.isNotEmpty, isTrue);
    });
  });
}
