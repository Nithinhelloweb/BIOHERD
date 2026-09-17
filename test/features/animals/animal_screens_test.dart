import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/data/animal_repository.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/animals/presentation/animal_list_screen.dart';
import 'package:bioherd/features/animals/presentation/widgets/animal_passport_dialog.dart';
import 'package:bioherd/features/animals/presentation/widgets/qr_scan_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child, AnimalBloc bloc) {
    return MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: child,
      ),
    );
  }

  group('Animal Screens Widget Tests', () {
    testWidgets('AnimalListScreen renders herd overview, stats, and search bar', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = await OfflineFirstAnimalRepository.create();
      final bloc = AnimalBloc(repository: repo);
      bloc.add(const LoadAnimalsEvent());

      await tester.pumpWidget(createTestWidget(const AnimalListScreen(), bloc));
      await tester.pumpAndSettle();

      // Verify Header and Subtitle
      expect(find.text('Livestock Registry'), findsOneWidget);
      expect(find.text('पशुधन नोंदणी व आरोग्य व्यवस्थापन'), findsOneWidget);

      // Verify Stats row
      expect(find.text('Total Herd'), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);

      // Verify Animals loaded
      expect(find.text('MH-PUN-GIR-104'), findsOneWidget);
      expect(find.textContaining('Gir'), findsWidgets);

      // Verify FAB
      expect(find.text('Register Animal / नोंदणी'), findsOneWidget);

      bloc.close();
    });

    testWidgets('QRScanDialog renders camera viewport and demo sample tag chips', (tester) async {
      String? detectedTag;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRScanDialog(
              onTagDetected: (tag) => detectedTag = tag,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Scan Animal Tag'), findsOneWidget);
      expect(find.text('Align Ear Tag / QR in frame'), findsOneWidget);
      expect(find.text('Gir Cow (Pune)'), findsOneWidget);

      // Tap on Gir Cow chip to simulate scan
      await tester.tap(find.text('Gir Cow (Pune)'));
      await tester.pump();

      expect(detectedTag, 'MH-PUN-GIR-104');
    });

    testWidgets('AnimalPassportDialog renders official Govt of Maharashtra header and verification hash', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final passport = AnimalPassport(
        animalId: 'test-01',
        tagId: 'MH-SOL-KHL-201',
        species: 'Cattle / गाय',
        breed: 'Khillari',
        sex: 'male',
        weightKg: 485.0,
        ageMonths: 48,
        farmId: 'farm-01',
        farmName: 'Patil Khillari Farm',
        districtName: 'Solapur, Maharashtra',
        ownerName: 'Sanjay Patil',
        ownerPhone: '+91 98765 00002',
        isActive: true,
        registeredAt: DateTime(2026, 1, 15),
        healthEventsCount: 3,
        vaccinationsCount: 2,
        recentEvents: [],
        verificationHash: '3E9D2C8A7B6F1C4E',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalPassportDialog(passport: passport),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GOVT OF MAHARASHTRA • BIOHERD'), findsOneWidget);
      expect(find.text('MH-SOL-KHL-201'), findsOneWidget);
      expect(find.textContaining('Khillari'), findsWidgets);
      expect(find.text('VERIFICATION HASH: 3E9D2C8A7B6F1C4E'), findsOneWidget);
      expect(find.text('Print / शेअर करा'), findsOneWidget);
    });
  });
}
