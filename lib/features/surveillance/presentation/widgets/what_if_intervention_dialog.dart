import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/surveillance_model.dart';
import '../../services/epizootic_prediction_service.dart';

/// "What-If" Epizootic Policy Intervention & Scenario Simulator Modal
/// Allows epidemiologists and state administrators to simulate the impact
/// of quarantine cordons, mandi closures, and ring vaccination on contagion curves.
class WhatIfInterventionDialog extends StatefulWidget {
  final List<DistrictRiskModel> districts;
  final List<OutbreakClusterModel> clusters;
  final PredictionHorizon initialHorizon;
  final PolicyIntervention initialPolicies;
  final void Function(PredictionHorizon horizon, PolicyIntervention policies) onApplyPolicies;

  const WhatIfInterventionDialog({
    super.key,
    required this.districts,
    required this.clusters,
    this.initialHorizon = PredictionHorizon.day14,
    this.initialPolicies = const PolicyIntervention(),
    required this.onApplyPolicies,
  });

  static void show(
    BuildContext context, {
    required List<DistrictRiskModel> districts,
    required List<OutbreakClusterModel> clusters,
    PredictionHorizon initialHorizon = PredictionHorizon.day14,
    PolicyIntervention initialPolicies = const PolicyIntervention(),
    required void Function(PredictionHorizon horizon, PolicyIntervention policies) onApplyPolicies,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => WhatIfInterventionDialog(
        districts: districts,
        clusters: clusters,
        initialHorizon: initialHorizon,
        initialPolicies: initialPolicies,
        onApplyPolicies: onApplyPolicies,
      ),
    );
  }

  @override
  State<WhatIfInterventionDialog> createState() => _WhatIfInterventionDialogState();
}

class _WhatIfInterventionDialogState extends State<WhatIfInterventionDialog> {
  late PredictionHorizon _selectedHorizon;
  late bool _mandiMoratorium;
  late bool _ringVaccination;
  late bool _borderCheckpoints;
  late bool _vectorFogging;

  @override
  void initState() {
    super.initState();
    _selectedHorizon = widget.initialHorizon == PredictionHorizon.now ? PredictionHorizon.day14 : widget.initialHorizon;
    _mandiMoratorium = widget.initialPolicies.mandiMoratoriumActive;
    _ringVaccination = widget.initialPolicies.ringVaccinationActive;
    _borderCheckpoints = widget.initialPolicies.borderCheckpointsActive;
    _vectorFogging = widget.initialPolicies.vectorFoggingActive;
  }

