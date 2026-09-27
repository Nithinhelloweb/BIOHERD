import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bioherd/features/surveillance/models/crisis_dispatch_model.dart';
import 'package:bioherd/features/surveillance/presentation/widgets/crisis_dispatch_copilot_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Crisis Dispatch & AI SitRep Model Tests', () {
    test('RapidResponseTeam preseeded teams are well-formed', () {
      final teams = RapidResponseTeam.getPreseededTeams();
      expect(teams.length, greaterThanOrEqualTo(4));

      final alpha = teams.firstWhere((t) => t.id == 'RRT-MH-13-A');
      expect(alpha.assignedDistrict, 'Solapur');
      expect(alpha.leadOfficer, contains('Anjali Deshmukh'));
      expect(alpha.coldBoxTempC, lessThanOrEqualTo(4.0));
      expect(alpha.lsdDosesAvailable, greaterThan(3000));
      expect(alpha.statusLabel, contains('EN ROUTE'));
      expect(alpha.statusColor, const Color(0xFF3B82F6));
    });

    test('FarmerBroadcastCampaign default parameters and scripts', () {
      final campaign = FarmerBroadcastCampaign.getDefaultCampaign('Solapur');
      expect(campaign.targetDistrict, 'Solapur');
      expect(campaign.recipientCount, 4820);
      expect(campaign.radiusKm, 5.0);
      expect(campaign.marathiScript, contains('लम्पी'));
      expect(campaign.hindiScript, contains('लंपी'));
      expect(campaign.englishScript, contains('Lumpy Skin Disease'));
    });

    test('AiSitRepBriefing live SitRep and Natural Language AI Query Engine', () {
      final sitrep = AiSitRepBriefing.getLiveSitRep();
      expect(sitrep.threatLevel, contains('CRITICAL LEVEL 4'));
      expect(sitrep.primaryEpicenters.length, greaterThanOrEqualTo(3));
      expect(sitrep.operationalChecklist.length, greaterThanOrEqualTo(5));

      // Test AI Co-Pilot query answers
      final vaccineAns = AiSitRepBriefing.answerQuery('What is the vaccine deficit in Solapur?');
      expect(vaccineAns, contains('CRISIS SUPPLY STATUS'));
      expect(vaccineAns, contains('3,850'));

      final mandiAns = AiSitRepBriefing.answerQuery('Draft an APMC Mandi closure order');
      expect(mandiAns, contains('STATUTORY MANDI DIRECTIVE'));

      final borderAns = AiSitRepBriefing.answerQuery('Analyze interstate Karnataka border risk');
      expect(borderAns, contains('INTERSTATE BORDER INTEL'));

      final generalAns = AiSitRepBriefing.answerQuery('Tell me the general situation');
      expect(generalAns, contains('OPERATIONAL SITUATION BRIEF'));
    });
  });

  group('CrisisDispatchCopilotDialog Widget Tests', () {
    testWidgets('Renders SitRep header, executive summary, checklist, and queries AI', (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrisisDispatchCopilotDialog(activeDistrict: 'Solapur'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Header verification
      expect(find.text('C4I CRISIS DISPATCH & AI SITREP CO-PILOT'), findsOneWidget);
      expect(find.text('LEVEL 4 EMERGENCY'), findsOneWidget);

      // Tab bar labels
      expect(find.text('AI SitRep Co-Pilot'), findsOneWidget);
      expect(find.text('RRT Mobilization Matrix'), findsOneWidget);
      expect(find.text('Farmer Broadcast Studio'), findsOneWidget);

      // Executive Summary
      expect(find.text('OPERATIONAL SITREP BRIEFING (EXECUTIVE COMMAND)'), findsOneWidget);

      // Operational Checklist
      expect(find.text('Deploy 3-Tier Ring Containment Cordon (1km / 3km / 10km)'), findsOneWidget);

      // Test preset question chip tap
      await tester.tap(find.text('What is the vaccine deficit in Solapur & Latur?'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('CO-PILOT INTEL ADVISORY'), findsOneWidget);
      expect(find.textContaining('CRISIS SUPPLY STATUS'), findsOneWidget);
    });

    testWidgets('Switches to RRT Mobilization Matrix tab and triggers action', (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? actionExecuted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrisisDispatchCopilotDialog(
              activeDistrict: 'Solapur',
              onActionExecuted: (action, desc) => actionExecuted = action,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Tab 2: RRT Matrix
      await tester.tap(find.text('RRT Mobilization Matrix'));
      await tester.pumpAndSettle();

      // Verify teams are rendered
      expect(find.text('Solapur Strike Team Alpha'), findsOneWidget);
      expect(find.text('Latur Mobile Biosecurity Unit Beta'), findsOneWidget);
      expect(find.text('Pune State Emergency Reserve C'), findsOneWidget);

      // Tap Start Ring Strike on the first team
      await tester.tap(find.text('Start Ring Strike').first);
      await tester.pumpAndSettle();

      expect(actionExecuted, 'RRT_REASSIGN');
      expect(find.text('RING VACCINATING'), findsWidgets);
    });

    testWidgets('Switches to Farmer Broadcast Studio and initiates voice broadcast', (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? actionExecuted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrisisDispatchCopilotDialog(
              activeDistrict: 'Solapur',
              onActionExecuted: (action, desc) => actionExecuted = action,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Tab 3: Farmer Broadcast Studio
      await tester.tap(find.text('Farmer Broadcast Studio'));
      await tester.pumpAndSettle();

      expect(find.textContaining('4820 REGISTERED LIVESTOCK KEEPERS'), findsOneWidget);
      expect(find.text('Voice IVR Outbound (1800)'), findsOneWidget);
      expect(find.text('Cell Broadcast SMS'), findsOneWidget);

      // Tap Hindi chip
      await tester.tap(find.text('हिंदी (Hindi)'));
      await tester.pump(const Duration(milliseconds: 100));

      // Trigger Broadcast launch button
      await tester.tap(find.textContaining('Initiate Autonomous Outbound Voice IVR'));
      await tester.pumpAndSettle();

      expect(actionExecuted, 'FARMER_BROADCAST');
      expect(find.textContaining('BROADCAST LIVE'), findsOneWidget);
    });
  });
}
