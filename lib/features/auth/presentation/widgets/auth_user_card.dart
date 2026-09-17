import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/hallmark_tokens.dart';
import 'package:bioherd/core/widgets/bioherd_badge.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_event.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

class AuthUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onLogout;

  const AuthUserCard({
    super.key,
    required this.user,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? HallmarkTokens.darkSurface : HallmarkTokens.surfaceCard;
    final textColor = isDark ? HallmarkTokens.darkTextPrimary : HallmarkTokens.textPrimary;
    final subtextColor = isDark ? HallmarkTokens.darkTextSecondary : HallmarkTokens.textSecondary;

    return Container(
      padding: const EdgeInsets.all(HallmarkTokens.spaceLg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(HallmarkTokens.radiusLg),
        border: Border.all(
          color: isDark ? HallmarkTokens.darkBorder : HallmarkTokens.surfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: HallmarkTokens.forestMoss,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: HallmarkTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BioHerdBadge(
                          label: user.role.toBackendString().toUpperCase(),
                          variant: _getBadgeVariant(user.role),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+91 ${user.phoneNumber} • ${user.district}, MH',
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HallmarkTokens.spaceMd),
          const Divider(height: 1),
          const SizedBox(height: HallmarkTokens.spaceMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    user.twoFactorEnabled
                        ? PhosphorIconsFill.shieldCheck
                        : PhosphorIconsRegular.shieldWarning,
                    color: user.twoFactorEnabled
                        ? HallmarkTokens.forestMoss
                        : HallmarkTokens.terracotta,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.twoFactorEnabled
                        ? '2FA Security: Active'
                        : '2FA Security: Recommended',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user.twoFactorEnabled
                          ? HallmarkTokens.forestMoss
                          : HallmarkTokens.terracotta,
                    ),
                  ),
                ],
              ),
              BioHerdButton(
                key: const Key('auth_logout_button'),
                label: 'Sign Out',
                variant: BioHerdButtonVariant.secondary,
                isFullWidth: false,
                icon: const Icon(PhosphorIconsRegular.signOut, size: 16),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutSubmitted());
                  onLogout?.call();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  BioHerdBadgeVariant _getBadgeVariant(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return BioHerdBadgeVariant.success;
      case UserRole.veterinarian:
        return BioHerdBadgeVariant.info;
      case UserRole.dairyCoop:
        return BioHerdBadgeVariant.warning;
      case UserRole.dvoOfficer:
      case UserRole.stateAdmin:
        return BioHerdBadgeVariant.critical;
    }
  }
}
