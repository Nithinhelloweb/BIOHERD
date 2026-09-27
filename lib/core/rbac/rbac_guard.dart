import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bioherd/core/rbac/permission.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

/// Widget guard that conditionally shows [child] based on the
/// current user's role and the required [permission].
///
/// Usage:
/// ```dart
/// RbacGuard(
///   permission: Permission.declareQuarantine,
///   child: DeclareQuarantineButton(),
///   fallback: const SizedBox.shrink(),  // hide if not allowed
/// )
/// ```
class RbacGuard extends StatelessWidget {
  final Permission permission;
  final Widget child;

  /// Widget to show when the user does NOT have the permission.
  /// Defaults to [SizedBox.shrink()] (hidden).
  final Widget? fallback;

  /// If true, shows a lock icon tooltip instead of hiding.
  final bool showLockedState;

  const RbacGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showLockedState = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          (prev is AuthAuthenticated) != (curr is AuthAuthenticated),
      builder: (context, state) {
        UserRole? role;
        if (state is AuthAuthenticated) {
          role = state.user.role;
        }

        final allowed = role != null && RbacService.hasPermission(role, permission);

        if (allowed) return child;

        if (showLockedState && role != null) {
          return Tooltip(
            message: 'Requires ${_requiredRoleLabel(permission)} access',
            child: Opacity(
              opacity: 0.38,
              child: IgnorePointer(child: child),
            ),
          );
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }

  String _requiredRoleLabel(Permission p) {
    switch (p) {
      case Permission.declareOutbreak:
      case Permission.declareQuarantine:
      case Permission.exportReports:
      case Permission.viewAllDistricts:
        return 'DVO Officer or State Admin';
      case Permission.prescribeTreatment:
      case Permission.recordVaccination:
        return 'Veterinarian';
      case Permission.manageUsers:
      case Permission.viewSystemHealth:
      case Permission.seedMockData:
        return 'State Admin';
      default:
        return 'higher privilege';
    }
  }
}

/// Multi-permission variant — requires ANY of the listed permissions.
class RbacAnyGuard extends StatelessWidget {
  final List<Permission> permissions;
  final Widget child;
  final Widget? fallback;

  const RbacAnyGuard({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        UserRole? role;
        if (state is AuthAuthenticated) {
          role = state.user.role;
        }

        final allowed = role != null &&
            RbacService.hasAnyPermission(role, permissions);

        return allowed ? child : (fallback ?? const SizedBox.shrink());
      },
    );
  }
}
