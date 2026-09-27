import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bioherd/features/auth/data/auth_repository.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<Auth2FAVerificationSubmitted>(_onAuth2FAVerificationSubmitted);
    on<AuthRegisterSubmitted>(_onAuthRegisterSubmitted);
    on<AuthLogoutSubmitted>(_onAuthLogoutSubmitted);
    on<DemoLoginRequested>(_onDemoLoginRequested);
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
      emit(AuthUnauthenticated(errorMessage: e.message, isOfflineError: e.isOffline));
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
      emit(AuthUnauthenticated(errorMessage: e.message, isOfflineError: e.isOffline));
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

  Future<void> _onDemoLoginRequested(
    DemoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Starting demo session...'));
    final demoUser = _buildDemoUser(event.role);
    await authRepository.saveDemoUser(demoUser);
    emit(AuthAuthenticated(user: demoUser, isDemoMode: true));
  }

  UserModel _buildDemoUser(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const UserModel(
          id: 'demo-farmer-001',
          phoneNumber: '+91 9876543210',
          fullName: 'Ramesh Patil',
          role: UserRole.farmer,
          district: 'Pune',
          block: 'Haveli',
          village: 'Wagholi',
          twoFactorEnabled: false,
          isActive: true,
        );
      case UserRole.paravet:
        return const UserModel(
          id: 'demo-paravet-001',
          phoneNumber: '+91 9876543214',
          fullName: 'Ganesh More (Pashu Sakha)',
          role: UserRole.paravet,
          district: 'Pune',
          block: 'Haveli',
          village: 'Wagholi',
          twoFactorEnabled: false,
          isActive: true,
        );
      case UserRole.veterinarian:
        return const UserModel(
          id: 'demo-vet-001',
          phoneNumber: '+91 9876501234',
          fullName: 'Dr. Anjali Deshmukh',
          role: UserRole.veterinarian,
          district: 'Pune',
          block: 'Haveli',
          twoFactorEnabled: true,
          isActive: true,
          email: 'dr.anjali@ahd.mh.gov.in',
        );
      case UserRole.labTechnician:
        return const UserModel(
          id: 'demo-lab-001',
          phoneNumber: '+91 9876543215',
          fullName: 'Dr. Vikram Joshi (Lab Tech)',
          role: UserRole.labTechnician,
          district: 'Pune',
          block: 'Haveli',
          labId: 'DIS-LAB-PUNE-01',
          twoFactorEnabled: true,
          isActive: true,
          email: 'lab.pune@ahd.mh.gov.in',
        );
      case UserRole.dvoOfficer:
        return const UserModel(
          id: 'demo-dvo-001',
          phoneNumber: '+91 9876509876',
          fullName: 'Rajesh Shinde (DVO Ahmednagar)',
          role: UserRole.dvoOfficer,
          district: 'Ahmednagar',
          twoFactorEnabled: true,
          isActive: true,
          email: 'dvo.ahmednagar@ahd.mh.gov.in',
        );
      case UserRole.stateAdmin:
        return const UserModel(
          id: 'demo-admin-001',
          phoneNumber: '+91 9876500001',
          fullName: 'Dr. Suresh Kulkarni (State Official)',
          role: UserRole.stateAdmin,
          district: 'Mumbai',
          state: 'Maharashtra',
          twoFactorEnabled: true,
          isActive: true,
          email: 'commissioner@ahd.mh.gov.in',
        );
      case UserRole.superAdmin:
        return const UserModel(
          id: 'demo-superadmin-001',
          phoneNumber: '+91 9876543299',
          fullName: 'Super Administrator',
          role: UserRole.superAdmin,
          district: 'Pune',
          twoFactorEnabled: true,
          isActive: true,
          email: 'superadmin@bioherd.in',
        );
      case UserRole.dairyCoop:
        return const UserModel(
          id: 'demo-dairy-001',
          phoneNumber: '+91 9876500099',
          fullName: 'Kolhapur Dairy Cooperative',
          role: UserRole.dairyCoop,
          district: 'Kolhapur',
          twoFactorEnabled: false,
          isActive: true,
          email: 'info@kolhapurdairy.com',
        );
    }
  }
}
