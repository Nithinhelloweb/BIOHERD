import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/symptoms/models/symptom_model.dart';

abstract class SymptomRepository {
  List<BodySystemCategory> getBodySystemCategories();
  Future<AIDiagnosisResult> analyzeSymptoms({
    String? species,
    Map<String, List<String>>? symptomsChecklist,
    String? vernacularDescription,
    List<String>? images,
  });
  Future<SymptomReportModel> submitReport({
    required String animalId,
    String? animalTagId,
    String? species,
    String? breed,
    Map<String, List<String>>? symptomsChecklist,
    String? vernacularDescription,
    List<String>? images,
    String? voiceNoteUrl,
  });
  Future<List<SymptomReportModel>> getReports({String? animalId});
  Future<SymptomReportModel?> getReportById(String reportId);
}

class OfflineFirstSymptomRepository implements SymptomRepository {
  final SharedPreferences _prefs;
  final http.Client? _httpClient;
  final String _baseUrl;

  static const String _storageKey = 'bioherd_symptom_reports_v1';

  OfflineFirstSymptomRepository({
    required SharedPreferences prefs,
    http.Client? httpClient,
    String baseUrl = 'http://10.0.2.2:8000/api/v1',
  })  : _prefs = prefs,
        _httpClient = httpClient,
        _baseUrl = baseUrl;

