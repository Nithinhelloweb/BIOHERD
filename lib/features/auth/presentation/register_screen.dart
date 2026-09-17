import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/hallmark_tokens.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/l10n/app_localizations.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegistered;

  const RegisterScreen({super.key, this.onRegistered});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedRole = 'farmer';
  String _selectedDistrict = 'Pune';
  bool _obscurePassword = true;

  static const List<String> _maharashtraDistricts = [
    'Ahmednagar',
    'Akola',
    'Amravati',
    'Beed',
    'Bhandara',
    'Buldhana',
    'Chandrapur',
    'Chhatrapati Sambhajinagar',
    'Dhule',
    'Gadchiroli',
    'Gondia',
    'Hingoli',
    'Jalgaon',
    'Jalna',
    'Kolhapur',
    'Latur',
    'Mumbai City',
    'Mumbai Suburban',
    'Nagpur',
    'Nanded',
    'Nandurbar',
    'Nashik',
    'Dharashiv',
    'Palghar',
    'Parbhani',
    'Pune',
    'Raigad',
    'Ratnagiri',
    'Sangli',
    'Satara',
    'Sindhudurg',
    'Solapur',
    'Thane',
    'Wardha',
    'Washim',
    'Yavatmal',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthRegisterSubmitted(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            role: _selectedRole,
            district: _selectedDistrict,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper;
    final cardBg = isDark ? HallmarkTokens.darkSurface : HallmarkTokens.surfaceCard;
    final textColor = isDark ? HallmarkTokens.darkTextPrimary : HallmarkTokens.textPrimary;
    final subtextColor = isDark ? HallmarkTokens.darkTextSecondary : HallmarkTokens.textSecondary;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: HallmarkTokens.forestMoss,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onRegistered?.call();
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
          appBar: AppBar(
            title: Text(
              l10n?.register ?? 'Register Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            backgroundColor: cardBg,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HallmarkTokens.spaceLg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
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
                            'Farmer & Officer Registration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Join the Maharashtra BIOHERD Disease Surveillance Network',
                            style: TextStyle(
                              fontSize: 13,
                              color: subtextColor,
                            ),
                          ),
                          const SizedBox(height: HallmarkTokens.spaceLg),

                          // Full Name
                          Text(
                            l10n?.fullName ?? 'Full Name',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('register_name_field'),
                            controller: _nameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
                              hintText: 'e.g. Ramesh Patil',
                              filled: true,
                              fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
                          ),
                          const SizedBox(height: HallmarkTokens.spaceMd),

                          // Phone Number
                          Text(
                            l10n?.phoneNumber ?? 'Phone Number',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('register_phone_field'),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon: const Icon(PhosphorIconsRegular.phone, size: 18),
                              hintText: '9876543210',
                              filled: true,
                              fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length != 10) {
                                return l10n?.invalidPhone ?? 'Enter valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: HallmarkTokens.spaceMd),

                          // Role selection
                          Text(
                            l10n?.role ?? 'Role',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: const Key('register_role_dropdown'),
                            isExpanded: true,
                            initialValue: _selectedRole,
                            items: [
                              DropdownMenuItem(value: 'farmer', child: Text(l10n?.farmer ?? 'Farmer (शेतकरी)')),
                              DropdownMenuItem(value: 'veterinarian', child: Text(l10n?.veterinarian ?? 'Veterinarian (पशुवैद्यक)')),
                              DropdownMenuItem(value: 'dairy_coop', child: Text(l10n?.dairyCooperative ?? 'Dairy Cooperative (दुग्ध संस्था)')),
                              DropdownMenuItem(value: 'dvo_officer', child: Text(l10n?.dvoOfficer ?? 'DVO Officer (जिल्हा अधिकारी)')),
                            ],
                            onChanged: (val) => setState(() => _selectedRole = val ?? 'farmer'),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(PhosphorIconsRegular.identificationBadge, size: 18),
                              filled: true,
                              fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd)),
                            ),
                          ),
                          const SizedBox(height: HallmarkTokens.spaceMd),

                          // Maharashtra District selection
                          Text(
                            l10n?.district ?? 'District (Maharashtra)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: const Key('register_district_dropdown'),
                            isExpanded: true,
                            initialValue: _selectedDistrict,
                            items: _maharashtraDistricts.map((district) {
                              return DropdownMenuItem(value: district, child: Text(district, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedDistrict = val ?? 'Pune'),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(PhosphorIconsRegular.mapPin, size: 18),
                              filled: true,
                              fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd)),
                            ),
                          ),
                          const SizedBox(height: HallmarkTokens.spaceMd),

                          // Password
                          Text(
                            l10n?.password ?? 'Password (Min 8 chars, 1 uppercase, 1 number)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('register_password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(PhosphorIconsRegular.lockKey, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              hintText: 'e.g. Secret123!',
                              filled: true,
                              fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd)),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: HallmarkTokens.spaceLg),

                          // Submit Button
                          BioHerdButton(
                            key: const Key('register_submit_button'),
                            label: isLoading ? (l10n?.loading ?? 'Registering...') : (l10n?.register ?? 'Register'),
                            icon: isLoading ? null : const Icon(PhosphorIconsRegular.userPlus, color: Colors.white, size: 18),
                            onPressed: isLoading ? null : _submitRegistration,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
