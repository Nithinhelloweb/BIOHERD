import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';

// ============================================================================
// Events
// ============================================================================

abstract class VeterinaryEvent {
  const VeterinaryEvent();
}

class LoadCasesEvent extends VeterinaryEvent {
  final CaseStatus? status;
  final CasePriority? priority;
  final String? query;
  final bool? unassignedOnly;

  const LoadCasesEvent({
    this.status,
    this.priority,
    this.query,
    this.unassignedOnly,
  });
}

class SelectCaseEvent extends VeterinaryEvent {
  final String caseId;
  const SelectCaseEvent(this.caseId);
}

class AssignCaseEvent extends VeterinaryEvent {
  final String caseId;
  final String vetId;
  final String vetName;
  final String? notes;

  const AssignCaseEvent({
    required this.caseId,
    required this.vetId,
    required this.vetName,
    this.notes,
  });
}

class UpdateCaseStatusEvent extends VeterinaryEvent {
  final String caseId;
  final CaseStatus status;
  final String? notes;
  final String? resolutionSummary;

  const UpdateCaseStatusEvent({
    required this.caseId,
    required this.status,
    this.notes,
    this.resolutionSummary,
  });
}

class IssuePrescriptionEvent extends VeterinaryEvent {
  final String caseId;
  final PrescriptionModel prescription;

  const IssuePrescriptionEvent({
    required this.caseId,
    required this.prescription,
  });
}

class CalculateDosageEvent extends VeterinaryEvent {
  final String drugId;
  final String species;
  final double weightKg;

  const CalculateDosageEvent({
    required this.drugId,
    required this.species,
    required this.weightKg,
  });
}

class StartTelemedicineEvent extends VeterinaryEvent {
  final String caseId;
  const StartTelemedicineEvent(this.caseId);
}

class EndTelemedicineEvent extends VeterinaryEvent {
  final String sessionId;
  const EndTelemedicineEvent(this.sessionId);
}

// ============================================================================
// State
// ============================================================================

enum VeterinaryStatus { initial, loading, loaded, error }

class VeterinaryState {
  final VeterinaryStatus status;
  final List<CaseModel> cases;
  final CaseModel? selectedCase;
  final CaseStatus? selectedStatusFilter;
  final CasePriority? selectedPriorityFilter;
  final bool unassignedOnly;
  final String? searchQuery;
  final List<DrugItem> drugCatalog;
  final DosageCalculationResult? activeDosageCalculation;
  final TelemedicineSessionModel? activeTelemedicineSession;
  final bool isTelemedicineActive;
  final String? errorMessage;

  const VeterinaryState({
    this.status = VeterinaryStatus.initial,
    this.cases = const [],
    this.selectedCase,
    this.selectedStatusFilter,
    this.selectedPriorityFilter,
    this.unassignedOnly = false,
    this.searchQuery,
    this.drugCatalog = const [],
    this.activeDosageCalculation,
    this.activeTelemedicineSession,
    this.isTelemedicineActive = false,
    this.errorMessage,
  });

  int get triageCount => cases.where((c) => c.status == CaseStatus.submitted).length;
  int get criticalCount => cases.where((c) => c.priority == CasePriority.critical).length;
  int get prescriptionIssuedCount => cases.where((c) => c.hasPrescription).length;

