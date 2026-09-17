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

  static const String _districtsCacheKey = 'bioherd_surveillance_districts';
  static const String _clustersCacheKey = 'bioherd_surveillance_clusters';
  static const String _alertsCacheKey = 'bioherd_surveillance_alerts';

  OfflineFirstSurveillanceRepository({SharedPreferences? prefs}) : _prefs = prefs {
    _initializeData();
  }

  static Future<OfflineFirstSurveillanceRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = OfflineFirstSurveillanceRepository(prefs: prefs);
    return repo;
  }

  void _initializeData() {
    // 1. Load from cache if available
    if (_prefs != null) {
      final cachedDistricts = _prefs.getString(_districtsCacheKey);
      if (cachedDistricts != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedDistricts);
          _districts = decoded.map((e) => DistrictRiskModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      final cachedClusters = _prefs.getString(_clustersCacheKey);
      if (cachedClusters != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedClusters);
          _clusters = decoded.map((e) => OutbreakClusterModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      final cachedAlerts = _prefs.getString(_alertsCacheKey);
      if (cachedAlerts != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedAlerts);
          _alerts = decoded.map((e) => SurveillanceAlertModel.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }

    // 2. Fall back to pre-seeded Maharashtra data
    if (_districts.isEmpty) {
      _districts = _seedMaharashtraDistricts();
      _saveDistrictsToCache();
    }

    if (_clusters.isEmpty) {
      _clusters = _seedMaharashtraClusters();
      _saveClustersToCache();
    }

    if (_alerts.isEmpty) {
      _alerts = _seedMaharashtraAlerts();
      _saveAlertsToCache();
    }
  }

  List<DistrictRiskModel> _seedMaharashtraDistricts() {
    return [
      const DistrictRiskModel(
        districtId: 'dist-solapur',
        districtName: 'Solapur',
        districtNameMr: 'सोलापूर',
        latitude: 17.6599,
        longitude: 75.9064,
        livestockPopulation: 850000,
        activeCases: 14,
        riskScore: 84.5,
        severity: SeverityLevel.critical,
        r0Estimate: 2.1,
        weatherFactor: 1.35,
        caseDensityPer10k: 1.65,
        primaryDisease: 'Foot and Mouth Disease',
      ),
      const DistrictRiskModel(
        districtId: 'dist-kolhapur',
        districtName: 'Kolhapur',
        districtNameMr: 'कोल्हापूर',
        latitude: 16.7050,
        longitude: 74.2433,
        livestockPopulation: 920000,
        activeCases: 9,
        riskScore: 71.2,
        severity: SeverityLevel.high,
        r0Estimate: 1.6,
        weatherFactor: 1.25,
        caseDensityPer10k: 0.98,
        primaryDisease: 'Lumpy Skin Disease',
      ),
      const DistrictRiskModel(
        districtId: 'dist-ahmednagar',
        districtName: 'Ahmednagar',
        districtNameMr: 'अहमदनगर',
        latitude: 19.0948,
        longitude: 74.7480,
        livestockPopulation: 1100000,
        activeCases: 6,
        riskScore: 63.8,
        severity: SeverityLevel.high,
        r0Estimate: 1.4,
        weatherFactor: 1.30,
        caseDensityPer10k: 0.55,
        primaryDisease: 'Haemorrhagic Septicaemia',
      ),
      const DistrictRiskModel(
        districtId: 'dist-pune',
        districtName: 'Pune',
        districtNameMr: 'पुणे',
        latitude: 18.5204,
        longitude: 73.8567,
        livestockPopulation: 980000,
        activeCases: 3,
        riskScore: 42.0,
        severity: SeverityLevel.medium,
        r0Estimate: 1.1,
        weatherFactor: 1.20,
        caseDensityPer10k: 0.31,
        primaryDisease: 'Bovine Theileriosis',
      ),
      const DistrictRiskModel(
        districtId: 'dist-satara',
        districtName: 'Satara',
        districtNameMr: 'सातारा',
        latitude: 17.6805,
        longitude: 74.0183,
        livestockPopulation: 760000,
        activeCases: 2,
        riskScore: 36.5,
        severity: SeverityLevel.medium,
        r0Estimate: 1.0,
        weatherFactor: 1.15,
        caseDensityPer10k: 0.26,
        primaryDisease: 'Black Quarter',
      ),
      const DistrictRiskModel(
        districtId: 'dist-sangli',
        districtName: 'Sangli',
        districtNameMr: 'सांगली',
        latitude: 16.8524,
        longitude: 74.5815,
        livestockPopulation: 680000,
        activeCases: 2,
        riskScore: 34.0,
        severity: SeverityLevel.medium,
        r0Estimate: 0.9,
        weatherFactor: 1.20,
        caseDensityPer10k: 0.29,
        primaryDisease: 'Foot and Mouth Disease',
      ),
      const DistrictRiskModel(
        districtId: 'dist-nashik',
        districtName: 'Nashik',
        districtNameMr: 'नाशिक',
        latitude: 19.9975,
        longitude: 73.7898,
        livestockPopulation: 1050000,
        activeCases: 1,
        riskScore: 24.5,
        severity: SeverityLevel.low,
        r0Estimate: 0.8,
        weatherFactor: 1.10,
        caseDensityPer10k: 0.10,
        primaryDisease: 'Mastitis',
      ),
      const DistrictRiskModel(
        districtId: 'dist-nagpur',
        districtName: 'Nagpur',
        districtNameMr: 'नागपूर',
        latitude: 21.1458,
        longitude: 79.0882,
        livestockPopulation: 540000,
        activeCases: 0,
        riskScore: 18.0,
        severity: SeverityLevel.low,
        r0Estimate: 0.0,
        weatherFactor: 1.15,
        caseDensityPer10k: 0.0,
        primaryDisease: 'None',
      ),
    ];
  }

  List<OutbreakClusterModel> _seedMaharashtraClusters() {
    return [
      OutbreakClusterModel(
        id: 'cluster-solapur-fmd',
        districtId: 'dist-solapur',
        districtName: 'Solapur',
        districtNameMr: 'सोलापूर',
        diseaseName: 'Foot and Mouth Disease',
        diseaseNameMr: 'लाळ्या खुरकूत',
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
        notesEn: 'Active FMD cluster in Pandharpur/Mohol talukas. Ring vaccination underway.',
        notesMr: 'पंढरपूर व मोहोळ तालुक्यात लाळ्या खुरकूतचा संसर्ग. ५ किमी क्षेत्रात जनावरे वाहतूक बंदी लागू.',
      ),
      OutbreakClusterModel(
        id: 'cluster-kolhapur-lsd',
        districtId: 'dist-kolhapur',
        districtName: 'Kolhapur',
        districtNameMr: 'कोल्हापूर',
        diseaseName: 'Lumpy Skin Disease',
        diseaseNameMr: 'गाठींचा त्वचा रोग',
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
        notesMr: 'पंचगंगा खोऱ्यात संकरित गाईंमध्ये गाठींचा प्रादुर्भाव. धुरी व डास प्रतिबंधक फवारणी सुरू.',
      ),
      OutbreakClusterModel(
        id: 'cluster-ahmednagar-hs',
        districtId: 'dist-ahmednagar',
        districtName: 'Ahmednagar',
        districtNameMr: 'अहमदनगर',
        diseaseName: 'Haemorrhagic Septicaemia',
        diseaseNameMr: 'घटसर्प',
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
        notesEn: 'Acute submandibular edema reported post monsoon showers. Veterinary team deployed.',
        notesMr: 'पावसाळ्यानंतर गळ्याखाली सूज व ताप. पशुवैद्यकीय पथकाद्वारे तातडीचे उपचार.',
      ),
    ];
  }

  List<SurveillanceAlertModel> _seedMaharashtraAlerts() {
    return [
      SurveillanceAlertModel(
        id: 'alert-fmd-solapur',
        alertType: 'outbreak',
        severity: SeverityLevel.critical,
        titleEn: 'CRITICAL: Foot and Mouth Disease Outbreak in Solapur',
        titleMr: 'तातडीचा इशारा: सोलापूर जिल्ह्यात लाळ्या खुरकूतचा प्रादुर्भाव',
        bodyEn: '5km quarantine zone active in Pandharpur-Mohol. Strictly suspend cattle transport and isolate limping animals.',
        bodyMr: 'पंढरपूर-मोहोळ भागात ५ किमी विलगीकरण क्षेत्र लागू. जनावरांची वाहतूक थांबवा व बाधित जनावरे वेगळी ठेवा.',
        channels: const ['push', 'sms'],
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        distanceKm: 4.2,
      ),
      SurveillanceAlertModel(
        id: 'alert-lsd-kolhapur',
        alertType: 'outbreak',
        severity: SeverityLevel.high,
        titleEn: 'WARNING: Lumpy Skin Disease Hotspot Detected',
        titleMr: 'दक्षता सूचना: कोल्हापूर परिसरात गाठींचा त्वचा रोग',
        bodyEn: 'Active cluster within 10km. Spray anti-vector repellents in cow sheds and report nodular skin eruptions.',
        bodyMr: '१० किमी परिघात प्रादुर्भाव. गोठ्यात डास व गोचीड प्रतिबंधक फवारणी करा आणि अंगावर गाठी दिसल्यास लगेच नोंदवा.',
        channels: const ['push'],
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        distanceKm: 8.5,
      ),
    ];
  }

  void _saveDistrictsToCache() {
    if (_prefs != null) {
      final jsonStr = jsonEncode(_districts.map((e) => e.toJson()).toList());
      _prefs.setString(_districtsCacheKey, jsonStr);
    }
  }

  void _saveClustersToCache() {
    if (_prefs != null) {
      final jsonStr = jsonEncode(_clusters.map((e) => e.toJson()).toList());
      _prefs.setString(_clustersCacheKey, jsonStr);
    }
  }

  void _saveAlertsToCache() {
    if (_prefs != null) {
      final jsonStr = jsonEncode(_alerts.map((e) => e.toJson()).toList());
      _prefs.setString(_alertsCacheKey, jsonStr);
    }
  }

  @override
  Future<List<DistrictRiskModel>> getDistrictRiskRankings({String? minSeverity}) async {
    if (minSeverity == null) return List.unmodifiable(_districts);
    return _districts.where((d) => d.severity.name.toLowerCase() == minSeverity.toLowerCase()).toList();
  }

  @override
  Future<List<OutbreakClusterModel>> getActiveClusters({String? disease}) async {
    if (disease == null || disease.isEmpty || disease.toLowerCase() == 'all') {
      return List.unmodifiable(_clusters);
    }
    return _clusters.where((c) => c.diseaseName.toLowerCase().contains(disease.toLowerCase())).toList();
  }

  @override
  Future<List<SurveillanceAlertModel>> getSurveillanceAlerts() async {
    return List.unmodifiable(_alerts);
  }

  @override
  Future<DistrictRiskModel?> getDistrictRisk(String districtId) async {
    try {
      return _districts.firstWhere(
        (d) => d.districtId == districtId || d.districtName.toLowerCase() == districtId.toLowerCase(),
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
