import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bioherd/core/theme/app_theme.dart';
import 'package:bioherd/core/widgets/ai_confidence_meter.dart';
import 'package:bioherd/core/widgets/animal_card.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/offline_banner.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';

void main() {
  group('BioHerdButton Tests', () {
    testWidgets('renders primary button and handles tap callback', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BioHerdButton(
              label: 'Submit Report',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Report'), findsOneWidget);
      await tester.tap(find.byType(BioHerdButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator and prevents tap when isLoading is true', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BioHerdButton(
              label: 'Loading Button',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
      await tester.tap(find.byType(BioHerdButton));
      expect(tapped, isFalse);
    });
  });

  group('SeverityBadge Tests', () {
    testWidgets('renders all severity levels with proper labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                SeverityBadge(level: SeverityLevel.low),
                SeverityBadge(level: SeverityLevel.medium),
                SeverityBadge(level: SeverityLevel.high),
                SeverityBadge(level: SeverityLevel.critical),
              ],
            ),
          ),
        ),
      );

      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
    });
  });

  group('BioHerdCard Tests', () {
    testWidgets('renders child content and handles tap', (WidgetTester tester) async {
      bool cardTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BioHerdCard(
              severity: CardSeverity.critical,
              onTap: () => cardTapped = true,
              child: const Text('Critical Disease Alert'),
            ),
          ),
        ),
      );

      expect(find.text('Critical Disease Alert'), findsOneWidget);
      await tester.tap(find.byType(BioHerdCard));
      expect(cardTapped, isTrue);
    });
  });

  group('AIConfidenceMeter Tests', () {
    testWidgets('displays percentage and model metadata correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AIConfidenceMeter(
              confidence: 0.925,
              modelName: 'EfficientNet-B4',
            ),
          ),
        ),
      );

      expect(find.text('92.5%'), findsOneWidget);
      expect(find.text('EfficientNet-B4'), findsOneWidget);
    });
  });

  group('AnimalCard Tests', () {
    testWidgets('displays tag, breed, species and handles tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AnimalCard(
              tagId: 'MH-PUN-001',
              species: 'Cattle',
              breed: 'Gir',
              activeSeverity: SeverityLevel.high,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('MH-PUN-001'), findsOneWidget);
      expect(find.text('Cattle • Gir'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);

      await tester.tap(find.byType(AnimalCard));
      expect(tapped, isTrue);
    });
  });

  group('OfflineBanner Tests', () {
    testWidgets('displays when offline and hides when online', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OfflineBanner(isOffline: true),
          ),
        ),
      );

      expect(find.text("You're offline. Data will sync when connected."), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OfflineBanner(isOffline: false),
          ),
        ),
      );

      expect(find.text("You're offline. Data will sync when connected."), findsNothing);
    });
  });
}
