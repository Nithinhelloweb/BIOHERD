import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

/// Full-screen demo login / role selector.
/// Works 100% offline — no backend required.
class DemoLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const DemoLoginScreen({super.key, this.onLoginSuccess});

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  bool _showLoginForm = false;
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          widget.onLoginSuccess?.call();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F7F4),
        body: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    // Left Hero Panel (desktop/tablet)
                    Expanded(flex: 5, child: _buildHeroPanel(isDark)),
                    // Right Form Panel
                    Expanded(flex: 4, child: _buildFormPanel(isDark, size)),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCompactHero(isDark),
                      _buildFormPanel(isDark, size),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroPanel(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0D2137), const Color(0xFF071A0C)]
              : [const Color(0xFF1B6E3C), const Color(0xFF0D4F5C)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _fadeController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.shieldCheck,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'BIOHERD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SIH26128 — Livestock Disease\nEarly Detection & Management',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Livestock Disease Early Detection & Management System',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildHeroStat('36', 'Maharashtra Districts'),
                  const SizedBox(height: 16),
                  _buildHeroStat('5', 'User Roles & RBAC'),
                  const SizedBox(height: 16),
                  _buildHeroStat('AI', 'Disease Detection Engine'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeroStat(String value, String label) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHero(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D2137), const Color(0xFF071A0C)]
              : [const Color(0xFF1B6E3C), const Color(0xFF0D4F5C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsFill.shieldCheck, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'BIOHERD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SIH26128 • Government of Maharashtra',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(bool isDark, Size size) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: size.height * 0.7),
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 700 ? 48 : 24,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showLoginForm) _buildLoginForm(isDark) else _buildDemoRoleSelector(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Demo Role Cards ─────────────────────────────────

  Widget _buildDemoRoleSelector(bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to BIOHERD',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0D2137),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select your role to explore the system',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.wifiSlash,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Demo mode — works 100% offline. No backend required.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role Cards
            ..._demoRoles.map((r) => _buildRoleCard(r, isDark, isLoading, context)),

            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(PhosphorIconsRegular.signIn),
              label: const Text('Login with credentials'),
              onPressed: () => setState(() => _showLoginForm = true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            if (state is AuthUnauthenticated && state.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(state.errorMessage!, state.isOfflineError),
            ],
          ],
        );
      },
    );
  }

  static const List<_DemoRole> _demoRoles = [
    _DemoRole(
      role: UserRole.farmer,
      label: 'Farmer',
      subtitle: 'Pune (Wagholi) • Ramesh Patil',
      description: 'Report symptoms/deaths, animal passport, AI triage, advisories',
      icon: PhosphorIconsFill.cow,
      colorHex: 0xFF2E7D32,
    ),
    _DemoRole(
      role: UserRole.paravet,
      label: 'Para-Vet (Field Worker)',
      subtitle: 'Haveli Panchayat • Ganesh More',
      description: 'First responder, area triage, vaccination drives, sample collection',
      icon: PhosphorIconsFill.usersThree,
      colorHex: 0xFF00796B,
    ),
    _DemoRole(
      role: UserRole.veterinarian,
      label: 'Field Veterinarian',
      subtitle: 'Haveli Block • Dr. Anjali Deshmukh',
      description: 'Clinical diagnosis, prescriptions, sample tracking, block drives',
      icon: PhosphorIconsFill.stethoscope,
      colorHex: 0xFF1565C0,
    ),
    _DemoRole(
      role: UserRole.labTechnician,
      label: 'Lab Technician',
      subtitle: 'District Lab Pune • Dr. Vikram Joshi',
      description: 'Sample intake, PCR/ELISA tests, pathogen entry, SDDL referrals',
      icon: PhosphorIconsFill.flask,
      colorHex: 0xFF0288D1,
    ),
    _DemoRole(
      role: UserRole.dvoOfficer,
      label: 'District Vet Officer',
      subtitle: 'Ahmednagar District • Rajesh Shinde',
      description: 'Outbreak containment, quarantine declaration, drive coordination',
      icon: PhosphorIconsFill.mapTrifold,
      colorHex: 0xFFE65100,
    ),
    _DemoRole(
      role: UserRole.stateAdmin,
      label: 'State Official',
      subtitle: 'Mumbai / Pune • Dr. Suresh Kulkarni',
      description: 'State surveillance heatmap, mass broadcasts, policy & approvals',
      icon: PhosphorIconsFill.shieldStar,
      colorHex: 0xFF6A1B9A,
    ),
    _DemoRole(
      role: UserRole.superAdmin,
      label: 'Super Admin',
      subtitle: 'National System Administrator',
      description: 'Full system configuration, RBAC scopes, audit ledgers',
      icon: PhosphorIconsFill.gearSix,
      colorHex: 0xFF37474F,
    ),
  ];

  Widget _buildRoleCard(
    _DemoRole r,
    bool isDark,
    bool isLoading,
    BuildContext context,
  ) {
    final color = Color(r.colorHex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isLoading ? null : () => context.read<AuthBloc>().add(DemoLoginRequested(r.role)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? color.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.05),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(r.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0D2137),
                      ),
                    ),
                    Text(
                      r.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.arrowRight, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Login Form ────────────────────────────────────

  Widget _buildLoginForm(bool isDark) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  onPressed: () => setState(() => _showLoginForm = false),
                ),
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0D2137),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(PhosphorIconsRegular.phone),
                hintText: '+91 XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(PhosphorIconsRegular.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass
                      ? PhosphorIconsRegular.eye
                      : PhosphorIconsRegular.eyeSlash),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<AuthBloc>().add(AuthLoginSubmitted(
                              phone: _phoneCtrl.text.trim(),
                              password: _passCtrl.text,
                            ));
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In'),
              ),
            ),

            if (state is AuthUnauthenticated && state.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(state.errorMessage!, state.isOfflineError),
            ],
          ],
        );
      },
    );
  }

  Widget _buildErrorBanner(String message, bool isOffline) {
    final icon = isOffline
        ? PhosphorIconsRegular.wifiSlash
        : PhosphorIconsRegular.warning;
    final color = isOffline ? Colors.orange : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }
}

class _DemoRole {
  final UserRole role;
  final String label;
  final String subtitle;
  final String description;
  final IconData icon;
  final int colorHex;

  const _DemoRole({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.colorHex,
  });
}
