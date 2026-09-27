import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/layout/bioherd_shell.dart';
import 'core/services/auth_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/animals/bloc/animal_bloc.dart';
import 'features/animals/data/animal_repository.dart';
import 'features/animals/presentation/animal_list_screen.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/presentation/demo_login_screen.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/showcase/presentation/showcase_screen.dart';
import 'features/surveillance/bloc/surveillance_bloc.dart';
import 'features/surveillance/data/surveillance_repository.dart';
import 'features/surveillance/presentation/advisories_broadcast_screen.dart';
import 'features/surveillance/presentation/surveillance_map_screen.dart';
import 'features/surveillance/presentation/vaccination_drives_screen.dart';
import 'features/symptoms/bloc/symptom_bloc.dart';
import 'features/symptoms/data/symptom_repository.dart';
import 'features/symptoms/presentation/diagnosis_dashboard_screen.dart';
import 'features/symptoms/presentation/telecom_offline_screen.dart';
import 'features/veterinary/bloc/veterinary_bloc.dart';
import 'features/veterinary/data/veterinary_repository.dart';
import 'features/veterinary/presentation/lab_workspace_screen.dart';
import 'features/veterinary/presentation/veterinarian_workspace_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('bioherd_language') ?? 'en';
  final isDarkMode = prefs.getBool('bioherd_dark_mode') ?? false;

  final authStorage = AuthStorageService(prefs);
  final authRepository = AuthRepository(storage: authStorage);
  final animalRepository = await OfflineFirstAnimalRepository.create();
  final symptomRepository = await OfflineFirstSymptomRepository.create();
  final surveillanceRepository = await OfflineFirstSurveillanceRepository.create();
  final veterinaryRepository = await OfflineFirstVeterinaryRepository.create();

  runApp(BioHerdApp(
    initialLocale: Locale(savedLanguage),
    initialThemeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    authRepository: authRepository,
    animalRepository: animalRepository,
    symptomRepository: symptomRepository,
    surveillanceRepository: surveillanceRepository,
    veterinaryRepository: veterinaryRepository,
  ));
}

class BioHerdApp extends StatefulWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;
  final AuthRepository authRepository;
  final AnimalRepository animalRepository;
  final SymptomRepository symptomRepository;
  final SurveillanceRepository surveillanceRepository;
  final VeterinaryRepository? veterinaryRepository;

  const BioHerdApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
    required this.authRepository,
    required this.animalRepository,
    required this.symptomRepository,
    required this.surveillanceRepository,
    this.veterinaryRepository,
  });

  @override
  State<BioHerdApp> createState() => _BioHerdAppState();
}

class _BioHerdAppState extends State<BioHerdApp> {
  late Locale _locale;
  late ThemeMode _themeMode;
  late final AuthBloc _authBloc;
  late final AnimalBloc _animalBloc;
  late final SymptomBloc _symptomBloc;
  late final SurveillanceBloc _surveillanceBloc;
  late final VeterinaryRepository _veterinaryRepository;
  late final VeterinaryBloc _veterinaryBloc;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _themeMode = widget.initialThemeMode;

    _authBloc = AuthBloc(authRepository: widget.authRepository);
    _authBloc.add(const AuthCheckRequested());

    _animalBloc = AnimalBloc(repository: widget.animalRepository);
    _animalBloc.add(const LoadAnimalsEvent());

    _symptomBloc = SymptomBloc(repository: widget.symptomRepository);
    _symptomBloc.add(const LoadSymptomReportsEvent());

    _surveillanceBloc = SurveillanceBloc(repository: widget.surveillanceRepository);
    _surveillanceBloc.add(const LoadSurveillanceDataEvent());

