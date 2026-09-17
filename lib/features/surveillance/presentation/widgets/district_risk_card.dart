import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import '../../models/surveillance_model.dart';

class DistrictRiskCard extends StatelessWidget {
  final DistrictRiskModel district;
  final bool isSelected;
  final VoidCallback? onTap;

  const DistrictRiskCard({
    super.key,
    required this.district,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r0Color = district.r0Estimate >= 1.5
        ? AppColors.alertRed
        : district.r0Estimate >= 1.0
            ? AppColors.alertAmber
            : AppColors.primaryGreen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.primaryGreen.withValues(alpha: 0.08))
            : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryGreen
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: District Name & Severity Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            district.districtName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (district.districtNameMr.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${district.districtNameMr})',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SeverityBadge(severity: district.severity),
                  ],
                ),
                const SizedBox(height: 10),
                // Middle Row: Primary Disease & Risk Index Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.virus, size: 12, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            district.primaryDisease,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Risk Index: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${district.riskScore.toStringAsFixed(1)}/100',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: r0Color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Bottom Metrics: Active Cases, R0 Meter, Weather Vector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Active cases
                    Row(
                      children: [
                        Icon(PhosphorIconsRegular.warningCircle, size: 14, color: AppColors.alertAmber),
                        const SizedBox(width: 4),
                        Text(
                          '${district.activeCases} Active Cases',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    // R0 Transmission
                    Row(
                      children: [
                        const Text(
                          'R₀: ',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: r0Color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            district.r0Estimate.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: r0Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          district.r0Estimate >= 1.0 ? 'Accelerating' : 'Stable',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Weather Risk
                    Row(
                      children: [
                        Icon(PhosphorIconsRegular.cloudRain, size: 13, color: Colors.blue[400]),
                        const SizedBox(width: 3),
                        Text(
                          '${district.weatherFactor}x Vector',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
