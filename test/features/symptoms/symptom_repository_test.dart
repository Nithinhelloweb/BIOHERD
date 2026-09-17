import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/symptoms/data/symptom_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSymptomRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstSymptomRepository.create();
  });

  group('OfflineFirstSymptomRepository Tests', () {
    test('getBodySystemCategories returns 6 categories with symptoms and Marathi terms', () {
      final categories = repository.getBodySystemCategories();
      expect(categories.length, 6);

      final categoryIds = categories.map((c) => c.id).toList();
      expect(categoryIds, containsAll([
        'vitality',
        'skin_coat',
        'oral_nasal',
        'locomotion',
        'udder_milk',
        'digestive_excretory',
      ]));

      // Verify Marathi translations present
      for (final cat in categories) {
        expect(cat.nameMr.isNotEmpty, isTrue);
        expect(cat.symptoms.isNotEmpty, isTrue);
        for (final s in cat.symptoms) {
          expect(s.nameMr.isNotEmpty, isTrue);
        }
      }
    });

    test('Initial seeding creates demo reports (LSD Pune and Mastitis Solapur)', () async {
      final reports = await repository.getReports();
      expect(reports.length, greaterThanOrEqualTo(2));

      final lsdReport = reports.firstWhere((r) => r.animalTagId == 'MH-PUN-GIR-104');
      expect(lsdReport.severity, SeverityLevel.critical);
      expect(lsdReport.detectionResult, isNotNull);
      expect(lsdReport.detectionResult!.primaryDiagnosis.diseaseId, 'dis-lsd');

      final mastitisReport = reports.firstWhere((r) => r.animalTagId == 'MH-SOL-KHL-201');
      expect(mastitisReport.severity, SeverityLevel.medium);
      expect(mastitisReport.detectionResult!.primaryDiagnosis.diseaseId, 'dis-mastitis');
    });

    test('submitReport with LSD symptoms generates accurate AI diagnosis and first aid', () async {
      final report = await repository.submitReport(
        animalId: 'test-cow-001',
        animalTagId: 'MH-SAT-044',
        species: 'Cattle',
        breed: 'Dangi',
        symptomsChecklist: {
          'skin_coat': ['nodular_skin_lesions', 'hard_nodules_all_over_body'],
          'vitality': ['high_fever'],
        },
        vernacularDescription: 'अंगावर मोठ्या कडक गाठी आल्या आहेत आणि ताप आहे',
        images: ['nodular_skin_lesions.jpg'],
      );

      expect(report.animalTagId, 'MH-SAT-044');
      expect(report.severity, anyOf(SeverityLevel.high, SeverityLevel.critical));
      expect(report.detectionResult, isNotNull);

      final primary = report.detectionResult!.primaryDiagnosis;
      expect(primary.diseaseId, 'dis-lsd');
      expect(primary.confidence, greaterThanOrEqualTo(0.8));
      expect(primary.diseaseNameMr, anyOf(contains('लंपी'), contains('लम्पी')));

      // Check first aid
      final firstAid = report.detectionResult!.firstAid;
      expect(firstAid.isolationProtocolsMr.isNotEmpty, isTrue);
      expect(firstAid.disinfectionMr.isNotEmpty, isTrue);
      expect(firstAid.emergencyHotline, '1962');

      // Verify report was persisted
      final fetched = await repository.getReportById(report.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, report.id);
    });

    test('submitReport with Mastitis symptoms triggers udder protocol', () async {
      final report = await repository.submitReport(
        animalId: 'test-cow-002',
        animalTagId: 'MH-KOL-112',
        species: 'Buffalo',
        breed: 'Murrah',
        symptomsChecklist: {
          'udder_milk': ['swollen_hot_painful_udder', 'clots_flakes_watery_milk'],
        },
        vernacularDescription: 'कास खूप सुजली आहे आणि दुधात गाठी येतात',
      );

      expect(report.detectionResult, isNotNull);
      final primary = report.detectionResult!.primaryDiagnosis;
      expect(primary.diseaseId, 'dis-mastitis');
      expect(report.detectionResult!.firstAid.supportiveCareMr, anyOf(contains('कास'), contains('सड')));
    });
  });
}
