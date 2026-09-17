import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';

class AnimalPassportDialog extends StatelessWidget {
  final AnimalPassport passport;

  const AnimalPassportDialog({super.key, required this.passport});

  static Future<void> show(BuildContext context, AnimalPassport passport) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AnimalPassportDialog(passport: passport),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Official Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary400, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.warning600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(PhosphorIconsRegular.shieldCheck, color: Colors.white, size: 24),
                      ),
                    ),
                    AppSpacing.hSpace12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOVT OF MAHARASHTRA • BIOHERD',
                            style: AppTextStyles.label(color: AppColors.primary100).copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Livestock Health Passport / पशुधन पास',
                            style: AppTextStyles.h3(color: Colors.white).copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // QR Code & Tamper Proof Box
              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Column(
                  children: [
                    // Stylized QR code representation with Forest Green motif
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary600, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _StylizedQRPainter(seed: passport.tagId.hashCode),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Ear Tag ID prominently
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.barcode, color: AppColors.primary600, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            passport.tagId,
                            style: AppTextStyles.h3(color: AppColors.primary600).copyWith(fontSize: 16, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tamper Proof Hash
                    Text(
                      'VERIFICATION HASH: ${passport.verificationHash}',
                      style: AppTextStyles.caption(color: AppColors.neutral700).copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // Identity & Medical Grid
              _buildSectionTitle('Animal Particulars / पशु तपशील'),
              AppSpacing.vSpace8,
              _buildInfoRow('Species / प्रजाती', passport.species),
              _buildInfoRow('Indigenous Breed / देशी जात', passport.breed),
              _buildInfoRow('Sex / लिंग', passport.sex.toUpperCase()),
              _buildInfoRow('Live Weight / वजन', '${passport.weightKg} kg'),
              if (passport.ageMonths != null)
                _buildInfoRow('Age / वय', '${passport.ageMonths} months'),

              AppSpacing.vSpace12,
              _buildSectionTitle('Ownership & Jurisdiction / मालक व पत्ता'),
              AppSpacing.vSpace8,
              _buildInfoRow('Owner Name / पशुपालक', passport.ownerName),
              _buildInfoRow('Contact / संपर्क', passport.ownerPhone),
              _buildInfoRow('Farm Name / गोठा', passport.farmName),
              _buildInfoRow('District / जिल्हा', passport.districtName),

              AppSpacing.vSpace12,
              _buildSectionTitle('Health & Immunity / लसीकरण स्थिती'),
              AppSpacing.vSpace8,
              _buildInfoRow('Vaccinations / लसीकरण', '${passport.vaccinationsCount} doses recorded'),
              _buildInfoRow('Clinical Events / आरोग्य नोंदी', '${passport.healthEventsCount} historical events'),
              _buildInfoRow(
                'Registry Status / स्थिती',
                passport.isActive ? 'ACTIVE & VERIFIED' : 'INACTIVE',
                isSuccess: passport.isActive,
              ),

              AppSpacing.vSpace20,

              // Actions
              Row(
                children: [
                  Expanded(
                    child: BioHerdButton(
                      label: 'Print / शेअर करा',
                      icon: const Icon(PhosphorIconsRegular.printer, color: AppColors.primary600, size: 18),
                      variant: BioHerdButtonVariant.secondary,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Passport for ${passport.tagId} ready for export/print.'),
                            backgroundColor: AppColors.primary600,
                          ),
                        );
                      },
                    ),
                  ),
                  AppSpacing.hSpace12,
                  Expanded(
                    child: BioHerdButton(
                      label: 'Close / बंद करा',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.label(color: AppColors.neutral700).copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool? isSuccess}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: AppTextStyles.bodySmall(color: AppColors.neutral700)),
          ),
          AppSpacing.hSpace8,
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall(
                color: isSuccess == true
                    ? AppColors.success600
                    : (isSuccess == false ? AppColors.danger600 : AppColors.neutral900),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StylizedQRPainter extends CustomPainter {
  final int seed;

  _StylizedQRPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = const Color(0xFF1B6B3A);

    // 3 Target Corner Squares (QR Standard Position Markers)
    const markerSize = 28.0;
    _drawMarker(canvas, const Offset(0, 0), markerSize, darkPaint);
    _drawMarker(canvas, Offset(size.width - markerSize, 0), markerSize, darkPaint);
    _drawMarker(canvas, Offset(0, size.height - markerSize), markerSize, darkPaint);

    // Fill pseudo data blocks
    const rows = 11;
    final step = size.width / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < rows; c++) {
        if ((r < 4 && c < 4) || (r < 4 && c > rows - 5) || (r > rows - 5 && c < 4)) {
          continue;
        }
        final val = (r * 17 + c * 31 + seed) % 7;
        if (val < 4) {
          canvas.drawRect(
            Rect.fromLTWH(c * step + 1, r * step + 1, step - 2, step - 2),
            darkPaint,
          );
        }
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset offset, double size, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, size, size), paint);
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(offset.dx + 4, offset.dy + 4, size - 8, size - 8), whitePaint);
    canvas.drawRect(Rect.fromLTWH(offset.dx + 8, offset.dy + 8, size - 16, size - 16), paint);
  }

  @override
  bool shouldRepaint(covariant _StylizedQRPainter oldDelegate) => oldDelegate.seed != seed;
}
