import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bioherd/core/services/auth_storage_service.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final bool isOffline;

  const AuthException(this.message, [this.statusCode, this.isOffline = false]);

  @override
  String toString() => 'AuthException: $message (code: $statusCode)';
}

class AuthRepository {
  final String baseUrl;
  final http.Client _client;
  final AuthStorageService storage;

  /// Timeout for all HTTP calls. Keep short to fail fast in offline mode.
  static const _kTimeout = Duration(seconds: 8);

  AuthRepository({
    this.baseUrl = 'http://127.0.0.1:8000/api/v1/auth',
    http.Client? client,
    required this.storage,
  }) : _client = client ?? http.Client();

  // ─────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────

  bool _isNetworkError(Object e) {
    return e is SocketException ||
        e is HttpException ||
        e is OSError ||
        (e.toString().contains('Connection refused')) ||
        (e.toString().contains('Connection timed out')) ||
        (e.toString().contains('wsarecv')) ||
        (e.toString().contains('stream reading error'));
  }

  // ─────────────────────────────────────────────
  // Auth methods
  // ─────────────────────────────────────────────

  Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': phone,
              'password': password,
              'device_fingerprint': 'bioherd-flutter-client',
            }),
          )
          .timeout(_kTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);
        if (!authResponse.requires2FA && authResponse.tokens != null) {
          await storage.saveTokens(
            accessToken: authResponse.tokens!.accessToken,
            refreshToken: authResponse.tokens!.refreshToken,
          );
          if (authResponse.user != null) {
            await storage.saveUser(authResponse.user!);
          }
        }
        return authResponse;
      } else if (response.statusCode == 429) {
        throw const AuthException('Too many login attempts. Please wait 1 minute.', 429);
      } else {
        final detail = data['detail'] ?? 'Login failed';
        throw AuthException(detail.toString(), response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      if (_isNetworkError(e)) {
        throw AuthException(
          'Backend is offline. Use demo mode to explore the app.',
          null,
          true,
        );
      }
      throw AuthException('Connection error: $e');
    }
  }

  Future<AuthResponse> verify2FA({
    required String tempToken,
    required String code,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/verify-2fa'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'temp_token': tempToken,
              'totp_code': code,
            }),
          )
          .timeout(_kTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);
        if (authResponse.tokens != null) {
          await storage.saveTokens(
            accessToken: authResponse.tokens!.accessToken,
            refreshToken: authResponse.tokens!.refreshToken,
          );
          if (authResponse.user != null) {
            await storage.saveUser(authResponse.user!);
          }
        }
        return authResponse;
      } else {
        final detail = data['detail'] ?? '2FA verification failed';
        throw AuthException(detail.toString(), response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const AuthException('Cannot verify 2FA — backend offline.', null, true);
      }
      throw AuthException('Failed to verify 2FA code: $e');
    }
  }

  Future<UserModel> register({
    required String phone,
    required String password,
    required String fullName,
    required String role,
    required String district,
    String? email,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': phone,
              'password': password,
              'full_name': fullName,
              'role': role,
              'district': district,
              if (email != null && email.isNotEmpty) 'email': email,
            }),
          )
          .timeout(_kTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return UserModel.fromJson(data);
      } else {
        final detail = data['detail'] ?? 'Registration failed';
        throw AuthException(detail.toString(), response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const AuthException('Cannot register — backend offline.', null, true);
      }
      throw AuthException('Registration network error: $e');
    }
  }

  Future<AuthTokens?> refreshToken() async {
    final currentRefresh = storage.getRefreshToken();
    if (currentRefresh == null) return null;

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': currentRefresh}),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newTokens = AuthTokens.fromJson(data);
        await storage.saveTokens(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken,
        );
        return newTokens;
      } else {
        await storage.clearAuth();
        return null;
      }
    } catch (_) {
      // Offline — don't clear auth, just return null
      return null;
    }
  }

  Future<void> logout() async {
    final accessToken = storage.getAccessToken();
    if (accessToken != null) {
      try {
        await _client
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
            )
            .timeout(_kTimeout);
      } catch (_) {
        // Clear local storage regardless of network
      }
    }
    await storage.clearAuth();
  }

  /// Gets current user.
  /// Priority: 1) live API call  2) cached user (offline fallback)
  Future<UserModel?> getCurrentUser() async {
    final cached = storage.getUser();
    final accessToken = storage.getAccessToken();

    if (accessToken == null) {
      // No session at all — return null (unauthenticated)
      return null;
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = UserModel.fromJson(data);
        await storage.saveUser(user);
        return user;
      } else if (response.statusCode == 401) {
        final newTokens = await refreshToken();
        if (newTokens != null) {
          return getCurrentUser();
        }
        await storage.clearAuth();
        return null;
      }
    } catch (e) {
      // Offline fallback — serve cached user silently
      if (cached != null) return cached;
    }

    return cached;
  }

  /// Saves a demo user without any network call.
  /// Used by the demo login screen for 100% offline exploration.
  Future<void> saveDemoUser(UserModel user) async {
    await storage.saveUser(user);
    // Use a dummy token so getAccessToken() returns non-null
    await storage.saveTokens(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
    );
  }

  /// Checks if backend is reachable (lightweight ping).
  Future<bool> pingBackend() async {
    try {
      final response = await _client
          .get(Uri.parse(
            baseUrl.replaceAll('/auth', '/health'),
          ))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
