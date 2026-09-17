import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// OfflineBanner
/// Critical rural connectivity state banner.
/// Always visible when offline; displays active queue flush progress during sync.
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final bool isSyncing;
  final int pendingSyncCount;
  final String? customMessage;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.isSyncing = false,
    this.pendingSyncCount = 0,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !isSyncing) {
      return const SizedBox.shrink();
    }

    final Color bgColor = isSyncing ? AppColors.info100 : AppColors.warning100;
    final Color fgColor = isSyncing ? AppColors.info600 : AppColors.warning600;
    final IconData icon = isSyncing ? PhosphorIconsRegular.arrowsClockwise : PhosphorIconsRegular.wifiSlash;

    String displayText;
    if (customMessage != null) {
      displayText = customMessage!;
    } else if (isSyncing) {
      displayText = 'Syncing… $pendingSyncCount items pending';
    } else {
      displayText = "You're offline. Data will sync when connected.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: 8.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: fgColor.withAlpha(50), width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fgColor),
              AppSpacing.hSpace8,
              Expanded(
                child: Text(
                  displayText,
                  style: AppTextStyles.label(color: fgColor).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          if (isSyncing) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: const LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.info600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
