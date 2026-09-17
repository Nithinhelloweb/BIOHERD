import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// AIConfidenceMeter
/// Transparent visual confidence metric indicator for AI diagnostic inferences.
/// Clearly discloses model information and includes AI-assistance disclaimers.
class AIConfidenceMeter extends StatelessWidget {
  final double confidence; // Range 0.0 to 1.0 (or 0 to 100)
  final String modelName;
  final String? disclaimerText;

  const AIConfidenceMeter({
    super.key,
    required this.confidence,
    this.modelName = 'EfficientNet-B4 + IndicBERT Ensemble',
    this.disclaimerText,
  });

  double get _normalizedConfidence {
    if (confidence > 1.0) {
      return (confidence / 100.0).clamp(0.0, 1.0);
    }
    return confidence.clamp(0.0, 1.0);
  }

  Color get _meterColor {
    final pct = _normalizedConfidence * 100.0;
    if (pct <= 40.0) return AppColors.danger600;
    if (pct <= 70.0) return AppColors.warning600;
    return AppColors.success600;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_normalizedConfidence * 100.0).toStringAsFixed(1);
    final color = _meterColor;

    return Semantics(
      label: 'AI Diagnostic Confidence: $pct percent. Model: $modelName',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  modelName,
                  style: AppTextStyles.label(color: AppColors.neutral700).copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.hSpace8,
              Text(
                '$pct%',
                style: AppTextStyles.label(color: color).copyWith(fontSize: 13),
              ),
            ],
          ),
          AppSpacing.vSpace8,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: _normalizedConfidence,
              minHeight: 8.0,
              backgroundColor: AppColors.neutral100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          AppSpacing.vSpace4,
          Text(
            disclaimerText ?? 'AI-assisted diagnosis • Final verification required by a licensed veterinarian',
            style: AppTextStyles.caption(color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}
