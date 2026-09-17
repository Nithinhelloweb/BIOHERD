import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// BIOHERD Application Theme
/// Single source of truth for ThemeData matching DESIGN.md.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary600,
      primary: AppColors.primary600,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary600,
      secondary: AppColors.primary500,
      surface: AppColors.white,
      onSurface: AppColors.neutral900,
      error: AppColors.danger600,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.neutral50,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(),
        headlineLarge: AppTextStyles.h1(),
        headlineMedium: AppTextStyles.h2(),
        headlineSmall: AppTextStyles.h3(),
        bodyLarge: AppTextStyles.bodyLarge(),
        bodyMedium: AppTextStyles.body(),
        bodySmall: AppTextStyles.bodySmall(),
        labelLarge: AppTextStyles.label(),
        labelSmall: AppTextStyles.caption(),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.neutral900,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2(),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
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
          borderSide: const BorderSide(color: AppColors.neutral300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger600, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger600, width: 2.0),
        ),
        labelStyle: AppTextStyles.body(color: AppColors.neutral500),
        hintStyle: AppTextStyles.body(color: AppColors.neutral500),
        errorStyle: AppTextStyles.bodySmall(color: AppColors.danger600),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary600,
      primary: AppColors.darkPrimary,
      onPrimary: Colors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      error: AppColors.danger600,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkPageBg,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(color: AppColors.darkText),
        headlineLarge: AppTextStyles.h1(color: AppColors.darkText),
        headlineMedium: AppTextStyles.h2(color: AppColors.darkText),
        headlineSmall: AppTextStyles.h3(color: AppColors.darkText),
        bodyLarge: AppTextStyles.bodyLarge(color: AppColors.darkText),
        bodyMedium: AppTextStyles.body(color: AppColors.darkText),
        bodySmall: AppTextStyles.bodySmall(color: AppColors.darkTextSecondary),
        labelLarge: AppTextStyles.label(color: AppColors.darkText),
        labelSmall: AppTextStyles.caption(color: AppColors.darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: 14.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.neutral700, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.neutral700, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger600, width: 2.0),
        ),
        labelStyle: AppTextStyles.body(color: AppColors.darkTextSecondary),
        hintStyle: AppTextStyles.body(color: AppColors.darkTextSecondary),
        errorStyle: AppTextStyles.bodySmall(color: AppColors.danger600),
      ),
    );
  }
}
