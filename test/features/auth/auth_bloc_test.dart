import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioherd/core/services/auth_storage_service.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/data/auth_repository.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthStorageService Tests', () {
    test('Stores and retrieves tokens and user data cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorageService(prefs);

      expect(storage.isAuthenticated, false);
      expect(storage.getAccessToken(), isNull);
      expect(storage.getUser(), isNull);

      await storage.saveTokens(
        accessToken: 'mock-access-jwt',
        refreshToken: 'mock-refresh-jwt',
      );

      expect(storage.isAuthenticated, true);
      expect(storage.getAccessToken(), 'mock-access-jwt');
      expect(storage.getRefreshToken(), 'mock-refresh-jwt');

      const user = UserModel(
        id: 'usr-123',
        phoneNumber: '9876543210',
        fullName: 'Ramesh Patil',
        role: UserRole.farmer,
        district: 'Pune',
      );

      await storage.saveUser(user);
      final retrieved = storage.getUser();
      expect(retrieved, isNotNull);
      expect(retrieved!.fullName, 'Ramesh Patil');
      expect(retrieved.role, UserRole.farmer);
      expect(retrieved.district, 'Pune');

      await storage.clearAuth();
      expect(storage.isAuthenticated, false);
      expect(storage.getAccessToken(), isNull);
      expect(storage.getUser(), isNull);
    });
  });

  group('AuthBloc & Repository Tests', () {
    late SharedPreferences prefs;
    late AuthStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = AuthStorageService(prefs);
    });

    test('AuthCheckRequested emits AuthUnauthenticated when storage is empty', () async {
      final repo = AuthRepository(storage: storage);
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const AuthCheckRequested());
    });

    test('AuthLoginSubmitted emits AuthAuthenticated on standard successful login', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt-access-token',
              'refresh_token': 'jwt-refresh-token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'requires_2fa': false,
              'user': {
                'id': 'u1',
                'phone_number': '9876543210',
                'full_name': 'Ramesh Patil',
                'role': 'farmer',
                'district': 'Pune',
                'two_factor_enabled': false,
                'is_active': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = AuthRepository(client: mockClient, storage: storage);
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        predicate<AuthState>((state) {
          if (state is AuthAuthenticated) {
            return state.user.fullName == 'Ramesh Patil' &&
                state.user.role == UserRole.farmer;
          }
          return false;
        }),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const AuthLoginSubmitted(
        phone: '9876543210',
        password: 'FarmerPass123!',
      ));
    });

    test('AuthLoginSubmitted emits AuthRequires2FA when 2FA is active', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({
              'requires_2fa': true,
              'temp_token': 'temp-challenge-2fa-token',
              'message': '2FA verification code required',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = AuthRepository(client: mockClient, storage: storage);
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        predicate<AuthState>((state) {
          if (state is AuthRequires2FA) {
            return state.tempToken == 'temp-challenge-2fa-token' &&
                state.phone == '9876543210';
          }
          return false;
        }),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const AuthLoginSubmitted(
        phone: '9876543210',
        password: 'FarmerPass123!',
      ));
    });

    test('Auth2FAVerificationSubmitted completes login with valid code', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/verify-2fa')) {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt-verified-access',
              'refresh_token': 'jwt-verified-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'requires_2fa': false,
              'user': {
                'id': 'u1',
                'phone_number': '9876543210',
                'full_name': 'Ramesh Patil',
                'role': 'farmer',
                'district': 'Pune',
                'two_factor_enabled': true,
                'is_active': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = AuthRepository(client: mockClient, storage: storage);
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        predicate<AuthState>((state) {
          if (state is AuthAuthenticated) {
            return state.user.twoFactorEnabled == true;
          }
          return false;
        }),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const Auth2FAVerificationSubmitted(
        tempToken: 'temp-token',
        code: '123456',
      ));
    });

    test('AuthRegisterSubmitted emits AuthRegisterSuccess', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/register')) {
          return http.Response(
            jsonEncode({
              'id': 'new-u',
              'phone_number': '9876543299',
              'full_name': 'Anil Deshmukh',
              'role': 'veterinarian',
              'district': 'Kolhapur',
              'two_factor_enabled': false,
              'is_active': true,
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = AuthRepository(client: mockClient, storage: storage);
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        isA<AuthRegisterSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const AuthRegisterSubmitted(
        phone: '9876543299',
        password: 'PassWord123!',
        fullName: 'Anil Deshmukh',
        role: 'veterinarian',
        district: 'Kolhapur',
      ));
    });

    test('AuthLogoutSubmitted clears auth and emits AuthUnauthenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Logged out successfully'}), 200);
      });

      await storage.saveTokens(accessToken: 'tk', refreshToken: 'rf');
      final repo = AuthRepository(client: mockClient, storage: storage);
      final bloc = AuthBloc(authRepository: repo);

      final expectedStates = [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const AuthLogoutSubmitted());
    });
  });
}