  static Future<OfflineFirstSymptomRepository> create({
    http.Client? httpClient,
    String baseUrl = 'http://10.0.2.2:8000/api/v1',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = OfflineFirstSymptomRepository(
      prefs: prefs,
      httpClient: httpClient,
      baseUrl: baseUrl,
    );
    await repo._seedInitialReportsIfEmpty();
    return repo;
  }

  @override
  List<BodySystemCategory> getBodySystemCategories() {
    return [
      const BodySystemCategory(
        id: 'vitality',
        nameEn: 'Vitality & Fever',
          nameMr: 'Vitality & Fever',
        iconKey: 'thermometer',
        symptoms: [
          SymptomItem(id: 'high_fever', nameEn: 'High Fever (104-106°F)', nameMr: 'High Fever (104-106°F)'),
          SymptomItem(id: 'loss_of_appetite', nameEn: 'Loss of Appetite / Not Feeding', nameMr: 'Loss of Appetite / Not Feeding'),
          SymptomItem(id: 'severe_depression', nameEn: 'Severe Depression & Lethargy', nameMr: 'Severe Depression & Lethargy'),
          SymptomItem(id: 'shivering', nameEn: 'Shivering / Chills', nameMr: 'Shivering / Chills'),
        ],
      ),
      const BodySystemCategory(
        id: 'skin_coat',
        nameEn: 'Skin, Coat & Lesions',
          nameMr: 'Skin, Coat & Lesions',
        iconKey: 'shield',
        symptoms: [
          SymptomItem(id: 'nodular_skin_lesions', nameEn: 'Nodular Lumps / Skin Knots', nameMr: 'Nodular Lumps / Skin Knots'),
          SymptomItem(id: 'hard_nodules_all_over_body', nameEn: 'Hard Nodules (Neck/Back)', nameMr: 'Hard Nodules (Neck/Back)'),
          SymptomItem(id: 'skin_ulcers', nameEn: 'Ruptured / Bleeding Ulcers', nameMr: 'Ruptured / Bleeding Ulcers'),
          SymptomItem(id: 'edema_of_limbs_dewlap', nameEn: 'Swelling on Legs / Dewlap', nameMr: 'Swelling on Legs / Dewlap'),
          SymptomItem(id: 'crepitant_swelling_thigh_shoulder', nameEn: 'Crackling Muscle Swelling (Black Quarter)', nameMr: 'Crackling Muscle Swelling (Black Quarter)'),
          SymptomItem(id: 'heavy_tick_infestation', nameEn: 'Heavy Tick / Parasite Load', nameMr: 'Heavy Tick / Parasite Load'),
        ],
      ),
      const BodySystemCategory(
        id: 'oral_nasal',
        nameEn: 'Mouth, Saliva & Nasal',
          nameMr: 'Mouth, Saliva & Nasal',
        iconKey: 'drop',
        symptoms: [
          SymptomItem(id: 'frothy_salivation', nameEn: 'Frothy Ropey Salivation', nameMr: 'Frothy Ropey Salivation'),
          SymptomItem(id: 'mouth_tongue_blisters', nameEn: 'Blisters / Ulcers on Tongue & Gums', nameMr: 'Blisters / Ulcers on Tongue & Gums'),
          SymptomItem(id: 'smacking_of_lips', nameEn: 'Smacking of Lips / Teeth Grinding', nameMr: 'Smacking of Lips / Teeth Grinding'),
          SymptomItem(id: 'purulent_nasal_discharge', nameEn: 'Thick Nasal Discharge', nameMr: 'Thick Nasal Discharge'),
          SymptomItem(id: 'submandibular_throat_swelling', nameEn: 'Throat & Jaw Swelling (HS)', nameMr: 'Throat & Jaw Swelling (HS)'),
        ],
      ),
      const BodySystemCategory(
        id: 'locomotion',
        nameEn: 'Locomotion & Hooves',
          nameMr: 'Locomotion & Hooves',
        iconKey: 'pawPrint',
        symptoms: [
          SymptomItem(id: 'severe_lameness', nameEn: 'Severe Lameness / Limping', nameMr: 'Severe Lameness / Limping'),
          SymptomItem(id: 'interdigital_hoof_lesions', nameEn: 'Wounds / Maggots in Hoof Cleft', nameMr: 'Wounds / Maggots in Hoof Cleft'),
          SymptomItem(id: 'inability_to_stand', nameEn: 'Inability to Stand Up', nameMr: 'Inability to Stand Up'),
          SymptomItem(id: 'stiffness_in_joints', nameEn: 'Swollen Stiff Knee Joints', nameMr: 'Swollen Stiff Knee Joints'),
        ],
      ),
      const BodySystemCategory(
        id: 'udder_milk',
        nameEn: 'Udder, Teats & Milk',
          nameMr: 'Udder, Teats & Milk',
        iconKey: 'cow',
        symptoms: [
          SymptomItem(id: 'swollen_hot_painful_udder', nameEn: 'Hot, Swollen & Painful Udder', nameMr: 'Hot, Swollen & Painful Udder'),
          SymptomItem(id: 'clots_flakes_watery_milk', nameEn: 'Curds / Flakes / Watery Milk', nameMr: 'Curds / Flakes / Watery Milk'),
          SymptomItem(id: 'blood_in_milk', nameEn: 'Blood / Reddishtinged Milk', nameMr: 'Blood / Reddishtinged Milk'),
          SymptomItem(id: 'drastic_milk_reduction', nameEn: 'Sudden Drastic Drop in Milk Yield', nameMr: 'Sudden Drastic Drop in Milk Yield'),
          SymptomItem(id: 'kicking_during_milking', nameEn: 'Refuses Touching / Kicking at Milking', nameMr: 'Refuses Touching / Kicking at Milking'),
        ],
      ),
      const BodySystemCategory(
        id: 'digestive_excretory',
        nameEn: 'Digestion & Excretion',
          nameMr: 'Digestion & Excretion',
        iconKey: 'activity',
        symptoms: [
          SymptomItem(id: 'dark_red_coffee_colored_urine', nameEn: 'Dark Red / Coffee Colored Urine', nameMr: 'Dark Red / Coffee Colored Urine'),
          SymptomItem(id: 'foul_smelling_watery_diarrhea', nameEn: 'Foul-smelling Watery Diarrhea', nameMr: 'Foul-smelling Watery Diarrhea'),
          SymptomItem(id: 'bloat_tympany', nameEn: 'Abdominal Bloat / Gas Accumulation', nameMr: 'Abdominal Bloat / Gas Accumulation'),
        ],
      ),
    ];
  }

  @override
  Future<AIDiagnosisResult> analyzeSymptoms({
    String? species,
    Map<String, List<String>>? symptomsChecklist,
    String? vernacularDescription,
    List<String>? images,
  }) async {
    // If online with httpClient, try backend
    if (_httpClient != null) {
      try {
        final uri = Uri.parse('$_baseUrl/symptoms/analyze');
        final response = await _httpClient.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'species': species,
            'symptoms_checklist': symptomsChecklist,
            'vernacular_description': vernacularDescription,
            'images': images,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return AIDiagnosisResult.fromJson(data);
        }
      } catch (_) {
        // Fall back to offline heuristic inference
      }
    }

    // Local heuristic engine for 100% offline availability
    return _localHeuristicInference(
      species: species,
      checklist: symptomsChecklist ?? {},
      vernacularText: vernacularDescription ?? '',
      hasImages: (images != null && images.isNotEmpty),
    );
  }

