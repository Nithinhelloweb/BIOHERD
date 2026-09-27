import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/surveillance_repository.dart';
import '../models/surveillance_model.dart';
import '../services/heatmap_simulation_service.dart';

// ─── Events ─────────────────────────────────────────────────────

abstract class SurveillanceEvent {
  const SurveillanceEvent();
}

class LoadSurveillanceDataEvent extends SurveillanceEvent {
  const LoadSurveillanceDataEvent();
}

class FilterByDiseaseEvent extends SurveillanceEvent {
  final String disease;
  const FilterByDiseaseEvent(this.disease);
}

class SelectDistrictEvent extends SurveillanceEvent {
  final DistrictRiskModel? district;
  const SelectDistrictEvent(this.district);
}

class SelectClusterEvent extends SurveillanceEvent {
  final OutbreakClusterModel? cluster;
  const SelectClusterEvent(this.cluster);
}

class DeclareQuarantineEvent extends SurveillanceEvent {
  final String clusterId;
  const DeclareQuarantineEvent(this.clusterId);
}

class RefreshSurveillanceEvent extends SurveillanceEvent {
  const RefreshSurveillanceEvent();
}

/// Fired by the HeatmapSimulationService stream subscription.
class SimulationTickEvent extends SurveillanceEvent {
  final SimulationTickData tickData;
  const SimulationTickEvent(this.tickData);
}

class ToggleSimulationEvent extends SurveillanceEvent {
  const ToggleSimulationEvent();
}

class SetSimulationSpeedEvent extends SurveillanceEvent {
  final double speedMultiplier;
  const SetSimulationSpeedEvent(this.speedMultiplier);
}

class TriggerMockOutbreakEvent extends SurveillanceEvent {
  final String districtId;
  final String disease;
  const TriggerMockOutbreakEvent(this.districtId, {this.disease = 'Foot and Mouth Disease (FMD)'});
}

class ToggleAutoPatrolEvent extends SurveillanceEvent {
  const ToggleAutoPatrolEvent();
}

class SelectTransitVehicleEvent extends SurveillanceEvent {
  final LivestockTransitVehicle? vehicle;
  const SelectTransitVehicleEvent(this.vehicle);
}

class ToggleSurveillanceLayerEvent extends SurveillanceEvent {
  final String layerId;
  const ToggleSurveillanceLayerEvent(this.layerId);
}

class ResetSimulationEvent extends SurveillanceEvent {
  const ResetSimulationEvent();
}

// ─── State ──────────────────────────────────────────────────────

class SurveillanceState {
  final bool isLoading;
  final List<DistrictRiskModel> districts;
  final List<OutbreakClusterModel> clusters;
  final List<SurveillanceAlertModel> alerts;
  final String selectedDiseaseFilter;
  final DistrictRiskModel? selectedDistrict;
  final OutbreakClusterModel? selectedCluster;
  final String? errorMessage;
  final bool simulationRunning;
  final double simulationSpeed;
  final bool autoPatrolEnabled;
  final List<LivestockTransitVehicle> transitVehicles;
  final LivestockTransitVehicle? selectedVehicle;
  final List<LiveSurveillanceLog> telemetryLogs;
  final Set<String> visibleLayers;
  final int totalTransitInterceptions;
  final int totalSimulationTicks;
  final double averageRiskIndex;
  final DateTime lastUpdated;

