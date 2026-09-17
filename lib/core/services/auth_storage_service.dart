import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';

class AuthStorageService {
  static const String _keyAccessToken = 'bioherd_access_token';
  static const String _keyRefreshToken = 'bioherd_refresh_token';
  static const String _keyUserData = 'bioherd_user_data';

  final SharedPreferences _prefs;

  AuthStorageService(this._prefs);

  static Future<AuthStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthStorageService(prefs);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
  }

  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_keyUserData, userJson);
  }

  UserModel? getUser() {
    final data = _prefs.getString(_keyUserData);
    if (data == null || data.isEmpty) return null;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserData);
  }

  bool get isAuthenticated {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
