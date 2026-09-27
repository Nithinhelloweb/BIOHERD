import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/severity_badge.dart';
import '../../models/surveillance_model.dart';
import 'containment_cordon_config_dialog.dart';
import 'quarantine_protocols_dialog.dart';

/// Tactical C4I District Dossier Modal
/// Displays comprehensive epidemiological telemetry, cold-chain readiness,
/// livestock demographics, and instant 1-click bio-containment command actions.
class DistrictTacticalDossierDialog extends StatefulWidget {
  final DistrictRiskModel district;
  final OutbreakClusterModel? associatedCluster;

  const DistrictTacticalDossierDialog({
    super.key,
    required this.district,
    this.associatedCluster,
  });

  static void show(
    BuildContext context,
    DistrictRiskModel district, {
    OutbreakClusterModel? associatedCluster,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DistrictTacticalDossierDialog(
        district: district,
        associatedCluster: associatedCluster,
      ),
    );
  }

  @override
  State<DistrictTacticalDossierDialog> createState() =>
      _DistrictTacticalDossierDialogState();
}

class _DistrictTacticalDossierDialogState
    extends State<DistrictTacticalDossierDialog> {
  bool _isRequisitionDispatched = false;
  bool _isMandiMoratoriumActive = false;
  bool _isAdvisoryBroadcasted = false;

  String _getDistrictRtoCode(String districtName) {
    final name = districtName.toLowerCase().trim();
    if (name.contains('solapur')) return 'MH-13';
    if (name.contains('osmanabad') || name.contains('dharashiv')) return 'MH-25';
    if (name.contains('pune')) return 'MH-12';
    if (name.contains('nashik')) return 'MH-15';
    if (name.contains('kolhapur')) return 'MH-09';
    if (name.contains('latur')) return 'MH-24';
    if (name.contains('ahmednagar')) return 'MH-16';
    if (name.contains('satara')) return 'MH-11';
    if (name.contains('sangli')) return 'MH-10';
    if (name.contains('nagpur')) return 'MH-31';
    if (name.contains('amravati')) return 'MH-27';
    if (name.contains('aurangabad') || name.contains('chhatrapati')) return 'MH-20';
    if (name.contains('jalna')) return 'MH-21';
    if (name.contains('beed')) return 'MH-23';
    if (name.contains('nanded')) return 'MH-26';
    if (name.contains('parbhani')) return 'MH-22';
    if (name.contains('buldhana')) return 'MH-28';
    if (name.contains('akola')) return 'MH-30';
    if (name.contains('washim')) return 'MH-37';
    if (name.contains('yavatmal')) return 'MH-29';
    if (name.contains('wardha')) return 'MH-32';
    if (name.contains('chandrapur')) return 'MH-34';
    if (name.contains('gadchiroli')) return 'MH-33';
    if (name.contains('bhandara')) return 'MH-36';
    if (name.contains('gondia')) return 'MH-35';
    if (name.contains('dhule')) return 'MH-18';
    if (name.contains('jalgaon')) return 'MH-19';
    if (name.contains('nandurbar')) return 'MH-39';
    if (name.contains('raigad')) return 'MH-06';
    if (name.contains('ratnagiri')) return 'MH-08';
    if (name.contains('sindhudurg')) return 'MH-07';
    if (name.contains('thane')) return 'MH-04';
    if (name.contains('palghar')) return 'MH-48';
    return 'MH-AHD';
  }

  int _calculateAvailableVaccines(DistrictRiskModel d) {
    final base = (d.livestockPopulation * 0.05).round();
    return (base - (d.activeCases * 12)).clamp(850, 45000);
  }

  double _calculateVaccinationCoverage(DistrictRiskModel d) {
    if (d.severity == SeverityLevel.critical) return 0.42;
    if (d.severity == SeverityLevel.high) return 0.58;
    if (d.severity == SeverityLevel.medium) return 0.73;
    return 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.district;
    final rtoCode = _getDistrictRtoCode(d.districtName);
    final coverage = _calculateVaccinationCoverage(d);
    final vaccinesAvailable = _calculateAvailableVaccines(d);

    final r0Color = d.r0Estimate >= 1.5
        ? AppColors.alertRed
        : d.r0Estimate >= 1.0
            ? AppColors.alertAmber
            : AppColors.primaryGreen;

    final threatColor = d.severity == SeverityLevel.critical
        ? AppColors.alertRed
        : d.severity == SeverityLevel.high
            ? AppColors.alertAmber
            : d.severity == SeverityLevel.medium
                ? Colors.blue
                : AppColors.primaryGreen;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: threatColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: threatColor.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content Scroll Area
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: District Badge, Names, Severity
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: threatColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: threatColor, width: 1.2),
                        ),
                        child: Text(
                          rtoCode,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: threatColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.districtName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (d.districtNameMr.isNotEmpty)
                              Text(
                                d.districtNameMr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Tactical Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: threatColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: threatColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsFill.shieldWarning,
                            size: 20, color: threatColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d.severity.name.toUpperCase()} THREAT — ${d.primaryDisease.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: threatColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Risk Score: ${(d.riskScore * 100).toInt()}/100 • Case Density: ${d.caseDensityPer10k.toStringAsFixed(1)} per 10k heads',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SeverityBadge(severity: d.severity),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Core Metrics 4-Grid
                  const Text(
                    'EPIDEMIOLOGICAL TELEMETRY',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: PhosphorIconsRegular.warningCircle,
                          label: 'Active Cases',
                          value: '${d.activeCases}',
                          subtext: 'Confirmed Clinical',
                          color: AppColors.alertRed,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: PhosphorIconsRegular.chartLineUp,
                          label: 'R0 Estimate',
                          value: d.r0Estimate.toStringAsFixed(2),
                          subtext: d.r0Estimate >= 1.2
                              ? 'Fast Transmission'
                              : 'Controlled',
                          color: r0Color,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: PhosphorIconsRegular.cow,
                          label: 'Total Cattle Census',
                          value: _formatNumber(d.livestockPopulation),
                          subtext: 'Monitored Herd',
                          color: Colors.blueAccent,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: PhosphorIconsRegular.cloudRain,
                          label: 'Vector Eco-Factor',
                          value: '${d.weatherFactor.toStringAsFixed(2)}x',
                          subtext: 'LST & Rainfall Multiplier',
                          color: AppColors.alertAmber,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Herd Vaccination Defense Shield
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'VACCINATION DEFENSE SHIELD',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${(coverage * 100).toInt()}% Immunized',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: coverage >= 0.75
                              ? AppColors.primaryGreen
                              : AppColors.alertAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: coverage,
                      minHeight: 10,
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        coverage >= 0.75
                            ? AppColors.primaryGreen
                            : (coverage >= 0.50
                                ? AppColors.alertAmber
                                : AppColors.alertRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Protected: ${_formatNumber((d.livestockPopulation * coverage).toInt())}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      Text(
                        'Susceptible Deficit: ${_formatNumber((d.livestockPopulation * (1.0 - coverage)).toInt())}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.alertRed,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // DVC Veterinary Logistics & Cold Chain
                  const Text(
                    'DISTRICT VET LOGISTICS & COLD STORAGE',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildLogisticsRow(
                          icon: PhosphorIconsFill.syringe,
                          label: 'Homologous Vaccine Stock',
                          value: '${_formatNumber(vaccinesAvailable)} doses',
                          status: vaccinesAvailable > 5000
                              ? 'Cold-Chain Secure'
                              : 'Replenishment Needed',
                          statusColor: vaccinesAvailable > 5000
                              ? AppColors.primaryGreen
                              : AppColors.alertAmber,
                          isDark: isDark,
                        ),
                        const Divider(height: 14),
                        _buildLogisticsRow(
                          icon: PhosphorIconsFill.thermometer,
                          label: 'Cold-Chain Temperature',
                          value: '4.2°C (Nominal)',
                          status: 'ILR Verified',
                          statusColor: AppColors.primaryGreen,
                          isDark: isDark,
                        ),
                        const Divider(height: 14),
                        _buildLogisticsRow(
                          icon: PhosphorIconsFill.truck,
                          label: 'Mobile Veterinary Units (MVUs)',
                          value: '3 Units Deployed',
                          status: 'Live Patrol Active',
                          statusColor: Colors.blueAccent,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // C4I Tactical Operations Command Action Grid
                  const Text(
                    'C4I TACTICAL INTERVENTION COMMANDS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Action 1: Dynamic 1km / 3km / 10km Ring Cordon
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alertRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: const Icon(PhosphorIconsFill.shieldPlus, size: 20),
                      label: const Text(
                        'Activate 1km/3km/10km Ring Containment Cordon',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ContainmentCordonConfigDialog.show(
                          context,
                          district: d,
                          cluster: widget.associatedCluster,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action 2 & 3: Vaccine Dispatch & Advisory Broadcast
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: _isRequisitionDispatched
                                  ? AppColors.primaryGreen
                                  : (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[400]!),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(
                            _isRequisitionDispatched
                                ? PhosphorIconsFill.checkCircle
                                : PhosphorIconsRegular.truck,
                            size: 16,
                            color: _isRequisitionDispatched
                                ? AppColors.primaryGreen
                                : null,
                          ),
                          label: Text(
                            _isRequisitionDispatched
                                ? 'Stock Dispatched'
                                : 'Vaccine Dispatch',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isRequisitionDispatched
                                  ? AppColors.primaryGreen
                                  : null,
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isRequisitionDispatched = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Emergency Cold-Chain Requisition of 10,000 ${d.primaryDisease} vaccine vials dispatched to DVC ${d.districtName}.',
                                ),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: _isAdvisoryBroadcasted
                                  ? AppColors.primaryGreen
                                  : (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[400]!),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(
                            _isAdvisoryBroadcasted
                                ? PhosphorIconsFill.broadcast
                                : PhosphorIconsRegular.megaphone,
                            size: 16,
                            color: _isAdvisoryBroadcasted
                                ? AppColors.primaryGreen
                                : null,
                          ),
                          label: Text(
                            _isAdvisoryBroadcasted
                                ? 'Broadcast Sent'
                                : 'Farmer Alert',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isAdvisoryBroadcasted
                                  ? AppColors.primaryGreen
                                  : null,
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isAdvisoryBroadcasted = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Hyper-local Marathi & Hindi bio-alert transmitted via SMS/IVR to ${_formatNumber(d.livestockPopulation ~/ 4)} registered farmers in ${d.districtName}.',
                                ),
                                backgroundColor: Colors.blueAccent,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Action 4: Mandi Moratorium & Protocol Dialog
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: _isMandiMoratoriumActive
                                  ? AppColors.alertRed
                                  : (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[400]!),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(
                            PhosphorIconsFill.prohibit,
                            size: 16,
                            color: _isMandiMoratoriumActive
                                ? AppColors.alertRed
                                : null,
                          ),
                          label: Text(
                            _isMandiMoratoriumActive
                                ? 'Mandi Moratorium Active'
                                : 'Mandi Moratorium',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isMandiMoratoriumActive
                                  ? AppColors.alertRed
                                  : null,
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isMandiMoratoriumActive =
                                !_isMandiMoratoriumActive);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isMandiMoratoriumActive
                                      ? 'Moratorium Order Enacted: All cattle fairs & APMC livestock trading in ${d.districtName} prohibited.'
                                      : 'Mandi Moratorium in ${d.districtName} lifted.',
                                ),
                                backgroundColor: _isMandiMoratoriumActive
                                    ? AppColors.alertRed
                                    : AppColors.alertAmber,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'View Official Protocols',
                        icon: const Icon(PhosphorIconsRegular.bookOpen, size: 18),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => const QuarantineProtocolsDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsRow({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: statusColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
