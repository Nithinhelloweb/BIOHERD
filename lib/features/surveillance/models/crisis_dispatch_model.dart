import 'package:flutter/material.dart';

enum RrtDeploymentStatus {
  depotStaged,
  enRoute,
  onSiteContained,
  vaccinating,
}

class RapidResponseTeam {
  final String id;
  final String teamName;
  final String baseDepot;
  final String leadOfficer;
  final String contactNumber;
  final String assignedDistrict;
  final String assignedEpicenter;
  RrtDeploymentStatus status;
  final String vehicleId;
  final double coldBoxTempC; // Active cold-chain monitor
  int lsdDosesAvailable;
  int fmdDosesAvailable;
  final int pcrCartridges;
  final int ppeKits;
  int etaMinutes;

  RapidResponseTeam({
    required this.id,
    required this.teamName,
    required this.baseDepot,
    required this.leadOfficer,
    required this.contactNumber,
    required this.assignedDistrict,
    required this.assignedEpicenter,
    this.status = RrtDeploymentStatus.depotStaged,
    required this.vehicleId,
    required this.coldBoxTempC,
    required this.lsdDosesAvailable,
    required this.fmdDosesAvailable,
    required this.pcrCartridges,
    required this.ppeKits,
    required this.etaMinutes,
  });

  Color get statusColor {
    switch (status) {
      case RrtDeploymentStatus.depotStaged:
        return const Color(0xFF64748B);
      case RrtDeploymentStatus.enRoute:
        return const Color(0xFF3B82F6);
      case RrtDeploymentStatus.onSiteContained:
        return const Color(0xFF10B981);
      case RrtDeploymentStatus.vaccinating:
        return const Color(0xFF8B5CF6);
    }
  }

  String get statusLabel {
    switch (status) {
      case RrtDeploymentStatus.depotStaged:
        return 'DEPOT STAGED';
      case RrtDeploymentStatus.enRoute:
        return 'EN ROUTE ($etaMinutes MIN)';
      case RrtDeploymentStatus.onSiteContained:
        return 'ON SITE CONTAINED';
      case RrtDeploymentStatus.vaccinating:
        return 'RING VACCINATING';
    }
  }

  static List<RapidResponseTeam> getPreseededTeams() {
    return [
      RapidResponseTeam(
        id: 'RRT-MH-13-A',
        teamName: 'Solapur Strike Team Alpha',
        baseDepot: 'District Veterinary Polyclinic (DVP) Solapur',
        leadOfficer: 'Dr. Anjali Deshmukh, MVSc (Epidemiology)',
        contactNumber: '+91 98224 88102',
        assignedDistrict: 'Solapur',
        assignedEpicenter: 'Solapur South Hotspot (17.6599°N, 75.9064°E)',
        status: RrtDeploymentStatus.enRoute,
        vehicleId: 'MH-13-VET-0101 (Cold-Chain Mobile Unit)',
        coldBoxTempC: 3.8,
        lsdDosesAvailable: 3850,
        fmdDosesAvailable: 2400,
        pcrCartridges: 180,
        ppeKits: 45,
        etaMinutes: 14,
      ),
      RapidResponseTeam(
        id: 'RRT-MH-25-B',
        teamName: 'Latur Mobile Biosecurity Unit Beta',
        baseDepot: 'Marathwada Veterinary Hospital Latur',
        leadOfficer: 'Dr. Rajesh Patil, MVSc',
        contactNumber: '+91 94231 77209',
        assignedDistrict: 'Latur',
        assignedEpicenter: 'Ausa Block Cluster (18.25°N, 76.50°E)',
        status: RrtDeploymentStatus.vaccinating,
        vehicleId: 'MH-24-VET-0402 (Refrigerated Cruiser)',
        coldBoxTempC: 4.1,
        lsdDosesAvailable: 2100,
        fmdDosesAvailable: 1500,
        pcrCartridges: 95,
        ppeKits: 30,
        etaMinutes: 0,
      ),
      RapidResponseTeam(
        id: 'RRT-MH-12-C',
        teamName: 'Pune State Emergency Reserve C',
        baseDepot: 'State Disease Investigation Section (DIS) Aundh, Pune',
        leadOfficer: 'Dr. Vikramaditya Shinde, Joint Director',
        contactNumber: '+91 98220 33419',
        assignedDistrict: 'Pune',
        assignedEpicenter: 'Indapur Expressway Transit Barrier',
        status: RrtDeploymentStatus.depotStaged,
        vehicleId: 'MH-12-VET-9900 (Heavy Logistics Van)',
        coldBoxTempC: 3.5,
        lsdDosesAvailable: 15000,
        fmdDosesAvailable: 10000,
        pcrCartridges: 500,
        ppeKits: 120,
        etaMinutes: 45,
      ),
      RapidResponseTeam(
        id: 'RRT-MH-09-D',
        teamName: 'Kolhapur Southern Barrier Squad',
        baseDepot: 'Central Veterinary Dispensary Kolhapur',
        leadOfficer: 'Dr. Suhas Kulkarni, B.V.Sc',
        contactNumber: '+91 99750 11842',
        assignedDistrict: 'Kolhapur',
        assignedEpicenter: 'Kagal Highway Disinfection Gate',
        status: RrtDeploymentStatus.onSiteContained,
        vehicleId: 'MH-09-VET-0055 (Disinfection Arch Mobile)',
        coldBoxTempC: 4.0,
        lsdDosesAvailable: 4200,
        fmdDosesAvailable: 3100,
        pcrCartridges: 150,
        ppeKits: 60,
        etaMinutes: 0,
      ),
    ];
  }
}

