import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/services/auth_storage_service.dart';
import 'package:bioherd/core/theme/app_theme.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/data/auth_repository.dart';
import 'package:bioherd/features/auth/models/user_model.dart';
import 'package:bioherd/features/auth/presentation/login_screen.dart';
import 'package:bioherd/features/auth/presentation/register_screen.dart';
import 'package:bioherd/features/auth/presentation/widgets/auth_user_card.dart';
import 'package:bioherd/features/auth/presentation/widgets/two_factor_dialog.dart';
import 'package:bioherd/l10n/app_localizations.dart';

Widget createTestWidget({required Widget child, required AuthBloc authBloc}) {
  return BlocProvider.value(
    value: authBloc,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('mr', ''),
        Locale('hi', ''),
      ],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthStorageService storage;
  late AuthRepository repo;
  late AuthBloc authBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = AuthStorageService(prefs);
    repo = AuthRepository(storage: storage);
    authBloc = AuthBloc(authRepository: repo);
  });

  tearDown(() {
    authBloc.close();
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders phone field, password field, and submit button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        authBloc: authBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.text('BIOHERD'), findsOneWidget);
      expect(find.byKey(const Key('login_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('⚡ Quick Demo Login Credentials:'), findsOneWidget);
    });

    testWidgets('Tapping demo preset fills phone and password fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        authBloc: authBloc,
      ));
      await tester.pumpAndSettle();

      final vetPreset = find.text('Veterinarian');
      expect(vetPreset, findsOneWidget);
      await tester.ensureVisible(vetPreset);
      await tester.tap(vetPreset);
      await tester.pump();

      final phoneField = tester.widget<TextFormField>(find.byKey(const Key('login_phone_field')));
      expect(phoneField.controller?.text, '9876543211');
    });

    testWidgets('Validation shows error when phone length is less than 10 digits', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        authBloc: authBloc,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login_phone_field')), '12345');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'Secret123!');
      final submitButton = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Please enter a valid 10-digit phone number'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders full name, role dropdown, Maharashtra districts and register button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        authBloc: authBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_role_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('register_district_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
    });
  });

  group('TwoFactorDialog Widget Tests', () {
    testWidgets('Submits 6 digit OTP when entered', (tester) async {
      String? submittedCode;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TwoFactorDialog(
            phoneNumber: '9876543210',
            onVerify: (code) => submittedCode = code,
            onCancel: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Two-Factor Verification'), findsOneWidget);
      expect(find.text('2-Step Security for +91 9876543210'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '654321');
      await tester.pump();

      expect(submittedCode, '654321');
    });
  });

  group('AuthUserCard Widget Tests', () {
    testWidgets('Displays authenticated farmer details and sign out button', (tester) async {
      const user = UserModel(
        id: 'u-1',
        phoneNumber: '9876543210',
        fullName: 'Ramesh Patil',
        role: UserRole.farmer,
        district: 'Pune',
        twoFactorEnabled: true,
      );

      await tester.pumpWidget(createTestWidget(
        child: const Scaffold(body: AuthUserCard(user: user)),
        authBloc: authBloc,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.text('+91 9876543210 • Pune, MH'), findsOneWidget);
      expect(find.text('FARMER'), findsOneWidget);
      expect(find.text('2FA Security: Active'), findsOneWidget);
      expect(find.byKey(const Key('auth_logout_button')), findsOneWidget);
    });
  });
}
