import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/veterinary/bloc/veterinary_bloc.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';
import 'package:bioherd/features/veterinary/presentation/veterinarian_workspace_screen.dart';
import 'package:bioherd/features/veterinary/presentation/case_detail_screen.dart';
import 'package:bioherd/features/veterinary/presentation/telemedicine_screen.dart';
import 'package:bioherd/features/veterinary/presentation/widgets/prescription_pad_dialog.dart';
import 'package:bioherd/features/veterinary/presentation/widgets/prescription_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late OfflineFirstVeterinaryRepository repository;
  late VeterinaryBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = OfflineFirstVeterinaryRepository(prefs);
    bloc = VeterinaryBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  Widget createTestApp(Widget child) {
    return MaterialApp(
      home: RepositoryProvider<VeterinaryRepository>.value(
        value: repository,
        child: BlocProvider<VeterinaryBloc>.value(
          value: bloc,
          child: child,
        ),
      ),
    );
  }

  group('Veterinary Screens Widget Tests', () {
    testWidgets('VeterinarianWorkspaceScreen renders header, triage metrics, and cases', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        bloc.add(const LoadCasesEvent());
        await bloc.stream.firstWhere((s) => s.status == VeterinaryStatus.loaded);
      });

      await tester.pumpWidget(createTestApp(const VeterinarianWorkspaceScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header and Subtitle
      expect(find.text('Veterinary Clinic & Triage'), findsOneWidget);
      expect(find.text('पशुवैद्यकीय दवाखाना व तपासणी कक्ष'), findsOneWidget);

      // Verify Metrics
      expect(find.text('Triage Queue'), findsWidgets);
      expect(find.text('Critical'), findsWidgets);
      expect(find.text('Prescribed'), findsWidgets);
      expect(find.text('Total Active'), findsOneWidget);

      // Verify Case Cards loaded
      expect(find.text('CASE-SOL-001'), findsOneWidget);
      expect(find.text('CASE-KOL-002'), findsOneWidget);
      expect(find.textContaining('Foot and Mouth Disease'), findsWidgets);
      expect(find.textContaining('Dnyaneshwar Shinde'), findsWidgets);

      // Verify Action Buttons on Case Cards
      expect(find.text('Dossier'), findsWidgets);
      expect(find.text('Telemed'), findsWidgets);
    });

    testWidgets('CaseDetailScreen renders patient vitals, AI findings, and clinical actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cases = await repository.getCases();
      final targetCase = cases.firstWhere((c) => c.id == 'CASE-SOL-001');

      await tester.pumpWidget(createTestApp(CaseDetailScreen(caseModel: targetCase)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Patient Info
      expect(find.text('CASE-SOL-001'), findsWidgets);
      expect(find.textContaining('Khillari'), findsWidgets);
      expect(find.textContaining('Dnyaneshwar Shinde'), findsWidgets);

      // Verify AI Clinical Findings
      expect(find.text('AI Triage Diagnostic Findings'), findsOneWidget);
      expect(find.textContaining('Foot and Mouth Disease'), findsWidgets);

      // Verify Symptoms tags
      expect(find.textContaining('High Fever'), findsWidgets);

      // Verify Clinical Action Buttons
      expect(find.text('Telemed Call'), findsOneWidget);
      expect(find.text('Prescribe'), findsOneWidget);
    });

    testWidgets('TelemedicineScreen renders consultation room, low-bandwidth mode and controls', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cases = await repository.getCases();
      final targetCase = cases.firstWhere((c) => c.id == 'CASE-SOL-001');

      await tester.pumpWidget(createTestApp(TelemedicineScreen(caseModel: targetCase)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Consultation HUD
      expect(find.textContaining('LIVE'), findsOneWidget);
      expect(find.textContaining('Solapur'), findsWidgets);

      // Verify Low-Bandwidth Mode Indicator & Codec stream
      expect(find.text('Rural 2G/3G'), findsOneWidget);
      expect(find.text('WebRTC 120 kbps Low-Bitrate Opus Stream'), findsOneWidget);

      // Verify Patient Vitals Overlay
      expect(find.textContaining('Dnyaneshwar Shinde'), findsWidgets);
      expect(find.textContaining('420 kg'), findsWidgets);

      // Verify Doctor PiP View
      expect(find.text('Dr. Deshmukh'), findsWidgets);

      // Verify Call Action Controls
      expect(find.text('Prescribe'), findsOneWidget);
    });

    testWidgets('PrescriptionPadDialog renders formulary, weight calculation, and Schedule-H alerts', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cases = await repository.getCases();
      final targetCase = cases.firstWhere((c) => c.id == 'CASE-SOL-001');

      await tester.pumpWidget(createTestApp(
        Scaffold(
          body: Center(
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PrescriptionPadDialog.show(
                    ctx,
                    caseModel: targetCase,
                    repository: repository,
                    onPrescriptionIssued: (_) {},
                  );
                },
                child: const Text('Open Pad'),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap to open Prescription Pad Dialog
      await tester.tap(find.text('Open Pad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Dialog Header
      expect(find.text('Digital Veterinary Prescription Pad'), findsOneWidget);
      expect(find.textContaining('MSVC Compliant'), findsWidgets);
      expect(find.textContaining('420 kg'), findsWidgets);

      // Verify Drug Selection Dropdown
      expect(find.text('Select Drug from Formulary / औषध निवडा'), findsOneWidget);

      // Verify Dosage and Duration Fields
      expect(find.text('Calculated Dose / मात्रा'), findsOneWidget);
      expect(find.text('Duration / दिवस'), findsOneWidget);

      // Scroll down in dialog ListView to reveal MSVC registration field
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // Verify Registration Input and Action Button
      expect(find.text('MSVC Registration No. / डॉक्टर नोंदणी क्रमांक'), findsOneWidget);
      expect(find.text('Sign & Issue Rx / पाठवा'), findsOneWidget);
    });

    testWidgets('PrescriptionCard renders official MSVC header, withdrawal rules, and signature hash', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prescription = PrescriptionModel(
        id: 'RX-CARD-TEST-01',
        caseId: 'CASE-SOL-001',
        issuedBy: 'MSVC-2022-09412',
        issuedByName: 'Dr. Priya Deshmukh',
        drugName: 'Ceftriaxone + Sulbactam 4.5g',
        dosage: '28.0 ml (10 mg/kg Once Daily IV)',
        durationDays: 3,
        instructionsMultilingual: const {
          'en': 'Reconstitute with Sterile Water. Administer slowly IV once daily for 3 days.',
          'mr': 'जंतुविरहित पाण्यात विरघळवून शिरेतून हळूहळू दररोज एकदा ३ दिवस द्या. दूध ७ दिवस फेकून द्यावे.',
        },
        scheduleHWarning: true,
        milkWithdrawalDays: 7,
        meatWithdrawalDays: 28,
        digitalSignatureHash: 'a89c3b7e4f1a2d5e6890bc423f11de89a89c3b7e4f1a2d5e6890bc423f11de89',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PrescriptionCard(prescription: prescription),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Rx header & drug
      expect(find.text('Rx'), findsOneWidget);
      expect(find.text('Ceftriaxone + Sulbactam 4.5g'), findsOneWidget);
      expect(find.text('28.0 ml (10 mg/kg Once Daily IV)'), findsOneWidget);

      // Verify Schedule-H Antibiotic Warning Badge
      expect(find.text('Schedule-H'), findsOneWidget);

      // Verify Withdrawal Periods for Food Safety
      expect(find.text('Food Safety Withdrawal: '), findsOneWidget);
      expect(find.textContaining('Milk 7d'), findsOneWidget);
      expect(find.textContaining('Meat 28d'), findsOneWidget);

      // Verify Bilingual Instructions
      expect(find.textContaining('जंतुविरहित पाण्यात'), findsOneWidget);

      // Verify Digital Signature Badge
      expect(find.textContaining('Digitally Signed: #a89c3b7e4f1a...'), findsOneWidget);
    });
  });
}
