import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bioherd/core/theme/app_theme.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/surveillance/models/eco_climate_model.dart';
import 'package:bioherd/features/surveillance/models/surveillance_model.dart';
import 'package:bioherd/features/surveillance/services/epizootic_prediction_service.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/what_if_intervention_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDistricts = [
    const DistrictRiskModel(
      districtId: 'dist-solapur',
      districtName: 'Solapur',
      districtNameMr: 'सोलापूर',
      latitude: 17.6599,
      longitude: 75.9064,
      livestockPopulation: 450000,
      activeCases: 142,
      riskScore: 88.5,
      severity: SeverityLevel.critical,
      r0Estimate: 2.85,
      weatherFactor: 1.4,
      caseDensityPer10k: 3.16,
      primaryDisease: 'Foot and Mouth Disease (FMD)',
    ),
    const DistrictRiskModel(
      districtId: 'dist-osmanabad',
      districtName: 'Osmanabad',
      districtNameMr: 'उस्मानाबाद',
      latitude: 18.1856,
      longitude: 76.0419,
      livestockPopulation: 320000,
      activeCases: 38,
      riskScore: 72.0,
      severity: SeverityLevel.high,
      r0Estimate: 1.95,
      weatherFactor: 1.25,
      caseDensityPer10k: 1.18,
      primaryDisease: 'Lumpy Skin Disease (LSD)',
    ),
    const DistrictRiskModel(
      districtId: 'dist-pune',
      districtName: 'Pune',
      districtNameMr: 'पुणे',
      latitude: 18.5204,
      longitude: 73.8567,
      livestockPopulation: 680000,
      activeCases: 5,
      riskScore: 24.0,
      severity: SeverityLevel.low,
      r0Estimate: 0.95,
      weatherFactor: 1.05,
      caseDensityPer10k: 0.07,
      primaryDisease: 'Haemorrhagic Septicaemia (HS)',
    ),
  ];

  final testClusters = [
    OutbreakClusterModel(
      id: 'cluster-solapur-1',
      districtId: 'dist-solapur',
      districtName: 'Solapur',
      districtNameMr: 'सोलापूर',
      diseaseName: 'Foot and Mouth Disease (FMD)',
      diseaseNameMr: 'लाळ-खुरकत',
      caseCount: 142,
      riskLevel: SeverityLevel.critical,
      latitude: 17.6599,
      longitude: 75.9064,
      containmentRadiusKm: 5.0,
      surveillanceRadiusKm: 10.0,
      r0Estimate: 2.85,
      affectedFarmsCount: 28,
      quarantineDeclared: true,
      declaredAt: DateTime.now().subtract(const Duration(days: 3)),
      notesEn: 'Epicenter around Sangola cattle mandi.',
      notesMr: 'सांगोला जनावरांच्या बाजाराभोवती प्रादुर्भाव.',
    ),
  ];

  group('Eco-Climate & Environmental Telemetry Tests', () {
    test('DistrictEcoClimateModel default profiles are rich and valid', () {
      final solapurEco = DistrictEcoClimateModel.getProfileForDistrict('Solapur');
      expect(solapurEco.districtName, equals('Solapur'));
      expect(solapurEco.vectorViabilityIndex, greaterThanOrEqualTo(0.8));
      expect(solapurEco.vectorBreedingRiskLevel, equals('CRITICAL'));
      expect(solapurEco.landSurfaceTempC, equals(34.2));
      expect(solapurEco.windSpeedKmH, greaterThan(20.0));
      expect(solapurEco.microclimateContagionMultiplier, greaterThan(1.5));

      final kolhapurEco = DistrictEcoClimateModel.getProfileForDistrict('Kolhapur');
      expect(kolhapurEco.soilMoistureSaturationPct, greaterThan(70.0));
      expect(kolhapurEco.stagnantWaterIndex, greaterThan(0.8));
    });

    test('Generic fallback profile is returned for unlisted district', () {
      final genericEco = DistrictEcoClimateModel.getProfileForDistrict('Sindhudurg');
      expect(genericEco.districtName, equals('Sindhudurg'));
      expect(genericEco.vectorBreedingRiskLevel, equals('MODERATE'));
    });
  });

  group('Epizootic Spatio-Temporal Prediction Service Tests', () {
    test('computeForecast computes baseline at NOW (T-0)', () {
      final forecast = EpizooticPredictionService.computeForecast(
        districts: testDistricts,
        clusters: testClusters,
        horizon: PredictionHorizon.now,
        policies: const PolicyIntervention(),
      );

      expect(forecast.horizon, equals(PredictionHorizon.now));
      expect(forecast.totalCurrentCases, equals(185)); // 142 + 38 + 5
      expect(forecast.totalProjectedCases, equals(185));
      expect(forecast.projectedEpicentersCount, greaterThanOrEqualTo(1));
      expect(forecast.sitRepBriefing, contains('ACTIVE SITUATION [T-0]'));
    });

    test('computeForecast projects unconstrained exponential growth at +14 Days', () {
      final forecast = EpizooticPredictionService.computeForecast(
        districts: testDistricts,
        clusters: testClusters,
        horizon: PredictionHorizon.day14,
        policies: const PolicyIntervention(), // Zero interventions
      );

      expect(forecast.horizon, equals(PredictionHorizon.day14));
      expect(forecast.totalProjectedCases, greaterThan(forecast.totalCurrentCases));
      expect(forecast.sitRepBriefing, contains('UNCONTROLLED PROJECTION [+14 DAYS]'));
      expect(forecast.sitRepBriefingMr, contains('अनियंत्रित अंदाज [+14 दिवस]'));

      final solapurResult = forecast.districtForecasts['dist-solapur'];
      expect(solapurResult, isNotNull);
      expect(solapurResult!.projectedCases, greaterThan(solapurResult.baselineCases));
      expect(solapurResult.downwindPlumeDistanceKm, greaterThan(25.0));
      expect(solapurResult.spilloverProbabilities['Osmanabad'], greaterThan(0.5));
    });

    test('Policy interventions dramatically reduce contagion spread', () {
      final unmitigated = EpizooticPredictionService.computeForecast(
        districts: testDistricts,
        clusters: testClusters,
        horizon: PredictionHorizon.day14,
        policies: const PolicyIntervention(),
      );

      final mitigated = EpizooticPredictionService.computeForecast(
        districts: testDistricts,
        clusters: testClusters,
        horizon: PredictionHorizon.day14,
        policies: const PolicyIntervention(
          mandiMoratoriumActive: true,
          ringVaccinationActive: true,
          borderCheckpointsActive: true,
          vectorFoggingActive: true,
        ),
      );

      expect(mitigated.totalProjectedCases, lessThan(unmitigated.totalProjectedCases));
      expect(mitigated.activeInterventions.activePolicyCount, equals(4));
      expect(mitigated.sitRepBriefing, contains('WITH 4 INTERVENTIONS'));

      final solapurMitigated = mitigated.districtForecasts['dist-solapur']!;
      final solapurUnmitigated = unmitigated.districtForecasts['dist-solapur']!;
      expect(solapurMitigated.projectedCases, lessThan(solapurUnmitigated.projectedCases));
      expect(solapurMitigated.projectedContainmentRadiusKm, lessThan(solapurUnmitigated.projectedContainmentRadiusKm));
    });
  });

  group('WhatIfInterventionDialog Widget Tests', () {
    testWidgets('Renders policy switches, comparative tiles, and applies policies', (tester) async {
      PredictionHorizon? appliedHorizon;
      PolicyIntervention? appliedPolicies;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => WhatIfInterventionDialog.show(
                  ctx,
                  districts: testDistricts,
                  clusters: testClusters,
                  onApplyPolicies: (h, p) {
                    appliedHorizon = h;
                    appliedPolicies = p;
                  },
                ),
                child: const Text('Open Simulator'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Simulator'));
      await tester.pumpAndSettle();

      // Verify Header & Sections
      expect(find.text('EPIZOOTIC "WHAT-IF" POLICY SIMULATOR'), findsOneWidget);
      expect(find.text('PREDICTION HORIZON TIMELINE'), findsOneWidget);
      expect(find.text('TEST POLICY INTERVENTIONS'), findsOneWidget);
      expect(find.text('PREDICTED CONTAGION IMPACT'), findsOneWidget);

      // Verify Policy Switches
      expect(find.text('Mandi Trade Moratorium'), findsOneWidget);
      expect(find.text('Emergency 5km Ring Vaccination (72h Target)'), findsOneWidget);
      expect(find.text('Highway Police & RTO Transit Checkpoints'), findsOneWidget);
      expect(find.text('Aerial Vector Insecticide Fogging'), findsOneWidget);

      // Toggle Mandi Trade Moratorium
      await tester.tap(find.text('Mandi Trade Moratorium'));
      await tester.pumpAndSettle();

      // Toggle Ring Vaccination
      await tester.tap(find.text('Emergency 5km Ring Vaccination (72h Target)'));
      await tester.pumpAndSettle();

      // Switch Horizon to +30 Days
      await tester.tap(find.text('+30 Days (Extended)'));
      await tester.pumpAndSettle();

      // Tap Apply Scenario to Live Map
      expect(find.text('Apply Scenario to Live Map'), findsOneWidget);
      await tester.tap(find.text('Apply Scenario to Live Map'));
      await tester.pumpAndSettle();

      expect(appliedHorizon, equals(PredictionHorizon.day30));
      expect(appliedPolicies, isNotNull);
      expect(appliedPolicies!.mandiMoratoriumActive, isTrue);
      expect(appliedPolicies!.ringVaccinationActive, isTrue);
    });
  });
}
