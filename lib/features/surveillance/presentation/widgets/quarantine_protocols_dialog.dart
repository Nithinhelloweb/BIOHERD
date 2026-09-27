import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';

class QuarantineProtocolsDialog extends StatelessWidget {
  const QuarantineProtocolsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.shieldWarning,
                      color: AppColors.alertRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GOVT. OF MAHARASHTRA • ANIMAL HUSBANDRY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quarantine & Biosecurity Directives',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.alertAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(PhosphorIconsFill.warningCircle, size: 16, color: AppColors.alertAmber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Orders Issued Under the Epidemic Diseases Act',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Protocol List
              Expanded(
                child: ListView(
                  children: [
                    _buildProtocolItem(
                      number: '1',
                      titleMr: 'Complete 5km Livestock Movement Ban',
                      titleEn: 'Complete 5km Livestock Movement Ban',
                      descMr: 'Zero animal transit into or out of the containment zone.',
                      descEn: 'Zero animal transit into or out of the containment zone.',
                      icon: PhosphorIconsRegular.prohibit,
                      color: AppColors.alertRed,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '2',
                      titleMr: 'Mandatory Strict Isolation',
                      titleEn: 'Mandatory Strict Isolation',
                      descMr: 'Isolate symptomatic animals immediately in a separate dry shelter.',
                      descEn: 'Isolate symptomatic animals immediately in a separate dry shelter.',
                      icon: PhosphorIconsRegular.arrowsSplit,
                      color: AppColors.alertAmber,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '3',
                      titleMr: 'Daily Disinfection Protocol',
                      titleEn: 'Daily Disinfection Protocol',
                      descMr: 'Wash stall floors and mangers with 4% sodium carbonate solution.',
                      descEn: 'Wash stall floors and mangers with 4% sodium carbonate solution.',
                      icon: PhosphorIconsRegular.sparkle,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '4',
                      titleMr: 'Emergency Ring Vaccination',
                      titleEn: 'Emergency Ring Vaccination',
                      descMr: 'Mandatory ring vaccination of all healthy animals within the 10km buffer.',
                      descEn: 'Mandatory ring vaccination of all healthy animals within the 10km buffer.',
                      icon: PhosphorIconsRegular.syringe,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '5',
                      titleMr: 'Milk & Water Biosecurity',
                      titleEn: 'Milk & Water Biosecurity',
                      descMr: 'Do not sell or mix milk from infected animals. Boil before consumption.',
                      descEn: 'Do not sell or mix milk from infected animals. Boil before consumption.',
                      icon: PhosphorIconsRegular.drop,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '6',
                      titleMr: 'Daily Reporting to 1962 Toll-Free',
                      titleEn: 'Daily Reporting to 1962 Toll-Free',
                      descMr: 'Report any fresh fever, blisters, or casualties to the 1962 district desk.',
                      descEn: 'Report any fresh fever, blisters, or casualties to the 1962 district desk.',
                      icon: PhosphorIconsRegular.phoneCall,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Acknowledged', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolItem({
    required String number,
    required String titleMr,
    required String titleEn,
    required String descMr,
    required String descEn,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.grey[750]! : Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $titleEn',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  descEn,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