  @override
  Future<SymptomReportModel> submitReport({
    required String animalId,
    String? animalTagId,
    String? species,
    String? breed,
    Map<String, List<String>>? symptomsChecklist,
    String? vernacularDescription,
    List<String>? images,
    String? voiceNoteUrl,
  }) async {
    final aiResult = await analyzeSymptoms(
      species: species,
      symptomsChecklist: symptomsChecklist,
      vernacularDescription: vernacularDescription,
      images: images,
    );

    final newReport = SymptomReportModel(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      animalId: animalId,
      animalTagId: animalTagId ?? 'MH-HERD-${animalId.substring(0, 4).toUpperCase()}',
      species: species ?? 'Cattle',
      breed: breed ?? 'Gir',
      reportedBy: 'Vitthal Shinde (Farmer)',
      symptomsJson: {
        'checklist': symptomsChecklist ?? {},
        'vernacular_description': vernacularDescription ?? '',
      },
      severity: aiResult.severity,
      status: 'submitted',
      voiceNoteUrl: voiceNoteUrl,
      images: images ?? [],
      detectionResult: aiResult,
      caseId: aiResult.shouldEscalateCase ? 'CASE-${DateTime.now().millisecondsSinceEpoch % 100000}' : null,
      createdAt: DateTime.now(),
    );

    final reports = await getReports();
    reports.insert(0, newReport);
    await _saveReports(reports);

    return newReport;
  }

