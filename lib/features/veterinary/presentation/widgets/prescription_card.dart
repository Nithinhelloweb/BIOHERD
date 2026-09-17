import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';

class PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback? onPrintShare;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    this.onPrintShare,
  });

  @override
  Widget build(BuildContext context) {
    return BioHerdCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Rx', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.drugName,
                      style: AppTextStyles.h3(color: AppColors.forestGreen),
                    ),
                    Text(
                      'Issued by: ${prescription.issuedByName ?? "Dr. Licensed Veterinarian"}',
                      style: AppTextStyles.caption(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              if (prescription.scheduleHWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.alertCrimson.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.alertCrimson.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Schedule-H',
                    style: TextStyle(color: AppColors.alertCrimson, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),

          // Dosage & Duration
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosage / मात्रा', style: AppTextStyles.caption(color: AppColors.neutral500)),
                    const SizedBox(height: 2),
                    Text(
                      prescription.dosage,
                      style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duration / कालावधी', style: AppTextStyles.caption(color: AppColors.neutral500)),
                    const SizedBox(height: 2),
                    Text(
                      '${prescription.durationDays} Days (दिवस)',
                      style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),

          // Instructions in Marathi & English
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 सूचना (मराठी): ${prescription.instructionMr}',
                  style: AppTextStyles.bodySm(fontWeight: FontWeight.w600, color: AppColors.neutral800),
                ),
                if (prescription.instructionEn.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Directions (EN): ${prescription.instructionEn}',
                    style: AppTextStyles.caption(color: AppColors.neutral600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space8),

          // Food Safety Withdrawal Badges
          if (prescription.milkWithdrawalDays > 0 || prescription.meatWithdrawalDays > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.alertAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.shieldWarning, color: AppColors.alertAmber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Food Safety Withdrawal: ',
                    style: AppTextStyles.caption(fontWeight: FontWeight.bold, color: AppColors.neutral800),
                  ),
                  if (prescription.milkWithdrawalDays > 0)
                    Text('Milk ${prescription.milkWithdrawalDays}d ', style: const TextStyle(color: AppColors.alertCrimson, fontSize: 11, fontWeight: FontWeight.bold)),
                  if (prescription.meatWithdrawalDays > 0)
                    Text('Meat ${prescription.meatWithdrawalDays}d', style: const TextStyle(color: AppColors.alertCrimson, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.space8),

          // Digital Signature & Action Bar
          Row(
            children: [
              const Icon(PhosphorIconsFill.sealCheck, size: 16, color: AppColors.forestGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  prescription.digitalSignatureHash != null
                      ? 'Digitally Signed: #${prescription.digitalSignatureHash!.substring(0, 12)}...'
                      : 'Digitally Verified by MSVC Doctor',
                  style: AppTextStyles.caption(color: AppColors.neutral600).copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onPrintShare != null)
                TextButton.icon(
                  onPressed: onPrintShare,
                  icon: const Icon(PhosphorIconsRegular.shareNetwork, size: 14, color: AppColors.forestGreen),
                  label: const Text('Share / Print', style: TextStyle(color: AppColors.forestGreen, fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
