import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/symptoms/data/symptom_repository.dart';
import 'package:bioherd/features/symptoms/models/symptom_model.dart';

// ---------------- EVENTS ----------------
abstract class SymptomEvent extends Equatable {
  const SymptomEvent();

  @override
  List<Object?> get props => [];
}

class LoadSymptomReportsEvent extends SymptomEvent {
  final String? animalId;
  const LoadSymptomReportsEvent({this.animalId});

  @override
  List<Object?> get props => [animalId];
}

class InitSymptomWizardEvent extends SymptomEvent {
  final AnimalModel? initialAnimal;
  const InitSymptomWizardEvent({this.initialAnimal});

  @override
  List<Object?> get props => [initialAnimal];
}

class SelectWizardAnimalEvent extends SymptomEvent {
  final AnimalModel animal;
  const SelectWizardAnimalEvent(this.animal);

  @override
  List<Object?> get props => [animal];
}

class ToggleWizardSymptomEvent extends SymptomEvent {
  final String systemId;
  final String symptomId;
  const ToggleWizardSymptomEvent({required this.systemId, required this.symptomId});

  @override
  List<Object?> get props => [systemId, symptomId];
}

class AddWizardPhotoEvent extends SymptomEvent {
  final String photoPath;
  const AddWizardPhotoEvent(this.photoPath);

  @override
  List<Object?> get props => [photoPath];
}

class RemoveWizardPhotoEvent extends SymptomEvent {
  final int index;
  const RemoveWizardPhotoEvent(this.index);

  @override
  List<Object?> get props => [index];
}

class SetWizardDescriptionEvent extends SymptomEvent {
  final String description;
  const SetWizardDescriptionEvent(this.description);

  @override
  List<Object?> get props => [description];
}

class SetWizardVoiceNoteEvent extends SymptomEvent {
  final String voiceNoteUrl;
  const SetWizardVoiceNoteEvent(this.voiceNoteUrl);

  @override
  List<Object?> get props => [voiceNoteUrl];
}

class SetWizardStepEvent extends SymptomEvent {
  final int step;
  const SetWizardStepEvent(this.step);

  @override
  List<Object?> get props => [step];
}

class SubmitWizardReportEvent extends SymptomEvent {
  const SubmitWizardReportEvent();
}

// ---------------- STATES ----------------
abstract class SymptomState extends Equatable {
  const SymptomState();

  @override
  List<Object?> get props => [];
}

class SymptomInitial extends SymptomState {
  const SymptomInitial();
}

class SymptomLoading extends SymptomState {
  const SymptomLoading();
}

class SymptomReportsLoaded extends SymptomState {
  final List<SymptomReportModel> reports;
  const SymptomReportsLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class SymptomWizardState extends SymptomState {
  final int currentStep; // 0: Animal, 1: Photos, 2: Checklist, 3: Voice/Note, 4: Review & Diagnosis
  final AnimalModel? selectedAnimal;
  final Map<String, Set<String>> selectedSymptoms;
  final List<String> photos;
  final String vernacularDescription;
  final String? voiceNoteUrl;
  final bool isSubmitting;
  final AIDiagnosisResult? diagnosisResult;
  final SymptomReportModel? submittedReport;
  final String? errorMessage;

  const SymptomWizardState({
    this.currentStep = 0,
    this.selectedAnimal,
    this.selectedSymptoms = const {},
    this.photos = const [],
    this.vernacularDescription = '',
    this.voiceNoteUrl,
    this.isSubmitting = false,
    this.diagnosisResult,
    this.submittedReport,
    this.errorMessage,
  });

  int get totalSymptomsSelected {
    int total = 0;
    for (final set in selectedSymptoms.values) {
      total += set.length;
    }
    return total;
  }

  SymptomWizardState copyWith({
    int? currentStep,
    AnimalModel? selectedAnimal,
    Map<String, Set<String>>? selectedSymptoms,
    List<String>? photos,
    String? vernacularDescription,
    String? voiceNoteUrl,
    bool? isSubmitting,
    AIDiagnosisResult? diagnosisResult,
    SymptomReportModel? submittedReport,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SymptomWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedAnimal: selectedAnimal ?? this.selectedAnimal,
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      photos: photos ?? this.photos,
      vernacularDescription: vernacularDescription ?? this.vernacularDescription,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
      submittedReport: submittedReport ?? this.submittedReport,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        selectedAnimal,
        selectedSymptoms,
        photos,
        vernacularDescription,
        voiceNoteUrl,
        isSubmitting,
        diagnosisResult,
        submittedReport,
        errorMessage,
      ];
}

// ---------------- BLOC ----------------
class SymptomBloc extends Bloc<SymptomEvent, SymptomState> {
  final SymptomRepository _repository;
  SymptomRepository get repository => _repository;

  SymptomBloc({required SymptomRepository repository})
      : _repository = repository,
        super(const SymptomInitial()) {
    on<LoadSymptomReportsEvent>(_onLoadReports);
    on<InitSymptomWizardEvent>(_onInitWizard);
    on<SelectWizardAnimalEvent>(_onSelectAnimal);
    on<ToggleWizardSymptomEvent>(_onToggleSymptom);
    on<AddWizardPhotoEvent>(_onAddPhoto);
    on<RemoveWizardPhotoEvent>(_onRemovePhoto);
    on<SetWizardDescriptionEvent>(_onSetDescription);
    on<SetWizardVoiceNoteEvent>(_onSetVoiceNote);
    on<SetWizardStepEvent>(_onSetStep);
    on<SubmitWizardReportEvent>(_onSubmitReport);
  }

  Future<void> _onLoadReports(
    LoadSymptomReportsEvent event,
    Emitter<SymptomState> emit,
  ) async {
    emit(const SymptomLoading());
    try {
      final reports = await _repository.getReports(animalId: event.animalId);
      emit(SymptomReportsLoaded(reports));
    } catch (e) {
      emit(SymptomWizardState(errorMessage: 'Failed to load reports: $e'));
    }
  }

  void _onInitWizard(
    InitSymptomWizardEvent event,
    Emitter<SymptomState> emit,
  ) {
    emit(SymptomWizardState(
      currentStep: event.initialAnimal != null ? 1 : 0,
      selectedAnimal: event.initialAnimal,
      selectedSymptoms: const {},
      photos: const [],
      vernacularDescription: '',
      voiceNoteUrl: null,
      isSubmitting: false,
      diagnosisResult: null,
      submittedReport: null,
      errorMessage: null,
    ));
  }

  void _onSelectAnimal(
    SelectWizardAnimalEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      emit(current.copyWith(
        selectedAnimal: event.animal,
        currentStep: 1, // Advance to photo capture
        clearError: true,
      ));
    }
  }

  void _onToggleSymptom(
    ToggleWizardSymptomEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      final newMap = Map<String, Set<String>>.from(
        current.selectedSymptoms.map((k, v) => MapEntry(k, Set<String>.from(v))),
      );

      final currentSet = newMap[event.systemId] ?? <String>{};
      if (currentSet.contains(event.symptomId)) {
        currentSet.remove(event.symptomId);
      } else {
        currentSet.add(event.symptomId);
      }
      newMap[event.systemId] = currentSet;

      emit(current.copyWith(selectedSymptoms: newMap, clearError: true));
    }
  }

