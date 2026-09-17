import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/theme/app_theme.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/surveillance/bloc/surveillance_bloc.dart';
import 'package:bioherd/features/surveillance/data/surveillance_repository.dart';
import 'package:bioherd/features/surveillance/models/surveillance_model.dart';
import 'package:bioherd/features/surveillance/presentation/surveillance_map_screen.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/district_risk_card.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/outbreak_alert_banner.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/quarantine_protocols_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSurveillanceRepository repository;
  late SurveillanceBloc bloc;

  const testDistrict = DistrictRiskModel(
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
  );

  final testAlert = SurveillanceAlertModel(
    id: 'alt-001',
    alertType: 'outbreak',
    severity: SeverityLevel.critical,
    titleEn: 'FMD Outbreak Declared in Solapur District',
    titleMr: 'सोलापूर जिल्ह्यात लाळ-खुरकत (FMD) प्रादुर्भाव घोषित',
    bodyEn: '5km containment zone activated. Animal transit restricted.',
    bodyMr: '५ किमी नियंत्रण क्षेत्र सक्रिय करण्यात आले आहे.',
    channels: const ['push', 'sms'],
    isRead: false,
    createdAt: DateTime.now(),
    distanceKm: 4.2,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await OfflineFirstSurveillanceRepository.create();
    bloc = SurveillanceBloc(repository: repository);
    bloc.add(const LoadSurveillanceDataEvent());
  });

  tearDown(() {
    bloc.close();
  });

  Widget buildTestApp(Widget child) {
    return BlocProvider<SurveillanceBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Surveillance Widget Tests', () {
    testWidgets('DistrictRiskCard renders score, level, R0 and Marathi text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DistrictRiskCard(district: testDistrict),
        ),
      ));

      expect(find.text('Solapur'), findsOneWidget);
      expect(find.text('(सोलापूर)'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('88.5/100'), findsOneWidget);
      expect(find.text('Foot and Mouth Disease (FMD)'), findsOneWidget);
      expect(find.text('142 Active Cases'), findsOneWidget);
      expect(find.text('2.85'), findsOneWidget);
    });

    testWidgets('OutbreakAlertBanner renders bilingual alert details', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: OutbreakAlertBanner(alert: testAlert),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FMD Outbreak Declared in Solapur District'), findsOneWidget);
      expect(find.text('सोलापूर जिल्ह्यात लाळ-खुरकत (FMD) प्रादुर्भाव घोषित'), findsOneWidget);
      expect(find.text('५ किमी नियंत्रण क्षेत्र सक्रिय करण्यात आले आहे.'), findsOneWidget);
    });

    testWidgets('QuarantineProtocolsDialog displays official containment directives', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const QuarantineProtocolsDialog(),
              ),
              child: const Text('Open Protocol'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Protocol'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quarantine & Biosecurity Directives'), findsOneWidget);
      expect(find.text('Complete 5km Livestock Movement Ban'), findsOneWidget);
      expect(find.text('Mandatory Strict Isolation'), findsOneWidget);
    });

    testWidgets('SurveillanceMapScreen renders map canvas, filter chips and leaderboard tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const SurveillanceMapScreen()));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Outbreak Surveillance'), findsOneWidget);
      expect(find.text('रोग प्रादुर्भाव व भौगोलिक देखरेख (Maharashtra GIS)'), findsOneWidget);
      expect(find.text('All Diseases (सर्व)'), findsOneWidget);
      expect(find.text('FMD (लाळ्या खुरकूत)'), findsOneWidget);

      // Switch to Districts tab
      await tester.tap(find.text('Districts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show Solapur, Kolhapur cards
      expect(find.text('Solapur'), findsOneWidget);
      expect(find.text('Kolhapur'), findsOneWidget);
    });
  });
}
