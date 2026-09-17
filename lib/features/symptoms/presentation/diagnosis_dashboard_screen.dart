import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/symptoms/bloc/symptom_bloc.dart';
import 'package:bioherd/features/symptoms/models/symptom_model.dart';
import 'package:bioherd/features/symptoms/presentation/ai_results_screen.dart';
import 'package:bioherd/features/symptoms/presentation/symptom_wizard_screen.dart';
import 'package:bioherd/features/veterinary/presentation/veterinarian_workspace_screen.dart';

/// Diagnosis Dashboard Screen for BIOHERD
/// Main screen of the 'Diagnosis' navigation tab. Displays outbreak metrics,
/// quick launch CTA for AI Symptom Wizard, and recent diagnostic screenings.
class DiagnosisDashboardScreen extends StatefulWidget {
  const DiagnosisDashboardScreen({super.key});

  @override
  State<DiagnosisDashboardScreen> createState() => _DiagnosisDashboardScreenState();
}

class _DiagnosisDashboardScreenState extends State<DiagnosisDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SymptomBloc>().add(const LoadSymptomReportsEvent());
  }

  void _refresh() {
    context.read<SymptomBloc>().add(const LoadSymptomReportsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Disease Screening', style: AppTextStyles.h2(color: AppColors.neutral900)),
            Text('रोग निदान व कृत्रिम बुद्धिमत्ता विश्लेषण', style: AppTextStyles.caption(color: AppColors.neutral500)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh Reports',
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise, color: AppColors.neutral700),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero CTA Card
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                backgroundColor: AppColors.primary50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.space12),
                          decoration: BoxDecoration(
                            color: AppColors.primary600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(PhosphorIconsRegular.sparkle, color: Colors.white, size: 28),
                        ),
                        AppSpacing.hSpace16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Suspect Livestock Disease?',
                                style: AppTextStyles.h3(color: AppColors.primary800).copyWith(fontSize: 17),
                              ),
                              Text(
                                'Multi-modal AI checks 10 endemic Maharashtra diseases with first-aid biosecurity protocols.',
                                style: AppTextStyles.caption(color: AppColors.primary700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpace16,
                    BioHerdButton(
                      label: 'Start New AI Symptom Report / नवीन तपासणी',
                      icon: const Icon(PhosphorIconsRegular.plusCircle, color: Colors.white, size: 20),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SymptomWizardScreen(),
                          ),
                        ).then((_) => _refresh());
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace20,

              // Quick Metrics
              BlocBuilder<SymptomBloc, SymptomState>(
                builder: (context, state) {
                  int totalReports = 0;
                  int highAlerts = 0;

                  if (state is SymptomReportsLoaded) {
                    totalReports = state.reports.length;
                    highAlerts = state.reports.where((r) => r.severity == SeverityLevel.high || r.severity == SeverityLevel.critical).length;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: BioHerdCard(
                          padding: const EdgeInsets.all(AppSpacing.space12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.clipboardText, size: 18, color: AppColors.primary600),
                                  const SizedBox(width: 6),
                                  Text('Screenings', style: AppTextStyles.caption(color: AppColors.neutral500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('$totalReports', style: AppTextStyles.h2().copyWith(fontSize: 22)),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: BioHerdCard(
                          padding: const EdgeInsets.all(AppSpacing.space12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.warning, size: 18, color: AppColors.danger600),
                                  const SizedBox(width: 6),
                                  Text('Critical/High', style: AppTextStyles.caption(color: AppColors.neutral500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('$highAlerts', style: AppTextStyles.h2(color: AppColors.danger600).copyWith(fontSize: 22)),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: BioHerdCard(
                          padding: const EdgeInsets.all(AppSpacing.space12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.shieldCheck, size: 18, color: AppColors.info600),
                                  const SizedBox(width: 6),
                                  Text('Diseases', style: AppTextStyles.caption(color: AppColors.neutral500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('10', style: AppTextStyles.h2(color: AppColors.info700).copyWith(fontSize: 22)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              AppSpacing.vSpace16,

              // Veterinary Doctor Workspace Banner
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                backgroundColor: AppColors.primary50,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space10),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(PhosphorIconsFill.firstAid, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Veterinary Officer Workspace',
                            style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                          ),
                          Text(
                            'Manage clinical triage queue, launch WebRTC telemed calls, & issue digital Rx.',
                            style: AppTextStyles.caption(color: AppColors.neutral700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsBold.arrowRight, color: AppColors.forestGreen),
                      tooltip: 'Open Vet Workspace',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VeterinarianWorkspaceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace24,

              // Recent Reports Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Diagnostic Screenings', style: AppTextStyles.h3()),
                      Text('अलीकडील तपासण्या व पशुवैद्यकीय नोंदी', style: AppTextStyles.caption(color: AppColors.neutral500)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SymptomWizardScreen(),
                        ),
                      ).then((_) => _refresh());
                    },
                    icon: const Icon(PhosphorIconsRegular.plus, size: 16, color: AppColors.primary600),
                    label: Text('New', style: AppTextStyles.label(color: AppColors.primary600)),
                  ),
                ],
              ),
              AppSpacing.vSpace12,

              // Reports list
              BlocBuilder<SymptomBloc, SymptomState>(
                builder: (context, state) {
                  if (state is SymptomLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is SymptomReportsLoaded) {
                    final reports = state.reports;
                    if (reports.isEmpty) {
                      return BioHerdCard(
                        padding: const EdgeInsets.all(AppSpacing.space24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(PhosphorIconsRegular.stethoscope, size: 40, color: AppColors.neutral300),
                              const SizedBox(height: 8),
                              Text('No diagnostic reports yet', style: AppTextStyles.body(color: AppColors.neutral700)),
                              const SizedBox(height: 12),
                              BioHerdButton(
                                label: 'Run First AI Diagnosis',
                                isFullWidth: false,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SymptomWizardScreen()),
                                  ).then((_) => _refresh());
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rep = reports[index];
                        return _buildReportCard(context, rep);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, SymptomReportModel report) {
    final diag = report.detectionResult;
    final primary = diag?.primaryDiagnosis;

    return InkWell(
      onTap: () {
        if (diag != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AIResultsScreen(
                result: diag,
                animalTagId: report.animalTagIdSafe,
                caseId: report.escalatedCaseId,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: BioHerdCard(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(PhosphorIconsRegular.cow, size: 20, color: AppColors.primary600),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.animalTagIdSafe, style: AppTextStyles.label().copyWith(fontWeight: FontWeight.bold)),
                        Text('${report.breed} • ${report.species}', style: AppTextStyles.caption(color: AppColors.neutral500)),
                      ],
                    ),
                  ],
                ),
                SeverityBadge(level: report.severity),
              ],
            ),
            const Divider(height: 20),
            Text(
              primary?.diseaseNameEn ?? 'Symptom Examination',
              style: AppTextStyles.h3().copyWith(fontSize: 16),
            ),
            if (primary != null)
              Text(
                primary.diseaseNameMr,
                style: AppTextStyles.caption(color: AppColors.primary700).copyWith(fontWeight: FontWeight.w600),
              ),
            AppSpacing.vSpace8,
            Row(
              children: [
                if (primary != null) ...[
                  Text(
                    'Confidence: ${(primary.confidence * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption(color: AppColors.neutral600),
                  ),
                  const SizedBox(width: 12),
                ],
                if (report.escalatedCaseId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.danger200),
                    ),
                    child: Text(
                      'Case: ${report.escalatedCaseId}',
                      style: const TextStyle(fontSize: 10, color: AppColors.danger700, fontWeight: FontWeight.bold),
                    ),
                  ),
                const Spacer(),
                const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.neutral400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
