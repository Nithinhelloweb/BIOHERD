import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/veterinary/bloc/veterinary_bloc.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';
import 'package:bioherd/features/veterinary/presentation/case_detail_screen.dart';
import 'package:bioherd/features/veterinary/presentation/telemedicine_screen.dart';
import 'package:bioherd/features/veterinary/presentation/widgets/prescription_pad_dialog.dart';

/// Veterinarian Workspace & Clinical Triage Screen
/// Central dashboard for registered veterinary officers in Maharashtra to manage cases,
/// review AI triage alerts, initiate WebRTC telemedicine consultations, and issue digital prescriptions.
class VeterinarianWorkspaceScreen extends StatefulWidget {
  const VeterinarianWorkspaceScreen({super.key});

  @override
  State<VeterinarianWorkspaceScreen> createState() => _VeterinarianWorkspaceScreenState();
}

class _VeterinarianWorkspaceScreenState extends State<VeterinarianWorkspaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  CaseStatus? _filterStatus;
  CasePriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCases() {
    context.read<VeterinaryBloc>().add(
          LoadCasesEvent(
            status: _filterStatus,
            priority: _filterPriority,
            query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          ),
        );
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

  void _openPrescriptionPad(CaseModel c) {
    final repo = context.read<VeterinaryRepository>();
    PrescriptionPadDialog.show(
      context,
      caseModel: c,
      repository: repo,
      onPrescriptionIssued: (prescription) {
        context.read<VeterinaryBloc>().add(
              IssuePrescriptionEvent(
                caseId: c.id,
                prescription: prescription,
              ),
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.forestGreen,
            content: Text(
              'Digital Prescription ${prescription.id} issued successfully.\nडिजिटल प्रिस्क्रिप्शन यशस्वीरीत्या नोंदवले.',
              style: AppTextStyles.bodySm(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Veterinary Clinic & Triage', style: AppTextStyles.h2(color: AppColors.neutral900)),
            Text('पशुवैद्यकीय दवाखाना व तपासणी कक्ष', style: AppTextStyles.caption(color: AppColors.neutral500)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Refresh Cases',
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise, color: AppColors.neutral700),
            onPressed: _loadCases,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadCases(),
        child: BlocBuilder<VeterinaryBloc, VeterinaryState>(
          builder: (context, state) {
            final cases = state.cases;

            return CustomScrollView(
              slivers: [
                // 1. KPI Statistics Strip
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    child: _buildMetricsStrip(state),
                  ),
                ),

                // 2. Search & Triage Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: AppSpacing.space12),
                        _buildFilterChips(),
                        const SizedBox(height: AppSpacing.space16),
                      ],
                    ),
                  ),
                ),

                // 3. Case List or Empty State
                if (state.status == VeterinaryStatus.loading && cases.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.forestGreen),
                    ),
                  )
                else if (cases.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsRegular.checkCircle, size: 48, color: AppColors.neutral400),
                          const SizedBox(height: 12),
                          Text('No matching veterinary cases', style: AppTextStyles.bodyLg(color: AppColors.neutral600)),
                          Text('कोणतीही प्रलंबित केस आढळली नाही', style: AppTextStyles.caption(color: AppColors.neutral400)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final caseModel = cases[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.space16),
                            child: _buildCaseCard(caseModel),
                          );
                        },
                        childCount: cases.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.space32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsStrip(VeterinaryState state) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Triage Queue',
            sublabel: 'प्रतीक्षा',
            value: '${state.triageCount}',
            color: AppColors.alertAmber,
            icon: PhosphorIconsFill.hourglassHigh,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: _buildMetricTile(
            label: 'Critical',
            sublabel: 'तातडीचे',
            value: '${state.criticalCount}',
            color: AppColors.alertCrimson,
            icon: PhosphorIconsFill.warningCircle,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: _buildMetricTile(
            label: 'Prescribed',
            sublabel: 'औषधोपचार',
            value: '${state.prescriptionIssuedCount}',
            color: AppColors.forestGreen,
            icon: PhosphorIconsFill.firstAid,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: _buildMetricTile(
            label: 'Total Active',
            sublabel: 'एकूण केसेस',
            value: '${state.cases.length}',
            color: AppColors.primary700,
            icon: PhosphorIconsFill.folderSimple,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String sublabel,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h2(color: color)),
          Text(label, style: AppTextStyles.caption(color: AppColors.neutral700, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          Text(sublabel, style: AppTextStyles.caption(color: AppColors.neutral400), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadCases(),
      decoration: InputDecoration(
        hintText: 'Search by Case ID, Tag, Farmer, or Disease...',
        prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.neutral500),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(PhosphorIconsBold.x, size: 16),
                onPressed: () {
                  _searchController.clear();
                  _loadCases();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Cases'),
            selected: _filterStatus == null && _filterPriority == null,
            onSelected: (_) {
              setState(() {
                _filterStatus = null;
                _filterPriority = null;
              });
              _loadCases();
            },
          ),
          const SizedBox(width: AppSpacing.space8),
          FilterChip(
            label: const Text('🚨 Critical Emergency'),
            selected: _filterPriority == CasePriority.critical,
            selectedColor: AppColors.alertCrimson.withValues(alpha: 0.2),
            onSelected: (selected) {
              setState(() {
                _filterPriority = selected ? CasePriority.critical : null;
              });
              _loadCases();
            },
          ),
          const SizedBox(width: AppSpacing.space8),
          FilterChip(
            label: const Text('⏳ Triage Queue'),
            selected: _filterStatus == CaseStatus.submitted,
            selectedColor: AppColors.alertAmber.withValues(alpha: 0.2),
            onSelected: (selected) {
              setState(() {
                _filterStatus = selected ? CaseStatus.submitted : null;
              });
              _loadCases();
            },
          ),
          const SizedBox(width: AppSpacing.space8),
          FilterChip(
            label: const Text('🔍 In Review'),
            selected: _filterStatus == CaseStatus.inReview,
            onSelected: (selected) {
              setState(() {
                _filterStatus = selected ? CaseStatus.inReview : null;
              });
              _loadCases();
            },
          ),
          const SizedBox(width: AppSpacing.space8),
          FilterChip(
            label: const Text('💊 Rx Issued'),
            selected: _filterStatus == CaseStatus.prescriptionIssued,
            selectedColor: AppColors.forestGreen.withValues(alpha: 0.2),
            onSelected: (selected) {
              setState(() {
                _filterStatus = selected ? CaseStatus.prescriptionIssued : null;
              });
              _loadCases();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(CaseModel c) {
    final confPercent = c.aiConfidence != null ? (c.aiConfidence! * 100).toInt() : 92;

    return BioHerdCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Case ID, Status, Priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(c.id, style: AppTextStyles.h3(color: AppColors.neutral900)),
                  const SizedBox(width: AppSpacing.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: c.status.color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      c.status.labelEn,
                      style: AppTextStyles.caption(
                        color: c.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SeverityBadge(level: _mapPriority(c.priority), customLabel: c.priority.labelEn),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),

          // Primary AI Diagnosis & Confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space6),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(PhosphorIconsBold.sparkle, color: AppColors.forestGreen, size: 16),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.primaryDiagnosis, style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold, color: AppColors.neutral900)),
                    Text('AI Confidence: $confPercent% • ${c.species} (${c.breed})', style: AppTextStyles.caption(color: AppColors.neutral600)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.space20),

          // Patient & Location Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactMeta(
                icon: PhosphorIconsRegular.identificationCard,
                label: 'Tag: ${c.animalTagId}',
                sub: '${c.weightKg.toInt()} kg',
              ),
              _buildCompactMeta(
                icon: PhosphorIconsRegular.user,
                label: c.farmerName ?? 'Farmer',
                sub: c.farmerPhone ?? 'N/A',
              ),
              _buildCompactMeta(
                icon: PhosphorIconsRegular.mapPin,
                label: c.taluka,
                sub: c.district,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),

          // Action Toolbar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.fileText, size: 16),
                  label: const Text('Dossier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutral800,
                    side: const BorderSide(color: AppColors.neutral300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CaseDetailScreen(caseModel: c),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsFill.videoCamera, size: 16, color: AppColors.primary700),
                  label: const Text('Telemed'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary700,
                    side: const BorderSide(color: AppColors.primary600),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TelemedicineScreen(
                          caseModel: c,
                          onPrescriptionRequested: () => _openPrescriptionPad(c),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(PhosphorIconsBold.firstAid, size: 16, color: Colors.white),
                  label: const Text('Prescribe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openPrescriptionPad(c),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMeta({required IconData icon, required String label, required String sub}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.neutral500),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySm(fontWeight: FontWeight.w600, color: AppColors.neutral800), overflow: TextOverflow.ellipsis),
                Text(sub, style: AppTextStyles.caption(color: AppColors.neutral500), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
