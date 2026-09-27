import 'package:bioherd/features/surveillance/presentation/widgets/district_tactical_dossier_dialog.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/containment_cordon_config_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/theme/app_theme.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/core/services/auth_storage_service.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/data/auth_repository.dart';
import 'package:bioherd/features/auth/models/user_model.dart';
import 'package:bioherd/features/surveillance/bloc/surveillance_bloc.dart';
import 'package:bioherd/features/surveillance/data/surveillance_repository.dart';
import 'package:bioherd/features/surveillance/models/surveillance_model.dart';
import 'package:bioherd/features/surveillance/presentation/surveillance_map_screen.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/district_risk_card.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/outbreak_alert_banner.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/quarantine_protocols_dialog.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/transit_manifest_sheet.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/telemetry_feed_dialog.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/simulation_outbreak_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFirstSurveillanceRepository repository;
  late SurveillanceBloc bloc;
  late AuthBloc authBloc;

  const testDistrict = DistrictRiskModel(
    districtId: 'dist-solapur',
    districtName: 'Solapur',
    districtNameMr: 'Solapur',
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
    titleMr: 'CRITICAL: FMD Outbreak — Solapur District',
    bodyEn: '5km containment zone activated. Animal transit restricted.',
    bodyMr: '5km containment zone activated. Animal transit restricted.',
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

    final prefs = await SharedPreferences.getInstance();
    final authRepo = AuthRepository(storage: AuthStorageService(prefs));
    authBloc = AuthBloc(authRepository: authRepo);
    authBloc.add(const DemoLoginRequested(UserRole.dvoOfficer));
  });

  tearDown(() {
    bloc.close();
    authBloc.close();
  });

  Widget buildTestApp(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SurveillanceBloc>.value(value: bloc),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Surveillance Widget Tests', () {
    testWidgets('DistrictRiskCard renders score, level, R0 and English text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DistrictRiskCard(district: testDistrict),
        ),
      ));

      expect(find.text('Solapur'), findsWidgets);
      expect(find.text('(Solapur)'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('88.5/100'), findsOneWidget);
      expect(find.text('Foot and Mouth Disease (FMD)'), findsOneWidget);
      expect(find.text('142 Active Cases'), findsOneWidget);
      expect(find.text('2.85'), findsOneWidget);
    });

    testWidgets('OutbreakAlertBanner renders alert details', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: OutbreakAlertBanner(alert: testAlert),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FMD Outbreak Declared in Solapur District'), findsOneWidget);
      expect(find.text('CRITICAL: FMD Outbreak — Solapur District'), findsOneWidget);
      expect(find.text('5km containment zone activated. Animal transit restricted.'), findsWidgets);
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
      expect(find.textContaining('Complete 5km Livestock Movement Ban'), findsOneWidget);
      expect(find.textContaining('Mandatory Strict Isolation'), findsOneWidget);
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
      expect(find.text('Disease Outbreaks & Geospatial Surveillance (Maharashtra GIS)'), findsOneWidget);
      expect(find.text('All Diseases'), findsOneWidget);
      expect(find.text('FMD'), findsOneWidget);

      // Switch to Districts tab
      await tester.tap(find.text('Districts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show Solapur, Kolhapur cards
      expect(find.text('Solapur'), findsWidgets);
      expect(find.text('Kolhapur'), findsOneWidget);
    });

    testWidgets('TransitManifestSheet renders carrier, vehicle and biosecurity info', (tester) async {
      final testVehicle = LivestockTransitVehicle(
        id: 'truck-test-1',
        licensePlate: 'MH-12-TEST-99',
        carrierName: 'Kisan Transit Cooperative',
        originDistrict: 'Pune',
        destinationDistrict: 'Solapur',
        originLat: 18.5204,
        originLon: 73.8567,
        destLat: 17.6599,
        destLon: 75.9064,
        currentLat: 18.1,
        currentLon: 74.5,
        progress: 0.45,
        speedKmH: 52.0,
        animalHeadCount: 35,
        species: 'Bovine',
        biosecurityStatus: 'Clear',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 98765 43210',
        dispatchedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TransitManifestSheet(vehicle: testVehicle),
        ),
      ));

      expect(find.text('MH-12-TEST-99'), findsOneWidget);
      expect(find.text('Kisan Transit Cooperative'), findsOneWidget);
      expect(find.text('TRANSIT CORRIDOR'), findsOneWidget);
      expect(find.text('35 head'), findsOneWidget);
      expect(find.text('Bovine'), findsOneWidget);
    });

    testWidgets('TelemetryFeedDialog renders real-time event logs and filter chips', (tester) async {
      final testLogs = [
        LiveSurveillanceLog(
          id: 'log-1',
          timestamp: DateTime.now(),
          district: 'Solapur',
          message: 'Containment checkpoint activated on NH-65 corridor',
          severity: SeverityLevel.critical,
          eventType: 'outbreak_surge',
        ),
        LiveSurveillanceLog(
          id: 'log-2',
          timestamp: DateTime.now(),
          district: 'Pune',
          message: 'Transit vehicle MH-12-AB-1234 cleared screening',
          severity: SeverityLevel.low,
          eventType: 'transit_screened',
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TelemetryFeedDialog(logs: testLogs),
        ),
      ));

      expect(find.text('Live Simulation Telemetry Stream'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Surge'), findsOneWidget);
      expect(find.text('Transit'), findsOneWidget);
      expect(find.text('Containment checkpoint activated on NH-65 corridor'), findsOneWidget);
      expect(find.text('Transit vehicle MH-12-AB-1234 cleared screening'), findsOneWidget);
    });

    testWidgets('SimulationOutbreakDialog displays district and pathogen selectors', (tester) async {
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<SurveillanceBloc>.value(value: bloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SimulationOutbreakDialog(districts: [testDistrict]),
          ),
        ),
      ));

      expect(find.text('Simulate Outbreak Surge'), findsOneWidget);
      expect(find.text('Target District'), findsOneWidget);
      expect(find.text('Pathogen / Disease'), findsOneWidget);
      expect(find.text('Inject Outbreak Surge'), findsOneWidget);
    });

    testWidgets('SurveillanceMapScreen renders and toggles Satellite and Normal Map view modes', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const SurveillanceMapScreen()));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Style chips are present
      expect(find.text('Satellite View'), findsWidgets);
      expect(find.text('Normal Map'), findsWidgets);

      // In default Normal Map mode, orbital recon banner is dismissed
      expect(find.textContaining('SENTINEL-2'), findsNothing);

      // Switch to Satellite mode
      await tester.tap(find.text('Satellite View').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In Satellite mode, orbital recon banner is shown
      expect(find.textContaining('SENTINEL-2'), findsOneWidget);

      // Switch back to Normal Map mode
      await tester.tap(find.text('Normal Map').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Orbital banner should be dismissed in Normal Map mode
      expect(find.textContaining('SENTINEL-2'), findsNothing);
    });

    testWidgets('SurveillanceMapScreen renders eStream satellite reconnaissance and clean view toggle', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const SurveillanceMapScreen()));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Satellite mode to view eStream satellite reconnaissance
      await tester.tap(find.text('Satellite View').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // eStream Recon Banner is present with Sentinel-2
      expect(find.textContaining('eStream™ ORBITAL SATELLITE RECON'), findsOneWidget);
      expect(find.textContaining('SENTINEL-2'), findsOneWidget);

      // Swath toggle is present
      expect(find.text('Swaths: ON'), findsOneWidget);
      await tester.tap(find.text('Swaths: ON'));
      await tester.pump();
      expect(find.text('Swaths: OFF'), findsOneWidget);

      // Clean View button is present
      expect(find.text('Clean View'), findsOneWidget);

      // Enter Clean View (Zen mode)
      await tester.tap(find.text('Clean View'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In Clean View, Exit Clean View button is visible
      expect(find.text('Exit Clean View'), findsOneWidget);

      // Exit Clean View
      await tester.tap(find.text('Exit Clean View'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Restored back to standard controls
      expect(find.text('Clean View'), findsOneWidget);
      expect(find.text('Outbreak Surveillance'), findsOneWidget);
    });

    testWidgets('DistrictTacticalDossierDialog displays C4I telemetry, DVC stock and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DistrictTacticalDossierDialog.show(ctx, testDistrict),
                child: const Text('Open Dossier'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dossier'));
      await tester.pumpAndSettle();

      // District Name & RTO Code
      expect(find.text('Solapur'), findsWidgets);
      expect(find.text('MH-13'), findsOneWidget);

      // Epidemiological Telemetry
      expect(find.text('Active Cases'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('R0 Estimate'), findsOneWidget);
      expect(find.text('2.85'), findsOneWidget);

      // C4I Tactical Intervention Commands
      expect(find.text('Activate 1km/3km/10km Ring Containment Cordon'), findsOneWidget);
      expect(find.text('Vaccine Dispatch'), findsOneWidget);
      expect(find.text('Farmer Alert'), findsOneWidget);
      expect(find.text('Mandi Moratorium'), findsOneWidget);
    });

    testWidgets('ContainmentCordonConfigDialog renders multi-tier sliders and deploy button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ContainmentCordonConfigDialog.show(ctx, district: testDistrict),
                child: const Text('Open Cordon Config'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Cordon Config'));
      await tester.pumpAndSettle();

      expect(find.text('DYNAMIC RING CONTAINMENT CORDON'), findsOneWidget);
      expect(find.textContaining('TIER 1: INFECTED ZONE CORDON'), findsOneWidget);
      expect(find.textContaining('TIER 2: SURVEILLANCE ZONE'), findsOneWidget);
      expect(find.textContaining('TIER 3: VACCINATION BUFFER SHIELD'), findsOneWidget);
      expect(find.text('Deploy Containment Cordon'), findsOneWidget);
    });

    testWidgets('SurveillanceMapScreen renders Ring Cordon Tool HUD button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const SurveillanceMapScreen()));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ring Cordon Tool'), findsOneWidget);
    });
  });
}
