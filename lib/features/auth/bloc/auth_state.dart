import '../models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});
}

class AuthUnauthenticated extends AuthState {
  final String? errorMessage;
  const AuthUnauthenticated({this.errorMessage});
}

class AuthRequires2FA extends AuthState {
  final String tempToken;
  final String phone;
  final String? message;

  const AuthRequires2FA({
    required this.tempToken,
    required this.phone,
    this.message,
  });
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});
}

class AuthRegisterSuccess extends AuthState {
  final String message;
  const AuthRegisterSuccess({required this.message});
}