  void _onAddPhoto(
    AddWizardPhotoEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      final newPhotos = List<String>.from(current.photos)..add(event.photoPath);
      emit(current.copyWith(photos: newPhotos, clearError: true));
    }
  }

  void _onRemovePhoto(
    RemoveWizardPhotoEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      final newPhotos = List<String>.from(current.photos);
      if (event.index >= 0 && event.index < newPhotos.length) {
        newPhotos.removeAt(event.index);
        emit(current.copyWith(photos: newPhotos, clearError: true));
      }
    }
  }

  void _onSetDescription(
    SetWizardDescriptionEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      emit(current.copyWith(vernacularDescription: event.description, clearError: true));
    }
  }

  void _onSetVoiceNote(
    SetWizardVoiceNoteEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      emit(current.copyWith(voiceNoteUrl: event.voiceNoteUrl, clearError: true));
    }
  }

  void _onSetStep(
    SetWizardStepEvent event,
    Emitter<SymptomState> emit,
  ) {
    if (state is SymptomWizardState) {
      final current = state as SymptomWizardState;
      emit(current.copyWith(currentStep: event.step, clearError: true));
    }
  }

  Future<void> _onSubmitReport(
    SubmitWizardReportEvent event,
    Emitter<SymptomState> emit,
  ) async {
    if (state is! SymptomWizardState) return;
    final current = state as SymptomWizardState;

    if (current.selectedAnimal == null) {
      emit(current.copyWith(errorMessage: 'Please select an animal first.'));
      return;
    }

    if (current.totalSymptomsSelected == 0 &&
        current.vernacularDescription.trim().isEmpty &&
        current.photos.isEmpty) {
      emit(current.copyWith(
          errorMessage: 'Please provide at least one symptom, photo, or description.'));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final checklistForApi = <String, List<String>>{};
      current.selectedSymptoms.forEach((key, set) {
        if (set.isNotEmpty) {
          checklistForApi[key] = set.toList();
        }
      });

      final animal = current.selectedAnimal!;
      final report = await _repository.submitReport(
        animalId: animal.id,
        animalTagId: animal.tagId,
        species: animal.species.displayName,
        breed: animal.breed,
        symptomsChecklist: checklistForApi,
        vernacularDescription: current.vernacularDescription,
        images: current.photos,
        voiceNoteUrl: current.voiceNoteUrl,
      );

      emit(current.copyWith(
        isSubmitting: false,
        submittedReport: report,
        diagnosisResult: report.detectionResult,
        currentStep: 4, // Final review & results screen
      ));
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit report: $e',
      ));
    }
  }
}
