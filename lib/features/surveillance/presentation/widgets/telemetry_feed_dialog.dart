import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/severity_badge.dart';
import '../../models/surveillance_model.dart';

class TelemetryFeedDialog extends StatefulWidget {
  final List<LiveSurveillanceLog> logs;

  const TelemetryFeedDialog({super.key, required this.logs});

  static Future<void> show(BuildContext context, List<LiveSurveillanceLog> logs) {
    return showDialog(
      context: context,
      builder: (_) => TelemetryFeedDialog(logs: logs),
    );
  }

  @override
  State<TelemetryFeedDialog> createState() => _TelemetryFeedDialogState();
}

class _TelemetryFeedDialogState extends State<TelemetryFeedDialog> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredLogs = _filter == 'All'
        ? widget.logs
        : widget.logs.where((l) {
            if (_filter == 'Surge') return l.eventType == 'outbreak_surge';
            if (_filter == 'Transit') return l.eventType == 'transit_screened';
            return l.severity == SeverityLevel.critical || l.severity == SeverityLevel.high;
          }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(PhosphorIconsFill.broadcast, color: AppColors.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Simulation Telemetry Stream',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Real-time IoT & Field Unit Dispatch Events',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('All', isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip('Surge', isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip('Transit', isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip('Critical', isDark),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Log List
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.rss, size: 36, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            const Text('No telemetry events logged for this filter.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final log = filteredLogs[idx];
                          final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: log.severity == SeverityLevel.critical
                                    ? AppColors.alertRed.withValues(alpha: 0.3)
                                    : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: log.severity == SeverityLevel.critical
                                        ? AppColors.alertRed
                                        : log.severity == SeverityLevel.high
                                            ? AppColors.alertAmber
                                            : AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log.district,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        log.message,
                                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              // Bottom Dismiss
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]))),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen,
      onSelected: (_) => setState(() => _filter = label),
    );
  }
}
