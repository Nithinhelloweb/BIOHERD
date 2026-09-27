import 'dart:math' as math;
import '../models/eco_climate_model.dart';
import '../models/surveillance_model.dart';
import '../../../../core/widgets/severity_badge.dart';

enum PredictionHorizon {
  now,
  day7,
  day14,
  day30,
}

extension PredictionHorizonExtension on PredictionHorizon {
  String get label {
    switch (this) {
      case PredictionHorizon.now:
        return 'NOW (T-0)';
      case PredictionHorizon.day7:
        return '+7 DAYS';
      case PredictionHorizon.day14:
        return '+14 DAYS';
      case PredictionHorizon.day30:
        return '+30 DAYS';
    }
  }

  int get days {
    switch (this) {
      case PredictionHorizon.now:
        return 0;
      case PredictionHorizon.day7:
        return 7;
      case PredictionHorizon.day14:
        return 14;
      case PredictionHorizon.day30:
        return 30;
    }
  }
}

class PolicyIntervention {
  final bool mandiMoratoriumActive;
  final bool ringVaccinationActive;
  final bool borderCheckpointsActive;
  final bool vectorFoggingActive;

  const PolicyIntervention({
    this.mandiMoratoriumActive = false,
    this.ringVaccinationActive = false,
    this.borderCheckpointsActive = false,
    this.vectorFoggingActive = false,
  });

  PolicyIntervention copyWith({
    bool? mandiMoratoriumActive,
    bool? ringVaccinationActive,
    bool? borderCheckpointsActive,
    bool? vectorFoggingActive,
  }) {
    return PolicyIntervention(
      mandiMoratoriumActive: mandiMoratoriumActive ?? this.mandiMoratoriumActive,
      ringVaccinationActive: ringVaccinationActive ?? this.ringVaccinationActive,
      borderCheckpointsActive: borderCheckpointsActive ?? this.borderCheckpointsActive,
      vectorFoggingActive: vectorFoggingActive ?? this.vectorFoggingActive,
    );
  }

  int get activePolicyCount {
    int c = 0;
    if (mandiMoratoriumActive) c++;
    if (ringVaccinationActive) c++;
    if (borderCheckpointsActive) c++;
    if (vectorFoggingActive) c++;
    return c;
  }
}

class DistrictForecastResult {
  final String districtId;
  final String districtName;
  final int baselineCases;
  final int projectedCases;
  final double baselineR0;
  final double projectedR0;
  final double projectedRiskScore;
  final double projectedContainmentRadiusKm;
  final Map<String, double> spilloverProbabilities;
  final double downwindPlumeAngleDeg;
  final double downwindPlumeDistanceKm;
  final bool isNewOutbreakProjected;
  final SeverityLevel projectedSeverity;

  const DistrictForecastResult({
    required this.districtId,
    required this.districtName,
    required this.baselineCases,
    required this.projectedCases,
    required this.baselineR0,
    required this.projectedR0,
    required this.projectedRiskScore,
    required this.projectedContainmentRadiusKm,
    required this.spilloverProbabilities,
    required this.downwindPlumeAngleDeg,
    required this.downwindPlumeDistanceKm,
    required this.isNewOutbreakProjected,
    required this.projectedSeverity,
  });
}

class StatewideEpizooticForecast {
  final PredictionHorizon horizon;
  final int totalCurrentCases;
  final int totalProjectedCases;
  final int projectedEpicentersCount;
  final int estimatedLivestockAtRisk;
  final PolicyIntervention activeInterventions;
  final Map<String, DistrictForecastResult> districtForecasts;
  final String sitRepBriefing;
  final String sitRepBriefingMr;

  const StatewideEpizooticForecast({
    required this.horizon,
    required this.totalCurrentCases,
    required this.totalProjectedCases,
    required this.projectedEpicentersCount,
    required this.estimatedLivestockAtRisk,
    required this.activeInterventions,
    required this.districtForecasts,
    required this.sitRepBriefing,
    required this.sitRepBriefingMr,
  });
}