  PolicyIntervention get _currentPolicies => PolicyIntervention(
        mandiMoratoriumActive: _mandiMoratorium,
        ringVaccinationActive: _ringVaccination,
        borderCheckpointsActive: _borderCheckpoints,
        vectorFoggingActive: _vectorFogging,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Run baseline uncontrolled forecast vs current policy forecast
    final uncontrolled = EpizooticPredictionService.computeForecast(
      districts: widget.districts,
      clusters: widget.clusters,
      horizon: _selectedHorizon,
      policies: const PolicyIntervention(),
    );

    final controlled = EpizooticPredictionService.computeForecast(
      districts: widget.districts,
      clusters: widget.clusters,
      horizon: _selectedHorizon,
      policies: _currentPolicies,
    );

    final casesSaved = (uncontrolled.totalProjectedCases - controlled.totalProjectedCases).clamp(0, 5000);
    final reductionPct = uncontrolled.totalProjectedCases > 0
        ? ((casesSaved / uncontrolled.totalProjectedCases) * 100).toInt()
        : 0;
    final economicSavedCrores = ((casesSaved * 45000) / 10000000).toStringAsFixed(2);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.chartLineUp,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EPIZOOTIC "WHAT-IF" POLICY SIMULATOR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        Text(
                          'Spatio-Temporal Contagion Curve Modeling across 36 Districts',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horizon Selector Tabs
                    const Text(
                      'PREDICTION HORIZON TIMELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _buildHorizonChip(PredictionHorizon.day7, '+7 Days', isDark),
                        const SizedBox(width: 8),
                        _buildHorizonChip(PredictionHorizon.day14, '+14 Days (Standard)', isDark),
                        const SizedBox(width: 8),
                        _buildHorizonChip(PredictionHorizon.day30, '+30 Days (Extended)', isDark),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Policy Intervention Toggles
                    const Text(
                      'TEST POLICY INTERVENTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),

                    _buildPolicySwitch(
                      icon: PhosphorIconsFill.prohibit,
                      title: 'Mandi Trade Moratorium',
                      subtitle: 'Halt all livestock trade in APMC cattle markets (cuts transit spread ~32%)',
                      color: AppColors.alertRed,
                      value: _mandiMoratorium,
                      onChanged: (v) => setState(() => _mandiMoratorium = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildPolicySwitch(
                      icon: PhosphorIconsFill.syringe,
                      title: 'Emergency 5km Ring Vaccination (72h Target)',
                      subtitle: 'Mandatory 100% buffer immunization (cuts effective Rt by ~42%)',
                      color: AppColors.primaryGreen,
                      value: _ringVaccination,
                      onChanged: (v) => setState(() => _ringVaccination = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildPolicySwitch(
                      icon: PhosphorIconsFill.shieldWarning,
                      title: 'Highway Police & RTO Transit Checkpoints',
                      subtitle: 'Quarantine checkpoints along NH-65, NH-52, NH-48 (cuts inter-district spillover ~80%)',
                      color: Colors.blueAccent,
                      value: _borderCheckpoints,
                      onChanged: (v) => setState(() => _borderCheckpoints = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildPolicySwitch(
                      icon: PhosphorIconsFill.fan,
                      title: 'Aerial Vector Insecticide Fogging',
                      subtitle: 'Suppression of Culicoides midges & tick populations around reservoirs (cuts vector multiplier ~25%)',
                      color: Colors.purpleAccent,
                      value: _vectorFogging,
                      onChanged: (v) => setState(() => _vectorFogging = v),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),

                    // Comparative Impact Analytics Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withValues(alpha: 0.12),
                            AppColors.primaryGreen.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PREDICTED CONTAGION IMPACT',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00E5FF),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: reductionPct > 0
                                      ? AppColors.primaryGreen
                                      : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  reductionPct > 0 ? '-$reductionPct% Contagion' : 'Baseline',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Uncontrolled vs Controlled Comparison Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildComparisonTile(
                                  label: 'Uncontrolled Spread',
                                  cases: '${uncontrolled.totalProjectedCases}',
                                  epicenters: '${uncontrolled.projectedEpicentersCount} Epicenters',
                                  color: AppColors.alertRed,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildComparisonTile(
                                  label: 'With Interventions',
                                  cases: '${controlled.totalProjectedCases}',
                                  epicenters: '${controlled.projectedEpicentersCount} Epicenters',
                                  color: AppColors.primaryGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Benefits summary banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceAround,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsFill.shieldCheck, size: 16, color: AppColors.primaryGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+$casesSaved Cattle Saved',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsFill.currencyInr, size: 16, color: Colors.amberAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹$economicSavedCrores Cr Protected',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(PhosphorIconsFill.checkCircle, size: 18),
                    label: const Text(
                      'Apply Scenario to Live Map',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      widget.onApplyPolicies(_selectedHorizon, _currentPolicies);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'What-If Scenario applied: ${_selectedHorizon.label} with ${_currentPolicies.activePolicyCount} interventions active.',
                          ),
                          backgroundColor: const Color(0xFF00E5FF),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizonChip(PredictionHorizon h, String label, bool isDark) {
    final isSelected = _selectedHorizon == h;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedHorizon = h),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E5FF)
                : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E5FF)
                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? color : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: value ? 1.5 : 1.0,
          ),
        ),
        child: Row(
        children: [
          Icon(icon, size: 20, color: value ? color : Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: value ? color : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildComparisonTile({
    required String label,
    required String cases,
    required String epicenters,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cases,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            epicenters,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