  SurveillanceState({
    this.isLoading = false,
    this.districts = const [],
    this.clusters = const [],
    this.alerts = const [],
    this.selectedDiseaseFilter = 'All',
    this.selectedDistrict,
    this.selectedCluster,
    this.errorMessage,
    this.simulationRunning = true,
    this.simulationSpeed = 1.0,
    this.autoPatrolEnabled = false,
    this.transitVehicles = const [],
    this.selectedVehicle,
    this.telemetryLogs = const [],
    this.visibleLayers = const {'heatmap', 'transit', 'clusters', 'districts', 'rings'},
    this.totalTransitInterceptions = 0,
    this.totalSimulationTicks = 0,
    this.averageRiskIndex = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  SurveillanceState copyWith({
    bool? isLoading,
    List<DistrictRiskModel>? districts,
    List<OutbreakClusterModel>? clusters,
    List<SurveillanceAlertModel>? alerts,
    String? selectedDiseaseFilter,
    DistrictRiskModel? selectedDistrict,
    bool clearSelectedDistrict = false,
    OutbreakClusterModel? selectedCluster,
    bool clearSelectedCluster = false,
    String? errorMessage,
    bool? simulationRunning,
    double? simulationSpeed,
    bool? autoPatrolEnabled,
    List<LivestockTransitVehicle>? transitVehicles,
    LivestockTransitVehicle? selectedVehicle,
    bool clearSelectedVehicle = false,
    List<LiveSurveillanceLog>? telemetryLogs,
    Set<String>? visibleLayers,
    int? totalTransitInterceptions,
    int? totalSimulationTicks,
    double? averageRiskIndex,
    DateTime? lastUpdated,
  }) {
    return SurveillanceState(
      isLoading: isLoading ?? this.isLoading,
      districts: districts ?? this.districts,
      clusters: clusters ?? this.clusters,
      alerts: alerts ?? this.alerts,
      selectedDiseaseFilter: selectedDiseaseFilter ?? this.selectedDiseaseFilter,
      selectedDistrict: clearSelectedDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
      selectedCluster: clearSelectedCluster ? null : (selectedCluster ?? this.selectedCluster),
      errorMessage: errorMessage,
      simulationRunning: simulationRunning ?? this.simulationRunning,
      simulationSpeed: simulationSpeed ?? this.simulationSpeed,
      autoPatrolEnabled: autoPatrolEnabled ?? this.autoPatrolEnabled,
      transitVehicles: transitVehicles ?? this.transitVehicles,
      selectedVehicle: clearSelectedVehicle ? null : (selectedVehicle ?? this.selectedVehicle),
      telemetryLogs: telemetryLogs ?? this.telemetryLogs,
      visibleLayers: visibleLayers ?? this.visibleLayers,
      totalTransitInterceptions: totalTransitInterceptions ?? this.totalTransitInterceptions,
      totalSimulationTicks: totalSimulationTicks ?? this.totalSimulationTicks,
      averageRiskIndex: averageRiskIndex ?? this.averageRiskIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  List<OutbreakClusterModel> get filteredClusters {
    if (selectedDiseaseFilter == 'All' || selectedDiseaseFilter.isEmpty) {
      return clusters;
    }
    return clusters
        .where((c) => c.diseaseName.toLowerCase().contains(selectedDiseaseFilter.toLowerCase()))
        .toList();
  }

  int get totalActiveCases => districts.fold(0, (sum, d) => sum + d.activeCases);
  int get activeQuarantineZonesCount => clusters.where((c) => c.quarantineDeclared).length;
  int get criticalDistrictCount => districts.where((d) => d.severity.name == 'critical').length;
  int get highRiskDistrictCount => districts.where((d) => d.severity.name == 'high').length;
}

// ─── BLoC ────────────────────────────────────────────────────────

class SurveillanceBloc extends Bloc<SurveillanceEvent, SurveillanceState> {
  final SurveillanceRepository repository;
  final HeatmapSimulationService _simulation;
  StreamSubscription<SimulationTickData>? _simulationSub;

  SurveillanceBloc({required this.repository})
      : _simulation = HeatmapSimulationService(
          updateInterval: const Duration(seconds: 2),
        ),
        super(SurveillanceState(isLoading: true)) {
    on<LoadSurveillanceDataEvent>(_onLoadData);
    on<FilterByDiseaseEvent>(_onFilterDisease);
    on<SelectDistrictEvent>(_onSelectDistrict);
    on<SelectClusterEvent>(_onSelectCluster);
    on<DeclareQuarantineEvent>(_onDeclareQuarantine);
    on<RefreshSurveillanceEvent>(_onRefreshData);
    on<SimulationTickEvent>(_onSimulationTick);
    on<ToggleSimulationEvent>(_onToggleSimulation);
    on<SetSimulationSpeedEvent>(_onSetSimulationSpeed);
    on<TriggerMockOutbreakEvent>(_onTriggerMockOutbreak);
    on<ToggleAutoPatrolEvent>(_onToggleAutoPatrol);
    on<SelectTransitVehicleEvent>(_onSelectTransitVehicle);
    on<ToggleSurveillanceLayerEvent>(_onToggleSurveillanceLayer);
    on<ResetSimulationEvent>(_onResetSimulation);
  }

  Future<void> _onLoadData(
    LoadSurveillanceDataEvent event,
    Emitter<SurveillanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final districts = await repository.getDistrictRiskRankings();
      final clusters = await repository.getActiveClusters();
      final alerts = await repository.getSurveillanceAlerts();

      emit(state.copyWith(
        isLoading: false,
        districts: districts,
        clusters: clusters,
        alerts: alerts,
        selectedCluster: clusters.isNotEmpty ? clusters.first : null,
        simulationRunning: true,
        lastUpdated: DateTime.now(),
      ));

      // Start real-time simulation after initial load
      _startSimulation(districts, clusters);
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _startSimulation(List<DistrictRiskModel> initialDistricts, List<OutbreakClusterModel> initialClusters) {
    _simulationSub?.cancel();
    _simulation.start(initialDistricts, initialClusters: initialClusters);

    _simulationSub = _simulation.tickStream.listen((tickData) {
      add(SimulationTickEvent(tickData));
    });
  }

  void _onSimulationTick(
    SimulationTickEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    final tick = event.tickData;
    // Update repo so getDistrictRiskRankings() returns fresh data
    if (repository is OfflineFirstSurveillanceRepository) {
      (repository as OfflineFirstSurveillanceRepository)
          .updateDistrictData(tick.districts);
    }

    final updatedAlerts = List<SurveillanceAlertModel>.from(state.alerts);
    for (final newAlt in tick.newAlerts) {
      if (!updatedAlerts.any((a) => a.titleEn == newAlt.titleEn)) {
        updatedAlerts.insert(0, newAlt);
      }
    }

    emit(state.copyWith(
      districts: tick.districts,
      transitVehicles: tick.vehicles,
      telemetryLogs: tick.recentLogs,
      alerts: updatedAlerts,
      totalTransitInterceptions: tick.totalTransitInterceptions,
      totalSimulationTicks: tick.totalTicks,
      averageRiskIndex: tick.averageRiskIndex,
      lastUpdated: DateTime.now(),
    ));
  }

  void _onToggleSimulation(
    ToggleSimulationEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    if (_simulation.isRunning) {
      _simulation.stop();
      emit(state.copyWith(simulationRunning: false));
    } else {
      _simulation.resume();
      emit(state.copyWith(simulationRunning: true));
    }
  }

  void _onSetSimulationSpeed(
    SetSimulationSpeedEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    _simulation.setSpeed(event.speedMultiplier);
    emit(state.copyWith(simulationSpeed: event.speedMultiplier));
  }

  void _onTriggerMockOutbreak(
    TriggerMockOutbreakEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    _simulation.triggerMockOutbreak(event.districtId, disease: event.disease);
  }

  void _onToggleAutoPatrol(
    ToggleAutoPatrolEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    emit(state.copyWith(autoPatrolEnabled: !state.autoPatrolEnabled));
  }

  void _onSelectTransitVehicle(
    SelectTransitVehicleEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    if (event.vehicle == null) {
      emit(state.copyWith(clearSelectedVehicle: true));
    } else {
      emit(state.copyWith(selectedVehicle: event.vehicle));
    }
  }

  void _onToggleSurveillanceLayer(
    ToggleSurveillanceLayerEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    final layers = Set<String>.from(state.visibleLayers);
    if (layers.contains(event.layerId)) {
      layers.remove(event.layerId);
    } else {
      layers.add(event.layerId);
    }
    emit(state.copyWith(visibleLayers: layers));
  }

  Future<void> _onResetSimulation(
    ResetSimulationEvent event,
    Emitter<SurveillanceState> emit,
  ) async {
    add(const LoadSurveillanceDataEvent());
  }

  void _onFilterDisease(
    FilterByDiseaseEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    emit(state.copyWith(selectedDiseaseFilter: event.disease));
  }

  void _onSelectDistrict(
    SelectDistrictEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    if (event.district == null) {
      emit(state.copyWith(clearSelectedDistrict: true));
    } else {
      emit(state.copyWith(selectedDistrict: event.district));
    }
  }

  void _onSelectCluster(
    SelectClusterEvent event,
    Emitter<SurveillanceState> emit,
  ) {
    if (event.cluster == null) {
      emit(state.copyWith(clearSelectedCluster: true));
    } else {
      emit(state.copyWith(selectedCluster: event.cluster));
    }
  }

  Future<void> _onDeclareQuarantine(
    DeclareQuarantineEvent event,
    Emitter<SurveillanceState> emit,
  ) async {
    try {
      await repository.declareQuarantine(event.clusterId);
      final clusters = await repository.getActiveClusters();
      OutbreakClusterModel? updatedSelected;
      for (final c in clusters) {
        if (c.id == event.clusterId) {
          updatedSelected = c;
          break;
        }
      }
      emit(state.copyWith(
        clusters: clusters,
        selectedCluster: updatedSelected ?? state.selectedCluster,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onRefreshData(
    RefreshSurveillanceEvent event,
    Emitter<SurveillanceState> emit,
  ) async {
    add(const LoadSurveillanceDataEvent());
  }

  @override
  Future<void> close() {
    _simulationSub?.cancel();
    _simulation.dispose();
    return super.close();
  }
}