/// Core Spatio-Temporal Mathematical Epizootic Prediction Engine
class EpizooticPredictionService {
  /// Primary forecast computation using SEIR network diffusion + microclimate vector indices
  static StatewideEpizooticForecast computeForecast({
    required List<DistrictRiskModel> districts,
    required List<OutbreakClusterModel> clusters,
    required PredictionHorizon horizon,
    required PolicyIntervention policies,
  }) {
    final days = horizon.days;
    final Map<String, DistrictForecastResult> results = {};
    int totalCurrent = 0;
    int totalProjected = 0;
    int epicenters = 0;

    // Highway connectivity graph (transit trade volume)
    final transitConnections = {
      'Solapur': {'Osmanabad': 0.85, 'Pune': 0.40, 'Ahmednagar': 0.35},
      'Osmanabad': {'Latur': 0.82, 'Solapur': 0.70, 'Beed': 0.45},
      'Kolhapur': {'Sangli': 0.75, 'Satara': 0.50, 'Pune': 0.30},
      'Ahmednagar': {'Pune': 0.60, 'Nashik': 0.55, 'Aurangabad': 0.40},
      'Pune': {'Satara': 0.45, 'Ahmednagar': 0.50, 'Solapur': 0.35},
      'Nashik': {'Dhule': 0.50, 'Jalgaon': 0.45, 'Ahmednagar': 0.40},
      'Latur': {'Nanded': 0.65, 'Osmanabad': 0.75, 'Parbhani': 0.40},
    };

    for (final d in districts) {
      totalCurrent += d.activeCases;
      final eco = DistrictEcoClimateModel.getProfileForDistrict(d.districtName);
      final hasActiveCluster = clusters.any((c) =>
          c.districtId == d.districtId ||
          c.districtName.toLowerCase() == d.districtName.toLowerCase());

      // Base immunity estimate
      double immunity = d.severity == SeverityLevel.critical ? 0.42 : 0.68;
      if (policies.ringVaccinationActive) {
        immunity = math.min(0.92, immunity + 0.25);
      }

      // Base transmission rate
      double r0 = d.r0Estimate * eco.microclimateContagionMultiplier;

      // Policy damping factors
      if (policies.mandiMoratoriumActive) r0 *= 0.68;
      if (policies.ringVaccinationActive) r0 *= 0.58;
      if (policies.borderCheckpointsActive) r0 *= 0.82;
      if (policies.vectorFoggingActive) r0 *= 0.75;

      final netRt = math.max(0.55, r0 * (1.0 - immunity * 0.7));

      // SEIR exponential growth / decay projection over days
      int projectedCases = d.activeCases;
      if (days > 0) {
        if (d.activeCases > 0) {
          final growthFactor = math.exp((netRt - 1.0) * (days / 6.5));
          projectedCases = (d.activeCases * growthFactor).round().clamp(1, 4800);
        } else {
          // Check spillover from infected neighbors
          double spilloverRisk = 0.0;
          for (final c in clusters) {
            final neighbors = transitConnections[c.districtName] ?? {};
            if (neighbors.containsKey(d.districtName)) {
              spilloverRisk += (neighbors[d.districtName]! * (c.r0Estimate / 2.0));
            }
          }
          if (policies.borderCheckpointsActive) spilloverRisk *= 0.20;
          if (policies.mandiMoratoriumActive) spilloverRisk *= 0.35;

          if (spilloverRisk > 0.45 && days >= 7) {
            projectedCases = (spilloverRisk * (days == 7 ? 14 : (days == 14 ? 38 : 95))).round();
          }
        }
      }

      totalProjected += projectedCases;

      // Projected risk score & severity
      double projectedRisk = d.riskScore;
      if (days > 0) {
        final ratio = d.activeCases > 0 ? (projectedCases / d.activeCases) : (projectedCases > 0 ? 2.0 : 0.8);
        projectedRisk = (d.riskScore * ratio).clamp(5.0, 99.0);
      }

      SeverityLevel projSeverity;
      if (projectedRisk >= 80.0 || projectedCases >= 100) {
        projSeverity = SeverityLevel.critical;
        epicenters++;
      } else if (projectedRisk >= 55.0 || projectedCases >= 40) {
        projSeverity = SeverityLevel.high;
      } else if (projectedRisk >= 30.0 || projectedCases >= 10) {
        projSeverity = SeverityLevel.medium;
      } else {
        projSeverity = SeverityLevel.low;
      }

      // Projected containment radius
      double projRadius = hasActiveCluster ? 5.0 : 0.0;
      if (hasActiveCluster) {
        if (days == 7) projRadius = policies.ringVaccinationActive ? 6.0 : 8.5;
        if (days == 14) projRadius = policies.ringVaccinationActive ? 7.0 : 13.0;
        if (days == 30) projRadius = policies.ringVaccinationActive ? 8.5 : 22.0;
      }

      // Neighbor spillover probabilities
      final Map<String, double> spillovers = {};
      final myNeighbors = transitConnections[d.districtName] ?? {};
      for (final n in myNeighbors.entries) {
        double p = n.value * (netRt / 2.5);
        if (policies.mandiMoratoriumActive) p *= 0.35;
        if (policies.borderCheckpointsActive) p *= 0.20;
        spillovers[n.key] = double.parse(p.clamp(0.05, 0.96).toStringAsFixed(2));
      }

      // Downwind aerosol dispersion reach (km)
      final plumeDist = (eco.windSpeedKmH * (days == 0 ? 0.8 : (days == 7 ? 1.8 : 2.5))).clamp(8.0, 48.0);

      results[d.districtId] = DistrictForecastResult(
        districtId: d.districtId,
        districtName: d.districtName,
        baselineCases: d.activeCases,
        projectedCases: projectedCases,
        baselineR0: d.r0Estimate,
        projectedR0: double.parse(netRt.toStringAsFixed(2)),
        projectedRiskScore: double.parse(projectedRisk.toStringAsFixed(1)),
        projectedContainmentRadiusKm: projRadius,
        spilloverProbabilities: spillovers,
        downwindPlumeAngleDeg: eco.windBearingDeg,
        downwindPlumeDistanceKm: plumeDist,
        isNewOutbreakProjected: d.activeCases == 0 && projectedCases > 0,
        projectedSeverity: projSeverity,
      );
    }

    final atRiskPopulation = (totalProjected * 18).clamp(totalCurrent * 8, 850000);

    // Natural Language Situation Briefing Generator (SitRep)
    String sitRep;
    String sitRepMr;

    if (days == 0) {
      sitRep = 'ACTIVE SITUATION [T-0]: 2 active epicenters in Solapur & Osmanabad. Statewide active cases: $totalCurrent across 36 monitored districts.';
      sitRepMr = 'सक्रिय परिस्थिती [T-0]: सोलापूर आणि उस्मानाबादमध्ये २ सक्रिय केंद्रे. ३६ जिल्ह्यांमध्ये एकूण $totalCurrent सक्रिय प्रकरणे.';
    } else {
      final delta = totalProjected - totalCurrent;
      final sign = delta >= 0 ? '+' : '';
      if (policies.activePolicyCount > 0) {
        sitRep = 'PROJECTION [+$days DAYS WITH ${policies.activePolicyCount} INTERVENTIONS]: Contagion velocity suppressed by ${(policies.activePolicyCount * 22)}%. Projected statewide cases: $totalProjected ($sign$delta).';
        sitRepMr = 'अंदाज [+$days दिवस - ${policies.activePolicyCount} उपायांसह]: प्रादुर्भावाचा वेग ${(policies.activePolicyCount * 22)}% कमी झाला आहे. अंदाजित प्रकरणे: $totalProjected ($sign$delta).';
      } else {
        sitRep = 'UNCONTROLLED PROJECTION [+$days DAYS]: High probability of spillover into Osmanabad & Latur along NH-52. Projected statewide cases: $totalProjected ($sign$delta). Immediate 5km ring vaccination recommended.';
        sitRepMr = 'अनियंत्रित अंदाज [+$days दिवस]: NH-52 महामार्गालगत उस्मानाबाद आणि लातूरमध्ये रोगाचा प्रसार होण्याची दाट शक्यता. अंदाजित प्रकरणे: $totalProjected ($sign$delta). त्वरित लसीकरण आवश्यक.';
      }
    }

    return StatewideEpizooticForecast(
      horizon: horizon,
      totalCurrentCases: totalCurrent,
      totalProjectedCases: totalProjected,
      projectedEpicentersCount: math.max(epicenters, 1),
      estimatedLivestockAtRisk: atRiskPopulation,
      activeInterventions: policies,
      districtForecasts: results,
      sitRepBriefing: sitRep,
      sitRepBriefingMr: sitRepMr,
    );
  }
}
