import 'package:flutter/material.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  final String phone;
  final String password;

  const AuthLoginSubmitted({
    required this.phone,
    required this.password,
  });
}

class Auth2FAVerificationSubmitted extends AuthEvent {
  final String tempToken;
  final String code;

  const Auth2FAVerificationSubmitted({
    required this.tempToken,
    required this.code,
  });
}

class AuthRegisterSubmitted extends AuthEvent {
  final String phone;
  final String password;
  final String fullName;
  final String role;
  final String district;
  final String? email;

  const AuthRegisterSubmitted({
    required this.phone,
    required this.password,
    required this.fullName,
    required this.role,
    required this.district,
    this.email,
  });
}

class AuthLogoutSubmitted extends AuthEvent {
  const AuthLogoutSubmitted();
}

class AuthLanguageChanged extends AuthEvent {
  final Locale locale;
  const AuthLanguageChanged(this.locale);
}
