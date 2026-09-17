import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum CardSeverity { none, low, medium, warning, high, critical }

/// BioHerdCard
/// Core container card matching DESIGN.md specifications.
/// Includes Level-1 soft elevation, 12dp radius, severity left border tinting, and tactile ripple effect.
class BioHerdCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final CardSeverity severity;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BoxBorder? border;
  final double? elevation;

  const BioHerdCard({
    super.key,
    required this.child,
    this.onTap,
    this.severity = CardSeverity.none,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.backgroundColor,
    this.border,
    this.elevation,
  });

  Color? get _severityBorderColor {
    switch (severity) {
      case CardSeverity.low:
        return AppColors.success600;
      case CardSeverity.medium:
        return AppColors.warning600;
      case CardSeverity.warning:
        return AppColors.warning600;
      case CardSeverity.high:
      case CardSeverity.critical:
        return AppColors.danger600;
      case CardSeverity.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _severityBorderColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.white),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: border ??
            Border.all(
              color: isDark ? AppColors.neutral700 : AppColors.neutral100,
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 12),
            blurRadius: elevation != null ? elevation! * 2 : 6,
            offset: Offset(0, elevation != null ? elevation! / 2 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (borderColor != null)
                Container(
                  width: 4.5,
                  color: borderColor,
                ),
              Expanded(
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          splashColor: AppColors.primary50,
          highlightColor: Colors.transparent,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
