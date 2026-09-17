import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/ai_confidence_meter.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/symptoms/models/symptom_model.dart';

/// AI Diagnostic Results Presentation Screen
/// Displays primary predicted condition, AI confidence meter, severity badge,
/// differential diagnoses, and bilingual emergency first-aid bio-security protocols.
class AIResultsScreen extends StatefulWidget {
  final AIDiagnosisResult result;
  final String animalTagId;
  final String? caseId;

  const AIResultsScreen({
    super.key,
    required this.result,
    required this.animalTagId,
    this.caseId,
  });

  @override
  State<AIResultsScreen> createState() => _AIResultsScreenState();
}

class _AIResultsScreenState extends State<AIResultsScreen> {
  bool _showDifferential = false;
  bool _caseContacted = false;

  CardSeverity _toCardSeverity(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low:
        return CardSeverity.low;
      case SeverityLevel.medium:
        return CardSeverity.medium;
      case SeverityLevel.high:
        return CardSeverity.high;
      case SeverityLevel.critical:
        return CardSeverity.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.result.primaryDiagnosis;
    final firstAid = widget.result.firstAid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Disease Screening',
          style: AppTextStyles.h2(color: AppColors.neutral900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.neutral900),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tag indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary100),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.tag, size: 14, color: AppColors.primary600),
                      const SizedBox(width: 4),
                      Text(
                        widget.animalTagId,
                        style: AppTextStyles.label(color: AppColors.primary600)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (widget.caseId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning600.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.firstAid, size: 14, color: AppColors.warning600),
                        const SizedBox(width: 4),
                        Text(
                          'Case #${widget.caseId}',
                          style: AppTextStyles.caption(color: AppColors.warning600)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            AppSpacing.vSpace16,

            // Primary Diagnosis Hero Card
            BioHerdCard(
              severity: _toCardSeverity(primary.severity),
              padding: const EdgeInsets.all(AppSpacing.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIMARY PREDICTION / मुख्य निदान',
                              style: AppTextStyles.caption(color: AppColors.neutral500)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              primary.nameEn,
                              style: AppTextStyles.h1(color: AppColors.neutral900),
                            ),
                            Text(
                              primary.nameMr,
                              style: AppTextStyles.body(color: AppColors.primary600)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      SeverityBadge(level: primary.severity),
                    ],
                  ),
                  AppSpacing.vSpace16,

                  // AI Confidence Meter
                  AIConfidenceMeter(
                    confidence: widget.result.confidence,
                    modelName: widget.result.modelVersion,
                  ),
                  AppSpacing.vSpace12,

                  // Pathogen & Clinical Reasoning
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.virus, size: 16, color: AppColors.neutral700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pathogen: ${primary.causativeAgent}',
                                style: AppTextStyles.bodySmall(color: AppColors.neutral700)
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          primary.clinicalReasoning,
                          style: AppTextStyles.bodySmall(color: AppColors.neutral700),
                        ),
                      ],
                    ),
                  ),

                  // Matched Symptom Badges
                  if (primary.matchedSymptoms.isNotEmpty) ...[
                    AppSpacing.vSpace12,
                    Text(
                      'Matched Clinical Indicators:',
                      style: AppTextStyles.caption(color: AppColors.neutral500)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: primary.matchedSymptoms.map((sym) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.neutral300),
                          ),
                          child: Text(
                            sym,
                            style: AppTextStyles.caption(color: AppColors.neutral900),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vSpace16,

            // Differential Diagnoses Toggle
            if (widget.result.differentialDiagnoses.isNotEmpty) ...[
              InkWell(
                onTap: () => setState(() => _showDifferential = !_showDifferential),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showDifferential
                            ? PhosphorIconsRegular.caretDown
                            : PhosphorIconsRegular.caretRight,
                        size: 18,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Differential Diagnoses (${widget.result.differentialDiagnoses.length} candidates)',
                        style: AppTextStyles.label(color: AppColors.primary600)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showDifferential) ...[
                for (final diff in widget.result.differentialDiagnoses) ...[
                  BioHerdCard(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                diff.nameEn,
                                style: AppTextStyles.h3().copyWith(fontSize: 15),
                              ),
                            ),
                            Text(
                              '${diff.confidence}%',
                              style: AppTextStyles.label(color: AppColors.neutral700)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          diff.nameMr,
                          style: AppTextStyles.caption(color: AppColors.neutral500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diff.clinicalReasoning,
                          style: AppTextStyles.bodySmall(color: AppColors.neutral700),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vSpace8,
                ],
              ],
              AppSpacing.vSpace12,
            ],

            // Emergency Bio-Security & First Aid Protocol
            BioHerdCard(
              backgroundColor: AppColors.primary50.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(PhosphorIconsRegular.shieldCheck, color: AppColors.primary600, size: 20),
                      ),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency First-Aid / तातडीची प्रथमोपचार',
                              style: AppTextStyles.h3().copyWith(fontSize: 16),
                            ),
                            Text(
                              'Government of Maharashtra Bio-Security Advisory',
                              style: AppTextStyles.caption(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSpace16,

                  // Isolation Action
                  _buildProtocolItem(
                    icon: PhosphorIconsRegular.lock,
                    iconColor: AppColors.danger600,
                    titleEn: 'Immediate Quarantine',
                    titleMr: 'तातडीचे विलगीकरण',
                    descEn: firstAid.immediateActionEn,
                    descMr: firstAid.immediateActionMr,
                  ),
                  AppSpacing.vSpace12,

                  // Stall Sanitation Action
                  _buildProtocolItem(
                    icon: PhosphorIconsRegular.sparkle,
                    iconColor: AppColors.primary600,
                    titleEn: 'Disinfection & Stall Hygiene',
                    titleMr: 'गोठा निर्जंतुकीकरण व स्वच्छता',
                    descEn: firstAid.sanitationEn,
                    descMr: firstAid.sanitationMr,
                  ),

                  // Emergency Helpline (1962)
                  AppSpacing.vSpace12,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary200),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.phoneCall, color: AppColors.primary600, size: 20),
                        AppSpacing.hSpace8,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Toll-Free Helpline / पशुसंवर्धन हेल्पलाईन',
                                style: AppTextStyles.caption(color: AppColors.neutral600),
                              ),
                              Text(
                                firstAid.emergencyHotline,
                                style: AppTextStyles.h3(color: AppColors.primary700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zoonotic Risk Warning
                  if (firstAid.zoonoticRisk) ...[
                    AppSpacing.vSpace12,
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      decoration: BoxDecoration(
                        color: AppColors.danger100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger600.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(PhosphorIconsRegular.warning, color: AppColors.danger600, size: 18),
                          AppSpacing.hSpace8,
                          Expanded(
                            child: Text(
                              'ZOONOTIC RISK: This pathogen can transmit to humans! Do not handle raw fluids or drink unpasteurized milk without protective gloves.',
                              style: AppTextStyles.bodySmall(color: AppColors.danger600)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vSpace24,

            // Action Buttons
            BioHerdButton(
              label: _caseContacted
                  ? 'Veterinarian Alerted ✓ (केस दाखल)'
                  : 'Consult District Veterinarian / पशुवैद्यांशी संपर्क',
              icon: Icon(
                _caseContacted ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.phoneCall,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {
                setState(() => _caseContacted = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Veterinarian notified for tag ${widget.animalTagId}. Case #${widget.caseId ?? "AUTO-101"} assigned.',
                    ),
                    backgroundColor: AppColors.primary600,
                  ),
                );
              },
            ),
            AppSpacing.vSpace12,

            BioHerdButton(
              label: 'Back to Herd / गोठ्याकडे परत',
              variant: BioHerdButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppSpacing.vSpace20,
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolItem({
    required IconData icon,
    required Color iconColor,
    required String titleEn,
    required String titleMr,
    required String descEn,
    required String descMr,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        AppSpacing.hSpace12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$titleEn • $titleMr',
                style: AppTextStyles.bodySmall(color: AppColors.neutral900)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                descMr,
                style: AppTextStyles.bodySmall(color: AppColors.neutral700),
              ),
              const SizedBox(height: 2),
              Text(
                descEn,
                style: AppTextStyles.caption(color: AppColors.neutral500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
