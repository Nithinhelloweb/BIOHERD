import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late OfflineFirstVeterinaryRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = OfflineFirstVeterinaryRepository(prefs);
  });

  group('OfflineFirstVeterinaryRepository', () {
    test('seeds 4 initial Maharashtra cases on first run', () async {
      final cases = await repository.getCases();
      expect(cases.length, 4);

      // Verify Solapur FMD case
      final solapurCase = cases.firstWhere((c) => c.district.contains('Solapur'));
      expect(solapurCase.id, 'CASE-SOL-001');
      expect(solapurCase.farmerName, 'Dnyaneshwar Shinde');
      expect(solapurCase.breed, contains('Khillari'));
      expect(solapurCase.weightKg, 420.0);
      expect(solapurCase.priority, CasePriority.high);
      expect(solapurCase.status, CaseStatus.inReview);
      expect(solapurCase.primaryDiagnosis, contains('Foot and Mouth Disease'));

      // Verify Kolhapur LSD case
      final kolhapurCase = cases.firstWhere((c) => c.district.contains('Kolhapur'));
      expect(kolhapurCase.id, 'CASE-KOL-002');
      expect(kolhapurCase.breed, contains('Pandharpuri'));
      expect(kolhapurCase.priority, CasePriority.critical);
      expect(kolhapurCase.status, CaseStatus.submitted);

      // Verify Ahmednagar Mastitis case
      final ahmednagarCase = cases.firstWhere((c) => c.district.contains('Ahmednagar'));
      expect(ahmednagarCase.id, 'CASE-AHM-003');
      expect(ahmednagarCase.species, contains('Cattle'));

      // Verify Pune PPR case
      final puneCase = cases.firstWhere((c) => c.district.contains('Pune'));
      expect(puneCase.id, 'CASE-PUN-004');
      expect(puneCase.species, contains('Goat'));
      expect(puneCase.breed, contains('Osmanabadi'));
    });

    test('filters cases by status, priority, and query', () async {
      // Filter by priority
      final criticalCases = await repository.getCases(priority: CasePriority.critical);
      expect(criticalCases.length, 1);
      expect(criticalCases.first.district, contains('Kolhapur'));

      // Filter by status
      final submittedCases = await repository.getCases(status: CaseStatus.submitted);
      expect(submittedCases.length, 1);
      expect(submittedCases.first.id, 'CASE-KOL-002');

      // Search query by farmer name
      final searchDnyan = await repository.getCases(query: 'Dnyaneshwar');
      expect(searchDnyan.length, 1);
      expect(searchDnyan.first.farmerName, contains('Dnyaneshwar'));

      // Search query by tag
      final searchTag = await repository.getCases(query: 'MH-KOL');
      expect(searchTag.length, 1);
      expect(searchTag.first.district, contains('Kolhapur'));
    });

    test('getCaseById returns matching case or null', () async {
      final found = await repository.getCaseById('CASE-SOL-001');
      expect(found, isNotNull);
      expect(found!.id, 'CASE-SOL-001');

      final notFound = await repository.getCaseById('INVALID-CASE-ID');
      expect(notFound, isNull);
    });

    test('assignCase assigns veterinary doctor and updates status', () async {
      final updated = await repository.assignCase(
        'CASE-KOL-002',
        'VET-MH-042',
        'Dr. Priya Deshmukh',
        notes: 'Priority triage assigned. Preparing WebRTC telemed call.',
      );

      expect(updated.assignedVetId, 'VET-MH-042');
      expect(updated.assignedVetName, 'Dr. Priya Deshmukh');
      expect(updated.status, CaseStatus.assigned);
      expect(updated.notes, contains('Priority triage assigned'));

      // Verify persistence in repository
      final fetched = await repository.getCaseById('CASE-KOL-002');
      expect(fetched!.assignedVetName, 'Dr. Priya Deshmukh');
      expect(fetched.status, CaseStatus.assigned);
    });

    test('updateCaseStatus transitions case lifecycle', () async {
      // Transition to inReview
      var updated = await repository.updateCaseStatus(
        'CASE-SOL-001',
        CaseStatus.inReview,
        notes: 'Clinical signs verified via telemedicine stream.',
      );
      expect(updated.status, CaseStatus.inReview);

      // Transition to closed with resolution summary
      updated = await repository.updateCaseStatus(
        'CASE-SOL-001',
        CaseStatus.closed,
        resolutionSummary: 'Lesions completely resolved after 5-day antibiotic and antiseptic spray regimen.',
      );
      expect(updated.status, CaseStatus.closed);
      expect(updated.resolutionSummary, contains('Lesions completely resolved'));
    });

    test('calculates accurate weight-based dosage for Meloxicam', () async {
      // Meloxicam: 0.5 mg/kg, 5 mg/ml. Body weight: 380 kg -> (380 * 0.5) / 5 = 38.0 ml
      final calc = await repository.calculateDosage('DRUG-MELX', 'Cattle', 380.0);
      expect(calc.drugId, 'DRUG-MELX');
      expect(calc.calculatedVolumeMl, closeTo(38.0, 0.01));
      expect(calc.route, contains('Intramuscular'));
      expect(calc.scheduleHWarning, isFalse);
    });

    test('calculates accurate weight-based dosage with Schedule-H warnings for Oxytetracycline', () async {
      // Oxytetracycline LA: 20 mg/kg, 200 mg/ml.
      final drugs = await repository.getDrugCatalog();
      final oxy = drugs.firstWhere((d) => d.id == 'DRUG-OXYT');
      expect(oxy.scheduleH, isTrue);
      expect(oxy.milkWithdrawalDays, 7);
      expect(oxy.meatWithdrawalDays, 21);

      final calc = await repository.calculateDosage('DRUG-OXYT', 'Cattle', 380.0);
      expect(calc.scheduleHWarning, isTrue);
      expect(calc.milkWithdrawalDays, 7);
      expect(calc.meatWithdrawalDays, 21);
      expect(calc.calculatedVolumeMl, closeTo(38.0, 0.01));
    });

    test('issues prescription with cryptographic digital signature and persists to case', () async {
      final newRx = PrescriptionModel(
        id: 'RX-TEST-999',
        caseId: 'CASE-SOL-001',
        issuedBy: 'MSVC-2022-09412',
        issuedByName: 'Dr. Priya Deshmukh',
        drugName: 'Meloxicam Injection',
        dosage: '38.0 ml (0.5 mg/kg Once Daily)',
        durationDays: 3,
        instructionsMultilingual: const {
          'en': 'Inject under aseptic precautions.',
          'mr': 'दररोज एकदा स्नायूमध्ये खोलवर इंजेक्शन द्यावे.',
        },
        scheduleHWarning: false,
        milkWithdrawalDays: 0,
        meatWithdrawalDays: 0,
        createdAt: DateTime.now(),
      );

      final saved = await repository.issuePrescription('CASE-SOL-001', newRx);
      expect(saved.id, 'RX-TEST-999');
      expect(saved.digitalSignatureHash, isNotEmpty);
      expect(saved.digitalSignatureHash!.length, 64); // SHA-256 hex string length

      // Verify case has updated prescription list and status
      final caseModel = await repository.getCaseById('CASE-SOL-001');
      expect(caseModel!.prescriptions.length, 1);
      expect(caseModel.status, CaseStatus.prescriptionIssued);
      expect(caseModel.prescriptions.first.digitalSignatureHash, saved.digitalSignatureHash);
    });

    test('creates telemedicine session with ICE STUN server configs', () async {
      final session = await repository.createTelemedicineSession('CASE-SOL-001');
      expect(session.caseId, 'CASE-SOL-001');
      expect(session.roomId, isNotEmpty);
      expect(session.isLowBandwidthMode, isTrue);
      expect(session.iceServers, isNotEmpty);
      expect(session.iceServers.any((s) => s.toString().contains('stun')), isTrue);
    });
  });
}
