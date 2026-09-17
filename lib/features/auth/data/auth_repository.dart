import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bioherd/core/services/auth_storage_service.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, [this.statusCode]);

  @override
  String toString() => 'AuthException: $message (code: $statusCode)';
}

class AuthRepository {
  final String baseUrl;
  final http.Client _client;
  final AuthStorageService storage;

  AuthRepository({
    this.baseUrl = 'http://127.0.0.1:8000/api/v1/auth',
    http.Client? client,
    required this.storage,
  }) : _client = client ?? http.Client();

  Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phone,
          'password': password,
          'device_fingerprint': 'bioherd-flutter-client',
        }),
      );

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
        throw AuthException('Too many login attempts. Please wait 1 minute.', 429);
      } else {
        final detail = data['detail'] ?? 'Login failed';
        throw AuthException(detail.toString(), response.statusCode);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Connection error. Please verify backend is running ($e)');
    }
  }

  Future<AuthResponse> verify2FA({
    required String tempToken,
    required String code,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/verify-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temp_token': tempToken,
          'totp_code': code,
        }),
      );

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
      final response = await _client.post(
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
      );

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
      throw AuthException('Registration network error: $e');
    }
  }

  Future<AuthTokens?> refreshToken() async {
    final currentRefresh = storage.getRefreshToken();
    if (currentRefresh == null) return null;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': currentRefresh}),
      );

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
      return null;
    }
  }

  Future<void> logout() async {
    final accessToken = storage.getAccessToken();
    if (accessToken != null) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
      } catch (_) {
        // Clear local storage regardless
      }
    }
    await storage.clearAuth();
  }

  Future<UserModel?> getCurrentUser() async {
    final cached = storage.getUser();
    final accessToken = storage.getAccessToken();

    if (accessToken == null) return null;

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = UserModel.fromJson(data);
        await storage.saveUser(user);
        return user;
      } else if (response.statusCode == 401) {
        // Attempt refresh
        final newTokens = await refreshToken();
        if (newTokens != null) {
          return getCurrentUser();
        }
      }
    } catch (_) {
      // Offline fallback: return cached user
      return cached;
    }

    return cached;
  }
}
