enum UserRole {
  farmer,
  veterinarian,
  dairyCoop,
  dvoOfficer,
  stateAdmin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'farmer':
        return UserRole.farmer;
      case 'veterinarian':
        return UserRole.veterinarian;
      case 'dairy_coop':
      case 'dairy_cooperative':
        return UserRole.dairyCoop;
      case 'dvo_officer':
        return UserRole.dvoOfficer;
      case 'state_admin':
        return UserRole.stateAdmin;
      default:
        return UserRole.farmer;
    }
  }

  String toBackendString() {
    switch (this) {
      case UserRole.farmer:
        return 'farmer';
      case UserRole.veterinarian:
        return 'veterinarian';
      case UserRole.dairyCoop:
        return 'dairy_coop';
      case UserRole.dvoOfficer:
        return 'dvo_officer';
      case UserRole.stateAdmin:
        return 'state_admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer (शेतकरी)';
      case UserRole.veterinarian:
        return 'Veterinarian (पशुवैद्यक)';
      case UserRole.dairyCoop:
        return 'Dairy Cooperative (दुग्ध संस्था)';
      case UserRole.dvoOfficer:
        return 'DVO Officer (जिल्हा अधिकारी)';
      case UserRole.stateAdmin:
        return 'State Admin';
    }
  }
}

class UserModel {
  final String id;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final String district;
  final bool twoFactorEnabled;
  final bool isActive;
  final String? email;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.district,
    this.twoFactorEnabled = false,
    this.isActive = true,
    this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'farmer'),
      district: json['district']?.toString() ?? 'Pune',
      twoFactorEnabled: json['two_factor_enabled'] == true,
      isActive: json['is_active'] != false,
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'role': role.toBackendString(),
      'district': district,
      'two_factor_enabled': twoFactorEnabled,
      'is_active': isActive,
      'email': email,
    };
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresIn = 3600,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
    };
  }
}

class AuthResponse {
  final bool requires2FA;
  final String? tempToken;
  final AuthTokens? tokens;
  final UserModel? user;
  final String? message;

  const AuthResponse({
    this.requires2FA = false,
    this.tempToken,
    this.tokens,
    this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final requires2FA = json['requires_2fa'] == true;
    if (requires2FA) {
      return AuthResponse(
        requires2FA: true,
        tempToken: json['temp_token']?.toString(),
        message: json['message']?.toString() ?? '2FA verification code required',
      );
    }

    final tokens = json['tokens'] != null
        ? AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>)
        : (json['access_token'] != null ? AuthTokens.fromJson(json) : null);

    final user = json['user'] != null
        ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
        : null;

    return AuthResponse(
      requires2FA: false,
      tokens: tokens,
      user: user,
      message: json['message']?.toString(),
    );
  }
}
