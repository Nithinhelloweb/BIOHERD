import 'package:flutter/material.dart';

/// BIOHERD Design Tokens — Colors
/// Defined according to SIH26128 Design System Specifications (DESIGN.md).
/// Forest Green palette signalling agriculture, animal health, and trust.
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary600 = Color(0xFF1B6B3A); // Primary buttons, key icons, active nav
  static const Color primary500 = Color(0xFF228B47); // Hover/press states on primary
  static const Color primary400 = Color(0xFF2DAE5A); // Accent highlights, progress bars
  static const Color primary100 = Color(0xFFD4EDDA); // Light fills, success banners
  static const Color primary50 = Color(0xFFEAF7EE);  // Section backgrounds, ripple effects

  // Semantic Colors
  static const Color danger600 = Color(0xFFC0392B);  // Critical alerts, destructive actions, high severity
  static const Color danger100 = Color(0xFFFADBD8);  // Danger background fills
  static const Color warning600 = Color(0xFFD35400); // Medium severity, caution states
  static const Color warning100 = Color(0xFFFAE5D3); // Warning background fills
  static const Color info600 = Color(0xFF1A5276);    // Informational, IoT data
  static const Color info100 = Color(0xFFD6EAF8);    // Info background fills
  static const Color success600 = Color(0xFF1E8449); // Confirmation, resolved cases, healthy readings
  static const Color success100 = Color(0xFFD5F5E3); // Success background fills

  // Brand & Semantic Aliases
  static const Color forestGreen = primary600;
  static const Color alertCrimson = danger600;
  static const Color alertAmber = warning600;
  static const Color secondary50 = Color(0xFFF3E8FF);
  static const Color secondary700 = Color(0xFF7E22CE);
  static const Color secondary800 = Color(0xFF6B21A8);

  // Neutral Palette
  static const Color neutral900 = Color(0xFF1A1A1A); // Primary text
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral700 = Color(0xFF3D3D3D); // Secondary text, labels
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral500 = Color(0xFF6B6B6B); // Placeholder, hint text
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral300 = Color(0xFFBDBDBD); // Disabled states, dividers
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral100 = Color(0xFFF2F2F2); // Card backgrounds, input fills
  static const Color neutral50 = Color(0xFFFAFAFA);  // Page background
  static const Color white = Color(0xFFFFFFFF);      // Surface

  // Extended Primary Shades
  static const Color primary900 = Color(0xFF082212);
  static const Color primary800 = Color(0xFF0F3D21);
  static const Color primary700 = Color(0xFF14532D);
  static const Color primary300 = Color(0xFF4ADE80);
  static const Color primary200 = Color(0xFFBBF7D0);

  // Extended Semantic Shades
  static const Color info50 = Color(0xFFF0F9FF);
  static const Color info700 = Color(0xFF0369A1);
  static const Color info800 = Color(0xFF075985);

  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success200 = Color(0xFFBBF7D0);

  static const Color danger50 = Color(0xFFFEF2F2);
  static const Color danger200 = Color(0xFFFECACA);
  static const Color danger700 = Color(0xFFB91C1C);
  static const Color danger800 = Color(0xFF991B1B);

  // Dark Mode Tokens
  static const Color darkPageBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkPrimary = Color(0xFF2DAE5A);
  static const Color darkText = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // Semantic Aliases
  static const Color alertRed = danger600;
  static const Color primaryGreen = primary600;
}
