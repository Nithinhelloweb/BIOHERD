import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/surveillance_bloc.dart';
import '../../models/surveillance_model.dart';
import 'quarantine_protocols_dialog.dart';

/// Dynamic 1km / 3km / 10km Bio-Containment Cordon Configuration Tool
/// Allows state epidemiologists and LDOs to configure multi-tier ring containment zones
/// around active livestock outbreak epicenters.
class ContainmentCordonConfigDialog extends StatefulWidget {
  final DistrictRiskModel district;
  final OutbreakClusterModel? cluster;

  const ContainmentCordonConfigDialog({
    super.key,
    required this.district,
    this.cluster,
  });

  static void show(
    BuildContext context, {
    required DistrictRiskModel district,
    OutbreakClusterModel? cluster,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ContainmentCordonConfigDialog(
        district: district,
        cluster: cluster,
      ),
    );
  }

  @override
  State<ContainmentCordonConfigDialog> createState() =>
      _ContainmentCordonConfigDialogState();
}

class _ContainmentCordonConfigDialogState
    extends State<ContainmentCordonConfigDialog> {
  double _infectedRadiusKm = 1.0;
  double _surveillanceRadiusKm = 3.0;
  double _bufferRadiusKm = 10.0;
  bool _enforcePoliceCheckpoints = true;
  bool _droneAerosolPatrol = true;
  bool _mandateRingVaccination = true;
  bool _isCordonDeployed = false;

  int _calculateEnclosedFarms() {
    return ((_bufferRadiusKm * _bufferRadiusKm * 3.14159) * 0.45).round().clamp(12, 450);
  }

  int _calculateEnclosedLivestock() {
    return (_calculateEnclosedFarms() * 28).clamp(300, 18000);
  }

  @override
  void initState() {
    super.initState();
    if (widget.cluster != null) {
      _infectedRadiusKm = (widget.cluster!.containmentRadiusKm * 0.3).clamp(0.5, 3.0);
      _surveillanceRadiusKm = (widget.cluster!.containmentRadiusKm).clamp(2.0, 6.0);
      _bufferRadiusKm = (widget.cluster!.surveillanceRadiusKm).clamp(5.0, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.cluster;
    final enclosedFarms = _calculateEnclosedFarms();
    final enclosedCattle = _calculateEnclosedLivestock();
    final vaccineDosesNeeded = (enclosedCattle * 1.15).round();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.alertRed.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.alertRed.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.alertRed.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.shieldWarning,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DYNAMIC RING CONTAINMENT CORDON',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.alertRed,
                          ),
                        ),
                        Text(
                          'Epicenter:  () • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            fontWeight: FontWeight.w600,
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

            // Scrollable Config Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Banner of Enclosed Zone
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              label: 'Cordon Area',
                              value: '${(3.14 * _bufferRadiusKm * _bufferRadiusKm).toInt()} km²',
                              icon: PhosphorIconsRegular.compass,
                              color: Colors.cyanAccent,
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              label: 'Farms',
                              value: '$enclosedFarms',
                              icon: PhosphorIconsRegular.houseLine,
                              color: Colors.amberAccent,
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              label: 'Livestock',
                              value: '$enclosedCattle',
                              icon: PhosphorIconsRegular.cow,
                              color: AppColors.primaryGreen,
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              label: 'Ring Doses',
                              value: '$vaccineDosesNeeded',
                              icon: PhosphorIconsRegular.syringe,
                              color: AppColors.alertRed,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // TIER 1: INFECTED ZONE
                    _buildTierSlider(
                      title: 'TIER 1: INFECTED ZONE CORDON (0 -  KM)',
                      subtitle: 'Strict quarantine: Zero livestock egress, daily bio-security spray, animal isolation.',
                      color: AppColors.alertRed,
                      value: _infectedRadiusKm,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (val) {
                        setState(() {
                          _infectedRadiusKm = val;
                          if (_surveillanceRadiusKm <= _infectedRadiusKm) {
                            _surveillanceRadiusKm = _infectedRadiusKm + 1.5;
                          }
                          if (_bufferRadiusKm <= _surveillanceRadiusKm) {
                            _bufferRadiusKm = _surveillanceRadiusKm + 5.0;
                          }
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // TIER 2: SURVEILLANCE ZONE
                    _buildTierSlider(
                      title: 'TIER 2: SURVEILLANCE ZONE ( -  KM)',
                      subtitle: 'Daily clinical thermometry by LDOs, nasal swab PCR sampling, movement manifest inspection.',
                      color: AppColors.alertAmber,
                      value: _surveillanceRadiusKm,
                      min: _infectedRadiusKm + 0.5,
                      max: 7.0,
                      onChanged: (val) {
                        setState(() {
                          _surveillanceRadiusKm = val;
                          if (_bufferRadiusKm <= _surveillanceRadiusKm) {
                            _bufferRadiusKm = _surveillanceRadiusKm + 4.0;
                          }
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // TIER 3: PROTECTIVE BUFFER RING
                    _buildTierSlider(
                      title: 'TIER 3: VACCINATION BUFFER SHIELD ( -  KM)',
                      subtitle: 'Compulsory ring-vaccination perimeter to establish immune barrier against regional escape.',
                      color: Colors.cyanAccent,
                      value: _bufferRadiusKm,
                      min: _surveillanceRadiusKm + 2.0,
                      max: 18.0,
                      onChanged: (val) {
                        setState(() => _bufferRadiusKm = val);
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Checkbox Directives
                    const Text(
                      'INTERVENTION DIRECTIVES & PROTOCOLS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),

                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _enforcePoliceCheckpoints,
                      activeColor: AppColors.alertRed,
                      title: const Text(
                        'Inter-district Highway Checkpoints (Police & RTO Transit Moratorium)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (v) => setState(() => _enforcePoliceCheckpoints = v ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _mandateRingVaccination,
                      activeColor: AppColors.primaryGreen,
                      title: const Text(
                        '100% Compulsory Ring Vaccination in 10km Buffer Zone within 72h',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (v) => setState(() => _mandateRingVaccination = v ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _droneAerosolPatrol,
                      activeColor: Colors.cyanAccent,
                      title: const Text(
                        'Deploy Thermal Drone Aerial Patrols for Herd Movement Monitoring',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (v) => setState(() => _droneAerosolPatrol = v ?? true),
                    ),
                  ],
                ),
              ),
            ),

            // Action Footer
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
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    icon: const Icon(PhosphorIconsRegular.bookOpen, size: 16),
                    label: const Text('Directives'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const QuarantineProtocolsDialog(),
                      );
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCordonDeployed
                          ? AppColors.primaryGreen
                          : AppColors.alertRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      _isCordonDeployed
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsFill.shieldPlus,
                      size: 18,
                    ),
                    label: Text(
                      _isCordonDeployed ? 'Cordon Deployed' : 'Deploy Containment Cordon',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (c != null) {
                        context.read<SurveillanceBloc>().add(
                              DeclareQuarantineEvent(c.id),
                            );
                      }
                      setState(() => _isCordonDeployed = true);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Multi-Tier Cordon ACTIVE: 0-km Infected, -km Surveillance, -km Buffer established around .',
                          ),
                          backgroundColor: AppColors.alertRed,
                          duration: const Duration(seconds: 5),
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

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTierSlider({
    required String title,
    required String subtitle,
    required Color color,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ' km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
