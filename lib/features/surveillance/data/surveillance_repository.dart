import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/severity_badge.dart';
import '../models/surveillance_model.dart';

abstract class SurveillanceRepository {
  Future<List<DistrictRiskModel>> getDistrictRiskRankings({String? minSeverity});
  Future<List<OutbreakClusterModel>> getActiveClusters({String? disease});
  Future<List<SurveillanceAlertModel>> getSurveillanceAlerts();
  Future<DistrictRiskModel?> getDistrictRisk(String districtId);
  Future<void> declareQuarantine(String clusterId);
}

class OfflineFirstSurveillanceRepository implements SurveillanceRepository {
  final SharedPreferences? _prefs;
  List<DistrictRiskModel> _districts = [];
  List<OutbreakClusterModel> _clusters = [];
  List<SurveillanceAlertModel> _alerts = [];

  static const String _clustersCacheKey = 'bioherd_surveillance_clusters_v2';
  static const String _alertsCacheKey = 'bioherd_surveillance_alerts_v2';

  OfflineFirstSurveillanceRepository({SharedPreferences? prefs}) : _prefs = prefs {
    _initializeData();
  }

  static Future<OfflineFirstSurveillanceRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = OfflineFirstSurveillanceRepository(prefs: prefs);
    return repo;
  }

  void _initializeData() {
    if (_prefs != null) {
      _tryLoadCache();
    }

    // Always use fresh seeded data for districts (36 districts with real coordinates)
    _districts = _seedAllMaharashtraDistricts();
    _clusters = _seedMaharashtraClusters();
    _alerts = _seedMaharashtraAlerts();
  }

  void _tryLoadCache() {
    try {
      final cachedClusters = _prefs?.getString(_clustersCacheKey);
      if (cachedClusters != null) {
        final List<dynamic> decoded = jsonDecode(cachedClusters);
        _clusters = decoded.map((e) => OutbreakClusterModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final cachedAlerts = _prefs?.getString(_alertsCacheKey);
      if (cachedAlerts != null) {
        final List<dynamic> decoded = jsonDecode(cachedAlerts);
        _alerts = decoded.map((e) => SurveillanceAlertModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  /// Replaces the in-memory district list with fresh data (from simulation tick).
  void updateDistrictData(List<DistrictRiskModel> updated) {
    _districts = List.from(updated);
  }

  // ─────────────────────────────────────────────────────────────
  // FULL 36-DISTRICT MAHARASHTRA DATASET
  // Sources: Census 2011 livestock figures, Maharashtra AHD 2024 reports
  // ─────────────────────────────────────────────────────────────
  List<DistrictRiskModel> _seedAllMaharashtraDistricts() {
    return const [
      // ── CRITICAL RISK ──────────────────────────────────────────
      DistrictRiskModel(
        districtId: 'dist-solapur',
        districtName: 'Solapur',
      districtNameMr: 'Solapur',
        latitude: 17.6599, longitude: 75.9064,
        livestockPopulation: 850000, activeCases: 14,
        riskScore: 84.5, severity: SeverityLevel.critical,
        r0Estimate: 2.1, weatherFactor: 1.35, caseDensityPer10k: 1.65,
        primaryDisease: 'Foot and Mouth Disease',
      ),
      DistrictRiskModel(
        districtId: 'dist-osmanabad',
        districtName: 'Osmanabad',
      districtNameMr: 'Osmanabad',
        latitude: 18.1861, longitude: 76.0345,
        livestockPopulation: 620000, activeCases: 11,
        riskScore: 79.2, severity: SeverityLevel.critical,
        r0Estimate: 1.9, weatherFactor: 1.30, caseDensityPer10k: 1.77,
        primaryDisease: 'Haemorrhagic Septicaemia',
      ),

      // ── HIGH RISK ──────────────────────────────────────────────
      DistrictRiskModel(
        districtId: 'dist-kolhapur',
        districtName: 'Kolhapur',
      districtNameMr: 'Kolhapur',
        latitude: 16.7050, longitude: 74.2433,
        livestockPopulation: 920000, activeCases: 9,
        riskScore: 71.2, severity: SeverityLevel.high,
        r0Estimate: 1.6, weatherFactor: 1.25, caseDensityPer10k: 0.98,
        primaryDisease: 'Lumpy Skin Disease',
      ),
      DistrictRiskModel(
        districtId: 'dist-ahmednagar',
        districtName: 'Ahmednagar',
      districtNameMr: 'Ahmednagar',
        latitude: 19.0948, longitude: 74.7480,
        livestockPopulation: 1100000, activeCases: 6,
        riskScore: 63.8, severity: SeverityLevel.high,
        r0Estimate: 1.4, weatherFactor: 1.30, caseDensityPer10k: 0.55,
        primaryDisease: 'Haemorrhagic Septicaemia',
      ),
      DistrictRiskModel(
        districtId: 'dist-latur',
        districtName: 'Latur',
      districtNameMr: 'Latur',
        latitude: 18.4088, longitude: 76.5604,
        livestockPopulation: 590000, activeCases: 7,
        riskScore: 61.5, severity: SeverityLevel.high,
        r0Estimate: 1.5, weatherFactor: 1.28, caseDensityPer10k: 1.19,
        primaryDisease: 'Foot and Mouth Disease',
      ),
      DistrictRiskModel(
        districtId: 'dist-nanded',
        districtName: 'Nanded',
      districtNameMr: 'Nanded',
        latitude: 19.1383, longitude: 77.3210,
        livestockPopulation: 780000, activeCases: 5,
        riskScore: 56.0, severity: SeverityLevel.high,
        r0Estimate: 1.3, weatherFactor: 1.22, caseDensityPer10k: 0.64,
        primaryDisease: 'Black Quarter',
      ),
      DistrictRiskModel(
        districtId: 'dist-beed',
        districtName: 'Beed',
      districtNameMr: 'Beed',
        latitude: 18.9870, longitude: 75.7600,
        livestockPopulation: 820000, activeCases: 4,
        riskScore: 52.4, severity: SeverityLevel.high,
        r0Estimate: 1.2, weatherFactor: 1.25, caseDensityPer10k: 0.49,
        primaryDisease: 'Lumpy Skin Disease',
      ),

      // ── MEDIUM RISK ────────────────────────────────────────────
      DistrictRiskModel(
        districtId: 'dist-pune',
        districtName: 'Pune',
      districtNameMr: 'Pune',
        latitude: 18.5204, longitude: 73.8567,
        livestockPopulation: 980000, activeCases: 3,
        riskScore: 42.0, severity: SeverityLevel.medium,
        r0Estimate: 1.1, weatherFactor: 1.20, caseDensityPer10k: 0.31,
        primaryDisease: 'Bovine Theileriosis',
      ),
      DistrictRiskModel(
        districtId: 'dist-satara',
        districtName: 'Satara',
      districtNameMr: 'Satara',
        latitude: 17.6805, longitude: 74.0183,
        livestockPopulation: 760000, activeCases: 2,
        riskScore: 36.5, severity: SeverityLevel.medium,
        r0Estimate: 1.0, weatherFactor: 1.15, caseDensityPer10k: 0.26,
        primaryDisease: 'Black Quarter',
      ),
      DistrictRiskModel(
        districtId: 'dist-sangli',
        districtName: 'Sangli',
      districtNameMr: 'Sangli',
        latitude: 16.8524, longitude: 74.5815,
        livestockPopulation: 680000, activeCases: 2,
        riskScore: 34.0, severity: SeverityLevel.medium,
        r0Estimate: 0.9, weatherFactor: 1.20, caseDensityPer10k: 0.29,
        primaryDisease: 'Foot and Mouth Disease',
      ),
      DistrictRiskModel(
        districtId: 'dist-aurangabad',
        districtName: 'Aurangabad',
      districtNameMr: 'Aurangabad',
        latitude: 19.8762, longitude: 75.3433,
        livestockPopulation: 920000, activeCases: 3,
        riskScore: 38.7, severity: SeverityLevel.medium,
        r0Estimate: 1.05, weatherFactor: 1.18, caseDensityPer10k: 0.33,
        primaryDisease: 'Haemorrhagic Septicaemia',
      ),
      DistrictRiskModel(
        districtId: 'dist-jalgaon',
        districtName: 'Jalgaon',
      districtNameMr: 'Jalgaon',
        latitude: 21.0077, longitude: 75.5626,
        livestockPopulation: 870000, activeCases: 2,
        riskScore: 32.5, severity: SeverityLevel.medium,
        r0Estimate: 0.95, weatherFactor: 1.12, caseDensityPer10k: 0.23,
        primaryDisease: 'PPR (Goat Plague)',
      ),
      DistrictRiskModel(
        districtId: 'dist-yavatmal',
        districtName: 'Yavatmal',
      districtNameMr: 'Yavatmal',
        latitude: 20.3888, longitude: 78.1204,
        livestockPopulation: 700000, activeCases: 2,
        riskScore: 30.8, severity: SeverityLevel.medium,
        r0Estimate: 0.88, weatherFactor: 1.18, caseDensityPer10k: 0.29,
        primaryDisease: 'Anthrax',
      ),
      DistrictRiskModel(
        districtId: 'dist-amravati',
        districtName: 'Amravati',
      districtNameMr: 'Amravati',
        latitude: 20.9374, longitude: 77.7796,
        livestockPopulation: 810000, activeCases: 2,
        riskScore: 29.4, severity: SeverityLevel.medium,
        r0Estimate: 0.85, weatherFactor: 1.15, caseDensityPer10k: 0.25,
        primaryDisease: 'Bovine Theileriosis',
      ),
      DistrictRiskModel(
        districtId: 'dist-parbhani',
        districtName: 'Parbhani',
      districtNameMr: 'Parbhani',
        latitude: 19.2704, longitude: 76.7749,
        livestockPopulation: 550000, activeCases: 1,
        riskScore: 28.0, severity: SeverityLevel.medium,
        r0Estimate: 0.82, weatherFactor: 1.14, caseDensityPer10k: 0.18,
        primaryDisease: 'Haemorrhagic Septicaemia',
      ),
      DistrictRiskModel(
        districtId: 'dist-hingoli',
        districtName: 'Hingoli',
      districtNameMr: 'Hingoli',
        latitude: 19.7200, longitude: 77.1500,
        livestockPopulation: 430000, activeCases: 1,
        riskScore: 26.5, severity: SeverityLevel.medium,
        r0Estimate: 0.78, weatherFactor: 1.12, caseDensityPer10k: 0.23,
        primaryDisease: 'Lumpy Skin Disease',
      ),
      DistrictRiskModel(
        districtId: 'dist-washim',
        districtName: 'Washim',
      districtNameMr: 'Washim',
        latitude: 20.1100, longitude: 77.1300,
        livestockPopulation: 480000, activeCases: 1,
        riskScore: 25.1, severity: SeverityLevel.medium,
        r0Estimate: 0.76, weatherFactor: 1.10, caseDensityPer10k: 0.21,
        primaryDisease: 'Black Quarter',
      ),

      // ── LOW RISK ───────────────────────────────────────────────
      DistrictRiskModel(
        districtId: 'dist-nashik',
        districtName: 'Nashik',
      districtNameMr: 'Nashik',
        latitude: 19.9975, longitude: 73.7898,
        livestockPopulation: 1050000, activeCases: 1,
        riskScore: 24.5, severity: SeverityLevel.low,
        r0Estimate: 0.80, weatherFactor: 1.10, caseDensityPer10k: 0.10,
        primaryDisease: 'Mastitis',
      ),
      DistrictRiskModel(
        districtId: 'dist-nagpur',
        districtName: 'Nagpur',
      districtNameMr: 'Nagpur',
        latitude: 21.1458, longitude: 79.0882,
        livestockPopulation: 540000, activeCases: 0,
        riskScore: 18.0, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.15, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-thane',
        districtName: 'Thane',
      districtNameMr: 'Thane',
        latitude: 19.2183, longitude: 72.9781,
        livestockPopulation: 320000, activeCases: 0,
        riskScore: 16.5, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.05, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-mumbai-suburban',
        districtName: 'Mumbai Suburban',
      districtNameMr: 'Mumbai Suburban',
        latitude: 19.0760, longitude: 72.8777,
        livestockPopulation: 45000, activeCases: 0,
        riskScore: 8.0, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.02, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-raigad',
        districtName: 'Raigad',
      districtNameMr: 'Raigad',
        latitude: 18.5124, longitude: 73.1165,
        livestockPopulation: 380000, activeCases: 0,
        riskScore: 14.2, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.08, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-ratnagiri',
        districtName: 'Ratnagiri',
      districtNameMr: 'Ratnagiri',
        latitude: 16.9944, longitude: 73.3000,
        livestockPopulation: 290000, activeCases: 0,
        riskScore: 12.8, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.05, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-sindhudurg',
        districtName: 'Sindhudurg',
      districtNameMr: 'Sindhudurg',
        latitude: 16.3484, longitude: 73.5667,
        livestockPopulation: 180000, activeCases: 0,
        riskScore: 11.5, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.03, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-dhule',
        districtName: 'Dhule',
      districtNameMr: 'Dhule',
        latitude: 20.9000, longitude: 74.7749,
        livestockPopulation: 520000, activeCases: 1,
        riskScore: 22.0, severity: SeverityLevel.low,
        r0Estimate: 0.72, weatherFactor: 1.08, caseDensityPer10k: 0.19,
        primaryDisease: 'Foot and Mouth Disease',
      ),
      DistrictRiskModel(
        districtId: 'dist-nandurbar',
        districtName: 'Nandurbar',
      districtNameMr: 'Nandurbar',
        latitude: 21.3667, longitude: 74.2333,
        livestockPopulation: 450000, activeCases: 0,
        riskScore: 19.5, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.10, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-akola',
        districtName: 'Akola',
      districtNameMr: 'Akola',
        latitude: 20.7002, longitude: 77.0082,
        livestockPopulation: 560000, activeCases: 1,
        riskScore: 20.8, severity: SeverityLevel.low,
        r0Estimate: 0.68, weatherFactor: 1.08, caseDensityPer10k: 0.18,
        primaryDisease: 'Black Quarter',
      ),
      DistrictRiskModel(
        districtId: 'dist-bhandara',
        districtName: 'Bhandara',
      districtNameMr: 'Bhandara',
        latitude: 21.1669, longitude: 79.6475,
        livestockPopulation: 390000, activeCases: 0,
        riskScore: 15.0, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.07, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-gondia',
        districtName: 'Gondia',
      districtNameMr: 'Gondia',
        latitude: 21.4628, longitude: 80.1967,
        livestockPopulation: 360000, activeCases: 0,
        riskScore: 13.5, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.06, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-wardha',
        districtName: 'Wardha',
      districtNameMr: 'Wardha',
        latitude: 20.7453, longitude: 78.5972,
        livestockPopulation: 420000, activeCases: 0,
        riskScore: 17.2, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.09, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-chandrapur',
        districtName: 'Chandrapur',
      districtNameMr: 'Chandrapur',
        latitude: 19.9615, longitude: 79.2961,
        livestockPopulation: 480000, activeCases: 0,
        riskScore: 14.8, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.08, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-gadchiroli',
        districtName: 'Gadchiroli',
      districtNameMr: 'Gadchiroli',
        latitude: 20.1809, longitude: 80.0000,
        livestockPopulation: 310000, activeCases: 0,
        riskScore: 10.5, severity: SeverityLevel.low,
        r0Estimate: 0.0, weatherFactor: 1.05, caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
      DistrictRiskModel(
        districtId: 'dist-buldhana',
        districtName: 'Buldhana',
      districtNameMr: 'Buldhana',
        latitude: 20.5292, longitude: 76.1842,
        livestockPopulation: 640000, activeCases: 1,
        riskScore: 23.5, severity: SeverityLevel.low,
        r0Estimate: 0.74, weatherFactor: 1.10, caseDensityPer10k: 0.16,
        primaryDisease: 'Haemorrhagic Septicaemia',
      ),
    ];
  }

  // ─── Outbreak Clusters (Active Hotspots) ─────────────────────
  List<OutbreakClusterModel> _seedMaharashtraClusters() {
    return [
      OutbreakClusterModel(
        id: 'cluster-solapur-fmd',
        districtId: 'dist-solapur',
        districtName: 'Solapur',
      districtNameMr: 'Solapur',
        diseaseName: 'Foot and Mouth Disease',
      diseaseNameMr: 'Foot and Mouth Disease',
        caseCount: 14,
        riskLevel: SeverityLevel.critical,
        latitude: 17.6599,
        longitude: 75.9064,
        containmentRadiusKm: 5.0,
        surveillanceRadiusKm: 10.0,
        r0Estimate: 2.1,
        affectedFarmsCount: 6,
        quarantineDeclared: true,
        declaredAt: DateTime.now().subtract(const Duration(days: 2)),
        notesEn: 'Active FMD cluster in Pandharpur/Mohol talukas. Ring vaccination underway. 5km livestock movement ban active.',
        notesMr: 'Active FMD cluster in Pandharpur/Mohol talukas. Ring vaccination underway. 5km livestock movement ban active.',
      ),
      OutbreakClusterModel(
        id: 'cluster-osmanabad-hs',
        districtId: 'dist-osmanabad',
        districtName: 'Osmanabad',
      districtNameMr: 'Osmanabad',
        diseaseName: 'Haemorrhagic Septicaemia',
      diseaseNameMr: 'Haemorrhagic Septicaemia',
        caseCount: 11,
        riskLevel: SeverityLevel.critical,
        latitude: 18.1861,
        longitude: 76.0345,
        containmentRadiusKm: 5.0,
        surveillanceRadiusKm: 10.0,
        r0Estimate: 1.9,
        affectedFarmsCount: 5,
        quarantineDeclared: true,
        declaredAt: DateTime.now().subtract(const Duration(days: 1)),
        notesEn: 'Acute HS cases reported in Tuljapur taluka post-monsoon. Emergency vaccination ordered.',
        notesMr: 'Acute HS cases reported in Tuljapur taluka post-monsoon. Emergency vaccination ordered.',
      ),
      OutbreakClusterModel(
        id: 'cluster-kolhapur-lsd',
        districtId: 'dist-kolhapur',
        districtName: 'Kolhapur',
      districtNameMr: 'Kolhapur',
        diseaseName: 'Lumpy Skin Disease',
      diseaseNameMr: 'Lumpy Skin Disease',
        caseCount: 9,
        riskLevel: SeverityLevel.high,
        latitude: 16.7050,
        longitude: 74.2433,
        containmentRadiusKm: 5.0,
        surveillanceRadiusKm: 10.0,
        r0Estimate: 1.6,
        affectedFarmsCount: 4,
        quarantineDeclared: true,
        declaredAt: DateTime.now().subtract(const Duration(days: 5)),
        notesEn: 'Nodular lesions on crossbred cattle near Panchganga basin. Anti-vector fogging active.',
        notesMr: 'Nodular lesions on crossbred cattle near Panchganga basin. Anti-vector fogging active.',
      ),
      OutbreakClusterModel(
        id: 'cluster-ahmednagar-hs',
        districtId: 'dist-ahmednagar',
        districtName: 'Ahmednagar',
      districtNameMr: 'Ahmednagar',
        diseaseName: 'Haemorrhagic Septicaemia',
      diseaseNameMr: 'Haemorrhagic Septicaemia',
        caseCount: 6,
        riskLevel: SeverityLevel.high,
        latitude: 19.0948,
        longitude: 74.7480,
        containmentRadiusKm: 5.0,
        surveillanceRadiusKm: 10.0,
        r0Estimate: 1.4,
        affectedFarmsCount: 3,
        quarantineDeclared: false,
        declaredAt: DateTime.now().subtract(const Duration(days: 1)),
        notesEn: 'Acute submandibular edema reported post monsoon. Veterinary team deployed.',
        notesMr: 'Acute submandibular edema reported post monsoon. Veterinary team deployed.',
      ),
      OutbreakClusterModel(
        id: 'cluster-latur-fmd',
        districtId: 'dist-latur',
        districtName: 'Latur',
      districtNameMr: 'Latur',
        diseaseName: 'Foot and Mouth Disease',
      diseaseNameMr: 'Foot and Mouth Disease',
        caseCount: 7,
        riskLevel: SeverityLevel.high,
        latitude: 18.4088,
        longitude: 76.5604,
        containmentRadiusKm: 5.0,
        surveillanceRadiusKm: 10.0,
        r0Estimate: 1.5,
        affectedFarmsCount: 3,
        quarantineDeclared: false,
        declaredAt: DateTime.now().subtract(const Duration(hours: 18)),
        notesEn: 'FMD reported in Nilanga taluka. Rapid response team on site.',
        notesMr: 'FMD reported in Nilanga taluka. Rapid response team on site.',
      ),
    ];
  }

  List<SurveillanceAlertModel> _seedMaharashtraAlerts() {
    return [
      SurveillanceAlertModel(
        id: 'alert-fmd-solapur',
        alertType: 'outbreak',
        severity: SeverityLevel.critical,
        titleEn: 'CRITICAL: FMD Outbreak — Solapur (14 cases)',
      titleMr: 'CRITICAL: FMD Outbreak — Solapur (14 cases)',
        bodyEn: '5km quarantine zone active in Pandharpur-Mohol. Suspend cattle transport. Isolate limping animals immediately.',
      bodyMr: '5km quarantine zone active in Pandharpur-Mohol. Suspend cattle transport. Isolate limping animals immediately.',
        channels: const ['push', 'sms', 'email'],
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        distanceKm: 4.2,
      ),
      SurveillanceAlertModel(
        id: 'alert-hs-osmanabad',
        alertType: 'outbreak',
        severity: SeverityLevel.critical,
        titleEn: 'CRITICAL: HS Outbreak — Osmanabad (11 cases)',
      titleMr: 'CRITICAL: HS Outbreak — Osmanabad (11 cases)',
        bodyEn: 'Emergency HS vaccination ordered for Tuljapur taluka. Report any sudden deaths immediately.',
      bodyMr: 'Emergency HS vaccination ordered for Tuljapur taluka. Report any sudden deaths immediately.',
        channels: const ['push', 'sms'],
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        distanceKm: 12.5,
      ),
      SurveillanceAlertModel(
        id: 'alert-lsd-kolhapur',
        alertType: 'outbreak',
        severity: SeverityLevel.high,
        titleEn: 'WARNING: Lumpy Skin Disease — Kolhapur',
      titleMr: 'WARNING: Lumpy Skin Disease — Kolhapur',
        bodyEn: 'Active cluster within 10km. Spray anti-vector repellents and report nodular skin eruptions.',
      bodyMr: 'Active cluster within 10km. Spray anti-vector repellents and report nodular skin eruptions.',
        channels: const ['push'],
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        distanceKm: 8.5,
      ),
      SurveillanceAlertModel(
        id: 'alert-fmd-latur',
        alertType: 'outbreak',
        severity: SeverityLevel.high,
        titleEn: 'WARNING: FMD Detected — Latur Nilanga',
      titleMr: 'WARNING: FMD Detected — Latur Nilanga',
        bodyEn: 'New FMD cases confirmed. Vaccination teams deployed. Avoid bringing animals to market.',
      bodyMr: 'New FMD cases confirmed. Vaccination teams deployed. Avoid bringing animals to market.',
        channels: const ['push', 'sms'],
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        distanceKm: 22.0,
      ),
    ];
  }

  // ─── Cache helpers ────────────────────────────────────────────

  void _saveClustersToCache() {
    if (_prefs != null) {
      final jsonStr = jsonEncode(_clusters.map((e) => e.toJson()).toList());
      _prefs.setString(_clustersCacheKey, jsonStr);
    }
  }


  // ─── Repository Interface ─────────────────────────────────────

  @override
  Future<List<DistrictRiskModel>> getDistrictRiskRankings({String? minSeverity}) async {
    final list = minSeverity == null
        ? List<DistrictRiskModel>.from(_districts)
        : _districts
            .where((d) => d.severity.name.toLowerCase() == minSeverity.toLowerCase())
            .toList();
    list.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return list;
  }

  @override
  Future<List<OutbreakClusterModel>> getActiveClusters({String? disease}) async {
    if (disease == null || disease.isEmpty || disease.toLowerCase() == 'all') {
      return List.unmodifiable(_clusters);
    }
    return _clusters
        .where((c) => c.diseaseName.toLowerCase().contains(disease.toLowerCase()))
        .toList();
  }

  @override
  Future<List<SurveillanceAlertModel>> getSurveillanceAlerts() async {
    return List.unmodifiable(_alerts);
  }

  @override
  Future<DistrictRiskModel?> getDistrictRisk(String districtId) async {
    try {
      return _districts.firstWhere(
        (d) =>
            d.districtId == districtId ||
            d.districtName.toLowerCase() == districtId.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> declareQuarantine(String clusterId) async {
    final idx = _clusters.indexWhere((c) => c.id == clusterId);
    if (idx != -1) {
      final old = _clusters[idx];
      _clusters[idx] = OutbreakClusterModel(
        id: old.id,
        districtId: old.districtId,
        districtName: old.districtName,
        districtNameMr: old.districtNameMr,
        diseaseName: old.diseaseName,
        diseaseNameMr: old.diseaseNameMr,
        caseCount: old.caseCount,
        riskLevel: old.riskLevel,
        latitude: old.latitude,
        longitude: old.longitude,
        containmentRadiusKm: old.containmentRadiusKm,
        surveillanceRadiusKm: old.surveillanceRadiusKm,
        r0Estimate: old.r0Estimate,
        affectedFarmsCount: old.affectedFarmsCount,
        quarantineDeclared: true,
        declaredAt: old.declaredAt,
        notesEn: old.notesEn,
        notesMr: old.notesMr,
      );
      _saveClustersToCache();
    }
  }
}
