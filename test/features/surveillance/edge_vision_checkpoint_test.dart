import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bioherd/features/surveillance/models/edge_vision_model.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/edge_vision_inspection_dialog.dart';
import 'package:bioherd/features/surveillance/models/surveillance_model.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/transit_manifest_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Biosecurity Checkpoint & Edge Vision Models Tests', () {
    test('Preseeded checkpoints are valid and cover major corridors', () {
      final checkpoints = BiosecurityCheckpoint.getPreseededCheckpoints();
      expect(checkpoints.length, greaterThanOrEqualTo(5));

      final ckpSolapur = checkpoints.firstWhere((c) => c.id == 'ckp-01');
      expect(ckpSolapur.district, 'Solapur');
      expect(ckpSolapur.hasThermalChute, isTrue);
      expect(ckpSolapur.disinfectionArchwayActive, isTrue);
      expect(ckpSolapur.cameraFeeds.length, greaterThanOrEqualTo(3));
      expect(ckpSolapur.statusColor, const Color(0xFFF59E0B)); // screeningDivert
    });

    test('EdgeLesionDetection model correctly serializes and stores bounding boxes', () {
      const det = EdgeLesionDetection(
        id: 'det-01',
        lesionType: 'Circumscribed Cutaneous Nodule',
        confidence: 0.962,
        boundingBox: Rect.fromLTWH(0.24, 0.32, 0.22, 0.25),
        anatomicalRegion: 'Dewlap & Left Shoulder',
        severity: 'Critical',
      );

      expect(det.confidence, 0.962);
      expect(det.severity, 'Critical');
      final json = det.toJson();
      expect(json['lesionType'], 'Circumscribed Cutaneous Nodule');
      expect(json['confidence'], 0.962);
      final bbox = (json['boundingBox'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
      expect(bbox[0], closeTo(0.24, 0.001));
      expect(bbox[1], closeTo(0.32, 0.001));
      expect(bbox[2], closeTo(0.22, 0.001));
      expect(bbox[3], closeTo(0.25, 0.001));
    });

    test('EdgeCameraFeed correctly calculates triage label, color and thermal fever', () {
      final ckp = BiosecurityCheckpoint.getPreseededCheckpoints().first;
      final feed = ckp.cameraFeeds.first;

      expect(feed.isFebrile, isTrue);
      expect(feed.thermalCoreTemp, 40.8);
      expect(feed.lamenessScore, 4);
      expect(feed.biosecurityTriage, BiosecurityTriage.impoundQuarantineRed);
      expect(feed.triageLabel, 'IMPOUND & QUARANTINE');
      expect(feed.triageColor, const Color(0xFFEF4444));
      expect(feed.angleName, 'Chute Cam A (Lateral)');
    });
  });

  group('EdgeVisionInspectionDialog Widget Tests', () {
    testWidgets('Renders checkpoint header, vision canvas, Pashu Aadhaar and detections', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ckp = BiosecurityCheckpoint.getPreseededCheckpoints().first;
      GateBarrierStatus? updatedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdgeVisionInspectionDialog(
              checkpoint: ckp,
              onGateStatusChanged: (status) => updatedStatus = status,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Checkpoint Header
      expect(find.text(ckp.name), findsOneWidget);
      expect(find.text('INTERSTATE BORDER POST'), findsOneWidget);

      // Camera Angle Tabs
      expect(find.text('Chute Cam A (Lateral)'), findsOneWidget);
      expect(find.text('FLIR Thermal Core'), findsOneWidget);

      // Pashu Aadhaar Dossier
      expect(find.text('PASHU AADHAAR / INAPH VERIFICATION'), findsOneWidget);
      expect(find.text('INAPH-MH-9481-2291'), findsOneWidget);
      expect(find.text('40.8°C'), findsOneWidget);
      expect(find.text('FEBRILE SPIKE'), findsOneWidget);
      expect(find.text('Score: 4/5'), findsOneWidget);

      // Detected Lesions
      expect(find.text('Circumscribed Cutaneous Nodule'), findsOneWidget);
      expect(find.text('Pustular Scab Lesion'), findsOneWidget);
      expect(find.text('Excessive Salivation Drool'), findsOneWidget);

      // Tactical Actuation Buttons
      expect(find.text('Engage Gate Clamp & Impound'), findsOneWidget);
      expect(find.text('Dispatch PCR Swab Unit'), findsOneWidget);
      expect(find.text('Grant E-Clearance Seal'), findsOneWidget);

      // Tap Engage Gate Clamp
      await tester.tap(find.text('Engage Gate Clamp & Impound'));
      await tester.pumpAndSettle();

      expect(updatedStatus, GateBarrierStatus.lockedDown);
      expect(find.textContaining('HYDRAULIC GATE CLAMP ENGAGED'), findsOneWidget);
    });

    testWidgets('Switching camera angle updates feed to Thermal FLIR', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ckp = BiosecurityCheckpoint.getPreseededCheckpoints().first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdgeVisionInspectionDialog(checkpoint: ckp),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on FLIR Thermal Core tab
      await tester.tap(find.text('FLIR Thermal Core'));
      await tester.pumpAndSettle();

      // Detections should now show Thermal Core Spike
      expect(find.text('Febrile Thermal Core Spike (40.8°C)'), findsOneWidget);
    });

    testWidgets('Granting E-Clearance Seal changes gate status to operational', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ckp = BiosecurityCheckpoint.getPreseededCheckpoints().first;
      GateBarrierStatus? updatedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdgeVisionInspectionDialog(
              checkpoint: ckp,
              onGateStatusChanged: (status) => updatedStatus = status,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grant E-Clearance Seal'));
      await tester.pumpAndSettle();

      expect(updatedStatus, GateBarrierStatus.operational);
      expect(find.textContaining('Digital Transit Pass QR Seal Issued'), findsOneWidget);
    });
  });

  group('TransitManifestSheet Edge Vision Button Tests', () {
    testWidgets('TransitManifestSheet renders Edge Vision button', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final vehicle = LivestockTransitVehicle(
        dispatchedAt: DateTime.now(),
        id: 'veh-01',
        licensePlate: 'MH-12-TR-4011',
        carrierName: 'Sahyadri Cattle Transport',
        originDistrict: 'Pune',
        destinationDistrict: 'Solapur',
        originLat: 18.5204,
        originLon: 73.8567,
        destLat: 17.6599,
        destLon: 75.9064,
        currentLat: 18.0,
        currentLon: 74.8,
        progress: 0.5,
        speedKmH: 45.0,
        animalHeadCount: 18,
        species: 'Bovine',
        biosecurityStatus: 'screening_required',
        hazardLevel: SeverityLevel.high,
        driverContact: '+91 98220 11223',
        
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitManifestSheet(vehicle: vehicle),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inspect via Checkpoint Edge Vision (YOLOv8)'), findsOneWidget);
    });
  });
}
