export 'bioherd_drawer.dart';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../features/auth/models/user_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'adaptive_layout.dart';
import 'bioherd_drawer.dart';

class NavigationTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavigationTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// BioHerdShell
/// Master application navigation wrapper.
/// Transitions seamlessly between:
/// - Slide-Out Hamburger Side Drawer on mobile (< 600dp)
/// - NavigationRail on tablet (600 - 1024dp)
/// - Persistent Left Sidebar on desktop/web (>= 1024dp)
class BioHerdShell extends StatelessWidget {
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  static void openDrawer([BuildContext? context]) {
    scaffoldKey.currentState?.openDrawer();
  }

  static void closeDrawer([BuildContext? context]) {
    scaffoldKey.currentState?.closeDrawer();
  }

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<NavigationTabItem> tabs;
  final Widget body;
  final Widget? floatingActionButton;
  final UserModel? user;

  const BioHerdShell({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.tabs,
    required this.body,
    this.floatingActionButton,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mobile: (context) => _buildMobile(context),
      tablet: (context) => _buildTablet(context),
      desktop: (context) => _buildDesktop(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      key: BioHerdShell.scaffoldKey,
      drawer: BioHerdDrawer(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
        tabs: tabs,
        user: user,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildTablet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTabSelected,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
            labelType: NavigationRailLabelType.all,
            indicatorColor: AppColors.primary100,
            selectedLabelTextStyle: AppTextStyles.label(color: AppColors.primary600),
            unselectedLabelTextStyle: AppTextStyles.caption(
              color: isDark ? AppColors.darkTextSecondary : AppColors.neutral700,
            ),
            destinations: tabs.map((tab) {
              return NavigationRailDestination(
                icon: Icon(tab.icon, color: isDark ? AppColors.darkTextSecondary : AppColors.neutral700),
                selectedIcon: Icon(tab.activeIcon, color: AppColors.primary600),
                label: Text(tab.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral100,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsFill.shieldCheck,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BIOHERD',
                            style: AppTextStyles.h2(
                              color: isDark ? AppColors.darkText : AppColors.primary600,
                            ),
                          ),
                          Text(
                            'SIH26128 • AHD Portal',
                            style: AppTextStyles.caption(color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      final isSelected = index == currentIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: isSelected ? AppColors.primary600 : AppColors.neutral700,
                            size: 22,
                          ),
                          title: Text(
                            tab.label,
                            style: isSelected
                                ? AppTextStyles.label(color: AppColors.primary600)
                                : AppTextStyles.body(color: isDark ? AppColors.darkText : AppColors.neutral700),
                          ),
                          onTap: () => onTabSelected(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
