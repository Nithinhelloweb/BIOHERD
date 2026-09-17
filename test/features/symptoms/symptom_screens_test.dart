import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/theme/app_theme.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/data/animal_repository.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/symptoms/bloc/symptom_bloc.dart';
import 'package:bioherd/features/symptoms/data/symptom_repository.dart';
import 'package:bioherd/features/symptoms/models/symptom_model.dart';
import 'package:bioherd/features/symptoms/presentation/ai_results_screen.dart';
import 'package:bioherd/features/symptoms/presentation/diagnosis_dashboard_screen.dart';
import 'package:bioherd/features/symptoms/presentation/symptom_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSymptomRepository symptomRepository;
  late OfflineFirstAnimalRepository animalRepository;
  late SymptomBloc symptomBloc;
  late AnimalBloc animalBloc;

  final testAnimal = Animal(
    id: 'anim-pune-01',
    farmId: 'farm-001',
    species: AnimalSpeciesEnum.cattle,
    breed: 'Gir / गीर',
    sex: 'Female',
    tagId: 'MH-PUN-019',
    createdAt: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    symptomRepository = await OfflineFirstSymptomRepository.create();
    animalRepository = await OfflineFirstAnimalRepository.create();
    symptomBloc = SymptomBloc(repository: symptomRepository);
    animalBloc = AnimalBloc(repository: animalRepository);
  });

  tearDown(() {
    symptomBloc.close();
    animalBloc.close();
  });

  Widget createTestWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SymptomBloc>.value(value: symptomBloc),
        BlocProvider<AnimalBloc>.value(value: animalBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('DiagnosisDashboardScreen Tests', () {
    testWidgets('Renders dashboard header, metrics, and pre-seeded reports', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const DiagnosisDashboardScreen()));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('AI Disease Screening'), findsOneWidget);
      expect(find.text('Suspect Livestock Disease?'), findsOneWidget);
      expect(find.text('Recent Diagnostic Screenings'), findsOneWidget);

      // Verify pre-seeded demo reports appear
      expect(find.text('MH-PUN-GIR-104'), findsOneWidget);
      expect(find.text('Lumpy Skin Disease (LSD)'), findsOneWidget);
    });
  });

  group('AIResultsScreen Tests', () {
    testWidgets('Renders diagnostic details, confidence meter, and first-aid protocol', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockResult = AIDiagnosisResult(
        modelVersion: 'bioherd-ai-v2.1',
        primaryDiagnosis: DiseasePredictionModel(
          diseaseId: 'dis-lsd',
          nameEn: 'Lumpy Skin Disease (LSD)',
          nameMr: 'लंपी त्वचा रोग',
          confidence: 0.88,
          severity: SeverityLevel.high,
          causativeAgent: 'Capripoxvirus',
          matchedSymptoms: ['nodular_skin_lesions', 'high_fever'],
          clinicalReasoning: 'Distinct cutaneous nodules and pyrexia',
        ),
        differentialDiagnoses: [
          DiseasePredictionModel(
            diseaseId: 'dis-mastitis',
            nameEn: 'Bovine Mastitis',
            nameMr: 'स्तनदाह / मस्टायटीस',
            confidence: 0.12,
            severity: SeverityLevel.high,
            causativeAgent: 'Staphylococcus aureus',
            matchedSymptoms: [],
            clinicalReasoning: 'Low correlation',
          ),
        ],
        severity: SeverityLevel.high,
        confidence: 0.88,
        shouldEscalateCase: true,
        firstAid: FirstAidModel(
          en: {
            'immediate_action': 'Isolate affected cow in shaded quarantine stall.',
            'sanitation': 'Spray 1% Virkon or 2% sodium hypochlorite.',
            'hotline': '1962',
          },
          mr: {
            'immediate_action': 'बाधित जनावराला तात्काळ वेगळे करा.',
            'sanitation': 'गोठ्यात जंतुनाशक फवारणी करा.',
          },
          isolationRequired: true,
          zoonoticRisk: false,
        ),
        inferenceDurationMs: 45,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AIResultsScreen(
            result: mockResult,
            animalTagId: 'MH-PUN-019',
            caseId: 'MH-PUN-VET-001',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Lumpy Skin Disease (LSD)'), findsOneWidget);
      expect(find.text('लंपी त्वचा रोग'), findsOneWidget);
      expect(find.text('MH-PUN-019'), findsOneWidget);
      expect(find.textContaining('Emergency First-Aid'), findsOneWidget);
      expect(find.text('1962'), findsOneWidget);
    });
  });

  group('SymptomWizardScreen Tests', () {
    testWidgets('Initializes at step 1 when animal is provided', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          SymptomWizardScreen(initialAnimal: testAnimal),
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('AI Symptom Reporting'), findsOneWidget);
      expect(find.text('Capture Clinical Photos'), findsOneWidget);
      expect(find.text('Next / पुढे'), findsOneWidget);
    });
  });
}
