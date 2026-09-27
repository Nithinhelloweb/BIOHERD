import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/models/user_model.dart';
import 'adaptive_layout.dart';
import 'bioherd_shell.dart';

/// Hamburger Menu Button for Root AppBars on Mobile
/// Hidden automatically on tablet and desktop screens where NavigationRail
/// or persistent left sidebar is active.
class BioHerdHamburgerButton extends StatelessWidget {
  final Color? color;
  final double size;

  const BioHerdHamburgerButton({
    super.key,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!AdaptiveLayout.isMobile(context)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? AppColors.darkText : AppColors.neutral800);

    return IconButton(
      tooltip: 'Open navigation menu',
      icon: Icon(PhosphorIconsRegular.list, color: iconColor, size: size),
      onPressed: () => BioHerdShell.openDrawer(context),
    );
  }
}

/// Slide-Out Side Navigation Drawer for Mobile View
/// Replaces the bottom horizontal navigation bar with an intuitive,
/// full-featured hamburger drawer listing all available options for the user's role.
class BioHerdDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<NavigationTabItem> tabs;
  final UserModel? user;

  const BioHerdDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.tabs,
    this.user,
  });

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.farmer:
        return const Color(0xFF2E7D32); // Forest Green
      case UserRole.paravet:
        return const Color(0xFF0288D1); // Sky Blue
      case UserRole.veterinarian:
        return const Color(0xFF00897B); // Teal
      case UserRole.labTechnician:
        return const Color(0xFF7B1FA2); // Purple
      case UserRole.dairyCoop:
        return const Color(0xFFF57C00); // Amber
      case UserRole.dvoOfficer:
        return const Color(0xFFC2185B); // Rose/Crimson
      case UserRole.stateAdmin:
      case UserRole.superAdmin:
        return const Color(0xFFD32F2F); // Red
      default:
        return AppColors.primary600;
    }
  }

  String _getRoleLabel(UserRole? role) {
    switch (role) {
      case UserRole.farmer:
        return 'FARMER';
      case UserRole.paravet:
        return 'PARA-VET (FIELD WORKER)';
      case UserRole.veterinarian:
        return 'FIELD VETERINARIAN';
      case UserRole.labTechnician:
        return 'LAB TECHNICIAN';
      case UserRole.dairyCoop:
        return 'DAIRY COOPERATIVE';
      case UserRole.dvoOfficer:
        return 'DISTRICT VET OFFICER';
      case UserRole.stateAdmin:
        return 'STATE OFFICIAL';
      case UserRole.superAdmin:
        return 'SUPER ADMIN';
      default:
        return 'USER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(user?.role);
    final roleLabel = _getRoleLabel(user?.role);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── Header: BioHerd Branding & User Profile ─────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F3D21),
                    Color(0xFF1B6B3A),
                    Color(0xFF228B47),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          PhosphorIconsFill.shieldCheck,
                          color: Color(0xFF1B6B3A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'BIOHERD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Animal Health Surveillance',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(
                            PhosphorIconsFill.user,
                            color: roleColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Livestock Officer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      user?.district ?? 'Pune',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Section Title ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                children: [
                  Text(
                    'NAVIGATION MENU',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.neutral500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tabs.length} options',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Navigation Options List ─────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = index == currentIndex;

                  final activeBg = isDark
                      ? const Color(0xFF1E3A2B)
                      : AppColors.primary50;
                  final activeBorder = isDark
                      ? AppColors.primary400
                      : AppColors.primary600;
                  final inactiveText = isDark
                      ? AppColors.darkText
                      : AppColors.neutral800;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? activeBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: activeBorder.withValues(alpha: 0.6), width: 1.2)
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        isSelected ? tab.activeIcon : tab.icon,
                        color: isSelected ? AppColors.primary600 : (isDark ? AppColors.darkTextSecondary : AppColors.neutral600),
                        size: 22,
                      ),
                      title: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary600 : inactiveText,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary600,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () {
                        onTabSelected(index);
                        Navigator.of(context).pop(); // Close drawer
                      },
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // ─── Footer: Quick Actions & Logout ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Maharashtra AHD • SIH 26128',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.neutral400,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<AuthBloc>().add(const AuthLogoutSubmitted());
                    },
                    icon: const Icon(PhosphorIconsRegular.signOut, size: 16, color: AppColors.danger600),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.danger600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
