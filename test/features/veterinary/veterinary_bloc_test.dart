import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/veterinary/bloc/veterinary_bloc.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';

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

  group('VeterinaryBloc', () {
    test('initial state has empty cases and initial status', () {
      expect(bloc.state.status, VeterinaryStatus.initial);
      expect(bloc.state.cases, isEmpty);
      expect(bloc.state.selectedCase, isNull);
    });

    test('LoadCasesEvent emits loaded state with seeded cases', () async {
      final futureExpect = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loading),
          predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loaded && s.cases.length == 4),
        ]),
      );

      bloc.add(const LoadCasesEvent());
      await futureExpect;

      expect(bloc.state.triageCount, 1);
      expect(bloc.state.criticalCount, 1);
    });

    test('LoadCasesEvent with filters filters cases correctly', () async {
      final futureExpect = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loading),
          predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loaded && s.cases.length == 1 && s.cases.first.district.contains('Kolhapur')),
        ]),
      );

      bloc.add(const LoadCasesEvent(priority: CasePriority.critical));
      await futureExpect;
    });

    test('SelectCaseEvent selects the requested case', () async {
      // First load cases
      final loadExpect = expectLater(
        bloc.stream,
        emitsThrough(predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loaded)),
      );
      bloc.add(const LoadCasesEvent());
      await loadExpect;

      final selectExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) => s.selectedCase?.id == 'CASE-SOL-001')),
      );
      bloc.add(const SelectCaseEvent('CASE-SOL-001'));
      await selectExpect;
    });

    test('AssignCaseEvent updates assigned doctor on case', () async {
      final loadExpect = expectLater(
        bloc.stream,
        emitsThrough(predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loaded)),
      );
      bloc.add(const LoadCasesEvent());
      await loadExpect;

      final assignExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) {
          final c = s.cases.firstWhere((caseItem) => caseItem.id == 'CASE-KOL-002');
          return c.assignedVetName == 'Dr. Priya Deshmukh' && c.status == CaseStatus.assigned;
        })),
      );

      bloc.add(const AssignCaseEvent(
        caseId: 'CASE-KOL-002',
        vetId: 'VET-MH-042',
        vetName: 'Dr. Priya Deshmukh',
        notes: 'Priority FMD outbreak investigation',
      ));
      await assignExpect;
    });

    test('UpdateCaseStatusEvent transitions case status', () async {
      final loadExpect = expectLater(
        bloc.stream,
        emitsThrough(predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loaded)),
      );
      bloc.add(const LoadCasesEvent());
      await loadExpect;

      final updateExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) {
          final c = s.cases.firstWhere((caseItem) => caseItem.id == 'CASE-SOL-001');
          return c.status == CaseStatus.closed;
        })),
      );

      bloc.add(const UpdateCaseStatusEvent(
        caseId: 'CASE-SOL-001',
        status: CaseStatus.closed,
      ));
      await updateExpect;
    });

    test('CalculateDosageEvent calculates weight-based dosage for drug', () async {
      final calcExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) {
          return s.activeDosageCalculation != null &&
              s.activeDosageCalculation!.calculatedVolumeMl == 38.0;
        })),
      );

      bloc.add(const CalculateDosageEvent(
        drugId: 'DRUG-MELX',
        species: 'Cattle',
        weightKg: 380.0,
      ));
      await calcExpect;
    });

    test('StartTelemedicineEvent and EndTelemedicineEvent manage consultation session', () async {
      final startExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) {
          return s.isTelemedicineActive &&
              s.activeTelemedicineSession != null &&
              s.activeTelemedicineSession!.caseId == 'CASE-SOL-001';
        })),
      );

      bloc.add(const StartTelemedicineEvent('CASE-SOL-001'));
      await startExpect;

      final sessionId = bloc.state.activeTelemedicineSession!.sessionId;
      final endExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) => !s.isTelemedicineActive && s.activeTelemedicineSession == null)),
      );

      bloc.add(EndTelemedicineEvent(sessionId));
      await endExpect;
    });

    test('IssuePrescriptionEvent attaches prescription to case', () async {
      final loadExpect = expectLater(
        bloc.stream,
        emitsThrough(predicate<VeterinaryState>((s) => s.status == VeterinaryStatus.loaded)),
      );
      bloc.add(const LoadCasesEvent());
      await loadExpect;

      final rx = PrescriptionModel(
        id: 'RX-BLOC-01',
        caseId: 'CASE-SOL-001',
        issuedBy: 'MSVC-2022-09412',
        issuedByName: 'Dr. Deshmukh',
        drugName: 'Meloxicam Injection',
        dosage: '38.0 ml (0.5 mg/kg Once Daily)',
        durationDays: 3,
        createdAt: DateTime.now(),
      );

      final issueExpect = expectLater(
        bloc.stream,
        emits(predicate<VeterinaryState>((s) {
          final c = s.cases.firstWhere((caseItem) => caseItem.id == 'CASE-SOL-001');
          return c.status == CaseStatus.prescriptionIssued &&
              c.hasPrescription &&
              c.prescriptions.isNotEmpty;
        })),
      );

      bloc.add(IssuePrescriptionEvent(
        caseId: 'CASE-SOL-001',
        prescription: rx,
      ));
      await issueExpect;
    });
  });
}
