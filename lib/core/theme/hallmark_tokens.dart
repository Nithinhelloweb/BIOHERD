import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Hallmark Design Tokens for BIOHERD
/// Anti-slop, high-contrast, rural Maharashtra palette
class HallmarkTokens {
  HallmarkTokens._();

  // Primary rural palette
  static const Color forestMoss = AppColors.primary600;
  static const Color forestMossDark = Color(0xFF14522C);
  static const Color terracotta = AppColors.warning600;
  static const Color alertCritical = AppColors.danger600;
  static const Color alertWarning = AppColors.warning600;
  static const Color alertInfo = AppColors.info600;
  static const Color alertSuccess = AppColors.success600;

  // Surfaces & Neutrals
  static const Color surfacePaper = AppColors.neutral50;
  static const Color surfaceCard = AppColors.white;
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = AppColors.neutral900;
  static const Color textSecondary = AppColors.neutral500;

  // Dark Mode Tokens
  static const Color darkBackground = AppColors.darkPageBg;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = AppColors.darkText;
  static const Color darkTextSecondary = AppColors.darkTextSecondary;

  // Spacing
  static const double spaceXs = AppSpacing.space4;
  static const double spaceSm = AppSpacing.space8;
  static const double spaceMd = AppSpacing.space16;
  static const double spaceLg = AppSpacing.space24;
  static const double spaceXl = AppSpacing.space32;
  static const double space2xl = AppSpacing.space48;

  // Border Radii
  static const double radiusSm = AppSpacing.radiusSm;
  static const double radiusMd = AppSpacing.radiusMd;
  static const double radiusLg = AppSpacing.radiusLg;
  static const double radiusFull = AppSpacing.radiusFull;
}
