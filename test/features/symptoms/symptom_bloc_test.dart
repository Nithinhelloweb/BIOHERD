import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/symptoms/bloc/symptom_bloc.dart';
import 'package:bioherd/features/symptoms/data/symptom_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSymptomRepository repository;
  late SymptomBloc bloc;

  final testAnimal = Animal(
    id: 'test-animal-101',
    farmId: 'farm-001',
    species: AnimalSpeciesEnum.cattle,
    breed: 'Gir / गीर',
    sex: 'Female',
    tagId: 'MH-PUN-019',
    createdAt: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstSymptomRepository.create();
    bloc = SymptomBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SymptomBloc Tests', () {
    test('Initial state is SymptomInitial', () {
      expect(bloc.state, isA<SymptomInitial>());
    });

    test('LoadSymptomReportsEvent loads pre-seeded reports', () async {
      bloc.add(const LoadSymptomReportsEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SymptomLoading>(),
          predicate<SymptomReportsLoaded>((state) {
            return state.reports.length >= 2 &&
                state.reports.any((r) => r.animalTagId == 'MH-PUN-GIR-104');
          }),
        ]),
      );
    });

    test('InitSymptomWizardEvent initializes state without initial animal at step 0', () async {
      bloc.add(const InitSymptomWizardEvent());

      await expectLater(
        bloc.stream,
        emits(predicate<SymptomWizardState>((state) {
          return state.currentStep == 0 &&
              state.selectedAnimal == null &&
              state.selectedSymptoms.isEmpty &&
              state.photos.isEmpty;
        })),
      );
    });

    test('InitSymptomWizardEvent with initial animal starts at step 1', () async {
      bloc.add(InitSymptomWizardEvent(initialAnimal: testAnimal));

      await expectLater(
        bloc.stream,
        emits(predicate<SymptomWizardState>((state) {
          return state.currentStep == 1 &&
              state.selectedAnimal?.id == testAnimal.id;
        })),
      );
    });

    test('SelectWizardAnimalEvent selects animal and advances step', () async {
      bloc.add(const InitSymptomWizardEvent());
      await bloc.stream.firstWhere((s) => s is SymptomWizardState);

      bloc.add(SelectWizardAnimalEvent(testAnimal));

      await expectLater(
        bloc.stream,
        emits(predicate<SymptomWizardState>((state) {
          return state.selectedAnimal?.id == testAnimal.id &&
              state.currentStep == 1;
        })),
      );
    });

    test('ToggleWizardSymptomEvent adds and removes symptoms', () async {
      bloc.add(InitSymptomWizardEvent(initialAnimal: testAnimal));
      await bloc.stream.firstWhere((s) => s is SymptomWizardState);

      // Add symptom
      bloc.add(const ToggleWizardSymptomEvent(
        systemId: 'skin_coat',
        symptomId: 'nodular_skin_lesions',
      ));

      await expectLater(
        bloc.stream,
        emits(predicate<SymptomWizardState>((state) {
          return state.selectedSymptoms['skin_coat']?.contains('nodular_skin_lesions') == true &&
              state.totalSymptomsSelected == 1;
        })),
      );

      // Toggle off
      bloc.add(const ToggleWizardSymptomEvent(
        systemId: 'skin_coat',
        symptomId: 'nodular_skin_lesions',
      ));

      await expectLater(
        bloc.stream,
        emits(predicate<SymptomWizardState>((state) {
          return state.selectedSymptoms['skin_coat']?.contains('nodular_skin_lesions') == false &&
              state.totalSymptomsSelected == 0;
        })),
      );
    });

    test('Photo management and vernacular note manipulation', () async {
      bloc.add(InitSymptomWizardEvent(initialAnimal: testAnimal));
      await bloc.stream.firstWhere((s) => s is SymptomWizardState);

      bloc.add(const AddWizardPhotoEvent('nodule1.jpg'));
      bloc.add(const SetWizardDescriptionEvent('अंगावर गाठी आहेत'));
      bloc.add(const SetWizardVoiceNoteEvent('audio_voice_test.wav'));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<SymptomWizardState>((state) {
          return state.photos.contains('nodule1.jpg') &&
              state.vernacularDescription == 'अंगावर गाठी आहेत' &&
              state.voiceNoteUrl == 'audio_voice_test.wav';
        })),
      );

      // Remove photo
      bloc.add(const RemoveWizardPhotoEvent(0));
      await expectLater(
        bloc.stream,
        emits(predicate<SymptomWizardState>((state) => state.photos.isEmpty)),
      );
    });

    test('SubmitWizardReportEvent successfully triggers AI diagnosis ensemble', () async {
      bloc.add(InitSymptomWizardEvent(initialAnimal: testAnimal));
      await bloc.stream.firstWhere((s) => s is SymptomWizardState);

      bloc.add(const ToggleWizardSymptomEvent(
        systemId: 'skin_coat',
        symptomId: 'nodular_skin_lesions',
      ));
      bloc.add(const ToggleWizardSymptomEvent(
        systemId: 'vitality',
        symptomId: 'high_fever',
      ));
      bloc.add(const SetWizardDescriptionEvent('अंगावर भरपूर कडक गाठी व ताप आहे'));
      bloc.add(const AddWizardPhotoEvent('nodular_skin_lesions.jpg'));

      // Advance to step 4
      bloc.add(const SetWizardStepEvent(4));

      // Submit report
      bloc.add(const SubmitWizardReportEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<SymptomWizardState>((state) {
          return state.isSubmitting == false &&
              state.diagnosisResult != null &&
              state.diagnosisResult!.primaryDiagnosis.diseaseId == 'dis-lsd' &&
              state.diagnosisResult!.confidence >= 0.8 &&
              state.diagnosisResult!.firstAid.emergencyHotline == '1962' &&
              state.submittedReport != null;
        })),
      );
    });
  });
}
