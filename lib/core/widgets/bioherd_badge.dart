import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum BioHerdBadgeVariant {
  success,
  info,
  warning,
  critical,
  neutral,
}

class BioHerdBadge extends StatelessWidget {
  final String label;
  final BioHerdBadgeVariant variant;
  final Widget? icon;

  const BioHerdBadge({
    super.key,
    required this.label,
    this.variant = BioHerdBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case BioHerdBadgeVariant.success:
        bg = AppColors.success100;
        fg = AppColors.success600;
        break;
      case BioHerdBadgeVariant.info:
        bg = AppColors.info100;
        fg = AppColors.info600;
        break;
      case BioHerdBadgeVariant.warning:
        bg = AppColors.warning100;
        fg = AppColors.warning600;
        break;
      case BioHerdBadgeVariant.critical:
        bg = AppColors.danger100;
        fg = AppColors.danger600;
        break;
      case BioHerdBadgeVariant.neutral:
        bg = AppColors.neutral100;
        fg = AppColors.neutral700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.label(color: fg).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
