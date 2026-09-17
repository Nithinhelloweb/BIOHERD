import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// BioHerdInputField
/// Form text input component matching DESIGN.md specifications.
/// Includes floating label, rounded borders, optional voice input button, and live validation error display.
class BioHerdInputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool enableVoiceInput;
  final VoidCallback? onVoiceInputTap;
  final Widget? prefixIcon;
  final String? semanticLabel;

  const BioHerdInputField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.enableVoiceInput = false,
    this.onVoiceInputTap,
    this.prefixIcon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      liveRegion: hasError, // Announce validation errors to screen reader per Hallmark
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: isPassword,
            keyboardType: keyboardType,
            maxLines: isPassword ? 1 : maxLines,
            maxLength: maxLength,
            style: AppTextStyles.body(),
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: hintText,
              prefixIcon: prefixIcon,
              suffixIcon: enableVoiceInput
                  ? IconButton(
                      icon: const Icon(
                        PhosphorIconsRegular.microphone,
                        color: AppColors.primary600,
                        size: 22,
                      ),
                      tooltip: 'Voice Input (बोलून सांगा)',
                      onPressed: onVoiceInputTap,
                    )
                  : null,
              filled: true,
              fillColor: AppColors.neutral100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: 14.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.neutral300, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: hasError ? AppColors.danger600 : AppColors.neutral300,
                  width: hasError ? 2.0 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: hasError ? AppColors.danger600 : AppColors.primary500,
                  width: 2.0,
                ),
              ),
            ),
          ),
          if (hasError) ...[
            AppSpacing.vSpace4,
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.space12),
              child: Text(
                errorText!,
                style: AppTextStyles.bodySmall(color: AppColors.danger600),
              ),
            ),
          ] else if (helperText != null) ...[
            AppSpacing.vSpace4,
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.space12),
              child: Text(
                helperText!,
                style: AppTextStyles.caption(color: AppColors.neutral500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
