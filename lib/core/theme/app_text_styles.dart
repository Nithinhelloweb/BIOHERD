import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// BIOHERD Typography System
/// Type scale and font pairings defined in DESIGN.md:
/// Primary font: Nunito (Latin) with Noto Sans Devanagari fallback for Marathi & Hindi.
/// Enforces Hallmark discipline: Roman headings, never italic headers.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    Color color = AppColors.neutral900,
    bool isDevanagari = false,
  }) {
    // 10% additional line height for Devanagari script to accommodate diacritics
    final effectiveHeight = isDevanagari ? height * 1.1 : height;
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: effectiveHeight,
      color: color,
      fontStyle: FontStyle.normal, // Strictly roman headings per Hallmark anti-slop rules
    );

    if (isDevanagari) {
      return GoogleFonts.notoSansDevanagari(textStyle: baseStyle);
    }
    return GoogleFonts.nunito(textStyle: baseStyle);
  }

  // Display — 28sp / 700 / 1.2
  static TextStyle display({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 28, fontWeight: fontWeight ?? FontWeight.w700, height: 1.2, color: color, isDevanagari: isDevanagari);

  // Headline 1 — 24sp / 700 / 1.25
  static TextStyle h1({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 24, fontWeight: fontWeight ?? FontWeight.w700, height: 1.25, color: color, isDevanagari: isDevanagari);

  // Headline 2 — 20sp / 600 / 1.3
  static TextStyle h2({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 20, fontWeight: fontWeight ?? FontWeight.w600, height: 1.3, color: color, isDevanagari: isDevanagari);

  // Headline 3 — 18sp / 600 / 1.35
  static TextStyle h3({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 18, fontWeight: fontWeight ?? FontWeight.w600, height: 1.35, color: color, isDevanagari: isDevanagari);

  // Body Large — 16sp / 400 / 1.6
  static TextStyle bodyLarge({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 16, fontWeight: fontWeight ?? FontWeight.w400, height: 1.6, color: color, isDevanagari: isDevanagari);
  static TextStyle bodyLg({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      bodyLarge(color: color, isDevanagari: isDevanagari, fontWeight: fontWeight);

  // Body — 14sp / 400 / 1.6
  static TextStyle body({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 14, fontWeight: fontWeight ?? FontWeight.w400, height: 1.6, color: color, isDevanagari: isDevanagari);
  static TextStyle bodyMd({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      body(color: color, isDevanagari: isDevanagari, fontWeight: fontWeight);
  static TextStyle bodyMedium({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      body(color: color, isDevanagari: isDevanagari, fontWeight: fontWeight);

  // Body Small — 12sp / 400 / 1.5
  static TextStyle bodySmall({Color color = AppColors.neutral700, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 12, fontWeight: fontWeight ?? FontWeight.w400, height: 1.5, color: color, isDevanagari: isDevanagari);
  static TextStyle bodySm({Color color = AppColors.neutral700, bool isDevanagari = false, FontWeight? fontWeight}) =>
      bodySmall(color: color, isDevanagari: isDevanagari, fontWeight: fontWeight);

  // Label — 12sp / 600 / 1.4
  static TextStyle label({Color color = AppColors.neutral900, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 12, fontWeight: fontWeight ?? FontWeight.w600, height: 1.4, color: color, isDevanagari: isDevanagari);

  // Caption — 11sp / 400 / 1.4 (Hard floor: never below 11sp on production screen)
  static TextStyle caption({Color color = AppColors.neutral500, bool isDevanagari = false, FontWeight? fontWeight}) =>
      _font(fontSize: 11, fontWeight: fontWeight ?? FontWeight.w400, height: 1.4, color: color, isDevanagari: isDevanagari);
}