  VeterinaryState copyWith({
    VeterinaryStatus? status,
    List<CaseModel>? cases,
    CaseModel? selectedCase,
    bool clearSelectedCase = false,
    CaseStatus? selectedStatusFilter,
    bool clearStatusFilter = false,
    CasePriority? selectedPriorityFilter,
    bool clearPriorityFilter = false,
    bool? unassignedOnly,
    String? searchQuery,
    List<DrugItem>? drugCatalog,
    DosageCalculationResult? activeDosageCalculation,
    bool clearDosageCalculation = false,
    TelemedicineSessionModel? activeTelemedicineSession,
    bool clearTelemedicineSession = false,
    bool? isTelemedicineActive,
    String? errorMessage,
  }) {
    return VeterinaryState(
      status: status ?? this.status,
      cases: cases ?? this.cases,
      selectedCase: clearSelectedCase ? null : (selectedCase ?? this.selectedCase),
      selectedStatusFilter: clearStatusFilter ? null : (selectedStatusFilter ?? this.selectedStatusFilter),
      selectedPriorityFilter: clearPriorityFilter ? null : (selectedPriorityFilter ?? this.selectedPriorityFilter),
      unassignedOnly: unassignedOnly ?? this.unassignedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      drugCatalog: drugCatalog ?? this.drugCatalog,
      activeDosageCalculation: clearDosageCalculation ? null : (activeDosageCalculation ?? this.activeDosageCalculation),
      activeTelemedicineSession: clearTelemedicineSession ? null : (activeTelemedicineSession ?? this.activeTelemedicineSession),
      isTelemedicineActive: isTelemedicineActive ?? this.isTelemedicineActive,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// BLoC
// ============================================================================

class VeterinaryBloc extends Bloc<VeterinaryEvent, VeterinaryState> {
  final VeterinaryRepository repository;

  VeterinaryBloc({required this.repository}) : super(const VeterinaryState()) {
    on<LoadCasesEvent>(_onLoadCases);
    on<SelectCaseEvent>(_onSelectCase);
    on<AssignCaseEvent>(_onAssignCase);
    on<UpdateCaseStatusEvent>(_onUpdateCaseStatus);
    on<IssuePrescriptionEvent>(_onIssuePrescription);
    on<CalculateDosageEvent>(_onCalculateDosage);
    on<StartTelemedicineEvent>(_onStartTelemedicine);
    on<EndTelemedicineEvent>(_onEndTelemedicine);
  }

  Future<void> _onLoadCases(
    LoadCasesEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    emit(state.copyWith(status: VeterinaryStatus.loading));
    try {
      final cases = await repository.getCases(
        status: event.status ?? state.selectedStatusFilter,
        priority: event.priority ?? state.selectedPriorityFilter,
        query: event.query ?? state.searchQuery,
        unassignedOnly: event.unassignedOnly ?? state.unassignedOnly,
      );
      final drugs = await repository.getDrugCatalog();

      emit(state.copyWith(
        status: VeterinaryStatus.loaded,
        cases: cases,
        drugCatalog: drugs,
        selectedStatusFilter: event.status,
        selectedPriorityFilter: event.priority,
        searchQuery: event.query,
        unassignedOnly: event.unassignedOnly,
      ));
    } catch (e) {
      emit(state.copyWith(status: VeterinaryStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSelectCase(
    SelectCaseEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    try {
      final c = await repository.getCaseById(event.caseId);
      if (c != null) {
        emit(state.copyWith(selectedCase: c));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAssignCase(
    AssignCaseEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    try {
      final updated = await repository.assignCase(
        event.caseId,
        event.vetId,
        event.vetName,
        notes: event.notes,
      );
      final updatedList = state.cases.map((c) => c.id == updated.id ? updated : c).toList();
      emit(state.copyWith(
        cases: updatedList,
        selectedCase: state.selectedCase?.id == updated.id ? updated : state.selectedCase,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateCaseStatus(
    UpdateCaseStatusEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    try {
      final updated = await repository.updateCaseStatus(
        event.caseId,
        event.status,
        notes: event.notes,
        resolutionSummary: event.resolutionSummary,
      );
      final updatedList = state.cases.map((c) => c.id == updated.id ? updated : c).toList();
      emit(state.copyWith(
        cases: updatedList,
        selectedCase: state.selectedCase?.id == updated.id ? updated : state.selectedCase,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onIssuePrescription(
    IssuePrescriptionEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    try {
      await repository.issuePrescription(event.caseId, event.prescription);
      // Reload updated case
      final updatedCase = await repository.getCaseById(event.caseId);
      if (updatedCase != null) {
        final updatedList = state.cases.map((c) => c.id == updatedCase.id ? updatedCase : c).toList();
        emit(state.copyWith(
          cases: updatedList,
          selectedCase: updatedCase,
          clearDosageCalculation: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCalculateDosage(
    CalculateDosageEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    try {
      final result = await repository.calculateDosage(
        event.drugId,
        event.species,
        event.weightKg,
      );
      emit(state.copyWith(activeDosageCalculation: result));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onStartTelemedicine(
    StartTelemedicineEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    try {
      final session = await repository.createTelemedicineSession(event.caseId);
      final updatedCase = await repository.getCaseById(event.caseId);
      emit(state.copyWith(
        activeTelemedicineSession: session,
        isTelemedicineActive: true,
        selectedCase: updatedCase ?? state.selectedCase,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onEndTelemedicine(
    EndTelemedicineEvent event,
    Emitter<VeterinaryState> emit,
  ) async {
    emit(state.copyWith(
      isTelemedicineActive: false,
      clearTelemedicineSession: true,
    ));
  }
}
