import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/hallmark_tokens.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/l10n/app_localizations.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/presentation/register_screen.dart';
import 'package:bioherd/features/auth/presentation/widgets/two_factor_dialog.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final Function(Locale)? onLocaleChanged;
  final Locale? currentLocale;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onLocaleChanged,
    this.currentLocale,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLoginSubmitted(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  void _fillPreset(String phone, String password) {
    setState(() {
      _phoneController.text = phone;
      _passwordController.text = password;
    });
  }

  void _show2FADialog(String tempToken, String phone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => TwoFactorDialog(
        phoneNumber: phone,
        onVerify: (code) {
          Navigator.of(dialogCtx).pop();
          context.read<AuthBloc>().add(Auth2FAVerificationSubmitted(
                tempToken: tempToken,
                code: code,
              ));
        },
        onCancel: () {
          Navigator.of(dialogCtx).pop();
          context.read<AuthBloc>().add(const AuthCheckRequested());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = HallmarkTokens.forestMoss;
    final surfaceBg = isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper;
    final cardBg = isDark ? HallmarkTokens.darkSurface : HallmarkTokens.surfaceCard;
    final textColor = isDark ? HallmarkTokens.darkTextPrimary : HallmarkTokens.textPrimary;
    final subtextColor = isDark ? HallmarkTokens.darkTextSecondary : HallmarkTokens.textSecondary;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRequires2FA) {
          _show2FADialog(state.tempToken, state.phone);
        } else if (state is AuthAuthenticated) {
          widget.onLoginSuccess?.call();
        } else if (state is AuthUnauthenticated && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: HallmarkTokens.alertCritical,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: surfaceBg,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: HallmarkTokens.spaceLg,
                  vertical: HallmarkTokens.spaceXl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Language Selector Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(PhosphorIconsRegular.translate, size: 16, color: HallmarkTokens.forestMoss),
                          const SizedBox(width: 6),
                          _buildLanguageChip('English', const Locale('en'), isDark),
                          const SizedBox(width: 4),
                          _buildLanguageChip('मराठी', const Locale('mr'), isDark),
                          const SizedBox(width: 4),
                          _buildLanguageChip('हिंदी', const Locale('hi'), isDark),
                        ],
                      ),
                      const SizedBox(height: HallmarkTokens.spaceLg),

                      // Brand Header
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(HallmarkTokens.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PhosphorIconsFill.cow,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: HallmarkTokens.spaceMd),
                      Center(
                        child: Text(
                          'BIOHERD',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: textColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          l10n?.tagline ?? 'Healthy Animals. Prosperous Farmers.',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: HallmarkTokens.spaceXl),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(HallmarkTokens.spaceXl),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(HallmarkTokens.radiusLg),
                          border: Border.all(
                            color: isDark ? HallmarkTokens.darkBorder : HallmarkTokens.surfaceBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n?.login ?? 'Login',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: HallmarkTokens.spaceLg),

                              // Phone input
                              Text(
                                l10n?.phoneNumber ?? 'Phone Number',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('login_phone_field'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  counterText: '',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(PhosphorIconsRegular.phone, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 1,
                                          height: 20,
                                          color: Colors.grey.withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  hintText: '9876543210',
                                  filled: true,
                                  fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().length != 10) {
                                    return l10n?.invalidPhone ?? 'Enter valid 10-digit phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: HallmarkTokens.spaceMd),

                              // Password input
                              Text(
                                l10n?.password ?? 'Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('login_password_field'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(PhosphorIconsRegular.lockKey, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? PhosphorIconsRegular.eye
                                          : PhosphorIconsRegular.eyeSlash,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  hintText: '••••••••',
                                  filled: true,
                                  fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.length < 6) {
                                    return l10n?.passwordRequired ?? 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: HallmarkTokens.spaceLg),

                              // Submit Button
                              BioHerdButton(
                                key: const Key('login_submit_button'),
                                label: isLoading
                                    ? (l10n?.loading ?? 'Authenticating...')
                                    : (l10n?.login ?? 'Sign In'),
                                icon: isLoading ? null : const Icon(PhosphorIconsRegular.signIn, color: Colors.white, size: 18),
                                onPressed: isLoading ? null : _submitLogin,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: HallmarkTokens.spaceMd),

                      // Quick Role Demo Presets (Hallmark ease-of-use)
                      Container(
                        padding: const EdgeInsets.all(HallmarkTokens.spaceMd),
                        decoration: BoxDecoration(
                          color: cardBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd),
                          border: Border.all(
                            color: isDark ? HallmarkTokens.darkBorder : HallmarkTokens.surfaceBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Quick Demo Login Credentials:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildPresetChip('Farmer', '9876543210', 'FarmerPass123!'),
                                _buildPresetChip('Veterinarian', '9876543211', 'VetPass123!'),
                                _buildPresetChip('Dairy Coop', '9876543212', 'CoopPass123!'),
                                _buildPresetChip('DVO Officer', '9876543213', 'DVOPass123!'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: HallmarkTokens.spaceLg),

                      // Register Link
                      Center(
                        child: TextButton(
                          key: const Key('goto_register_button'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<AuthBloc>(),
                                  child: RegisterScreen(
                                    onRegistered: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            l10n?.dontHaveAccount ?? "Don't have an account? Register",
                            style: const TextStyle(
                              color: HallmarkTokens.forestMoss,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageChip(String label, Locale targetLocale, bool isDark) {
    final isSelected = widget.currentLocale?.languageCode == targetLocale.languageCode;
    return InkWell(
      onTap: () => widget.onLocaleChanged?.call(targetLocale),
      borderRadius: BorderRadius.circular(HallmarkTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? HallmarkTokens.forestMoss : Colors.transparent,
          borderRadius: BorderRadius.circular(HallmarkTokens.radiusSm),
          border: Border.all(
            color: isSelected
                ? HallmarkTokens.forestMoss
                : (isDark ? HallmarkTokens.darkBorder : HallmarkTokens.surfaceBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String roleLabel, String phone, String password) {
    return ActionChip(
      label: Text(roleLabel, style: const TextStyle(fontSize: 11)),
      onPressed: () => _fillPreset(phone, password),
      avatar: const Icon(PhosphorIconsRegular.userCircle, size: 14),
      visualDensity: VisualDensity.compact,
    );
  }
}
