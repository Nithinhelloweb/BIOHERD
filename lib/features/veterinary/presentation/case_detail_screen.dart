import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/veterinary/bloc/veterinary_bloc.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';
import 'package:bioherd/features/veterinary/presentation/telemedicine_screen.dart';
import 'package:bioherd/features/veterinary/presentation/widgets/prescription_card.dart';
import 'package:bioherd/features/veterinary/presentation/widgets/prescription_pad_dialog.dart';

/// Clinical Case Dossier Screen
/// Deep clinical view for veterinarians to inspect symptoms, review AI triage,
/// initiate WebRTC telemedicine consultations, and issue Schedule-H verified digital prescriptions.
class CaseDetailScreen extends StatefulWidget {
  final CaseModel caseModel;

  const CaseDetailScreen({
    super.key,
    required this.caseModel,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late CaseModel _currentCase;

  @override
  void initState() {
    super.initState();
    _currentCase = widget.caseModel;
  }

  SeverityLevel _mapPriority(CasePriority priority) {
    switch (priority) {
      case CasePriority.low:
        return SeverityLevel.low;
      case CasePriority.medium:
        return SeverityLevel.medium;
      case CasePriority.high:
        return SeverityLevel.high;
      case CasePriority.critical:
        return SeverityLevel.critical;
    }
  }

  void _openPrescriptionPad() {
    final repo = context.read<VeterinaryRepository>();
    PrescriptionPadDialog.show(
      context,
      caseModel: _currentCase,
      repository: repo,
      onPrescriptionIssued: (prescription) {
        context.read<VeterinaryBloc>().add(
              IssuePrescriptionEvent(
                caseId: _currentCase.id,
                prescription: prescription,
              ),
            );

        setState(() {
          final updatedPrescriptions = [..._currentCase.prescriptions, prescription];
          _currentCase = _currentCase.copyWith(
            status: CaseStatus.prescriptionIssued,
            prescriptions: updatedPrescriptions,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.forestGreen,
            content: Row(
              children: [
                const Icon(PhosphorIconsFill.checkCircle, color: Colors.white),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Text(
                    'Digital Prescription ${prescription.id} issued successfully.\nडिजिटल प्रिस्क्रिप्शन यशस्वीरीत्या नोंदवले.',
                    style: AppTextStyles.bodySm(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchTelemedicine() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelemedicineScreen(
          caseModel: _currentCase,
          onPrescriptionRequested: _openPrescriptionPad,
        ),
      ),
    );
  }

  void _showStatusDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Case Status', style: AppTextStyles.h2(color: AppColors.neutral900)),
              Text('केस स्थिती अद्ययावत करा', style: AppTextStyles.caption(color: AppColors.neutral500)),
              const SizedBox(height: AppSpacing.space16),
              ...CaseStatus.values.map((status) {
                final isCurrent = status == _currentCase.status;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: status.color,
                  ),
                  title: Text(status.labelEn, style: AppTextStyles.bodyMd()),
                  subtitle: Text(status.labelMr, style: AppTextStyles.caption(color: AppColors.neutral500)),
                  trailing: isCurrent ? const Icon(PhosphorIconsFill.checkCircle, color: AppColors.forestGreen) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<VeterinaryBloc>().add(
                          UpdateCaseStatusEvent(
                            caseId: _currentCase.id,
                            status: status,
                          ),
                        );
                    setState(() {
                      _currentCase = _currentCase.copyWith(status: status);
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VeterinaryBloc, VeterinaryState>(
      listener: (context, state) {
        // Sync if updated in bloc
        final matched = state.cases.where((c) => c.id == _currentCase.id);
        if (matched.isNotEmpty) {
          setState(() {
            _currentCase = matched.first;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentCase.id, style: AppTextStyles.h3(color: AppColors.neutral900)),
              Text(
                '${_currentCase.taluka}, ${_currentCase.district} • ${_currentCase.species}',
                style: AppTextStyles.caption(color: AppColors.neutral500),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.videoCamera, color: AppColors.primary700),
              tooltip: 'Launch Telemed Call',
              onPressed: _launchTelemedicine,
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.pencilSimpleLine, color: AppColors.neutral700),
              tooltip: 'Update Status',
              onPressed: _showStatusDialog,
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Clinical Status Stepper
              _buildStatusStepper(),
              const SizedBox(height: AppSpacing.space16),

              // 2. Patient & Farmer Identity Card
              _buildPatientCard(),
              const SizedBox(height: AppSpacing.space16),

              // 3. AI Triage & Clinical Findings Card
              _buildClinicalFindingsCard(),
              const SizedBox(height: AppSpacing.space16),

              // 4. Clinical Evidence & Symptoms
              _buildSymptomsAndPhotosCard(),
              const SizedBox(height: AppSpacing.space16),

              // 5. Prescriptions Issued Section
              _buildPrescriptionsSection(),
              const SizedBox(height: AppSpacing.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStepper() {
    final steps = [
      CaseStatus.submitted,
      CaseStatus.assigned,
      CaseStatus.inReview,
      CaseStatus.prescriptionIssued,
      CaseStatus.closed,
    ];

    final currentIndex = steps.indexOf(_currentCase.status);
    final activeIndex = currentIndex == -1 ? 2 : currentIndex;

    return BioHerdCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clinical Progression', style: AppTextStyles.bodyMd(fontWeight: FontWeight.w600)),
              SeverityBadge(level: _mapPriority(_currentCase.priority), customLabel: _currentCase.priority.labelEn),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepNum = index ~/ 2;
                final isDone = stepNum < activeIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? AppColors.forestGreen : AppColors.neutral300,
                  ),
                );
              }

              final stepIdx = index ~/ 2;
              final isPassed = stepIdx <= activeIndex;
              final isCurrent = stepIdx == activeIndex;

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed ? AppColors.forestGreen : AppColors.neutral200,
                      border: isCurrent ? Border.all(color: AppColors.primary300, width: 3) : null,
                    ),
                    child: Center(
                      child: isPassed
                          ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white)
                          : Text(
                              '${stepIdx + 1}',
                              style: AppTextStyles.caption(color: AppColors.neutral600),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    steps[stepIdx].labelEn.split(' ').first,
                    style: AppTextStyles.caption(
                      color: isPassed ? AppColors.neutral900 : AppColors.neutral400,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    return BioHerdCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space8),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(PhosphorIconsFill.cow, color: AppColors.primary700, size: 24),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tag: ${_currentCase.animalTagId}', style: AppTextStyles.h3()),
                    Text(
                      '${_currentCase.breed} • ${_currentCase.species} • ${_currentCase.ageYears} yrs',
                      style: AppTextStyles.caption(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.scales, size: 16, color: AppColors.secondary700),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentCase.weightKg.toInt()} kg',
                      style: AppTextStyles.bodySm(fontWeight: FontWeight.bold, color: AppColors.secondary800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.space24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                label: 'Farmer / शेतकरी',
                value: _currentCase.farmerName ?? 'Farmer',
                icon: PhosphorIconsRegular.user,
              ),
              _buildDetailItem(
                label: 'Phone / फोन',
                value: _currentCase.farmerPhone ?? 'N/A',
                icon: PhosphorIconsRegular.phone,
              ),
              _buildDetailItem(
                label: 'Location / ठिकाण',
                value: '${_currentCase.taluka}, ${_currentCase.district}',
                icon: PhosphorIconsRegular.mapPin,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value, required IconData icon}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.neutral500),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label, style: AppTextStyles.caption(color: AppColors.neutral500), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySm(fontWeight: FontWeight.w600, color: AppColors.neutral800),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalFindingsCard() {
    final confPercent = _currentCase.aiConfidence != null
        ? (_currentCase.aiConfidence! * 100).toInt()
        : 92;

    return BioHerdCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space6),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(PhosphorIconsBold.sparkle, color: AppColors.forestGreen, size: 18),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text('AI Triage Diagnostic Findings', style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$confPercent% Confidence',
                  style: AppTextStyles.caption(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            _currentCase.primaryDiagnosis,
            style: AppTextStyles.h3(color: AppColors.forestGreen),
          ),
          if (_currentCase.differentialDiagnoses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space8),
            Text('Differential Considerations (संभाव्य इतर आजार):', style: AppTextStyles.caption(color: AppColors.neutral600)),
            const SizedBox(height: AppSpacing.space4),
            Wrap(
              spacing: 8,
              children: _currentCase.differentialDiagnoses.map((diff) {
                return Chip(
                  label: Text(diff, style: AppTextStyles.caption(color: AppColors.neutral700)),
                  backgroundColor: AppColors.neutral100,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomsAndPhotosCard() {
    return BioHerdCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Signs & Observations (लक्षणे)', style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.space12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentCase.symptoms.map((symptom) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.alertAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsFill.warningCircle, size: 14, color: AppColors.alertAmber),
                    const SizedBox(width: 6),
                    Text(symptom, style: AppTextStyles.bodySm(fontWeight: FontWeight.w500, color: AppColors.neutral800)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text('Field Photos & Video Attachments', style: AppTextStyles.caption(color: AppColors.neutral600)),
          const SizedBox(height: AppSpacing.space8),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPhotoThumbnail(
                  title: 'Oral Mucosa / दात व जीभ',
                  icon: PhosphorIconsRegular.camera,
                ),
                const SizedBox(width: AppSpacing.space12),
                _buildPhotoThumbnail(
                  title: 'Interdigital Hoof / खुर',
                  icon: PhosphorIconsRegular.camera,
                ),
                const SizedBox(width: AppSpacing.space12),
                _buildPhotoThumbnail(
                  title: 'Thermal Scan / तापमान',
                  icon: PhosphorIconsRegular.thermometerHot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail({required String title, required IconData icon}) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.forestGreen),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyles.caption(color: AppColors.neutral700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Digital Prescriptions (${_currentCase.prescriptions.length})', style: AppTextStyles.h3()),
            TextButton.icon(
              icon: const Icon(PhosphorIconsBold.plusCircle, size: 16),
              label: const Text('Add Drug / औषध जोडा'),
              style: TextButton.styleFrom(foregroundColor: AppColors.forestGreen),
              onPressed: _openPrescriptionPad,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        if (_currentCase.prescriptions.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space24),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral200, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(PhosphorIconsRegular.pill, size: 36, color: AppColors.neutral400),
                  const SizedBox(height: 8),
                  Text('No prescriptions issued yet', style: AppTextStyles.bodyMd(color: AppColors.neutral600)),
                  Text('कोणतीही औषधे अद्याप दिलेली नाहीत', style: AppTextStyles.caption(color: AppColors.neutral400)),
                  const SizedBox(height: 12),
                  BioHerdButton(
                    text: 'Open Prescription Pad',
                    icon: PhosphorIconsRegular.firstAid,
                    onPressed: _openPrescriptionPad,
                  ),
                ],
              ),
            ),
          )
        else
          ..._currentCase.prescriptions.map((prescription) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space16),
              child: PrescriptionCard(prescription: prescription),
            );
          }),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(PhosphorIconsFill.videoCamera, color: AppColors.primary700),
              label: const Text('Telemed Call'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary700,
                side: const BorderSide(color: AppColors.primary600),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _launchTelemedicine,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(PhosphorIconsBold.firstAid, color: Colors.white),
              label: const Text('Prescribe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _openPrescriptionPad,
            ),
          ),
        ],
      ),
    );
  }
}
