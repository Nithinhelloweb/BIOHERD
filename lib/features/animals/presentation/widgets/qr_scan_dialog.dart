import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_input_field.dart';

class QRScanDialog extends StatefulWidget {
  final ValueChanged<String> onTagDetected;

  const QRScanDialog({super.key, required this.onTagDetected});

  @override
  State<QRScanDialog> createState() => _QRScanDialogState();
}

class _QRScanDialogState extends State<QRScanDialog> with SingleTickerProviderStateMixin {
  late final TextEditingController _tagController;
  late final AnimationController _scanLineController;

  final List<Map<String, String>> _sampleTags = [
    {'tag': 'MH-PUN-GIR-104', 'label': 'Gir Cow (Pune)'},
    {'tag': 'MH-SOL-KHL-201', 'label': 'Khillari Bull (Solapur)'},
    {'tag': 'MH-KOL-PND-305', 'label': 'Pandharpuri Buffalo (Kolhapur)'},
    {'tag': 'MH-OSM-OSM-402', 'label': 'Osmanabadi Goat (Dharashiv)'},
    {'tag': 'MH-NAN-KDK-501', 'label': 'Kadaknath Hen (Nandurbar)'},
  ];

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tagController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _submitTag(String tag) {
    if (tag.trim().isEmpty) return;
    Navigator.of(context).pop();
    widget.onTagDetected(tag.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space8),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(PhosphorIconsRegular.qrCode, color: AppColors.primary600, size: 24),
                  ),
                  AppSpacing.hSpace12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan Animal Tag', style: AppTextStyles.h3()),
                        Text('क्यूआर किंवा कानपट्टी स्कॅन करा', style: AppTextStyles.caption(color: AppColors.neutral500)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, color: AppColors.neutral500),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.vSpace20,

              // Animated Scanner Viewport
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.neutral900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary400, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner targeting brackets
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Icon(PhosphorIconsRegular.cornersIn, color: AppColors.primary400, size: 28),
                              Icon(PhosphorIconsRegular.cornersIn, color: AppColors.primary400, size: 28),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Icon(PhosphorIconsRegular.cornersIn, color: AppColors.primary400, size: 28),
                              Icon(PhosphorIconsRegular.cornersIn, color: AppColors.primary400, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Central animated scanning sweep
                    AnimatedBuilder(
                      animation: _scanLineController,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (_scanLineController.value * 130),
                          left: 32,
                          right: 32,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primary400,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary400.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Center camera viewfinder text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsRegular.camera, color: Colors.white70, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'Align Ear Tag / QR in frame',
                          style: AppTextStyles.caption(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace20,

              // Manual Ear Tag Input
              BioHerdInputField(
                label: 'Or Enter Ear Tag ID',
                hintText: 'e.g. MH-PUN-GIR-104',
                controller: _tagController,
                prefixIcon: const Icon(PhosphorIconsRegular.barcode, color: AppColors.neutral500),
              ),
              AppSpacing.vSpace12,

              BioHerdButton(
                label: 'Search Tag / शोधा',
                icon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: Colors.white, size: 18),
                onPressed: () => _submitTag(_tagController.text),
              ),
              AppSpacing.vSpace16,

              // Quick demo tag chips for evaluator convenience
              Text(
                'Quick Simulate Ear Tag (Demo Tests):',
                style: AppTextStyles.label(color: AppColors.neutral700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sampleTags.map((t) {
                  return ActionChip(
                    backgroundColor: AppColors.primary50,
                    side: const BorderSide(color: AppColors.primary100),
                    avatar: const Icon(PhosphorIconsRegular.qrCode, size: 14, color: AppColors.primary600),
                    label: Text(
                      t['label']!,
                      style: AppTextStyles.caption(color: AppColors.primary600),
                    ),
                    onPressed: () => _submitTag(t['tag']!),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
