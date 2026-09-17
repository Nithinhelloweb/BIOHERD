import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop }

/// AdaptiveLayout
/// Responsive layout manager supporting phones, tablets, and desktop/web dashboard.
/// Breakpoints:
/// - Mobile: < 600dp
/// - Tablet: 600dp - 1024dp
/// - Desktop: >= 1024dp
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static DeviceScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceScreenType.desktop;
    if (width >= 600) return DeviceScreenType.tablet;
    return DeviceScreenType.mobile;
  }

  static bool isMobile(BuildContext context) => getScreenType(context) == DeviceScreenType.mobile;
  static bool isTablet(BuildContext context) => getScreenType(context) == DeviceScreenType.tablet;
  static bool isDesktop(BuildContext context) => getScreenType(context) == DeviceScreenType.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024 && desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}
