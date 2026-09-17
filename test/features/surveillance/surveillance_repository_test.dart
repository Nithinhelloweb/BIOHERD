import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/surveillance/data/surveillance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSurveillanceRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstSurveillanceRepository.create();
  });

  group('OfflineFirstSurveillanceRepository Tests', () {
    test('getDistrictRiskRankings returns Maharashtra districts sorted by risk score', () async {
      final districts = await repository.getDistrictRiskRankings();
      expect(districts.length, greaterThanOrEqualTo(8));

      // Verify descending order
      for (int i = 0; i < districts.length - 1; i++) {
        expect(districts[i].riskScore >= districts[i + 1].riskScore, isTrue);
      }

      // Top districts should have high or critical risk
      final topDistrict = districts.first;
      expect(topDistrict.riskScore, greaterThanOrEqualTo(80.0));
      expect(topDistrict.districtName, isNotEmpty);
      expect(topDistrict.districtNameMr, isNotEmpty);

      // Verify key districts are present with Marathi translations
      final solapur = districts.firstWhere((d) => d.districtName == 'Solapur');
      expect(solapur.districtNameMr, 'सोलापूर');
      expect(solapur.severity, SeverityLevel.critical);
      expect(solapur.r0Estimate, greaterThan(1.0));

      final kolhapur = districts.firstWhere((d) => d.districtName == 'Kolhapur');
      expect(kolhapur.districtNameMr, 'कोल्हापूर');
      expect(kolhapur.severity, SeverityLevel.high);
    });

    test('getActiveClusters returns baseline Maharashtra clusters with containment specs', () async {
      final clusters = await repository.getActiveClusters();
      expect(clusters.length, greaterThanOrEqualTo(3));

      final fmdCluster = clusters.firstWhere((c) => c.diseaseName.contains('FMD') || c.diseaseName.contains('Foot'));
      expect(fmdCluster.containmentRadiusKm, 5.0);
      expect(fmdCluster.surveillanceRadiusKm, 10.0);
      expect(fmdCluster.r0Estimate, greaterThan(2.0));
      expect(fmdCluster.districtName, 'Solapur');
      expect(fmdCluster.affectedFarmsCount, greaterThan(0));

      final lsdCluster = clusters.firstWhere((c) => c.diseaseName.contains('Lumpy Skin'));
      expect(lsdCluster.districtName, 'Kolhapur');
      expect(lsdCluster.r0Estimate, greaterThan(1.5));
    });

    test('getDistrictRisk retrieves specific district profile', () async {
      final district = await repository.getDistrictRisk('dist-solapur');
      expect(district, isNotNull);
      expect(district!.districtName, 'Solapur');
      expect(district.districtNameMr, 'सोलापूर');
      expect(district.activeCases, greaterThan(0));
      expect(district.primaryDisease, contains('Foot and Mouth'));
    });

    test('getSurveillanceAlerts returns bilingual alerts for farmers', () async {
      final alerts = await repository.getSurveillanceAlerts();
      expect(alerts.isNotEmpty, isTrue);

      final criticalAlert = alerts.firstWhere((a) => a.severity == SeverityLevel.critical);
      expect(criticalAlert.titleEn, isNotEmpty);
      expect(criticalAlert.titleMr, contains('सोलापूर'));
      expect(criticalAlert.bodyMr, isNotEmpty);
    });

    test('declareQuarantine updates cluster quarantine status', () async {
      final clustersBefore = await repository.getActiveClusters();
      final clusterToQuarantine = clustersBefore.firstWhere((c) => !c.quarantineDeclared);

      await repository.declareQuarantine(clusterToQuarantine.id);

      final clustersAfter = await repository.getActiveClusters();
      final updatedCluster = clustersAfter.firstWhere((c) => c.id == clusterToQuarantine.id);
      expect(updatedCluster.quarantineDeclared, isTrue);
    });
  });
}
