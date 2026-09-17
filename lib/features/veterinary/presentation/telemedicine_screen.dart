import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';

/// WebRTC Telemedicine Consultation Room
/// Real-time audiovisual consultation interface optimized for rural Maharashtra connectivity.
/// Features low-bandwidth fallback, PiP camera preview, animal vitals overlay,
/// and live prescription generation.
class TelemedicineScreen extends StatefulWidget {
  final CaseModel caseModel;
  final VoidCallback? onPrescriptionRequested;

  const TelemedicineScreen({
    super.key,
    required this.caseModel,
    this.onPrescriptionRequested,
  });

  @override
  State<TelemedicineScreen> createState() => _TelemedicineScreenState();
}

class _TelemedicineScreenState extends State<TelemedicineScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isLowBandwidthMode = true; // Default ON for rural resilience
  bool _isFrontCamera = true;
  bool _showVitalsOverlay = true;

  int _callSeconds = 48; // Simulated starting elapsed time
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startCallTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _toggleLowBandwidth() {
    setState(() {
      _isLowBandwidthMode = !_isLowBandwidthMode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: _isLowBandwidthMode ? AppColors.forestGreen : AppColors.primary700,
        content: Text(
          _isLowBandwidthMode
              ? 'Low-Bandwidth Mode Enabled (Audio prioritized, 120 kbps codec)\nकमी बँडविड्थ मोड सुरू केला (ऑडिओ प्राधान्य)'
              : 'HD Video Mode Enabled (500+ kbps)\nहाय-डेफिनिशन व्हिडिओ मोड सुरू केला',
        ),
      ),
    );
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Consultation?'),
        content: const Text(
          'Are you sure you want to end this telemedicine session? You can issue a prescription or review case notes now.\n\nसल्लामसलत सत्र समाप्त करायचे आहे का?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Resume Call'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close telemedicine screen
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Remote Farmer / Patient Feed (Main Viewport)
            _buildRemoteFeed(),

            // 2. Top HUD Bar (Case, Timer, Bandwidth Badge)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopHud(),
            ),

            // 3. Animal Clinical Vitals Overlay Banner (Collapsible)
            if (_showVitalsOverlay)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: _buildVitalsBanner(),
              ),

            // 4. Picture-in-Picture (Doctor Camera Feed)
            Positioned(
              right: 16,
              bottom: 110,
              child: _buildDoctorPip(),
            ),

            // 5. Bottom Control Toolbar
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteFeed() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF1A1A2E),
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background simulation canvas
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.forestGreen.withValues(alpha: 0.6),
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIconsFill.cow,
                    size: 72,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                widget.caseModel.farmerName ?? 'Farmer',
                style: AppTextStyles.h3(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.caseModel.breed} (${widget.caseModel.animalTagId})',
                style: AppTextStyles.bodySm(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.forestGreen.withValues(
                              alpha: 0.5 + (_pulseController.value * 0.5),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLowBandwidthMode
                          ? 'WebRTC 120 kbps Low-Bitrate Opus Stream'
                          : 'WebRTC 720p HD Stream (2.4 Mbps)',
                      style: AppTextStyles.caption(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Diagnostic inspection crosshair overlay
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'FOCUS: ORAL LESIONS',
                  style: AppTextStyles.caption(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHud() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back / Minimize Button
        Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(PhosphorIconsBold.caretLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // Session Timer & Room Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.alertCrimson,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE ${_formatDuration(_callSeconds)}',
                style: AppTextStyles.bodySm(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${widget.caseModel.district}',
                style: AppTextStyles.caption(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Low Bandwidth Mode Toggle Button
        GestureDetector(
          onTap: _toggleLowBandwidth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _isLowBandwidthMode ? AppColors.forestGreen.withValues(alpha: 0.8) : Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isLowBandwidthMode ? AppColors.forestGreen : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isLowBandwidthMode ? PhosphorIconsFill.lightning : PhosphorIconsRegular.broadcast,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _isLowBandwidthMode ? 'Rural 2G/3G' : 'HD Video',
                  style: AppTextStyles.caption(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.thermometerHot, color: AppColors.alertAmber, size: 18),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temp: 104.5°F', style: AppTextStyles.bodySm(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('High Fever / ताप', style: AppTextStyles.caption(color: Colors.white60)),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 28, color: Colors.white24),
          Row(
            children: [
              const Icon(PhosphorIconsFill.scales, color: AppColors.primary400, size: 18),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.caseModel.weightKg.toInt()} kg', style: AppTextStyles.bodySm(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Weight / वजन', style: AppTextStyles.caption(color: Colors.white60)),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 28, color: Colors.white24),
          IconButton(
            icon: const Icon(PhosphorIconsBold.x, size: 16, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _showVitalsOverlay = false),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorPip() {
    return Container(
      width: 105,
      height: 145,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white38, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoOff)
              const Center(
                child: Icon(PhosphorIconsFill.videoCameraSlash, color: Colors.white54, size: 28),
              )
            else
              Container(
                color: const Color(0xFF1F2937),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsFill.userCircle, size: 48, color: AppColors.forestGreen),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. Deshmukh',
                      style: AppTextStyles.caption(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _isFrontCamera = !_isFrontCamera),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(PhosphorIconsRegular.cameraRotate, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Audio Mute Toggle
          _buildControlButton(
            icon: _isMuted ? PhosphorIconsFill.microphoneSlash : PhosphorIconsFill.microphone,
            isActive: !_isMuted,
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),

          // Video Toggle
          _buildControlButton(
            icon: _isVideoOff ? PhosphorIconsFill.videoCameraSlash : PhosphorIconsFill.videoCamera,
            isActive: !_isVideoOff,
            onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
          ),

          // In-Call "Issue Prescription" Quick Launcher
          GestureDetector(
            onTap: () {
              if (widget.onPrescriptionRequested != null) {
                widget.onPrescriptionRequested!();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsBold.firstAid, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Prescribe',
                    style: AppTextStyles.bodySm(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // End Call
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.alertCrimson,
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.phoneDisconnect, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : AppColors.alertCrimson.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white24 : AppColors.alertCrimson,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.alertCrimson,
          size: 20,
        ),
      ),
    );
  }
}
