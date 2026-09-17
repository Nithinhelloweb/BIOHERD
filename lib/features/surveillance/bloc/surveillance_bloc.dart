import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/surveillance_repository.dart';
import '../models/surveillance_model.dart';

// Events
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

// States
class SurveillanceState {
  final bool isLoading;
  final List<DistrictRiskModel> districts;
  final List<OutbreakClusterModel> clusters;
  final List<SurveillanceAlertModel> alerts;
  final String selectedDiseaseFilter;
  final DistrictRiskModel? selectedDistrict;
  final OutbreakClusterModel? selectedCluster;
  final String? errorMessage;

  const SurveillanceState({
    this.isLoading = false,
    this.districts = const [],
    this.clusters = const [],
    this.alerts = const [],
    this.selectedDiseaseFilter = 'All',
    this.selectedDistrict,
    this.selectedCluster,
    this.errorMessage,
  });

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
}

// BLoC
class SurveillanceBloc extends Bloc<SurveillanceEvent, SurveillanceState> {
  final SurveillanceRepository repository;

  SurveillanceBloc({required this.repository}) : super(const SurveillanceState(isLoading: true)) {
    on<LoadSurveillanceDataEvent>(_onLoadData);
    on<FilterByDiseaseEvent>(_onFilterDisease);
    on<SelectDistrictEvent>(_onSelectDistrict);
    on<SelectClusterEvent>(_onSelectCluster);
    on<DeclareQuarantineEvent>(_onDeclareQuarantine);
    on<RefreshSurveillanceEvent>(_onRefreshData);
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
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
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
}
