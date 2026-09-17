import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bioherd/features/auth/data/auth_repository.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<Auth2FAVerificationSubmitted>(_onAuth2FAVerificationSubmitted);
    on<AuthRegisterSubmitted>(_onAuthRegisterSubmitted);
    on<AuthLogoutSubmitted>(_onAuthLogoutSubmitted);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking session...'));
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Authenticating...'));
    try {
      final response = await authRepository.login(
        phone: event.phone,
        password: event.password,
      );

      if (response.requires2FA && response.tempToken != null) {
        emit(AuthRequires2FA(
          tempToken: response.tempToken!,
          phone: event.phone,
          message: response.message,
        ));
      } else if (response.user != null) {
        emit(AuthAuthenticated(user: response.user!));
      } else {
        emit(const AuthUnauthenticated(errorMessage: 'Login failed to return user'));
      }
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(AuthUnauthenticated(errorMessage: 'Authentication error: $e'));
    }
  }

  Future<void> _onAuth2FAVerificationSubmitted(
    Auth2FAVerificationSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Verifying 2FA code...'));
    try {
      final response = await authRepository.verify2FA(
        tempToken: event.tempToken,
        code: event.code,
      );

      if (response.user != null) {
        emit(AuthAuthenticated(user: response.user!));
      } else {
        emit(const AuthUnauthenticated(errorMessage: 'Verification succeeded but user data missing'));
      }
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(AuthUnauthenticated(errorMessage: '2FA verification error: $e'));
    }
  }

  Future<void> _onAuthRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));
    try {
      final user = await authRepository.register(
        phone: event.phone,
        password: event.password,
        fullName: event.fullName,
        role: event.role,
        district: event.district,
        email: event.email,
      );

      emit(AuthRegisterSuccess(
        message: 'Account created for ${user.fullName}. Please login.',
      ));
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(AuthUnauthenticated(errorMessage: 'Registration failed: $e'));
    }
  }

  Future<void> _onAuthLogoutSubmitted(
    AuthLogoutSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