  @override
  Future<List<SymptomReportModel>> getReports({String? animalId}) async {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final reports = list
          .map((item) => SymptomReportModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (animalId != null) {
        return reports.where((r) => r.animalId == animalId).toList();
      }
      return reports;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<SymptomReportModel?> getReportById(String reportId) async {
    final reports = await getReports();
    try {
      return reports.firstWhere((r) => r.id == reportId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveReports(List<SymptomReportModel> reports) async {
    final listJson = reports.map((r) => r.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(listJson));
  }

  /// Seeds realistic Maharashtra livestock reports on initial boot
  Future<void> _seedInitialReportsIfEmpty() async {
    final existing = await getReports();
    if (existing.isNotEmpty) return;

    final seeded = [
      SymptomReportModel(
        id: 'rep-seed-01',
        animalId: 'anim-01',
        animalTagId: 'MH-PUN-GIR-104',
        species: 'Cattle',
        breed: 'Gir',
        reportedBy: 'Vitthal Shinde (Farmer)',
        symptomsJson: {
          'checklist': {
            'skin_coat': ['nodular_skin_lesions', 'hard_nodules_all_over_body'],
            'vitality': ['high_fever'],
          },
          'vernacular_description': 'Fever, appetite loss and clinical lesions observed.',
        },
        severity: SeverityLevel.critical,
        status: 'under_observation',
        images: ['https://bioherd.gov.in/demo/lsd_sample.jpg'],
        caseId: 'CASE-48192',
        detectionResult: const AIDiagnosisResult(
          modelVersion: 'bioherd-ensemble-v2.1-onnx-indicbert',
          primaryDiagnosis: DiseasePredictionModel(
            diseaseId: 'dis-lsd',
            nameEn: 'Lumpy Skin Disease (LSD)',
          nameMr: 'Lumpy Skin Disease (LSD)',
            confidence: 91.4,
            severity: SeverityLevel.critical,
            causativeAgent: 'Capripoxvirus',
            matchedSymptoms: ['Nodular Skin Lesions', 'High Fever', 'Hard Nodules'],
            clinicalReasoning: 'Distinctive circular skin nodules across dewlap and back accompanied by acute pyrexia.',
          ),
          differentialDiagnoses: [
            DiseasePredictionModel(
              diseaseId: 'dis-fmd',
              nameEn: 'Foot and Mouth Disease (FMD)',
          nameMr: 'Foot and Mouth Disease (FMD)',
              confidence: 5.8,
              severity: SeverityLevel.critical,
              causativeAgent: 'Aphthovirus',
              matchedSymptoms: ['High Fever'],
              clinicalReasoning: 'Secondary consideration based on shared viral fever profile.',
            ),
          ],
          severity: SeverityLevel.critical,
          confidence: 91.4,
          shouldEscalateCase: true,
          firstAid: FirstAidModel(
            en: {
              'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
              'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
            },
            mr: {
              'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
              'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
            },
            isolationRequired: true,
            zoonoticRisk: false,
          ),
          inferenceDurationMs: 64,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SymptomReportModel(
        id: 'rep-seed-02',
        animalId: 'anim-02',
        animalTagId: 'MH-SOL-KHL-201',
        species: 'Cattle',
        breed: 'Khillari',
        reportedBy: 'Sanjay Patil (Farmer)',
        symptomsJson: {
          'checklist': {
            'udder_milk': ['swollen_hot_painful_udder', 'clots_flakes_watery_milk'],
          },
          'vernacular_description': 'Fever, appetite loss and clinical lesions observed.',
        },
        severity: SeverityLevel.medium,
        status: 'in_treatment',
        images: [],
        caseId: 'CASE-31902',
        detectionResult: const AIDiagnosisResult(
          modelVersion: 'bioherd-ensemble-v2.1-onnx-indicbert',
          primaryDiagnosis: DiseasePredictionModel(
            diseaseId: 'dis-mastitis',
            nameEn: 'Mastitis (Clinical)',
          nameMr: 'Mastitis (Clinical)',
            confidence: 86.2,
            severity: SeverityLevel.medium,
            causativeAgent: 'Staphylococcus aureus',
            matchedSymptoms: ['Swollen Hot Painful Udder', 'Clots in Milk'],
            clinicalReasoning: 'Hot quarter inflammation with curdled milk secretions indicates acute clinical mastitis.',
          ),
          differentialDiagnoses: [],
          severity: SeverityLevel.medium,
          confidence: 86.2,
          shouldEscalateCase: true,
          firstAid: FirstAidModel(
            en: {
              'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
              'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
            },
            mr: {
              'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
              'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
            },
            isolationRequired: false,
            zoonoticRisk: true,
          ),
          inferenceDurationMs: 48,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    await _saveReports(seeded);
  }

  /// Offline fallback heuristic inference engine
  AIDiagnosisResult _localHeuristicInference({
    String? species,
    required Map<String, List<String>> checklist,
    required String vernacularText,
    required bool hasImages,
  }) {
    final allSymptoms = <String>{};
    checklist.forEach((_, list) => allSymptoms.addAll(list.map((s) => s.toLowerCase())));
    final textLower = vernacularText.toLowerCase();

    // Check for Mastitis (clinical udder & milk pathology)
    if (allSymptoms.contains('swollen_hot_painful_udder') ||
        allSymptoms.contains('clots_flakes_watery_milk') ||
        textLower.contains('mastitis') || textLower.contains('udder')) {
      return AIDiagnosisResult(
        modelVersion: 'bioherd-offline-heuristic-v1.0',
        primaryDiagnosis: const DiseasePredictionModel(
          diseaseId: 'dis-mastitis',
          nameEn: 'Mastitis (Clinical)',
          nameMr: 'Mastitis (Clinical)',
          confidence: 87.0,
          severity: SeverityLevel.medium,
          causativeAgent: 'Staphylococcus / Streptococcus',
          matchedSymptoms: ['Hot Swollen Udder', 'Clots in Milk'],
          clinicalReasoning: 'Inflammatory changes in mammary parenchyma and altered milk consistency indicate clinical mastitis.',
        ),
        differentialDiagnoses: const [],
        severity: SeverityLevel.medium,
        confidence: 87.0,
        shouldEscalateCase: true,
        firstAid: const FirstAidModel(
          en: {
            'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
            'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
          },
          mr: {
            'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
            'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
          },
          isolationRequired: false,
          zoonoticRisk: true,
        ),
        inferenceDurationMs: 38,
      );
    }

    // Check for Lumpy Skin Disease
    if (allSymptoms.contains('nodular_skin_lesions') ||
        allSymptoms.contains('hard_nodules_all_over_body') ||
        textLower.contains('lumpy') || textLower.contains('nodule')) {
      return AIDiagnosisResult(
        modelVersion: 'bioherd-offline-heuristic-v1.0',
        primaryDiagnosis: const DiseasePredictionModel(
          diseaseId: 'dis-lsd',
          nameEn: 'Lumpy Skin Disease (LSD)',
          nameMr: 'Lumpy Skin Disease (LSD)',
          confidence: 88.5,
          severity: SeverityLevel.critical,
          causativeAgent: 'Capripoxvirus',
          matchedSymptoms: ['Nodular Skin Lesions', 'Fever', 'Lumps on Body'],
          clinicalReasoning: 'Multiple cutaneous nodules detected matching classic Lumpy Skin Disease viral presentation.',
        ),
        differentialDiagnoses: const [
          DiseasePredictionModel(
            diseaseId: 'dis-fmd',
            nameEn: 'Foot and Mouth Disease (FMD)',
          nameMr: 'Foot and Mouth Disease (FMD)',
            confidence: 8.5,
            severity: SeverityLevel.critical,
            causativeAgent: 'Aphthovirus',
            matchedSymptoms: ['Pyrexia'],
            clinicalReasoning: 'Secondary differential consideration.',
          ),
        ],
        severity: SeverityLevel.critical,
        confidence: 88.5,
        shouldEscalateCase: true,
        firstAid: const FirstAidModel(
          en: {
            'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
            'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
          },
          mr: {
            'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
            'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
          },
          isolationRequired: true,
          zoonoticRisk: false,
        ),
        inferenceDurationMs: 45,
      );
    }

    // Check for Foot and Mouth Disease
    if (allSymptoms.contains('frothy_salivation') ||
        allSymptoms.contains('mouth_tongue_blisters') ||
        allSymptoms.contains('interdigital_hoof_lesions') ||
        textLower.contains('fmd') || textLower.contains('blister') || textLower.contains('saliva')) {
      return AIDiagnosisResult(
        modelVersion: 'bioherd-offline-heuristic-v1.0',
        primaryDiagnosis: const DiseasePredictionModel(
          diseaseId: 'dis-fmd',
          nameEn: 'Foot and Mouth Disease (FMD)',
          nameMr: 'Foot and Mouth Disease (FMD)',
          confidence: 89.2,
          severity: SeverityLevel.critical,
          causativeAgent: 'Aphthovirus',
          matchedSymptoms: ['Frothy Salivation', 'Hoof Cleft Lesions', 'Mouth Blisters'],
          clinicalReasoning: 'Bilateral vesicular stomatitis and interdigital hoof ulcers strongly point to Aphthovirus infection.',
        ),
        differentialDiagnoses: const [],
        severity: SeverityLevel.critical,
        confidence: 89.2,
        shouldEscalateCase: true,
        firstAid: const FirstAidModel(
          en: {
            'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
            'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
          },
          mr: {
            'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
            'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
          },
          isolationRequired: true,
          zoonoticRisk: false,
        ),
        inferenceDurationMs: 42,
      );
    }

    // Default General Pyrexia / Observation
    return AIDiagnosisResult(
      modelVersion: 'bioherd-offline-heuristic-v1.0',
      primaryDiagnosis: const DiseasePredictionModel(
        diseaseId: 'dis-general',
        nameEn: 'Undifferentiated Pyrexia / Under Observation',
          nameMr: 'Undifferentiated Pyrexia / Under Observation',
        confidence: 65.0,
        severity: SeverityLevel.low,
        causativeAgent: 'Non-specific viral or bacterial challenge',
        matchedSymptoms: ['Pyrexia / General Dullness'],
        clinicalReasoning: 'Mild non-specific symptom profile; monitor vitals and hydrate.',
      ),
      differentialDiagnoses: const [],
      severity: SeverityLevel.low,
      confidence: 65.0,
      shouldEscalateCase: false,
      firstAid: const FirstAidModel(
        en: {
          'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
          'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
        },
        mr: {
          'immediate_action': 'Isolate affected animal immediately in a dry, sanitized stall.',
          'sanitation': 'Disinfect shed with 4% sodium carbonate or lime powder.',
        },
        isolationRequired: false,
        zoonoticRisk: false,
      ),
      inferenceDurationMs: 35,
    );
  }
}
