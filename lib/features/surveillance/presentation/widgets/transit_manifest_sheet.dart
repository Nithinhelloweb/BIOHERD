import '../../models/edge_vision_model.dart';
import 'edge_vision_inspection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bioherd_button.dart';
import '../../../../core/widgets/severity_badge.dart';
import '../../models/surveillance_model.dart';

class TransitManifestSheet extends StatelessWidget {
  final LivestockTransitVehicle vehicle;
  final VoidCallback? onCleared;

  const TransitManifestSheet({
    super.key,
    required this.vehicle,
    this.onCleared,
  });

  static Future<void> show(BuildContext context, LivestockTransitVehicle vehicle, {VoidCallback? onCleared}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TransitManifestSheet(vehicle: vehicle, onCleared: onCleared),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIntercepted = vehicle.biosecurityStatus == 'containment_intercepted';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isIntercepted ? AppColors.alertRed : AppColors.primaryGreen).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsFill.truck,
                      color: isIntercepted ? AppColors.alertRed : AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.licensePlate,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        vehicle.carrierName,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              SeverityBadge(severity: vehicle.hazardLevel),
            ],
          ),
          const SizedBox(height: 16),

          // Biosecurity Status Alert
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isIntercepted ? AppColors.alertRed : AppColors.primaryGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isIntercepted ? AppColors.alertRed : AppColors.primaryGreen).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isIntercepted ? PhosphorIconsFill.shieldWarning : PhosphorIconsFill.shieldCheck,
                  color: isIntercepted ? AppColors.alertRed : AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.statusDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isIntercepted ? AppColors.alertRed : AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        isIntercepted
                          ? 'Vehicle detected inside 5km containment exclusion perimeter. Immediate veterinary screening required.'
                          : 'INAPH biometric e-tag verified. Clean health certificate logged.',
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Route & Progress
          Text('TRANSIT CORRIDOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(PhosphorIconsRegular.mapPin, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Text(vehicle.originDistrict, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1.5)),
                    Icon(PhosphorIconsRegular.arrowRight, size: 16, color: Colors.grey[500]),
                    const Expanded(child: Divider(thickness: 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(PhosphorIconsRegular.flag, size: 16, color: AppColors.alertAmber),
              const SizedBox(width: 6),
              Text(vehicle.destinationDistrict, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: vehicle.progress.clamp(0.0, 1.0),
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(isIntercepted ? AppColors.alertRed : AppColors.primaryGreen),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(vehicle.progress * 100).toInt()}% Route Traversed', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Speed: ${vehicle.speedKmH.toInt()} km/h', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),

          // Cargo & Driver Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Livestock Cargo', '${vehicle.animalHeadCount} head', vehicle.species),
                const SizedBox(height: 36, child: VerticalDivider()),
                _buildInfoColumn('Driver Contact', vehicle.driverContact, 'Authorized Carrier'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Edge Vision AI Terminal Trigger
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final checkpoints = BiosecurityCheckpoint.getPreseededCheckpoints();
                final targetCkp = checkpoints.firstWhere(
                  (c) => c.district.toLowerCase() == vehicle.originDistrict.toLowerCase() ||
                         c.district.toLowerCase() == vehicle.destinationDistrict.toLowerCase(),
                  orElse: () => checkpoints.first,
                );
                EdgeVisionInspectionDialog.show(context, checkpoint: targetCkp);
              },
              icon: const Icon(PhosphorIconsFill.videoCamera, size: 16),
              label: const Text('Inspect via Checkpoint Edge Vision (YOLOv8)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: const Color(0xFF00FFCC),
                side: const BorderSide(color: Color(0xFF00FFCC), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BioHerdButton(
                  label: isIntercepted ? 'Verify Screening & Clear' : 'Log Quarantine Inspection',
                  icon: PhosphorIconsFill.shieldCheck,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onCleared != null) onCleared!();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String val, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