class FarmerBroadcastCampaign {
  final String id;
  final String targetDistrict;
  final double radiusKm;
  final int recipientCount;
  final String marathiScript;
  final String hindiScript;
  final String englishScript;
  final double successRate;
  bool isDispatched;
  final String dispatchedTimestamp;

  FarmerBroadcastCampaign({
    required this.id,
    required this.targetDistrict,
    required this.radiusKm,
    required this.recipientCount,
    required this.marathiScript,
    required this.hindiScript,
    required this.englishScript,
    this.successRate = 0.984,
    this.isDispatched = true,
    required this.dispatchedTimestamp,
  });

  static FarmerBroadcastCampaign getDefaultCampaign(String district) {
    return FarmerBroadcastCampaign(
      id: 'BRD-2026-0925-01',
      targetDistrict: district,
      radiusKm: 5.0,
      recipientCount: 4820,
      marathiScript:
          'तातडीचा इशारा: $district जिल्ह्यात लम्पी त्वचारोगाचा प्रादुर्भाव. ५ किमी परिसरातील जनावरांचे बाजार व वाहतूक तात्काळ बंद. शासकीय जलद लसीकरण पथक आपल्या गावात दाखल होत आहे. ताप व गाठी दिसल्यास तात्काळ १८००-२४६-४३७३ वर संपर्क साधा.',
      hindiScript:
          'आपातकालीन चेतावनी: $district जिले में लंपी स्किन रोग का प्रकोप। ५ किमी क्षेत्र में पशु बाजार और परिवहन तत्काल प्रभाव से प्रतिबंधित। सरकारी टीकाकरण टीम आपके गांव पहुंच रही है। लक्षण दिखने पर १८००-२४६-४३७३ पर संपर्क करें।',
      englishScript:
          'EMERGENCY DIRECTIVE: Lumpy Skin Disease outbreak confirmed in $district. Mandatory 5km transit moratorium active. Mobile veterinary strike squads dispatched for ring vaccination. Dial 1800-246-4373 for assistance.',
      dispatchedTimestamp: 'LIVE 18:48:22 IST',
    );
  }
}

class AiSitRepBriefing {
  final String id;
  final String generatedTimestamp;
  final String threatLevel; // CRITICAL LEVEL 4, HIGH LEVEL 3, MODERATE LEVEL 2
  final String executiveSummary;
  final String statutoryProclamation;
  final List<String> primaryEpicenters;
  final Map<String, bool> operationalChecklist;

  AiSitRepBriefing({
    required this.id,
    required this.generatedTimestamp,
    required this.threatLevel,
    required this.executiveSummary,
    required this.statutoryProclamation,
    required this.primaryEpicenters,
    required this.operationalChecklist,
  });

