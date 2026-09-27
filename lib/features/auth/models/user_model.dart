enum UserRole {
  farmer,
  paravet,
  veterinarian,
  labTechnician,
  dairyCoop,
  dvoOfficer,
  stateAdmin,
  superAdmin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'farmer':
        return UserRole.farmer;
      case 'paravet':
      case 'field_worker':
        return UserRole.paravet;
      case 'veterinarian':
        return UserRole.veterinarian;
      case 'lab_technician':
      case 'labtechnician':
      case 'lab_tech':
        return UserRole.labTechnician;
      case 'dairy_coop':
      case 'dairy_cooperative':
        return UserRole.dairyCoop;
      case 'dvo_officer':
      case 'district_official':
        return UserRole.dvoOfficer;
      case 'state_admin':
      case 'state_official':
        return UserRole.stateAdmin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.farmer;
    }
  }

  String toBackendString() {
    switch (this) {
      case UserRole.farmer:
        return 'farmer';
      case UserRole.paravet:
        return 'paravet';
      case UserRole.veterinarian:
        return 'veterinarian';
      case UserRole.labTechnician:
        return 'lab_technician';
      case UserRole.dairyCoop:
        return 'dairy_coop';
      case UserRole.dvoOfficer:
        return 'district_official';
      case UserRole.stateAdmin:
        return 'state_admin';
      case UserRole.superAdmin:
        return 'super_admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.paravet:
        return 'Para-Vet (Field Worker)';
      case UserRole.veterinarian:
        return 'Field Veterinarian';
      case UserRole.labTechnician:
        return 'Lab Technician';
      case UserRole.dairyCoop:
        return 'Dairy Cooperative';
      case UserRole.dvoOfficer:
        return 'District Vet Officer';
      case UserRole.stateAdmin:
        return 'State Official';
      case UserRole.superAdmin:
        return 'Super Administrator';
    }
  }
}

class UserModel {
  final String id;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final String district;
  final String state;
  final String? block;
  final String? village;
  final String? labId;
  final bool twoFactorEnabled;
  final bool isActive;
  final String? email;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.district,
    this.state = 'Maharashtra',
    this.block,
    this.village,
    this.labId,
    this.twoFactorEnabled = false,
    this.isActive = true,
    this.email,
  });

  String get name => fullName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'farmer'),
      district: json['district']?.toString() ?? json['district_id']?.toString() ?? 'Pune',
      state: json['state']?.toString() ?? 'Maharashtra',
      block: json['block']?.toString(),
      village: json['village']?.toString(),
      labId: json['lab_id']?.toString(),
      twoFactorEnabled: json['two_factor_enabled'] == true || json['is_2fa_enabled'] == true,
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
      'state': state,
      'block': block,
      'village': village,
      'lab_id': labId,
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
