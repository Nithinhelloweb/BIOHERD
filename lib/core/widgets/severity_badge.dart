import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum SeverityLevel { low, medium, high, critical }

/// SeverityBadge
/// Compact status pill indicating disease or incident triage priority.
/// Features pulsing dot for High severity and entrance shake for Critical severity.
class SeverityBadge extends StatefulWidget {
  final SeverityLevel level;
  final String? customLabel;

  const SeverityBadge({
    super.key,
    SeverityLevel? level,
    SeverityLevel? severity,
    this.customLabel,
  }) : level = level ?? severity ?? SeverityLevel.low;

  @override
  State<SeverityBadge> createState() => _SeverityBadgeState();
}

class _SeverityBadgeState extends State<SeverityBadge> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for High severity
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.level == SeverityLevel.high) {
      _pulseController.repeat(reverse: true);
    }

    // Shake animation for Critical severity
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    if (widget.level == SeverityLevel.critical) {
      _shakeController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SeverityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level == SeverityLevel.high && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.level != SeverityLevel.high && _pulseController.isAnimating) {
      _pulseController.stop();
    }

    if (widget.level == SeverityLevel.critical) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (widget.level) {
      case SeverityLevel.low:
        bg = AppColors.success100;
        fg = AppColors.success600;
        label = widget.customLabel ?? 'LOW';
        break;
      case SeverityLevel.medium:
        bg = AppColors.warning100;
        fg = AppColors.warning600;
        label = widget.customLabel ?? 'MEDIUM';
        break;
      case SeverityLevel.high:
        bg = AppColors.danger100;
        fg = AppColors.danger600;
        label = widget.customLabel ?? 'HIGH';
        break;
      case SeverityLevel.critical:
        bg = AppColors.danger600;
        fg = Colors.white;
        label = widget.customLabel ?? 'CRITICAL';
        break;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.level == SeverityLevel.high) ...[
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.danger600,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.label(color: fg).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (widget.level == SeverityLevel.critical) {
      return AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final offset = math.sin(_shakeAnimation.value * math.pi * 4) * 4.0;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: badge,
      );
    }

    return badge;
  }
}
