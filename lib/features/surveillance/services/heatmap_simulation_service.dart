import 'dart:async';
import 'dart:math';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/surveillance/models/surveillance_model.dart';

/// Simulates real-time disease risk fluctuations, live auto-moving livestock
/// transit vectors, contagion wave propagation, and telemetry logs across Maharashtra.
class HeatmapSimulationService {
  Duration updateInterval;
  final _random = Random();

  // Dual streams: rich SimulationTickData and legacy district list
  final _tickController = StreamController<SimulationTickData>.broadcast();
  final _legacyController = StreamController<List<DistrictRiskModel>>.broadcast();

  Timer? _timer;
  List<DistrictRiskModel> _currentDistricts = [];
  List<OutbreakClusterModel> _currentClusters = [];
  List<LivestockTransitVehicle> _currentVehicles = [];
  final List<LiveSurveillanceLog> _logs = [];
  bool _isRunning = false;
  int _totalTicks = 0;
  int _totalInterceptions = 0;
  double _speedMultiplier = 1.0;

  HeatmapSimulationService({
    this.updateInterval = const Duration(seconds: 2),
  });

  Stream<SimulationTickData> get tickStream => _tickController.stream;
  Stream<List<DistrictRiskModel>> get stream => _legacyController.stream;
  bool get isRunning => _isRunning;
  double get speedMultiplier => _speedMultiplier;
  int get totalTicks => _totalTicks;
  List<LivestockTransitVehicle> get currentVehicles => List.unmodifiable(_currentVehicles);
  List<LiveSurveillanceLog> get currentLogs => List.unmodifiable(_logs);

