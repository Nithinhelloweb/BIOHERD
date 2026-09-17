import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/main.dart';
import 'package:bioherd/core/services/auth_storage_service.dart';
import 'package:bioherd/features/animals/data/animal_repository.dart';
import 'package:bioherd/features/auth/data/auth_repository.dart';
import 'package:bioherd/features/surveillance/data/surveillance_repository.dart';
import 'package:bioherd/features/symptoms/data/symptom_repository.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';

void main() {
  testWidgets('BioHerdApp smoke test and launch verification', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'bioherd_language': 'en',
      'bioherd_dark_mode': false,
    });

    final prefs = await SharedPreferences.getInstance();
    final authStorage = AuthStorageService(prefs);
    final authRepository = AuthRepository(storage: authStorage);
    final animalRepository = OfflineFirstAnimalRepository(prefs);
    final symptomRepository = OfflineFirstSymptomRepository(prefs: prefs);
    final surveillanceRepository = OfflineFirstSurveillanceRepository(prefs: prefs);
    final veterinaryRepository = OfflineFirstVeterinaryRepository(prefs);

    await tester.pumpWidget(BioHerdApp(
      initialLocale: const Locale('en'),
      initialThemeMode: ThemeMode.light,
      authRepository: authRepository,
      animalRepository: animalRepository,
      symptomRepository: symptomRepository,
      surveillanceRepository: surveillanceRepository,
      veterinaryRepository: veterinaryRepository,
    ));

    await tester.pump();

    // Verify app title and showcase screen loads
    expect(find.text('BIOHERD Design System'), findsOneWidget);
    expect(find.text('1. Brand & Semantic Color Tokens'), findsOneWidget);
  });
}
