import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum BioHerdButtonVariant { primary, secondary, danger }

/// BioHerdButton
/// Standard interactive action button conforming to DESIGN.md and Hallmark 8-state accessibility.
/// Minimum tap target: 48dp height.
class BioHerdButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BioHerdButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final String? semanticLabel;

  BioHerdButton({
    super.key,
    String? label,
    String? text,
    required this.onPressed,
    this.variant = BioHerdButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    dynamic icon,
    this.semanticLabel,
  })  : label = label ?? text ?? '',
        icon = icon is IconData ? Icon(icon, size: 20) : (icon as Widget?);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case BioHerdButtonVariant.primary:
        backgroundColor = AppColors.primary600;
        foregroundColor = Colors.white;
        break;
      case BioHerdButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary600;
        borderSide = const BorderSide(color: AppColors.primary600, width: 1.5);
        break;
      case BioHerdButtonVariant.danger:
        backgroundColor = AppColors.danger600;
        foregroundColor = Colors.white;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          AppSpacing.hSpace8,
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.label(color: foregroundColor).copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.label(color: foregroundColor).copyWith(fontSize: 15),
      );
    }

    final buttonWidget = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.4 : 1.0,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          splashColor: variant == BioHerdButtonVariant.secondary
              ? AppColors.primary50
              : Colors.white.withAlpha(40),
          highlightColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48.0),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: semanticLabel ?? label,
      child: isFullWidth ? SizedBox(width: double.infinity, child: buttonWidget) : buttonWidget,
    );
  }
}