    _veterinaryRepository = widget.veterinaryRepository!;
    _veterinaryBloc = VeterinaryBloc(repository: _veterinaryRepository);
    _veterinaryBloc.add(const LoadCasesEvent());
  }

  @override
  void dispose() {
    _authBloc.close();
    _animalBloc.close();
    _symptomBloc.close();
    _surveillanceBloc.close();
    _veterinaryBloc.close();
    super.dispose();
  }

  void _changeLocale(Locale newLocale) async {
    setState(() => _locale = newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bioherd_language', newLocale.languageCode);
  }

  void _changeThemeMode(ThemeMode newMode) async {
    setState(() => _themeMode = newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bioherd_dark_mode', newMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<VeterinaryRepository>.value(
      value: _veterinaryRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _animalBloc),
          BlocProvider.value(value: _symptomBloc),
          BlocProvider.value(value: _surveillanceBloc),
          BlocProvider.value(value: _veterinaryBloc),
        ],
        child: MaterialApp(
          title: 'BIOHERD',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          locale: _locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              // ── Loading ──────────────────────────────────────
              if (authState is AuthInitial || authState is AuthLoading) {
                return const _SplashScreen();
              }

              // ── Unauthenticated → Show Demo Login ───────────
              if (authState is! AuthAuthenticated) {
                return DemoLoginScreen(
                  onLoginSuccess: () {
                    // Handled by BlocListener inside the screen
                  },
                );
              }

              // ── Authenticated → Role-gated Shell ────────────
              final user = authState.user;
              final isDemoMode = authState.isDemoMode;
              return _RoleGatedShell(
                user: user,
                isDemoMode: isDemoMode,
                onLocaleChanged: _changeLocale,
                onThemeModeChanged: _changeThemeMode,
                currentThemeMode: _themeMode,
                currentLocale: _locale,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F7F4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B6E3C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                PhosphorIconsFill.shieldCheck,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'BIOHERD',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Color(0xFF1B6E3C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SIH26128 • Maharashtra AHD',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role-Gated Shell ─────────────────────────────────────────────

class _RoleGatedShell extends StatefulWidget {
  final UserModel user;
  final bool isDemoMode;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final Locale currentLocale;

  const _RoleGatedShell({
    required this.user,
    required this.isDemoMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
    required this.currentLocale,
  });

  @override
  State<_RoleGatedShell> createState() => _RoleGatedShellState();
}

class _RoleGatedShellState extends State<_RoleGatedShell> {
  int _currentTabIndex = 0;

  /// Builds the list of tabs allowed for the user's role.
  List<_RoleTab> _buildTabsForRole(UserRole role) {
    final all = <_RoleTab>[
      // ── Design System (Super Admin / Dev) ──────────────────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Design',
          icon: PhosphorIconsRegular.sparkle,
          activeIcon: PhosphorIconsFill.sparkle,
        ),
        screen: ShowcaseScreen(
          onLocaleChanged: widget.onLocaleChanged,
          onThemeModeChanged: widget.onThemeModeChanged,
          currentThemeMode: widget.currentThemeMode,
          currentLocale: widget.currentLocale,
        ),
        roles: {UserRole.superAdmin},
      ),

      // ── Animals ────────────────────────────────────────────────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Animals',
          icon: PhosphorIconsRegular.cow,
          activeIcon: PhosphorIconsFill.cow,
        ),
        screen: const AnimalListScreen(),
        roles: {
          UserRole.farmer,
          UserRole.paravet,
          UserRole.veterinarian,
          UserRole.dairyCoop,
          UserRole.stateAdmin,
          UserRole.superAdmin,
        },
      ),

      // ── Diagnosis (AI Triage & Sudden Death / Mortality) ──────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Diagnosis',
          icon: PhosphorIconsRegular.stethoscope,
          activeIcon: PhosphorIconsFill.stethoscope,
        ),
        screen: const DiagnosisDashboardScreen(),
        roles: {
          UserRole.farmer,
          UserRole.paravet,
          UserRole.veterinarian,
          UserRole.superAdmin,
        },
      ),

      // ── Vet Clinic (Cases, Prescriptions, Telemedicine) ───────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Vet Clinic',
          icon: PhosphorIconsRegular.firstAid,
          activeIcon: PhosphorIconsFill.firstAid,
        ),
        screen: const VeterinarianWorkspaceScreen(),
        roles: {
          UserRole.veterinarian,
          UserRole.dvoOfficer,
          UserRole.stateAdmin,
          UserRole.superAdmin,
        },
      ),

      // ── Lab Diagnostics (Samples, PCR/ELISA, SDDL Referral) ────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Lab Diagnostics',
          icon: PhosphorIconsRegular.testTube,
          activeIcon: PhosphorIconsFill.testTube,
        ),
        screen: const LabWorkspaceScreen(),
        roles: {
          UserRole.labTechnician,
          UserRole.veterinarian,
          UserRole.dvoOfficer,
          UserRole.stateAdmin,
          UserRole.superAdmin,
        },
      ),

      // ── Vaccinations & Drives ──────────────────────────────────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Vaccinations',
          icon: PhosphorIconsRegular.syringe,
          activeIcon: PhosphorIconsFill.syringe,
        ),
        screen: const VaccinationDrivesScreen(),
        roles: {
          UserRole.paravet,
          UserRole.veterinarian,
          UserRole.dvoOfficer,
          UserRole.stateAdmin,
          UserRole.superAdmin,
        },
      ),

      // ── Surveillance (GIS Heatmap, Weather & Historical) ───────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Surveillance',
          icon: PhosphorIconsRegular.mapTrifold,
          activeIcon: PhosphorIconsFill.mapTrifold,
        ),
        screen: const SurveillanceMapScreen(),
        roles: {
          UserRole.veterinarian,
          UserRole.dvoOfficer,
          UserRole.stateAdmin,
          UserRole.superAdmin,
        },
      ),

      // ── Alerts & Advisories (Multilingual Biosecurity) ──────────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'Alerts',
          icon: PhosphorIconsRegular.broadcast,
          activeIcon: PhosphorIconsFill.broadcast,
        ),
        screen: const AdvisoriesBroadcastScreen(),
        roles: UserRole.values.toSet(), // All roles receive or manage alerts
      ),

      // ── Telecom & Offline Tools (1800 IVR / SMS / Sync) ────────
      _RoleTab(
        item: const NavigationTabItem(
          label: 'IVR / Offline',
          icon: PhosphorIconsRegular.phoneCall,
          activeIcon: PhosphorIconsFill.phoneCall,
        ),
        screen: const TelecomOfflineScreen(),
        roles: {
          UserRole.farmer,
          UserRole.paravet,
          UserRole.superAdmin,
        },
      ),

      // ── Account ────────────────────────────────────────────────
      _RoleTab(
        item: NavigationTabItem(
          label: 'Account',
          icon: PhosphorIconsRegular.userCircle,
          activeIcon: PhosphorIconsFill.userCircle,
        ),
        screen: ProfileScreen(
          onLocaleChanged: widget.onLocaleChanged,
          onThemeModeChanged: widget.onThemeModeChanged,
          currentThemeMode: widget.currentThemeMode,
          currentLocale: widget.currentLocale,
        ),
        roles: UserRole.values.toSet(), // all roles
      ),
    ];

    return all.where((t) => t.roles.contains(role)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabsForRole(widget.user.role);

    // Clamp index if role switch reduced tab count
    final safeIndex = _currentTabIndex.clamp(0, tabs.length - 1);

    return Stack(
      children: [
        BioHerdShell(
          currentIndex: safeIndex,
          onTabSelected: (i) => setState(() => _currentTabIndex = i),
          tabs: tabs.map((t) => t.item).toList(),
          user: widget.user,
          body: Column(
            children: [
              // Demo mode banner
              if (widget.isDemoMode) const _DemoModeBanner(),
              Expanded(
                child: IndexedStack(
                  index: safeIndex,
                  children: tabs.map((t) => t.screen).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleTab {
  final NavigationTabItem item;
  final Widget screen;
  final Set<UserRole> roles;

  const _RoleTab({
    required this.item,
    required this.screen,
    required this.roles,
  });
}

// ─── Demo Mode Banner ─────────────────────────────────────────────

class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE65100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.lightningSlash, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '⚡ DEMO MODE — No backend connected. All data is simulated.',
              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutSubmitted()),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: Size.zero,
            ),
            child: const Text('Exit', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
