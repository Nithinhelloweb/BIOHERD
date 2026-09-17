import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/features/veterinary/models/case_model.dart';
import 'package:bioherd/features/veterinary/data/veterinary_repository.dart';

class PrescriptionPadDialog extends StatefulWidget {
  final CaseModel caseModel;
  final VeterinaryRepository repository;
  final Function(PrescriptionModel prescription) onPrescriptionIssued;

  const PrescriptionPadDialog({
    super.key,
    required this.caseModel,
    required this.repository,
    required this.onPrescriptionIssued,
  });

  static Future<void> show(
    BuildContext context, {
    required CaseModel caseModel,
    required VeterinaryRepository repository,
    required Function(PrescriptionModel prescription) onPrescriptionIssued,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PrescriptionPadDialog(
        caseModel: caseModel,
        repository: repository,
        onPrescriptionIssued: onPrescriptionIssued,
      ),
    );
  }

  @override
  State<PrescriptionPadDialog> createState() => _PrescriptionPadDialogState();
}

class _PrescriptionPadDialogState extends State<PrescriptionPadDialog> {
  List<DrugItem> _drugs = [];
  DrugItem? _selectedDrug;
  DosageCalculationResult? _calcResult;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '3');
  final TextEditingController _notesEnController = TextEditingController();
  final TextEditingController _notesMrController = TextEditingController();
  final TextEditingController _vetRegController = TextEditingController(text: 'MSVC-2022-09412');

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _durationController.dispose();
    _notesEnController.dispose();
    _notesMrController.dispose();
    _vetRegController.dispose();
    super.dispose();
  }

  Future<void> _loadDrugs() async {
    try {
      final items = await widget.repository.getDrugCatalog(species: widget.caseModel.species);
      if (mounted) {
        setState(() {
          _drugs = items;
          _isLoading = false;
          if (_drugs.isNotEmpty) {
            _onSelectDrug(_drugs.first);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSelectDrug(DrugItem drug) async {
    setState(() {
      _selectedDrug = drug;
    });

    try {
      final result = await widget.repository.calculateDosage(
        drug.id,
        widget.caseModel.species,
        widget.caseModel.weightKg,
      );

      if (mounted) {
        setState(() {
          _calcResult = result;
          _dosageController.text = '${result.calculatedVolumeMl.toStringAsFixed(1)} ml (${result.frequency})';
          _notesEnController.text = drug.instructionsEn;
          _notesMrController.text = drug.instructionsMr;
        });
      }
    } catch (_) {
      // Manual fallback
    }
  }

  void _submitPrescription() {
    if (_selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a drug / कृपया औषध निवडा')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final duration = int.tryParse(_durationController.text.trim()) ?? 3;

    final newRx = PrescriptionModel(
      id: 'RX-${DateTime.now().millisecondsSinceEpoch}',
      caseId: widget.caseModel.id,
      issuedBy: _vetRegController.text.trim().isNotEmpty ? _vetRegController.text.trim() : 'VET-MSVC-042',
      issuedByName: 'Dr. Deshmukh (MSVC)',
      drugName: _selectedDrug!.name,
      dosage: _dosageController.text.trim(),
      durationDays: duration,
      instructionsMultilingual: {
        'en': _notesEnController.text.trim(),
        'mr': _notesMrController.text.trim(),
      },
      scheduleHWarning: _selectedDrug!.scheduleH,
      milkWithdrawalDays: _selectedDrug!.milkWithdrawalDays,
      meatWithdrawalDays: _selectedDrug!.meatWithdrawalDays,
      createdAt: DateTime.now(),
    );

    widget.onPrescriptionIssued(newRx);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          children: [
            // Official Prescription Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(PhosphorIconsBold.firstAid, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Digital Veterinary Prescription Pad', style: AppTextStyles.h3(color: Colors.white)),
                        Text(
                          'महाराष्ट्र शासन पशुसंवर्धन विभाग • MSVC Compliant',
                          style: AppTextStyles.caption(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsBold.x, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Form
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      children: [
                        // Patient Summary Banner
                        BioHerdCard(
                          elevation: 0,
                          backgroundColor: AppColors.neutral50,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.forestGreen.withValues(alpha: 0.1),
                                child: const Icon(PhosphorIconsFill.cow, color: AppColors.forestGreen, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.caseModel.animalTagId} · ${widget.caseModel.species} (${widget.caseModel.breed})',
                                      style: AppTextStyles.bodyMd(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Body Weight: ${widget.caseModel.weightKg.toInt()} kg · Farmer: ${widget.caseModel.farmerName}',
                                      style: AppTextStyles.caption(color: AppColors.neutral600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space16),

                        // Formulary Drug Dropdown
                        Text('Select Drug from Formulary / औषध निवडा', style: AppTextStyles.bodySm(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.neutral300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DrugItem>(
                              isExpanded: true,
                              value: _selectedDrug,
                              items: _drugs.map((d) {
                                return DropdownMenuItem<DrugItem>(
                                  value: d,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${d.name} (${d.category})',
                                          style: AppTextStyles.bodyMd(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (d.scheduleH)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.alertCrimson.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Sch-H', style: TextStyle(color: AppColors.alertCrimson, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _onSelectDrug(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space16),

                        // Schedule-H Warning Alert if applicable
                        if (_selectedDrug?.scheduleH == true)
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.space16),
                            padding: const EdgeInsets.all(AppSpacing.space12),
                            decoration: BoxDecoration(
                              color: AppColors.alertCrimson.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.alertCrimson.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsFill.warning, color: AppColors.alertCrimson, size: 20),
                                const SizedBox(width: AppSpacing.space8),
                                Expanded(
                                  child: Text(
                                    'SCHEDULE H PRESCRIPTION DRUG: Strict antibiotic stewardship rules apply. Do not dispense without verified diagnosis.',
                                    style: AppTextStyles.caption(color: AppColors.alertCrimson, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Calculated Dosage Field
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Calculated Dose / मात्रा', style: AppTextStyles.bodySm(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _dosageController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      prefixIcon: const Icon(PhosphorIconsRegular.pill, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Duration / दिवस', style: AppTextStyles.bodySm(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixText: 'Days',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_calcResult != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Weight-based: ${_calcResult!.displayDose} · Route: ${_calcResult!.route}',
                            style: AppTextStyles.caption(color: AppColors.forestGreen, fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.space16),

                        // Withdrawal Period Badges (Food Safety AMR Guard)
                        if (_selectedDrug != null && (_selectedDrug!.milkWithdrawalDays > 0 || _selectedDrug!.meatWithdrawalDays > 0))
                          BioHerdCard(
                            elevation: 0,
                            backgroundColor: AppColors.alertAmber.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.4)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsFill.shieldWarning, color: AppColors.alertAmber, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mandatory Food Safety Withdrawal Periods / विल्हेवाट नियम',
                                      style: AppTextStyles.caption(fontWeight: FontWeight.bold, color: AppColors.neutral900),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (_selectedDrug!.milkWithdrawalDays > 0)
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                          child: Text(
                                            '🥛 Milk: ${_selectedDrug!.milkWithdrawalDays} Days Discard',
                                            style: const TextStyle(color: AppColors.alertCrimson, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    if (_selectedDrug!.milkWithdrawalDays > 0 && _selectedDrug!.meatWithdrawalDays > 0)
                                      const SizedBox(width: 8),
                                    if (_selectedDrug!.meatWithdrawalDays > 0)
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                          child: Text(
                                            '🥩 Meat: ${_selectedDrug!.meatWithdrawalDays} Days',
                                            style: const TextStyle(color: AppColors.alertCrimson, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.space16),

                        // Bilingual Instructions
                        Text('Marathi Instructions / मराठीत सूचना (शेतकऱ्यासाठी)', style: AppTextStyles.bodySm(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesMrController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: 'उदा. दररोज सकाळी आणि संध्याकाळी ५ दिवस द्या...',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space8),

                        Text('English Instructions', style: AppTextStyles.bodySm(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesEnController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: 'e.g. Administer deep IM once daily...',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space16),

                        // Vet Council Registration
                        Text('MSVC Registration No. / डॉक्टर नोंदणी क्रमांक', style: AppTextStyles.bodySm(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _vetRegController,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(PhosphorIconsFill.sealCheck, size: 18, color: AppColors.forestGreen),
                          ),
                        ),
                      ],
                    ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                border: Border(top: BorderSide(color: AppColors.neutral200)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel / रद्द करा'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space16),
                  Expanded(
                    flex: 2,
                    child: BioHerdButton(
                      label: 'Sign & Issue Rx / पाठवा',
                      icon: PhosphorIconsFill.checkCircle,
                      isLoading: _isSubmitting,
                      onPressed: _submitPrescription,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
