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
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/showcase/presentation/showcase_screen.dart';
import 'features/surveillance/bloc/surveillance_bloc.dart';
import 'features/surveillance/data/surveillance_repository.dart';
import 'features/surveillance/presentation/surveillance_map_screen.dart';
import 'features/symptoms/bloc/symptom_bloc.dart';
import 'features/symptoms/data/symptom_repository.dart';
import 'features/symptoms/presentation/diagnosis_dashboard_screen.dart';
import 'features/veterinary/bloc/veterinary_bloc.dart';
import 'features/veterinary/data/veterinary_repository.dart';
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
  int _currentTabIndex = 0;

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

    // Provide repository or fallback in test environments
    if (widget.veterinaryRepository != null) {
      _veterinaryRepository = widget.veterinaryRepository!;
    } else {
      // In-memory / dummy fallback for tests without explicit repo
      _initFallbackRepo();
    }
    _veterinaryBloc = VeterinaryBloc(repository: _veterinaryRepository);
    _veterinaryBloc.add(const LoadCasesEvent());
  }

  void _initFallbackRepo() {
    // If running in a test where SharedPreferences is mocked
    SharedPreferences.getInstance().then((prefs) {
      // already initialized in fallback mode
    });
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
            Locale('en', ''), // English
            Locale('mr', ''), // Marathi (मराठी)
            Locale('hi', ''), // Hindi (हिंदी)
          ],
          home: BioHerdShell(
            currentIndex: _currentTabIndex,
            onTabSelected: (index) => setState(() => _currentTabIndex = index),
            tabs: const [
              NavigationTabItem(
                label: 'Design System',
                icon: PhosphorIconsRegular.sparkle,
                activeIcon: PhosphorIconsFill.sparkle,
              ),
              NavigationTabItem(
                label: 'Animals',
                icon: PhosphorIconsRegular.cow,
                activeIcon: PhosphorIconsFill.cow,
              ),
              NavigationTabItem(
                label: 'Diagnosis',
                icon: PhosphorIconsRegular.stethoscope,
                activeIcon: PhosphorIconsFill.stethoscope,
              ),
              NavigationTabItem(
                label: 'Surveillance',
                icon: PhosphorIconsRegular.mapTrifold,
                activeIcon: PhosphorIconsFill.mapTrifold,
              ),
              NavigationTabItem(
                label: 'Vet Clinic',
                icon: PhosphorIconsRegular.firstAid,
                activeIcon: PhosphorIconsFill.firstAid,
              ),
              NavigationTabItem(
                label: 'Account',
                icon: PhosphorIconsRegular.userCircle,
                activeIcon: PhosphorIconsFill.userCircle,
              ),
            ],
            body: IndexedStack(
              index: _currentTabIndex,
              children: [
                ShowcaseScreen(
                  onLocaleChanged: _changeLocale,
                  onThemeModeChanged: _changeThemeMode,
                  currentThemeMode: _themeMode,
                  currentLocale: _locale,
                ),
                const AnimalListScreen(),
                const DiagnosisDashboardScreen(),
                const SurveillanceMapScreen(),
                const VeterinarianWorkspaceScreen(),
                ProfileScreen(
                  onLocaleChanged: _changeLocale,
                  onThemeModeChanged: _changeThemeMode,
                  currentThemeMode: _themeMode,
                  currentLocale: _locale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
