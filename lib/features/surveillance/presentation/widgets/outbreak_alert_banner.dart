import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import '../../models/surveillance_model.dart';
import 'quarantine_protocols_dialog.dart';

class OutbreakAlertBanner extends StatefulWidget {
  final SurveillanceAlertModel alert;
  final VoidCallback? onDismiss;

  const OutbreakAlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
  });

  @override
  State<OutbreakAlertBanner> createState() => _OutbreakAlertBannerState();
}

class _OutbreakAlertBannerState extends State<OutbreakAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.alert.severity == SeverityLevel.critical;
    final primaryColor = isCritical ? AppColors.alertRed : AppColors.alertAmber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 10 * _pulseAnimation.value,
                    height: 10 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.alert.titleEn,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onDismiss != null)
                InkWell(
                  onTap: widget.onDismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(PhosphorIconsRegular.x, size: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Marathi subtitle
          Text(
            widget.alert.titleMr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            widget.alert.bodyMr.isNotEmpty ? widget.alert.bodyMr : widget.alert.bodyEn,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.alert.distanceKm != null)
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.navigationArrow, size: 12, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.alert.distanceKm!.toStringAsFixed(1)} km from your herd',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const QuarantineProtocolsDialog(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.shieldWarning, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Protocols / नियमावली',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
