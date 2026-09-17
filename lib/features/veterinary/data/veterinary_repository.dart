import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';

abstract class VeterinaryRepository {
  Future<List<CaseModel>> getCases({
    CaseStatus? status,
    CasePriority? priority,
    String? query,
    bool? unassignedOnly,
  });
  Future<CaseModel?> getCaseById(String id);
  Future<CaseModel> assignCase(String caseId, String vetId, String vetName, {String? notes});
  Future<CaseModel> updateCaseStatus(
    String caseId,
    CaseStatus newStatus, {
    String? notes,
    String? resolutionSummary,
  });
  Future<PrescriptionModel> issuePrescription(String caseId, PrescriptionModel prescription);
  Future<List<DrugItem>> getDrugCatalog({String? species, String? diseaseQuery, bool? scheduleH});
  Future<DosageCalculationResult> calculateDosage(String drugId, String species, double bodyWeightKg);
  Future<TelemedicineSessionModel> createTelemedicineSession(String caseId);
}

class OfflineFirstVeterinaryRepository implements VeterinaryRepository {
  final SharedPreferences _prefs;
  static const String _casesKey = 'bioherd_veterinary_cases';

  OfflineFirstVeterinaryRepository(this._prefs) {
    _initSeedsIfNeeded();
  }

  static Future<OfflineFirstVeterinaryRepository> create({SharedPreferences? prefs}) async {
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    return OfflineFirstVeterinaryRepository(sharedPrefs);
  }

  void _initSeedsIfNeeded() {
    if (!_prefs.containsKey(_casesKey)) {
      final defaultCases = _getInitialSeededCases();
      final jsonList = defaultCases.map((c) => c.toJson()).toList();
      _prefs.setString(_casesKey, jsonEncode(jsonList));
    }
  }