  void start(List<DistrictRiskModel> initialDistricts, {List<OutbreakClusterModel>? initialClusters}) {
    _currentDistricts = List.from(initialDistricts);
    _currentClusters = List.from(initialClusters ?? []);
    if (_currentVehicles.isEmpty) {
      _currentVehicles = _seedInitialTransitVehicles(_currentDistricts);
    }
    _isRunning = true;

    _timer?.cancel();
    final effectiveInterval = Duration(milliseconds: (updateInterval.inMilliseconds / _speedMultiplier).round());
    _timer = Timer.periodic(effectiveInterval, (_) => _tick());

    // Send immediate initial tick
    _emitTick();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  void resume() {
    if (!_isRunning && _currentDistricts.isNotEmpty) {
      _isRunning = true;
      final effectiveInterval = Duration(milliseconds: (updateInterval.inMilliseconds / _speedMultiplier).round());
      _timer = Timer.periodic(effectiveInterval, (_) => _tick());
    }
  }

  void setSpeed(double multiplier) {
    _speedMultiplier = multiplier.clamp(0.5, 5.0);
    if (_isRunning) {
      _timer?.cancel();
      final effectiveInterval = Duration(milliseconds: (updateInterval.inMilliseconds / _speedMultiplier).round());
      _timer = Timer.periodic(effectiveInterval, (_) => _tick());
    }
  }

  void dispose() {
    stop();
    _tickController.close();
    _legacyController.close();
  }

  /// Instantly injects an outbreak spike into a given district to demonstrate live telemetry.
  void triggerMockOutbreak(String districtId, {String disease = 'Foot and Mouth Disease (FMD)'}) {
    final idx = _currentDistricts.indexWhere((d) => d.districtId == districtId || d.districtName.toLowerCase() == districtId.toLowerCase());
    if (idx != -1) {
      final old = _currentDistricts[idx];
      final newCases = old.activeCases + 18;
      final newRisk = min(98.5, old.riskScore + 28.0);
      final updated = old.copyWith(
        activeCases: newCases,
        riskScore: double.parse(newRisk.toStringAsFixed(1)),
        riskScoreDelta: 28.0,
        severity: SeverityLevel.critical,
        r0Estimate: min(3.4, old.r0Estimate + 0.8),
        primaryDisease: disease,
      );
      _currentDistricts[idx] = updated;

      _addLog(
        district: old.districtName,
        message: 'EPIDEMIC SURGE: Sudden spike of +18 suspected cases in ${old.districtName}. R0 surged to ${updated.r0Estimate}.',
        severity: SeverityLevel.critical,
        eventType: 'outbreak_surge',
      );

      _emitTick();
    }
  }

  void _tick() {
    _totalTicks++;

    // 1. Advance auto-moving livestock transit vehicles
    _advanceVehicles();

    // 2. Simulate district risk micro-fluctuations
    final List<SurveillanceAlertModel> newAlerts = [];
    _currentDistricts = _currentDistricts.map((d) {
      final isQuarantined = _currentClusters.any((c) => c.districtId == d.districtId && c.quarantineDeclared);

      // Quarantine enforcement causes risk to decline; uncontained hotspots slowly spread
      double delta;
      if (isQuarantined) {
        delta = -0.4 - (_random.nextDouble() * 1.2); // containment working
      } else if (d.severity == SeverityLevel.critical || d.severity == SeverityLevel.high) {
        delta = (_random.nextDouble() - 0.42) * 2.5; // active hotspot fluctuation
      } else {
        delta = (_random.nextDouble() - 0.50) * 1.2; // stable background variance
      }

      var newRisk = (d.riskScore + delta).clamp(4.0, 99.5);
      var newCases = d.activeCases;

      // Occasional case resolution or new reporting
      if (_random.nextDouble() < 0.20 && d.riskScore > 40) {
        newCases = (newCases + (_random.nextDouble() < 0.6 ? 1 : -1)).clamp(1, 180);
      }

      final newSeverity = _riskToSeverity(newRisk);
      final newR0 = _updateR0(d.r0Estimate, isQuarantined);

      // Check for crossing into critical threshold to trigger dynamic alert
      if (d.severity != SeverityLevel.critical && newSeverity == SeverityLevel.critical) {
        newAlerts.add(SurveillanceAlertModel(
          id: 'sim-alert-${DateTime.now().millisecondsSinceEpoch}',
          alertType: 'outbreak_surge',
          severity: SeverityLevel.critical,
          titleEn: 'CRITICAL ALERT: ${d.districtName} Risk Index Crossed 75',
          titleMr: 'CRITICAL ALERT: ${d.districtName} Risk Index Crossed 75',
          bodyEn: 'Active cases rose to $newCases. Mobile Veterinary Units deployed to high-density talukas.',
          bodyMr: 'Active cases rose to $newCases. Mobile Veterinary Units deployed to high-density talukas.',
          channels: const ['push', 'sms'],
          isRead: false,
          createdAt: DateTime.now(),
        ));

        _addLog(
          district: d.districtName,
          message: 'District status escalated to CRITICAL (${newRisk.toStringAsFixed(1)}/100). Containment advised.',
          severity: SeverityLevel.critical,
          eventType: 'outbreak_surge',
        );
      }

      // Update history
      final history = List<double>.from(d.recentRiskHistory);
      history.add(double.parse(newRisk.toStringAsFixed(1)));
      if (history.length > 8) history.removeAt(0);

      return d.copyWith(
        activeCases: newCases,
        riskScore: double.parse(newRisk.toStringAsFixed(1)),
        riskScoreDelta: double.parse(delta.toStringAsFixed(1)),
        severity: newSeverity,
        r0Estimate: newR0,
        recentRiskHistory: history,
        caseDensityPer10k: newCases / (d.livestockPopulation / 10000),
      );
    }).toList();

    // 3. Periodic telemetry logs
    if (_totalTicks % 3 == 0) {
      _generatePeriodicTelemetryLog();
    }

    _emitTick(newAlerts: newAlerts);
  }

  void _advanceVehicles() {
    for (int i = 0; i < _currentVehicles.length; i++) {
      final v = _currentVehicles[i];
      // Progress step based on speed
      final step = 0.035 * _speedMultiplier;
      var newProgress = v.progress + step;

      double curLat;
      double curLon;
      String status = v.biosecurityStatus;
      SeverityLevel hazard = v.hazardLevel;

      if (newProgress >= 1.0) {
        // Vehicle reached destination: swap origin and destination for return trip
        newProgress = 0.0;
        final newOriginDist = v.destinationDistrict;
        final newDestDist = v.originDistrict;
        final newOriginLat = v.destLat;
        final newOriginLon = v.destLon;
        final newDestLat = v.originLat;
        final newDestLon = v.originLon;

        curLat = newOriginLat;
        curLon = newOriginLon;
        status = 'cleared';
        hazard = SeverityLevel.low;

        _currentVehicles[i] = v.copyWith(
          originDistrict: newOriginDist,
          destinationDistrict: newDestDist,
          originLat: newOriginLat,
          originLon: newOriginLon,
          destLat: newDestLat,
          destLon: newDestLon,
          currentLat: curLat,
          currentLon: curLon,
          progress: 0.0,
          biosecurityStatus: status,
          hazardLevel: hazard,
        );
        continue;
      }

      // Interpolate along route
      curLat = v.originLat + (v.destLat - v.originLat) * newProgress;
      curLon = v.originLon + (v.destLon - v.originLon) * newProgress;

      // Check proximity to containment clusters (5km radius ~ 0.045 deg lat/lon)
      for (final cluster in _currentClusters) {
        final distKm = _approxDistanceKm(curLat, curLon, cluster.latitude, cluster.longitude);
        if (distKm <= cluster.containmentRadiusKm) {
          if (status != 'containment_intercepted') {
            status = 'containment_intercepted';
            hazard = SeverityLevel.critical;
            _totalInterceptions++;

            _addLog(
              district: cluster.districtName,
              message: 'BIOSECURITY INTERCEPTION: Vehicle ${v.licensePlate} (${v.animalHeadCount} ${v.species}) entered ${cluster.districtName} containment perimeter.',
              severity: SeverityLevel.critical,
              eventType: 'transit_screened',
            );
          }
          break;
        } else if (distKm <= cluster.surveillanceRadiusKm) {
          if (status == 'cleared') {
            status = 'screening_required';
            hazard = SeverityLevel.high;
          }
        }
      }

      _currentVehicles[i] = v.copyWith(
        currentLat: curLat,
        currentLon: curLon,
        progress: newProgress,
        biosecurityStatus: status,
        hazardLevel: hazard,
      );
    }
  }

  void _emitTick({List<SurveillanceAlertModel> newAlerts = const []}) {
    // Legacy stream gets districts sorted descending by risk score
    final sorted = List<DistrictRiskModel>.from(_currentDistricts)
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    _legacyController.add(List.unmodifiable(sorted));

    final avgRisk = _currentDistricts.isEmpty
        ? 0.0
        : _currentDistricts.fold<double>(0.0, (sum, d) => sum + d.riskScore) / _currentDistricts.length;

    _tickController.add(SimulationTickData(
      districts: List.unmodifiable(sorted),
      clusters: List.unmodifiable(_currentClusters),
      vehicles: List.unmodifiable(_currentVehicles),
      recentLogs: List.unmodifiable(_logs),
      newAlerts: newAlerts,
      totalTicks: _totalTicks,
      averageRiskIndex: double.parse(avgRisk.toStringAsFixed(1)),
      totalTransitInterceptions: _totalInterceptions,
    ));
  }

  void _addLog({
    required String district,
    required String message,
    required SeverityLevel severity,
    required String eventType,
  }) {
    _logs.insert(
      0,
      LiveSurveillanceLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(999)}',
        timestamp: DateTime.now(),
        district: district,
        message: message,
        severity: severity,
        eventType: eventType,
      ),
    );
    if (_logs.length > 25) {
      _logs.removeLast();
    }
  }

  void _generatePeriodicTelemetryLog() {
    final highDistricts = _currentDistricts.where((d) => d.severity == SeverityLevel.critical || d.severity == SeverityLevel.high).toList();
    if (highDistricts.isNotEmpty) {
      final sample = highDistricts[_random.nextInt(highDistricts.length)];
      final messages = [
        'Routine surveillance telemetry verified in ${sample.districtName}. Herd vaccination rate at 94.2%.',
        'Weather station sensor in ${sample.districtName} logged humidity front: ${sample.weatherFactor}x pathogen risk factor.',
        'Veterinary officer Dr. Shinde completed clinical review in ${sample.districtName} cluster.',
        'Containment zone checkpoint inspection: 14 agricultural carriers screened biosecure.',
      ];
      _addLog(
        district: sample.districtName,
        message: messages[_random.nextInt(messages.length)],
        severity: sample.severity == SeverityLevel.critical ? SeverityLevel.medium : SeverityLevel.low,
        eventType: 'telemetry_update',
      );
    }
  }

  SeverityLevel _riskToSeverity(double risk) {
    if (risk >= 75) return SeverityLevel.critical;
    if (risk >= 50) return SeverityLevel.high;
    if (risk >= 25) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  double _updateR0(double current, bool isQuarantined) {
    if (isQuarantined) {
      final delta = -0.05 - (_random.nextDouble() * 0.08);
      return double.parse((current + delta).clamp(0.6, 3.5).toStringAsFixed(2));
    } else {
      final delta = (_random.nextDouble() - 0.48) * 0.06;
      return double.parse((current + delta).clamp(0.6, 3.5).toStringAsFixed(2));
    }
  }

  double _approxDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1) * 111.0;
    final dLon = (lon2 - lon1) * 111.0 * cos(lat1 * pi / 180.0);
    return sqrt(dLat * dLat + dLon * dLon);
  }

  List<LivestockTransitVehicle> _seedInitialTransitVehicles(List<DistrictRiskModel> districts) {
    DistrictRiskModel findD(String name, double defLat, double defLon) {
      return districts.firstWhere(
        (d) => d.districtName.toLowerCase() == name.toLowerCase(),
        orElse: () => DistrictRiskModel(
          districtId: 'def',
          districtName: name,
          districtNameMr: name,
          latitude: defLat,
          longitude: defLon,
          livestockPopulation: 300000,
          activeCases: 10,
          riskScore: 40.0,
          severity: SeverityLevel.medium,
          r0Estimate: 1.2,
          weatherFactor: 1.0,
          caseDensityPer10k: 1.0,
          primaryDisease: 'FMD',
        ),
      );
    }

    final pune = findD('Pune', 18.5204, 73.8567);
    final solapur = findD('Solapur', 17.6599, 75.9064);
    final osmanabad = findD('Osmanabad', 18.1856, 76.0419);
    final kolhapur = findD('Kolhapur', 16.7050, 74.2433);
    final sangli = findD('Sangli', 16.8524, 74.5815);
    final nashik = findD('Nashik', 19.9975, 73.7898);
    final ahmednagar = findD('Ahmednagar', 19.0948, 74.7480);
    final nagpur = findD('Nagpur', 21.1458, 79.0882);
    final amravati = findD('Amravati', 20.9374, 77.7796);
    final satara = findD('Satara', 17.6805, 74.0183);
    final latur = findD('Latur', 18.4088, 76.5604);
    final nanded = findD('Nanded', 19.1383, 77.3210);

    return [
      LivestockTransitVehicle(
        id: 'veh-01',
        licensePlate: 'MH-12-TR-4011',
        carrierName: 'Sahyadri Cattle Transport',
        originDistrict: pune.districtName,
        destinationDistrict: solapur.districtName,
        originLat: pune.latitude,
        originLon: pune.longitude,
        destLat: solapur.latitude,
        destLon: solapur.longitude,
        currentLat: pune.latitude + (solapur.latitude - pune.latitude) * 0.35,
        currentLon: pune.longitude + (solapur.longitude - pune.longitude) * 0.35,
        progress: 0.35,
        speedKmH: 52.0,
        animalHeadCount: 22,
        species: 'Gir Cattle',
        biosecurityStatus: 'cleared',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 98221 44019',
        dispatchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LivestockTransitVehicle(
        id: 'veh-02',
        licensePlate: 'MH-13-LS-9920',
        carrierName: 'Deccan Livestock Carrier',
        originDistrict: solapur.districtName,
        destinationDistrict: osmanabad.districtName,
        originLat: solapur.latitude,
        originLon: solapur.longitude,
        destLat: osmanabad.latitude,
        destLon: osmanabad.longitude,
        currentLat: solapur.latitude + (osmanabad.latitude - solapur.latitude) * 0.70,
        currentLon: solapur.longitude + (osmanabad.longitude - solapur.longitude) * 0.70,
        progress: 0.70,
        speedKmH: 44.0,
        animalHeadCount: 18,
        species: 'Khillari Bulls',
        biosecurityStatus: 'containment_intercepted',
        hazardLevel: SeverityLevel.critical,
        driverContact: '+91 94220 88192',
        dispatchedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LivestockTransitVehicle(
        id: 'veh-03',
        licensePlate: 'MH-09-CK-3104',
        carrierName: 'Krishna Valley Agro Haulers',
        originDistrict: kolhapur.districtName,
        destinationDistrict: sangli.districtName,
        originLat: kolhapur.latitude,
        originLon: kolhapur.longitude,
        destLat: sangli.latitude,
        destLon: sangli.longitude,
        currentLat: kolhapur.latitude + (sangli.latitude - kolhapur.latitude) * 0.50,
        currentLon: kolhapur.longitude + (sangli.longitude - kolhapur.longitude) * 0.50,
        progress: 0.50,
        speedKmH: 48.0,
        animalHeadCount: 16,
        species: 'Murrah Buffaloes',
        biosecurityStatus: 'cleared',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 98901 33412',
        dispatchedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      LivestockTransitVehicle(
        id: 'veh-04',
        licensePlate: 'MH-15-VT-7712',
        carrierName: 'Godavari Farm Logistics',
        originDistrict: nashik.districtName,
        destinationDistrict: ahmednagar.districtName,
        originLat: nashik.latitude,
        originLon: nashik.longitude,
        destLat: ahmednagar.latitude,
        destLon: ahmednagar.longitude,
        currentLat: nashik.latitude + (ahmednagar.latitude - nashik.latitude) * 0.25,
        currentLon: nashik.longitude + (ahmednagar.longitude - nashik.longitude) * 0.25,
        progress: 0.25,
        speedKmH: 55.0,
        animalHeadCount: 20,
        species: 'Dangi Cattle',
        biosecurityStatus: 'cleared',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 97654 22910',
        dispatchedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      LivestockTransitVehicle(
        id: 'veh-05',
        licensePlate: 'MH-31-TR-5540',
        carrierName: 'Vidarbha Dairy Transit',
        originDistrict: nagpur.districtName,
        destinationDistrict: amravati.districtName,
        originLat: nagpur.latitude,
        originLon: nagpur.longitude,
        destLat: amravati.latitude,
        destLon: amravati.longitude,
        currentLat: nagpur.latitude + (amravati.latitude - nagpur.latitude) * 0.60,
        currentLon: nagpur.longitude + (amravati.longitude - nagpur.longitude) * 0.60,
        progress: 0.60,
        speedKmH: 60.0,
        animalHeadCount: 26,
        species: 'Gaolao Cattle',
        biosecurityStatus: 'cleared',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 99231 66720',
        dispatchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LivestockTransitVehicle(
        id: 'veh-06',
        licensePlate: 'MH-11-DF-2281',
        carrierName: 'Western Ghats Milk Van',
        originDistrict: satara.districtName,
        destinationDistrict: pune.districtName,
        originLat: satara.latitude,
        originLon: satara.longitude,
        destLat: pune.latitude,
        destLon: pune.longitude,
        currentLat: satara.latitude + (pune.latitude - satara.latitude) * 0.40,
        currentLon: satara.longitude + (pune.longitude - satara.longitude) * 0.40,
        progress: 0.40,
        speedKmH: 50.0,
        animalHeadCount: 14,
        species: 'Crossbred HF Cows',
        biosecurityStatus: 'cleared',
        hazardLevel: SeverityLevel.low,
        driverContact: '+91 98810 55198',
        dispatchedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LivestockTransitVehicle(
        id: 'veh-07',
        licensePlate: 'MH-24-DE-6632',
        carrierName: 'Marathwada Agro Transit',
        originDistrict: latur.districtName,
        destinationDistrict: nanded.districtName,
        originLat: latur.latitude,
        originLon: latur.longitude,
        destLat: nanded.latitude,
        destLon: nanded.longitude,
        currentLat: latur.latitude + (nanded.latitude - latur.latitude) * 0.80,
        currentLon: latur.longitude + (nanded.longitude - latur.longitude) * 0.80,
        progress: 0.80,
        speedKmH: 46.0,
        animalHeadCount: 17,
        species: 'Deoni Cattle',
        biosecurityStatus: 'screening_required',
        hazardLevel: SeverityLevel.medium,
        driverContact: '+91 94033 11827',
        dispatchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
