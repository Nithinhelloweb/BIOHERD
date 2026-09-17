import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/hallmark_tokens.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/models/user_model.dart';
import 'package:bioherd/features/auth/presentation/login_screen.dart';
import 'package:bioherd/features/auth/presentation/widgets/auth_user_card.dart';

class ProfileScreen extends StatelessWidget {
  final Function(Locale)? onLocaleChanged;
  final Function(ThemeMode)? onThemeModeChanged;
  final ThemeMode? currentThemeMode;
  final Locale? currentLocale;

  const ProfileScreen({
    super.key,
    this.onLocaleChanged,
    this.onThemeModeChanged,
    this.currentThemeMode,
    this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper;
    final cardBg = isDark ? HallmarkTokens.darkSurface : HallmarkTokens.surfaceCard;
    final textColor = isDark ? HallmarkTokens.darkTextPrimary : HallmarkTokens.textPrimary;
    final subtextColor = isDark ? HallmarkTokens.darkTextSecondary : HallmarkTokens.textSecondary;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return LoginScreen(
            onLocaleChanged: onLocaleChanged,
            currentLocale: currentLocale,
          );
        }

        final user = state.user;

        return Scaffold(
          backgroundColor: surfaceBg,
          appBar: AppBar(
            title: const Text('Account & Security', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: cardBg,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(HallmarkTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthUserCard(user: user),
                const SizedBox(height: HallmarkTokens.spaceLg),

                // Role Permissions Matrix
                Container(
                  padding: const EdgeInsets.all(HallmarkTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(HallmarkTokens.radiusLg),
                    border: Border.all(
                      color: isDark ? HallmarkTokens.darkBorder : HallmarkTokens.surfaceBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(PhosphorIconsRegular.shieldCheck, color: HallmarkTokens.forestMoss),
                          const SizedBox(width: 8),
                          Text(
                            'Active Role Permissions (RBAC)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: HallmarkTokens.spaceMd),
                      ..._buildRolePermissions(user.role, textColor, subtextColor),
                    ],
                  ),
                ),
                const SizedBox(height: HallmarkTokens.spaceLg),

                // Fast Role Switcher (For Evaluation & Demo)
                Container(
                  padding: const EdgeInsets.all(HallmarkTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(HallmarkTokens.radiusLg),
                    border: Border.all(
                      color: isDark ? HallmarkTokens.darkBorder : HallmarkTokens.surfaceBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Switch Demo Persona (SIH Evaluator)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Experience the app from different stakeholder viewpoints in Maharashtra:',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      const SizedBox(height: HallmarkTokens.spaceMd),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildRoleSwitchButton(
                            context,
                            'Farmer (Pune)',
                            '9876543210',
                            'FarmerPass123!',
                            user.phoneNumber == '9876543210',
                          ),
                          _buildRoleSwitchButton(
                            context,
                            'Veterinarian (Kolhapur)',
                            '9876543211',
                            'VetPass123!',
                            user.phoneNumber == '9876543211',
                          ),
                          _buildRoleSwitchButton(
                            context,
                            'Dairy Coop (Ahmednagar)',
                            '9876543212',
                            'CoopPass123!',
                            user.phoneNumber == '9876543212',
                          ),
                          _buildRoleSwitchButton(
                            context,
                            'DVO Officer (Maharashtra)',
                            '9876543213',
                            'DVOPass123!',
                            user.phoneNumber == '9876543213',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRolePermissions(UserRole role, Color textColor, Color subtextColor) {
    List<Map<String, dynamic>> perms;
    switch (role) {
      case UserRole.farmer:
        perms = [
          {'title': 'Register & Tag Cattle (RFID/QR)', 'allowed': true},
          {'title': 'AI Symptom & Disease Scanner', 'allowed': true},
          {'title': 'Request Vet Teleconsultation', 'allowed': true},
          {'title': 'District-Wide Outbreak Alert Broadcast', 'allowed': false},
        ];
        break;
      case UserRole.veterinarian:
        perms = [
          {'title': 'Access Assigned Farm Cases', 'allowed': true},
          {'title': 'Confirm Disease Diagnosis & Severity', 'allowed': true},
          {'title': 'Issue Treatment & Antibiotic Prescriptions', 'allowed': true},
          {'title': 'Escalate Outbreak to DVO', 'allowed': true},
        ];
        break;
      case UserRole.dairyCoop:
        perms = [
          {'title': 'Bulk Milk Collection Health Monitoring', 'allowed': true},
          {'title': 'Farm Member Disease Risk Advisory', 'allowed': true},
          {'title': 'Supply Chain Quality Safeguard', 'allowed': true},
          {'title': 'Prescription Writing', 'allowed': false},
        ];
        break;
      case UserRole.dvoOfficer:
      case UserRole.stateAdmin:
        perms = [
          {'title': 'District & State Disease Surveillance Map', 'allowed': true},
          {'title': 'Declare Containment & Quarantine Zones', 'allowed': true},
          {'title': 'Dispatch Rapid Response Vet Teams', 'allowed': true},
          {'title': 'Automated Maharashtra AHD Reports', 'allowed': true},
        ];
        break;
    }

    return perms.map((p) {
      final allowed = p['allowed'] as bool;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              allowed ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.xCircle,
              size: 18,
              color: allowed ? HallmarkTokens.forestMoss : HallmarkTokens.alertCritical,
            ),
            const SizedBox(width: 8),
            Text(
              p['title'] as String,
              style: TextStyle(
                fontSize: 13,
                color: allowed ? textColor : subtextColor,
                decoration: allowed ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRoleSwitchButton(
    BuildContext context,
    String label,
    String phone,
    String password,
    bool isActive,
  ) {
    return FilterChip(
      selected: isActive,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (_) {
        if (!isActive) {
          context.read<AuthBloc>().add(AuthLoginSubmitted(
                phone: phone,
                password: password,
              ));
        }
      },
      selectedColor: HallmarkTokens.forestMoss.withValues(alpha: 0.2),
      checkmarkColor: HallmarkTokens.forestMoss,
    );
  }
}
