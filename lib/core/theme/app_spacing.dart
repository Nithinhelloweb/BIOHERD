import 'package:flutter/material.dart';

/// BIOHERD Design Tokens — Spacing & Border Radius
/// 8dp base grid system matching DESIGN.md.
class AppSpacing {
  AppSpacing._();

  // Spacing Values
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Short aliases
  static const double xs = space4;
  static const double sm = space8;
  static const double md = space16;
  static const double lg = space24;
  static const double xl = space32;

  // Screen Horizontal Padding
  static const double screenMarginMobile = 16.0;
  static const double screenMarginWeb = 24.0;
  static const double maxContentWidth = 1200.0;

  // Border Radius Tokens
  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Vertical Spacers
  static const SizedBox vSpace4 = SizedBox(height: space4);
  static const SizedBox vSpace8 = SizedBox(height: space8);
  static const SizedBox vSpace12 = SizedBox(height: space12);
  static const SizedBox vSpace16 = SizedBox(height: space16);
  static const SizedBox vSpace20 = SizedBox(height: space20);
  static const SizedBox vSpace24 = SizedBox(height: space24);
  static const SizedBox vSpace32 = SizedBox(height: space32);
  static const SizedBox vSpace48 = SizedBox(height: space48);

  // Horizontal Spacers
  static const SizedBox hSpace4 = SizedBox(width: space4);
  static const SizedBox hSpace8 = SizedBox(width: space8);
  static const SizedBox hSpace12 = SizedBox(width: space12);
  static const SizedBox hSpace16 = SizedBox(width: space16);
  static const SizedBox hSpace20 = SizedBox(width: space20);
  static const SizedBox hSpace24 = SizedBox(width: space24);
  static const SizedBox hSpace32 = SizedBox(width: space32);
  static const SizedBox hSpace48 = SizedBox(width: space48);
}