  @override
  Future<List<CaseModel>> getCases({
    CaseStatus? status,
    CasePriority? priority,
    String? query,
    bool? unassignedOnly,
  }) async {
    final raw = _prefs.getString(_casesKey);
    if (raw == null) return [];

    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return list.where((c) {
      if (status != null && c.status != status) return false;
      if (priority != null && c.priority != priority) return false;
      if (unassignedOnly == true && !c.isUnassigned) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        final matchTag = c.animalTagId?.toLowerCase().contains(q) ?? false;
        final matchFarmer = c.farmerName?.toLowerCase().contains(q) ?? false;
        final matchSuspect = c.primarySuspect?.toLowerCase().contains(q) ?? false;
        final matchSuspectMr = c.primarySuspectMr?.toLowerCase().contains(q) ?? false;
        if (!matchTag && !matchFarmer && !matchSuspect && !matchSuspectMr) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<CaseModel?> getCaseById(String id) async {
    final cases = await getCases();
    for (final c in cases) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<CaseModel> assignCase(String caseId, String vetId, String vetName, {String? notes}) async {
    final cases = await getCases();
    final index = cases.indexWhere((c) => c.id == caseId);
    if (index == -1) throw Exception('Case with ID $caseId not found.');

    final existing = cases[index];
    final updated = existing.copyWith(
      assignedVetId: vetId,
      assignedVetName: vetName,
      status: existing.status == CaseStatus.submitted ? CaseStatus.assigned : existing.status,
      notes: notes != null
          ? (existing.notes != null ? '${existing.notes}\n[Triage]: $notes' : notes)
          : existing.notes,
      updatedAt: DateTime.now(),
    );

    cases[index] = updated;
    await _saveCases(cases);
    return updated;
  }

  @override
  Future<CaseModel> updateCaseStatus(
    String caseId,
    CaseStatus newStatus, {
    String? notes,
    String? resolutionSummary,
  }) async {
    final cases = await getCases();
    final index = cases.indexWhere((c) => c.id == caseId);
    if (index == -1) throw Exception('Case with ID $caseId not found.');

    final existing = cases[index];
    final updated = existing.copyWith(
      status: newStatus,
      notes: notes != null
          ? (existing.notes != null ? '${existing.notes}\n$notes' : notes)
          : existing.notes,
      resolutionSummary: resolutionSummary ?? existing.resolutionSummary,
      updatedAt: DateTime.now(),
    );

    cases[index] = updated;
    await _saveCases(cases);
    return updated;
  }

  @override
  Future<PrescriptionModel> issuePrescription(String caseId, PrescriptionModel prescription) async {
    final cases = await getCases();
    final index = cases.indexWhere((c) => c.id == caseId);
    if (index == -1) throw Exception('Case with ID $caseId not found.');

    // Generate cryptographic digital signature
    final rawSign = '${caseId}_${prescription.drugName}_${prescription.dosage}_${DateTime.now().toIso8601String()}';
    final signHash = sha256.convert(utf8.encode(rawSign)).toString();

    final signedPrescription = PrescriptionModel(
      id: prescription.id.isNotEmpty ? prescription.id : 'RX-${DateTime.now().millisecondsSinceEpoch}',
      caseId: caseId,
      issuedBy: prescription.issuedBy,
      issuedByName: prescription.issuedByName ?? 'Licensed Veterinarian',
      drugName: prescription.drugName,
      dosage: prescription.dosage,
      durationDays: prescription.durationDays,
      instructionsMultilingual: prescription.instructionsMultilingual,
      scheduleHWarning: prescription.scheduleHWarning,
      milkWithdrawalDays: prescription.milkWithdrawalDays,
      meatWithdrawalDays: prescription.meatWithdrawalDays,
      digitalSignatureHash: signHash,
      pdfUrl: prescription.pdfUrl,
      createdAt: DateTime.now(),
    );

    final existing = cases[index];
    final updatedPrescriptions = List<PrescriptionModel>.from(existing.prescriptions)..add(signedPrescription);
    final updatedCase = existing.copyWith(
      status: CaseStatus.prescriptionIssued,
      hasPrescription: true,
      prescriptions: updatedPrescriptions,
      updatedAt: DateTime.now(),
    );

    cases[index] = updatedCase;
    await _saveCases(cases);
    return signedPrescription;
  }

  @override
  Future<List<DrugItem>> getDrugCatalog({String? species, String? diseaseQuery, bool? scheduleH}) async {
    return _formulary.where((d) {
      if (species != null && !d.targetSpecies.map((s) => s.toLowerCase()).contains(species.toLowerCase())) {
        return false;
      }
      if (scheduleH != null && d.scheduleH != scheduleH) {
        return false;
      }
      if (diseaseQuery != null && diseaseQuery.trim().isNotEmpty) {
        final q = diseaseQuery.toLowerCase();
        final matchIndications = d.indications.any((ind) => ind.toLowerCase().contains(q));
        final matchName = d.name.toLowerCase().contains(q);
        if (!matchIndications && !matchName) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<DosageCalculationResult> calculateDosage(String drugId, String species, double bodyWeightKg) async {
    final drug = _formulary.firstWhere(
      (d) => d.id == drugId,
      orElse: () => throw Exception('Drug with ID $drugId not found.'),
    );

    double totalMg = 0.0;
    double volumeMl = 0.0;
    String displayDose = '';
    String displayDoseMr = '';

    if (drug.dosePerKgMg == 0.0) {
      if (drug.category.contains('Intramammary')) {
        volumeMl = 10.0;
        displayDose = '1 Syringe / quarter';
        displayDoseMr = '१ सिरिंज प्रति बाधित सड';
      } else {
        volumeMl = 0.0;
        displayDose = 'Topical Application';
        displayDoseMr = 'गरजेनुसार मलम लावा';
      }
    } else {
      totalMg = (bodyWeightKg * drug.dosePerKgMg * 10).round() / 10.0;
      volumeMl = (totalMg / drug.concentrationMgMl * 10).round() / 10.0;
      displayDose = '$volumeMl ml ($totalMg mg active)';
      displayDoseMr = '$volumeMl मिली ($totalMg मिग्रॅ सक्रिय घटक)';
    }

    return DosageCalculationResult(
      drugId: drug.id,
      drugName: drug.name,
      category: drug.category,
      scheduleH: drug.scheduleH,
      route: drug.route,
      bodyWeightKg: bodyWeightKg,
      calculatedVolumeMl: volumeMl,
      displayDose: displayDose,
      displayDoseMr: displayDoseMr,
      defaultDurationDays: drug.defaultDurationDays,
      milkWithdrawalDays: drug.milkWithdrawalDays,
      meatWithdrawalDays: drug.meatWithdrawalDays,
      instructionsEn: drug.instructionsEn,
      instructionsMr: drug.instructionsMr,
      contraindications: drug.contraindications,
    );
  }

  @override
  Future<TelemedicineSessionModel> createTelemedicineSession(String caseId) async {
    final cases = await getCases();
    final index = cases.indexWhere((c) => c.id == caseId);
    final sessionId = 'telemed-${DateTime.now().millisecondsSinceEpoch}';

    if (index != -1) {
      final existing = cases[index];
      final updated = existing.copyWith(
        telemedicineSessionId: sessionId,
        status: existing.status == CaseStatus.submitted || existing.status == CaseStatus.assigned
            ? CaseStatus.inReview
            : existing.status,
        updatedAt: DateTime.now(),
      );
      cases[index] = updated;
      await _saveCases(cases);
    }

    return TelemedicineSessionModel(
      sessionId: sessionId,
      caseId: caseId,
      roomName: 'bioherd-case-${caseId.substring(0, 8)}',
      iceServers: [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      status: 'active',
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveCases(List<CaseModel> list) async {
    final jsonList = list.map((c) => c.toJson()).toList();
    await _prefs.setString(_casesKey, jsonEncode(jsonList));
  }

  List<CaseModel> _getInitialSeededCases() {
    return [
      CaseModel(
        id: 'CASE-SOL-001',
        symptomReportId: 'REP-SOL-881',
        assignedVetId: 'VET-MH-01',
        assignedVetName: 'Dr. Nilesh Shinde (M.V.Sc)',
        status: CaseStatus.inReview,
        priority: CasePriority.high,
        animalId: 'ANM-SOL-01',
        animalTagId: 'MH-SOL-KHIL-4401',
        animalSpecies: 'Cattle (गाय)',
        animalBreed: 'Khillari (खिल्लारी)',
        animalWeightKg: 420.0,
        farmerId: 'FARMER-01',
        farmerName: 'Dnyaneshwar Shinde',
        farmerPhone: '+91 98765 40011',
        districtName: 'Solapur (सोलापूर)',
        primarySuspect: 'Foot and Mouth Disease',
        primarySuspectMr: 'लाळ्या खुरकूत',
        aiConfidence: 92.5,
        hasPrescription: false,
        symptomsSummary: const ['High Fever', 'Stringy Salivation', 'Hoof Blisters', 'Severe Lameness'],
        images: const [
          'https://images.unsplash.com/photo-1546445317-29f4545e9d53?w=600',
        ],
        notes: 'Priority clinical review. Salivation excessive since 48h.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CaseModel(
        id: 'CASE-KOL-002',
        symptomReportId: 'REP-KOL-882',
        assignedVetId: null,
        assignedVetName: null,
        status: CaseStatus.submitted,
        priority: CasePriority.critical,
        animalId: 'ANM-KOL-02',
        animalTagId: 'MH-KOL-PAND-9912',
        animalSpecies: 'Buffalo (म्हैस)',
        animalBreed: 'Pandharpuri (पंढरपुरी)',
        animalWeightKg: 480.0,
        farmerId: 'FARMER-02',
        farmerName: 'Subhash Patil',
        farmerPhone: '+91 98765 40022',
        districtName: 'Kolhapur (कोल्हापूर)',
        primarySuspect: 'Lumpy Skin Disease',
        primarySuspectMr: 'लंपी त्वचा रोग',
        aiConfidence: 95.0,
        hasPrescription: false,
        symptomsSummary: const ['Cutaneous Nodules', 'Prescapular Lymphadenopathy', 'High Pyrexia'],
        images: const [
          'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?w=600',
        ],
        notes: 'Immediate triage required. Circular skin nodules covering neck and flank.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CaseModel(
        id: 'CASE-AHM-003',
        symptomReportId: 'REP-AHM-883',
        assignedVetId: 'VET-MH-02',
        assignedVetName: 'Dr. Anjali Patil (B.V.Sc)',
        status: CaseStatus.prescriptionIssued,
        priority: CasePriority.high,
        animalId: 'ANM-AHM-03',
        animalTagId: 'MH-AHM-DEON-2203',
        animalSpecies: 'Cattle (गाय)',
        animalBreed: 'Deoni (देवणी)',
        animalWeightKg: 380.0,
        farmerId: 'FARMER-03',
        farmerName: 'Anand Gite',
        farmerPhone: '+91 98765 40033',
        districtName: 'Ahmednagar (अहमदनगर)',
        primarySuspect: 'Bovine Mastitis',
        primarySuspectMr: 'तीव्र स्तनदाह',
        aiConfidence: 94.0,
        hasPrescription: true,
        symptomsSummary: const ['Swollen Right Quarter', 'Milk Clots & Flakes', 'Drop in Milk Yield'],
        images: const [
          'https://images.unsplash.com/photo-1527153857715-3908f2ae5e81?w=600',
        ],
        prescriptions: [
          PrescriptionModel(
            id: 'RX-AHM-901',
            caseId: 'CASE-AHM-003',
            issuedBy: 'VET-MH-02',
            issuedByName: 'Dr. Anjali Patil',
            drugName: 'Ceftriaxone + Sulbactam 4.5g',
            dosage: '25 ml IV once daily',
            durationDays: 3,
            instructionsMultilingual: const {
              'en': 'Slow IV once daily for 3 days. Discard milk for 7 days.',
              'mr': 'शिरेतून हळूहळू दररोज एकदा ३ दिवस द्या. दूध ७ दिवस वापरू नका.',
            },
            scheduleHWarning: true,
            milkWithdrawalDays: 7,
            meatWithdrawalDays: 28,
            digitalSignatureHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          PrescriptionModel(
            id: 'RX-AHM-902',
            caseId: 'CASE-AHM-003',
            issuedBy: 'VET-MH-02',
            issuedByName: 'Dr. Anjali Patil',
            drugName: 'Melonex Plus (Meloxicam)',
            dosage: '15 ml deep IM once daily',
            durationDays: 3,
            instructionsMultilingual: const {
              'en': 'Deep IM for fever and udder pain for 3 days.',
              'mr': 'कासदुखी आणि ताप कमी करण्यासाठी खोल स्नायूत ३ दिवस द्या.',
            },
            scheduleHWarning: false,
            milkWithdrawalDays: 2,
            meatWithdrawalDays: 5,
            digitalSignatureHash: '4a6b2c891f73d4568912e731b849204128471203948123049182304918234912',
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ],
        notes: 'Ceftriaxone and Melonex therapy commenced. Quarter stripped regularly.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      CaseModel(
        id: 'CASE-PUN-004',
        symptomReportId: 'REP-PUN-884',
        assignedVetId: 'VET-MH-03',
        assignedVetName: 'Dr. Sachin Deshmukh (M.V.Sc)',
        status: CaseStatus.followUp,
        priority: CasePriority.medium,
        animalId: 'ANM-PUN-04',
        animalTagId: 'MH-PUN-OSM-7704',
        animalSpecies: 'Goat (शेळी)',
        animalBreed: 'Osmanabadi (उस्मानाबादी)',
        animalWeightKg: 38.0,
        farmerId: 'FARMER-04',
        farmerName: 'Pandurang Jagtap',
        farmerPhone: '+91 98765 40044',
        districtName: 'Pune (पुणे)',
        primarySuspect: 'Peste des Petits Ruminants',
        primarySuspectMr: 'शेळ्यांमधील देवी रोग',
        aiConfidence: 89.0,
        hasPrescription: true,
        symptomsSummary: const ['Mouth Ulcers', 'Foul Diarrhea', 'Ocular Discharge'],
        notes: 'Follow-up consultation after hydration and antibiotic course.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  static const List<DrugItem> _formulary = [
    DrugItem(
      id: 'DRUG-ENRO',
      name: 'Enrofloxacin 10%',
      tradeNames: ['Baytril', 'Floxidin', 'Enrocin'],
      category: 'Fluoroquinolone Antibiotic',
      scheduleH: true,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep', 'pig'],
      indications: ['Haemorrhagic Septicaemia (घटसर्प)', 'Black Quarter (एकटांग्या)', 'Severe Enteritis'],
      route: 'Intramuscular (IM)',
      dosePerKgMg: 5.0,
      concentrationMgMl: 100.0,
      defaultDurationDays: 4,
      milkWithdrawalDays: 4,
      meatWithdrawalDays: 14,
      instructionsEn: 'Administer deep IM once daily for 4 days. Discard milk for 4 days.',
      instructionsMr: 'दररोज एकदा खोल स्नायूत ४ दिवस द्या. दूध ४ दिवस मानवी वापरासाठी वापरू नये.',
      contraindications: 'Strictly Schedule-H. Do not use in calves under 12 months with cartilage disorders.',
    ),
    DrugItem(
      id: 'DRUG-CEFT',
      name: 'Ceftriaxone + Sulbactam 4.5g',
      tradeNames: ['Intacef Tazo', 'Xone-XP', 'Cefbact-SB'],
      category: '3rd Gen Cephalosporin Antibiotic',
      scheduleH: true,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep'],
      indications: ['Acute Bovine Mastitis (स्तनदाह)', 'Severe Metritis', 'Sepsis in LSD'],
      route: 'Slow Intravenous (IV/IM)',
      dosePerKgMg: 10.0,
      concentrationMgMl: 150.0,
      defaultDurationDays: 3,
      milkWithdrawalDays: 7,
      meatWithdrawalDays: 28,
      instructionsEn: 'Reconstitute with Sterile Water. Administer slowly IV once daily for 3 days.',
      instructionsMr: 'जंतुविरहित पाण्यात विरघळवून शिरेतून हळूहळू दररोज एकदा ३ दिवस द्या. दूध ७ दिवस फेकून द्यावे.',
      contraindications: 'Do not use in animals hypersensitive to cephalosporins.',
    ),
    DrugItem(
      id: 'DRUG-MELX',
      name: 'Melonex Plus (Meloxicam)',
      tradeNames: ['Melonex Plus', 'Meldex', 'Zobid-M'],
      category: 'NSAID Analgesic & Antipyretic',
      scheduleH: false,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep', 'pig'],
      indications: ['FMD High Fever & Pain', 'Lumpy Skin Pyrexia', 'Mastitis Inflammation'],
      route: 'Intramuscular (IM)',
      dosePerKgMg: 0.5,
      concentrationMgMl: 5.0,
      defaultDurationDays: 3,
      milkWithdrawalDays: 2,
      meatWithdrawalDays: 5,
      instructionsEn: 'Administer deep IM once daily for 3 days for acute fever and inflammatory swelling.',
      instructionsMr: 'तीव्र ताप आणि वेदना कमी करण्यासाठी दररोज एकदा खोल स्नायूत ३ दिवस द्या.',
      contraindications: 'Avoid in severely dehydrated or renal compromised animals.',
    ),
    DrugItem(
      id: 'DRUG-IVER',
      name: 'Ivermectin 1%',
      tradeNames: ['Neomec', 'Ivomec', 'Virbamec'],
      category: 'Endectocide Antiparasitic',
      scheduleH: false,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep'],
      indications: ['Tick Control in Theileriosis', 'Maggots & Flies in LSD', 'Mange Mites'],
      route: 'Subcutaneous (SC) ONLY',
      dosePerKgMg: 0.2,
      concentrationMgMl: 10.0,
      defaultDurationDays: 1,
      milkWithdrawalDays: 28,
      meatWithdrawalDays: 35,
      instructionsEn: 'Administer SC behind the shoulder. Never inject IV or IM. Milk withdrawal 28 days.',
      instructionsMr: 'फक्त कातडीखाली सैल जागेत (SC) टोचा. चुकूनही स्नायूत देऊ नका. २८ दिवस दूध विकू नये.',
      contraindications: 'Strictly SC. Not recommended in lactating cows producing milk for immediate consumption.',
    ),
    DrugItem(
      id: 'DRUG-OXYT',
      name: 'Oxytetracycline LA',
      tradeNames: ['Terramycin LA', 'Oxytet LA'],
      category: 'Tetracycline Broad-Spectrum',
      scheduleH: true,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep'],
      indications: ['Theileriosis & Anaplasmosis', 'Foot Rot', 'Pneumonia'],
      route: 'Deep Intramuscular (IM)',
      dosePerKgMg: 20.0,
      concentrationMgMl: 200.0,
      defaultDurationDays: 3,
      milkWithdrawalDays: 7,
      meatWithdrawalDays: 21,
      instructionsEn: 'Single deep IM depot injection. Provides 72 hours sustained therapeutic coverage.',
      instructionsMr: 'एकाच वेळी खोल स्नायूत द्या. ३ दिवस शरीरात औषध टिकून राहते. ७ दिवस दूध विकू नका.',
      contraindications: 'Avoid in late gestation animals.',
    ),
    DrugItem(
      id: 'DRUG-BUPR',
      name: 'Buparvaquone (Zubion)',
      tradeNames: ['Zubion', 'Butalex'],
      category: 'Antiprotozoal',
      scheduleH: true,
      targetSpecies: ['cattle', 'buffalo'],
      indications: ['Bovine Theileriosis (Theileria annulata)'],
      route: 'Deep IM in Neck',
      dosePerKgMg: 2.5,
      concentrationMgMl: 50.0,
      defaultDurationDays: 1,
      milkWithdrawalDays: 14,
      meatWithdrawalDays: 42,
      instructionsEn: 'Single injection deep in neck muscles. Specific cure for tick-borne Theileriosis.',
      instructionsMr: 'मानेच्या खोल स्नायूत एकदाच द्या. गोचीडजन्य ताप व थायलेरियावर अत्यंत गुणकारी.',
      contraindications: 'Do not administer IV. Guard against local site swelling.',
    ),
    DrugItem(
      id: 'DRUG-CHLR',
      name: 'Chlorpheniramine Maleate',
      tradeNames: ['Anistamin', 'Cadistin'],
      category: 'Antihistamine',
      scheduleH: false,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep'],
      indications: ['Allergic Itching in LSD', 'Insect Bite Edema', 'Ruminal Bloat support'],
      route: 'Intramuscular (IM)',
      dosePerKgMg: 0.5,
      concentrationMgMl: 10.0,
      defaultDurationDays: 3,
      milkWithdrawalDays: 1,
      meatWithdrawalDays: 3,
      instructionsEn: 'Administer IM once or twice daily to relieve acute pruritus and allergic edema.',
      instructionsMr: 'अंगावरील गांधी आणि खाज कमी करण्यासाठी स्नायूत २ वेळा द्या.',
      contraindications: 'Mild transient sedation may occur.',
    ),
    DrugItem(
      id: 'DRUG-CLOX',
      name: 'Intramammary Cloxacillin',
      tradeNames: ['Masticlox', 'Tilox'],
      category: 'Intramammary Antibiotic',
      scheduleH: true,
      targetSpecies: ['cattle', 'buffalo'],
      indications: ['Clinical Bovine Mastitis (कासदाह)'],
      route: 'Intramammary Infusion',
      dosePerKgMg: 0.0,
      concentrationMgMl: 0.0,
      defaultDurationDays: 3,
      milkWithdrawalDays: 4,
      meatWithdrawalDays: 7,
      instructionsEn: 'Strip quarter completely. Infuse 1 syringe per affected teat after milking for 3 days.',
      instructionsMr: 'दूध पूर्ण काढून सडाच्या तोंडावाटे औषध आत सोडा व वर चोळा. सलग ३ दिवस.',
      contraindications: 'For intramammary use only. Never inject parenterally.',
    ),
    DrugItem(
      id: 'DRUG-KMN4',
      name: 'KMNO4 + Boro-Glycerine',
      tradeNames: ['लाल औषध', 'Boro-Glycerine Gel'],
      category: 'Topical Antiseptic',
      scheduleH: false,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep', 'pig'],
      indications: ['FMD Mouth Blisters & Foot Ulcers'],
      route: 'Topical Wash & Gel',
      dosePerKgMg: 0.0,
      concentrationMgMl: 0.0,
      defaultDurationDays: 7,
      milkWithdrawalDays: 0,
      meatWithdrawalDays: 0,
      instructionsEn: 'Wash lesions twice daily with dilute pink KMNO4 solution. Apply Boro-Glycerine to mouth ulcers.',
      instructionsMr: '१:१००० लाल औषधाच्या पाण्याने तोंड व खूर धुवा. जिभेवर बोरो ग्लिसरीन लावा.',
      contraindications: 'External topical use only. Do not inject.',
    ),
    DrugItem(
      id: 'DRUG-VITM',
      name: 'Vitamin H + AD3E (Vimeral)',
      tradeNames: ['Vimeral', 'Tribivet', 'Multistar'],
      category: 'Epithelial Repair & Nutrient',
      scheduleH: false,
      targetSpecies: ['cattle', 'buffalo', 'goat', 'sheep'],
      indications: ['Skin Healing after LSD', 'Udder tissue regeneration', 'Convalescence'],
      route: 'Deep IM or Oral',
      dosePerKgMg: 0.02,
      concentrationMgMl: 1.0,
      defaultDurationDays: 7,
      milkWithdrawalDays: 0,
      meatWithdrawalDays: 0,
      instructionsEn: 'Administer 5-10 ml deep IM or 10 ml orally daily for 7 days to accelerate recovery.',
      instructionsMr: 'कातडी आणि कास लवकर भरून येण्यासाठी दररोज ५ ते १० मिली स्नायूत किंवा पाजा.',
      contraindications: 'Safe supportive therapy at recommended dosages.',
    ),
  ];
}