  static AiSitRepBriefing getLiveSitRep() {
    return AiSitRepBriefing(
      id: 'SITREP-MH-2026-LIVE',
      generatedTimestamp: '25-SEP-2026 18:50:00 IST',
      threatLevel: 'CRITICAL LEVEL 4 (STATE EPIDEMIC WATCH)',
      executiveSummary:
          'BIOHERD Epizootic Intelligence Engine confirms active contagion cluster in Solapur (R0 = 2.45) with outward microclimate aerosol drift (Azimuth 235° SW at 18 km/h). Secondary transmission vectors identified in Latur and Ahmednagar. Projected +14-day caseload without intervention: 1,842 head. Recommended immediate ring vaccination strike within 5km radius and strict APMC mandi moratorium.',
      statutoryProclamation:
          'ORDER UNDER SECTION 6 OF THE PREVENTION AND CONTROL OF INFECTIOUS AND CONTAGIOUS DISEASES IN ANIMALS ACT, 2009:\n\nWHEREAS Lumpy Skin Disease (LSD) has been confirmed in Solapur District; NOW THEREFORE, the Commissioner of Animal Husbandry hereby declares Solapur South and adjoining 10km buffer as a Controlled Containment Zone. Movement of bovine livestock, inter-district cattle transport, and operation of cattle markets are strictly PROHIBITED with immediate effect.',
      primaryEpicenters: [
        'Solapur South (Epicenter: 17.6599°N, 75.9064°E) - R0: 2.45',
        'Latur Ausa Block (Cluster: 18.25°N, 76.50°E) - R0: 1.82',
        'Kolhapur Kagal Belt (Cluster: 16.70°N, 74.24°E) - R0: 1.40',
      ],
      operationalChecklist: {
        'Deploy 3-Tier Ring Containment Cordon (1km / 3km / 10km)': true,
        'Enact APMC Livestock Mandi Moratorium Notification': true,
        'Mobilize Rapid Response Strike Teams (RRT Alpha & Beta)': true,
        'Dispatch Trilingual Voice IVR & SMS Broadcast (4,820 farmers)': true,
        'Requisition 25,000 Vaccine Doses from Pune Central Depot': false,
        'Seal Interstate Highway Border Gates (NH-52 & NH-161)': true,
        'Deploy Ultra-Low Volume (ULV) Vector Fogging in Stagnant Water Basins': false,
      },
    );
  }

  static String answerQuery(String query) {
    final q = query.toLowerCase();
    if (q.contains('vaccine') || q.contains('deficit') || q.contains('stock')) {
      return 'CRISIS SUPPLY STATUS:\n- Solapur DVP currently holds 3,850 LSD doses with a calculated deficit of 8,450 doses to achieve 80% herd ring immunity.\n- Action taken: Pune Central Depot (RRT-MH-12-C) has staged 15,000 doses with an ETA of 45 minutes to Solapur South.';
    } else if (q.contains('karnataka') || q.contains('border') || q.contains('interstate')) {
      return 'INTERSTATE BORDER INTEL:\n- Karnataka Belagavi & Bijapur border points report elevated vector activity (VVI = 0.82).\n- Solapur-Bijapur NH-52 checkpost (CKP-01) has engaged hydraulic clamp lockdown for uncertified livestock haulers.';
    } else if (q.contains('mandi') || q.contains('market') || q.contains('closure')) {
      return 'STATUTORY MANDI DIRECTIVE:\n- All APMC cattle market yards in Solapur, Sangli, and Osmanabad are placed under temporary moratorium under Section 6 of Act 2009.\n- Edge Vision camera feeds at Nashik and Latur mandis are set to Divert-to-Screening.';
    } else {
      return 'OPERATIONAL SITUATION BRIEF:\n- Overall statewide active caseload: 588 head. Interventions currently active: Ring Cordon, Checkpoint Gantries, and IVR Farmer Alerts.\n- Counterfactual modeling indicates 1,280 cattle and ₹10.24 Cr in livestock assets protected across the 14-day horizon.';
    }
  }
}
