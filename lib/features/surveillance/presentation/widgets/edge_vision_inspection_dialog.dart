import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/edge_vision_model.dart';

class EdgeVisionInspectionDialog extends StatefulWidget {
  final BiosecurityCheckpoint checkpoint;
  final Function(GateBarrierStatus newStatus)? onGateStatusChanged;
  final Function(String action, String message)? onActionExecuted;

  const EdgeVisionInspectionDialog({
    super.key,
    required this.checkpoint,
    this.onGateStatusChanged,
    this.onActionExecuted,
  });

  static Future<void> show(
    BuildContext context, {
    required BiosecurityCheckpoint checkpoint,
    Function(GateBarrierStatus newStatus)? onGateStatusChanged,
    Function(String action, String message)? onActionExecuted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EdgeVisionInspectionDialog(
        checkpoint: checkpoint,
        onGateStatusChanged: onGateStatusChanged,
        onActionExecuted: onActionExecuted,
      ),
    );
  }

  @override
  State<EdgeVisionInspectionDialog> createState() => _EdgeVisionInspectionDialogState();
}

class _EdgeVisionInspectionDialogState extends State<EdgeVisionInspectionDialog>
    with SingleTickerProviderStateMixin {
  late int _selectedFeedIndex;
  late GateBarrierStatus _currentGateStatus;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _selectedFeedIndex = 0;
    _currentGateStatus = widget.checkpoint.gateBarrierStatus;
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scanController.forward();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  EdgeCameraFeed get _activeFeed {
    if (widget.checkpoint.cameraFeeds.isEmpty) {
      return const EdgeCameraFeed(
        id: 'fallback-cam',
        checkpointId: 'fallback',
        cameraName: 'Standard Inspection Cam',
        angleType: CameraAngleType.lateralChute,
        activeTargetPlate: 'MH-00-XX-0000',
        activeTagId: 'INAPH-0000-0000',
        species: 'Bovine',
        thermalCoreTemp: 38.5,
        isFebrile: false,
        lamenessScore: 1,
        detections: [],
        overallConfidence: 0.99,
        biosecurityTriage: BiosecurityTriage.autoPassGreen,
        timestamp: 'LIVE',
      );
    }
    return widget.checkpoint.cameraFeeds[_selectedFeedIndex.clamp(0, widget.checkpoint.cameraFeeds.length - 1)];
  }

  void _actuateGate(GateBarrierStatus status, String actionDesc) {
    setState(() {
      _currentGateStatus = status;
      widget.checkpoint.gateBarrierStatus = status;
    });
    if (widget.onGateStatusChanged != null) {
      widget.onGateStatusChanged!(status);
    }
    if (widget.onActionExecuted != null) {
      widget.onActionExecuted!('GATE_ACTUATE', actionDesc);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: status == GateBarrierStatus.lockedDown
            ? const Color(0xFFEF4444)
            : status == GateBarrierStatus.screeningDivert
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
        content: Row(
          children: [
            const Icon(PhosphorIconsFill.shieldWarning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(actionDesc, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feed = _activeFeed;
    final size = MediaQuery.of(context).size;
    final dialogWidth = math.min(size.width * 0.94, 820.0);
    final dialogHeight = math.min(size.height * 0.92, 780.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: feed.triageColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: feed.triageColor.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            _buildHeader(isDark, feed),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Camera Angle Selector Tabs
                    _buildCameraTabs(isDark),
                    const SizedBox(height: 12),

                    // Edge Vision Live Feed Canvas
                    _buildVisionCanvas(feed, isDark),
                    const SizedBox(height: 14),

                    // Biometric & Pashu Aadhaar Verification Dossier
                    _buildPashuAadhaarDossier(feed, isDark),
                    const SizedBox(height: 14),

                    // Detected Lesions & Findings Breakdown
                    _buildDetectionsList(feed, isDark),
                  ],
                ),
              ),
            ),

            // Tactical Gate Actuation Bar
            _buildActionBar(isDark, feed),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, EdgeCameraFeed feed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: feed.triageColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: feed.triageColor.withValues(alpha: 0.5)),
            ),
            child: Icon(PhosphorIconsFill.videoCamera, color: feed.triageColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.checkpoint.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        widget.checkpoint.zoneType.toUpperCase(),
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.checkpoint.highway} • District: ${widget.checkpoint.district} • Queued: ${widget.checkpoint.queueCount} trucks',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Close Icon
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTabs(bool isDark) {
    if (widget.checkpoint.cameraFeeds.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.checkpoint.cameraFeeds.length, (idx) {
          final cam = widget.checkpoint.cameraFeeds[idx];
          final isSelected = _selectedFeedIndex == idx;
          IconData icon;
          switch (cam.angleType) {
            case CameraAngleType.lateralChute:
            case CameraAngleType.dorsalChute:
              icon = PhosphorIconsRegular.camera;
              break;
            case CameraAngleType.thermalFlir:
              icon = PhosphorIconsFill.thermometer;
              break;
            case CameraAngleType.gaitLocomotion:
              icon = PhosphorIconsRegular.heartbeat;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFeedIndex = idx),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cam.triageColor.withValues(alpha: 0.2)
                      : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cam.triageColor : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: isSelected ? cam.triageColor : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      cam.angleName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cam.triageColor : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    if (cam.detections.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cam.detections.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVisionCanvas(EdgeCameraFeed feed, bool isDark) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: feed.triageColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            // Background Visual Feed Simulation
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _EdgeFeedPainter(
                    feed: feed,
                    scanProgress: _scanController.value,
                  ),
                );
              },
            ),

            // Top Telemetry HUD Overlay
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          feed.timestamp,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      '${feed.yoloModel} • ${feed.inferenceLatencyMs}ms • ${feed.fps} FPS',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Target Lock Banner
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: feed.triageColor.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TARGET: ${feed.activeTargetPlate} • ${feed.species}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: feed.triageColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        feed.triageLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPashuAadhaarDossier(EdgeCameraFeed feed, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.identificationCard, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PASHU AADHAAR / INAPH VERIFICATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(feed.activeTagId,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Thermal Core Temp',
                  '${feed.thermalCoreTemp}°C',
                  feed.isFebrile ? 'FEBRILE SPIKE' : 'NORMAL RANGE',
                  feed.isFebrile ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  PhosphorIconsFill.thermometer,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Locomotion / Gait',
                  'Score: ${feed.lamenessScore}/5',
                  feed.lamenessScore >= 3 ? 'SEVERE ASYMMETRY' : 'SOUND GAIT',
                  feed.lamenessScore >= 3 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  PhosphorIconsRegular.heartbeat,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'AI Lesion Confidence',
                  '${(feed.overallConfidence * 100).toStringAsFixed(1)}%',
                  feed.detections.isNotEmpty ? '${feed.detections.length} ANOMALIES' : 'CLEAN SCAN',
                  feed.detections.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  PhosphorIconsFill.shieldCheck,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String badge,
    Color badgeColor,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionsList(EdgeCameraFeed feed, bool isDark) {
    if (feed.detections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text(
              'No pathological lesions or mucosal ulcerations identified by YOLOv8x.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOLOv8x-EPIZOOTIC DETECTED LESIONS',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ...feed.detections.map((det) {
          final isCritical = det.severity == 'Critical';
          final color = isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(isCritical ? PhosphorIconsFill.warning : PhosphorIconsFill.warningCircle, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        det.lesionType,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        'Region: ${det.anatomicalRegion} • Bounding Box: [${(det.boundingBox.left * 100).toInt()}%, ${(det.boundingBox.top * 100).toInt()}%]',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(det.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionBar(bool isDark, EdgeCameraFeed feed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Clear / Dismiss
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Close Terminal'),
          ),

          // Action 1: PCR Swab Unit Dispatch
          ElevatedButton.icon(
            onPressed: () => _actuateGate(
              GateBarrierStatus.screeningDivert,
              'Mobile PCR Field Swab Team Dispatched to Chute Bay.',
            ),
            icon: const Icon(PhosphorIconsFill.flask, size: 16),
            label: const Text('Dispatch PCR Swab Unit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

          // Action 2: Engage Gate Clamp & Quarantine Impound
          ElevatedButton.icon(
            onPressed: () => _actuateGate(
              GateBarrierStatus.lockedDown,
              'HYDRAULIC GATE CLAMP ENGAGED. Vehicle Diverted to Quarantine Pen.',
            ),
            icon: const Icon(PhosphorIconsFill.lockKey, size: 16),
            label: const Text('Engage Gate Clamp & Impound'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

          // Action 3: Grant Biosecurity Digital Seal
          ElevatedButton.icon(
            onPressed: () => _actuateGate(
              GateBarrierStatus.operational,
              'Digital Transit Pass QR Seal Issued. Gate Cleared.',
            ),
            icon: const Icon(PhosphorIconsFill.checkCircle, size: 16),
            label: const Text('Grant E-Clearance Seal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgeFeedPainter extends CustomPainter {
  final EdgeCameraFeed feed;
  final double scanProgress;

  _EdgeFeedPainter({required this.feed, required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background gradient depending on camera mode
    if (feed.angleType == CameraAngleType.thermalFlir) {
      // Thermal infrared palette (dark violet to neon orange to white)
      final thermalGrad = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E0850),
          const Color(0xFF5B1080),
          const Color(0xFFB82855),
          const Color(0xFFE86A1D),
          const Color(0xFFF9C74F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = thermalGrad);

      // Core hot-spot glow
      final hotPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawCircle(Offset(w * 0.45, h * 0.48), 50, hotPaint);
    } else {
      // Standard dark CCTV feed simulation
      final cctvPaint = Paint()..color = const Color(0xFF070D18);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), cctvPaint);

      // Grid lines
      final gridPaint = Paint()
        ..color = const Color(0xFF00FF66).withValues(alpha: 0.06)
        ..strokeWidth = 1.0;
      for (double x = 0; x < w; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      }
      for (double y = 0; y < h; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    }

    // Moving Laser Scanline
    final scanY = h * scanProgress;
    final scanPaint = Paint()
      ..color = (feed.angleType == CameraAngleType.thermalFlir
              ? Colors.amberAccent
              : const Color(0xFF00FFCC))
          .withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, scanY), Offset(w, scanY), scanPaint);

    // Corner Reticles
    final reticlePaint = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    const bracketSize = 18.0;

    // Top-left
    canvas.drawLine(const Offset(12, 12), const Offset(12 + bracketSize, 12), reticlePaint);
    canvas.drawLine(const Offset(12, 12), const Offset(12, 12 + bracketSize), reticlePaint);

    // Top-right
    canvas.drawLine(Offset(w - 12, 12), Offset(w - 12 - bracketSize, 12), reticlePaint);
    canvas.drawLine(Offset(w - 12, 12), Offset(w - 12, 12 + bracketSize), reticlePaint);

    // Bottom-left
    canvas.drawLine(Offset(12, h - 12), Offset(12 + bracketSize, h - 12), reticlePaint);
    canvas.drawLine(Offset(12, h - 12), Offset(12, h - 12 - bracketSize), reticlePaint);

    // Bottom-right
    canvas.drawLine(Offset(w - 12, h - 12), Offset(w - 12 - bracketSize, h - 12), reticlePaint);
    canvas.drawLine(Offset(w - 12, h - 12), Offset(w - 12, h - 12 - bracketSize), reticlePaint);

    // Draw YOLO Detections Bounding Boxes
    for (final det in feed.detections) {
      final boxRect = Rect.fromLTWH(
        det.boundingBox.left * w,
        det.boundingBox.top * h,
        det.boundingBox.width * w,
        det.boundingBox.height * h,
      );

      final boxColor = det.severity == 'Critical' ? const Color(0xFFFF2255) : const Color(0xFFFFB703);

      final boxPaint = Paint()
        ..color = boxColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(boxRect, boxPaint);

      // Shaded fill
      final fillPaint = Paint()
        ..color = boxColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(boxRect, fillPaint);

      // Label background & text
      final textSpan = TextSpan(
        text: ' ${det.lesionType.toUpperCase()} ${(det.confidence * 100).toInt()}% ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xCC000000),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(boxRect.left, math.max(0, boxRect.top - 14)));
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeFeedPainter oldDelegate) {
    return oldDelegate.feed != feed || oldDelegate.scanProgress != scanProgress;
  }
}
