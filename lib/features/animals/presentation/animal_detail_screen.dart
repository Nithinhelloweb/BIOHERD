import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/bioherd_input_field.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/animals/presentation/widgets/animal_passport_dialog.dart';
import 'package:bioherd/features/symptoms/presentation/symptom_wizard_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late Animal _animal;
  List<HealthTimelineEvent> _timelineEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    final repo = context.read<AnimalBloc>().repository;
    final events = await repo.getHealthEvents(_animal.id);
    if (mounted) {
      setState(() {
        _timelineEvents = events;
        _isLoadingEvents = false;
      });
    }
  }

  void _changeStatus(HealthStatus newStatus) {
    final updated = _animal.copyWith(healthStatus: newStatus);
    setState(() => _animal = updated);
    context.read<AnimalBloc>().add(UpdateAnimalEvent(updated));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to ${newStatus.label} (${newStatus.labelMr})'),
        backgroundColor: newStatus.textColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openAddEventDialog() async {
    final descController = TextEditingController();
    final doctorController = TextEditingController(text: 'LDO Field Veterinarian');
    String selectedType = 'vaccination';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.space20,
                right: AppSpacing.space20,
                top: AppSpacing.space20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.space24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add Health Event / आरोग्य नोंद', style: AppTextStyles.h3()),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.x),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    AppSpacing.vSpace16,

                    // Event Type Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Vaccination / लस'),
                          selected: selectedType == 'vaccination',
                          onSelected: (val) => setSheetState(() => selectedType = 'vaccination'),
                        ),
                        ChoiceChip(
                          label: const Text('Routine Checkup / तपासणी'),
                          selected: selectedType == 'routine_checkup',
                          onSelected: (val) => setSheetState(() => selectedType = 'routine_checkup'),
                        ),
                        ChoiceChip(
                          label: const Text('Medication / औषध'),
                          selected: selectedType == 'medication',
                          onSelected: (val) => setSheetState(() => selectedType = 'medication'),
                        ),
                        ChoiceChip(
                          label: const Text('Quarantine / विलगीकरण'),
                          selected: selectedType == 'quarantine',
                          onSelected: (val) => setSheetState(() => selectedType = 'quarantine'),
                        ),
                      ],
                    ),
                    AppSpacing.vSpace16,

                    BioHerdInputField(
                      label: 'Clinical Notes / वर्णन',
                      hintText: 'e.g. Administered Brucellosis S19 dose / ताप ३९ अंश',
                      controller: descController,
                      maxLines: 2,
                    ),
                    AppSpacing.vSpace12,

                    BioHerdInputField(
                      label: 'Practitioner / अधिकारी',
                      hintText: 'Doctor or Officer name',
                      controller: doctorController,
                    ),
                    AppSpacing.vSpace20,

                    BioHerdButton(
                      label: 'Record Event / नोंदवा',
                      icon: const Icon(PhosphorIconsRegular.checkCircle, color: Colors.white, size: 20),
                      onPressed: () {
                        if (descController.text.trim().isEmpty) return;
                        final newEvent = HealthTimelineEvent(
                          id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                          animalId: _animal.id,
                          eventType: selectedType,
                          description: descController.text.trim(),
                          recordedBy: doctorController.text.trim(),
                          occurredAt: DateTime.now(),
                          createdAt: DateTime.now(),
                        );
                        context.read<AnimalBloc>().add(AddHealthEventRecord(_animal.id, newEvent));
                        Navigator.of(ctx).pop();
                        _loadEvents();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(_animal.tagId, style: AppTextStyles.h3()),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'View QR Passport',
            icon: const Icon(PhosphorIconsRegular.qrCode, color: AppColors.primary600),
            onPressed: () async {
              final repo = context.read<AnimalBloc>().repository;
              final pass = await repo.getAnimalPassport(_animal.id);
              if (context.mounted) {
                AnimalPassportDialog.show(context, pass);
              }
            },
          ),
          IconButton(
            tooltip: 'Delete Record',
            icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger600),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Animal Record?'),
                  content: Text('Are you sure you want to deactivate ${_animal.tagId}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        context.read<AnimalBloc>().add(DeleteAnimalEvent(_animal.id));
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Deactivate', style: TextStyle(color: AppColors.danger600)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Identity Card
            BioHerdCard(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary100, width: 2),
                    ),
                    child: Icon(_animal.species.icon, color: AppColors.primary600, size: 36),
                  ),
                  AppSpacing.hSpace16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _animal.breed,
                              style: AppTextStyles.h2().copyWith(fontSize: 20),
                            ),
                            const Spacer(),
                            SeverityBadge(level: _animal.healthStatus.severityLevel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_animal.species.displayName} • ${_animal.sex.toUpperCase()} • ${_animal.formattedAge}',
                          style: AppTextStyles.bodySmall(color: AppColors.neutral700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weight: ${_animal.weightKg} kg',
                          style: AppTextStyles.caption(color: AppColors.primary600).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vSpace16,

            // Health Status Quick Action Switcher
            BioHerdCard(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Triage Status / आरोग्य स्थिती बदल',
                    style: AppTextStyles.label(color: AppColors.neutral700).copyWith(fontWeight: FontWeight.w700),
                  ),
                  AppSpacing.vSpace12,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: HealthStatus.values.map((status) {
                      final isSelected = _animal.healthStatus == status;
                      return ChoiceChip(
                        selected: isSelected,
                        backgroundColor: AppColors.neutral50,
                        selectedColor: status.bgColor,
                        side: BorderSide(
                          color: isSelected ? status.textColor : AppColors.neutral300,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.circle,
                              size: 14,
                              color: isSelected ? status.textColor : AppColors.neutral500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${status.label} (${status.labelMr})',
                              style: AppTextStyles.caption(
                                color: isSelected ? status.textColor : AppColors.neutral700,
                              ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
                            ),
                          ],
                        ),
                        onSelected: (_) => _changeStatus(status),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            AppSpacing.vSpace16,

            // QR Passport Banner
            BioHerdCard(
              padding: const EdgeInsets.all(AppSpacing.space16),
              backgroundColor: AppColors.primary50,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsRegular.qrCode, color: Colors.white, size: 28),
                  ),
                  AppSpacing.hSpace16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verifiable QR Passport', style: AppTextStyles.h3(color: AppColors.primary600).copyWith(fontSize: 16)),
                        Text('Digital identity for veterinary inspection', style: AppTextStyles.caption(color: AppColors.primary500)),
                      ],
                    ),
                  ),
                  BioHerdButton(
                    label: 'View Pass',
                    isFullWidth: false,
                    onPressed: () async {
                      final repo = context.read<AnimalBloc>().repository;
                      final pass = await repo.getAnimalPassport(_animal.id);
                      if (context.mounted) {
                        AnimalPassportDialog.show(context, pass);
                      }
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.vSpace12,

            // AI Symptom Checker Action Card
            BioHerdCard(
              padding: const EdgeInsets.all(AppSpacing.space16),
              backgroundColor: AppColors.neutral50,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: AppColors.primary700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsRegular.stethoscope, color: Colors.white, size: 28),
                  ),
                  AppSpacing.hSpace16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Symptom Checker', style: AppTextStyles.h3(color: AppColors.primary800).copyWith(fontSize: 16)),
                        Text('Screen for LSD, FMD, Mastitis & BQ', style: AppTextStyles.caption(color: AppColors.neutral600)),
                      ],
                    ),
                  ),
                  BioHerdButton(
                    label: 'Check / तपासा',
                    isFullWidth: false,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SymptomWizardScreen(initialAnimal: _animal),
                        ),
                      ).then((_) => _loadEvents());
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.vSpace20,

            // Health Timeline Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Timeline', style: AppTextStyles.h3()),
                    Text('आरोग्य नोंदी व लसीकरण इतिहास', style: AppTextStyles.caption(color: AppColors.neutral500)),
                  ],
                ),
                TextButton.icon(
                  onPressed: _openAddEventDialog,
                  icon: const Icon(PhosphorIconsRegular.plus, size: 16, color: AppColors.primary600),
                  label: Text('Add Record', style: AppTextStyles.label(color: AppColors.primary600)),
                ),
              ],
            ),
            AppSpacing.vSpace12,

            // Timeline List
            if (_isLoadingEvents)
              const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
            else if (_timelineEvents.isEmpty)
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(PhosphorIconsRegular.clipboardText, size: 40, color: AppColors.neutral300),
                      const SizedBox(height: 8),
                      Text('No health events logged yet', style: AppTextStyles.body(color: AppColors.neutral700)),
                      const SizedBox(height: 12),
                      BioHerdButton(
                        label: 'Record First Checkup',
                        isFullWidth: false,
                        onPressed: _openAddEventDialog,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timelineEvents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ev = _timelineEvents[index];
                  IconData icon;
                  Color iconColor;
                  switch (ev.eventType.toLowerCase()) {
                    case 'vaccination':
                      icon = PhosphorIconsRegular.syringe;
                      iconColor = AppColors.primary600;
                      break;
                    case 'disease':
                      icon = PhosphorIconsRegular.warning;
                      iconColor = AppColors.danger600;
                      break;
                    case 'quarantine':
                      icon = PhosphorIconsRegular.shieldWarning;
                      iconColor = AppColors.warning600;
                      break;
                    default:
                      icon = PhosphorIconsRegular.stethoscope;
                      iconColor = AppColors.info600;
                  }

                  return BioHerdCard(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        AppSpacing.hSpace12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.description, style: AppTextStyles.body()),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    ev.recordedBy,
                                    style: AppTextStyles.caption(color: AppColors.neutral700).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${ev.occurredAt.day}/${ev.occurredAt.month}/${ev.occurredAt.year}',
                                    style: AppTextStyles.caption(color: AppColors.neutral500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
