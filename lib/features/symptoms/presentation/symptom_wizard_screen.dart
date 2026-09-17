import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/ai_confidence_meter.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/bioherd_input_field.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/symptoms/bloc/symptom_bloc.dart';
import 'package:bioherd/features/symptoms/presentation/ai_results_screen.dart';

/// 5-Step Symptom Reporting & AI Disease Detection Wizard Screen
/// Steps:
/// 0. Select Animal (जनावर निवडा)
/// 1. Photo Capture / Upload (छायाचित्रे)
/// 2. Body System Checklist (लक्षणे सूची)
/// 3. Marathi Vernacular Note & Voice (आवाजी संदेश व शेरा)
/// 4. Review & AI Diagnosis (पडताळणी व AI निष्कर्ष)
class SymptomWizardScreen extends StatefulWidget {
  final AnimalModel? initialAnimal;

  const SymptomWizardScreen({super.key, this.initialAnimal});

  @override
  State<SymptomWizardScreen> createState() => _SymptomWizardScreenState();
}

class _SymptomWizardScreenState extends State<SymptomWizardScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _animalSearchController = TextEditingController();
  String _animalSearchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SymptomBloc>().add(InitSymptomWizardEvent(initialAnimal: widget.initialAnimal));
  }

  @override
  void dispose() {
    _descController.dispose();
    _animalSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SymptomBloc, SymptomState>(
      listener: (context, state) {
        if (state is SymptomWizardState && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger600,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! SymptomWizardState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final wizardState = state;
        final step = wizardState.currentStep;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Symptom Reporting',
                  style: AppTextStyles.h3(color: AppColors.neutral900),
                ),
                Text(
                  _getStepSubtitle(step),
                  style: AppTextStyles.caption(color: AppColors.neutral500),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.x, color: AppColors.neutral900),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // Stepper progress indicator
              _buildProgressHeader(step),

              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  child: _buildCurrentStepContent(context, wizardState),
                ),
              ),

              // Bottom Navigation Bar
              _buildBottomActions(context, wizardState),
            ],
          ),
        );
      },
    );
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'पायरी १/५: जनावर निवडा';
      case 1:
        return 'पायरी २/५: छायाचित्र जोडा';
      case 2:
        return 'पायरी ३/५: लक्षणे सूची';
      case 3:
        return 'पायरी ४/५: शेरा व आवाज नोंद';
      case 4:
        return 'पायरी ५/५: AI निदान व निष्कर्ष';
      default:
        return '';
    }
  }

  Widget _buildProgressHeader(int step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: 12),
      color: AppColors.neutral50,
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < step;
          final isCurrent = index == step;
          final color = isCurrent
              ? AppColors.primary600
              : (isCompleted ? AppColors.success600 : AppColors.neutral300);

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary50
                        : (isCompleted ? AppColors.success50 : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: isCurrent ? 2 : 1.5),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(PhosphorIconsRegular.check, size: 14, color: AppColors.success600)
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.caption(
                              color: isCurrent ? AppColors.primary600 : AppColors.neutral500,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? AppColors.success600 : AppColors.neutral200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context, SymptomWizardState state) {
    switch (state.currentStep) {
      case 0:
        return _buildAnimalSelectionStep(context, state);
      case 1:
        return _buildPhotoCaptureStep(context, state);
      case 2:
        return _buildChecklistStep(context, state);
      case 3:
        return _buildVernacularNoteStep(context, state);
      case 4:
        return _buildReviewAndDiagnosisStep(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  // ================= STEP 0: ANIMAL SELECTION =================
  Widget _buildAnimalSelectionStep(BuildContext context, SymptomWizardState state) {
    if (state.selectedAnimal != null) {
      final a = state.selectedAnimal!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Animal / निवडलेले जनावर', style: AppTextStyles.h3()),
          AppSpacing.vSpace12,
          BioHerdCard(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a.species.icon, color: AppColors.primary600, size: 30),
                ),
                AppSpacing.hSpace16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.tagId, style: AppTextStyles.h3()),
                      Text('${a.breed} • ${a.species.displayName}', style: AppTextStyles.body(color: AppColors.neutral600)),
                      const SizedBox(height: 4),
                      SeverityBadge(level: a.healthStatus.severityLevel),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<SymptomBloc>().add(const InitSymptomWizardEvent());
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,
          BioHerdCard(
            backgroundColor: AppColors.primary50,
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.shieldCheck, color: AppColors.primary600, size: 24),
                AppSpacing.hSpace12,
                Expanded(
                  child: Text(
                    'Animal tag ID verified against Maharashtra INAPH database. Tap "Next" to attach photos and clinical symptoms.',
                    style: AppTextStyles.caption(color: AppColors.primary700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Patient Animal', style: AppTextStyles.h3()),
        Text('आजार तपासणीसाठी आपल्या गोठ्यातील जनावर निवडा', style: AppTextStyles.caption(color: AppColors.neutral500)),
        AppSpacing.vSpace16,

        // Search Box
        TextField(
          controller: _animalSearchController,
          decoration: InputDecoration(
            hintText: 'Search Tag ID or Breed...',
            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => _animalSearchQuery = val.trim().toLowerCase()),
        ),
        AppSpacing.vSpace16,

        // Herd list from AnimalBloc
        BlocBuilder<AnimalBloc, AnimalState>(
          builder: (context, animalState) {
            List<AnimalModel> animals = [];
            if (animalState is AnimalLoaded) {
              animals = animalState.allAnimals;
            }

            if (_animalSearchQuery.isNotEmpty) {
              animals = animals.where((a) {
                return a.tagId.toLowerCase().contains(_animalSearchQuery) ||
                    a.breed.toLowerCase().contains(_animalSearchQuery) ||
                    a.species.displayName.toLowerCase().contains(_animalSearchQuery);
              }).toList();
            }

            if (animals.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const Icon(PhosphorIconsRegular.cow, size: 48, color: AppColors.neutral300),
                      const SizedBox(height: 8),
                      Text('No matching animals found', style: AppTextStyles.body(color: AppColors.neutral600)),
                      const SizedBox(height: 12),
                      BioHerdButton(
                        label: 'Register Mock Cattle MH-PUN-019',
                        isFullWidth: false,
                        onPressed: () {
                          final dummy = Animal(
                            id: 'mock-019',
                            farmId: 'farm-001',
                            species: AnimalSpeciesEnum.cattle,
                            breed: 'Gir / गीर',
                            sex: 'Female',
                            tagId: 'MH-PUN-019',
                            createdAt: DateTime.now(),
                          );
                          context.read<SymptomBloc>().add(SelectWizardAnimalEvent(dummy));
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
              itemCount: animals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = animals[index];
                return InkWell(
                  onTap: () {
                    context.read<SymptomBloc>().add(SelectWizardAnimalEvent(a));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: BioHerdCard(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.species.icon, color: AppColors.primary600, size: 24),
                        ),
                        AppSpacing.hSpace12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.tagId, style: AppTextStyles.label().copyWith(fontWeight: FontWeight.bold)),
                              Text('${a.breed} • ${a.species.displayName}', style: AppTextStyles.caption(color: AppColors.neutral600)),
                            ],
                          ),
                        ),
                        SeverityBadge(level: a.healthStatus.severityLevel),
                        const SizedBox(width: 8),
                        const Icon(PhosphorIconsRegular.caretRight, color: AppColors.neutral400, size: 18),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ================= STEP 1: PHOTO CAPTURE =================
  Widget _buildPhotoCaptureStep(BuildContext context, SymptomWizardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capture Clinical Photos', style: AppTextStyles.h3()),
        Text('त्वचा, तोंड किंवा कासेची छायाचित्रे जोडा (ऐच्छिक परंतु अत्यंत उपयुक्त)', style: AppTextStyles.caption(color: AppColors.neutral500)),
        AppSpacing.vSpace16,

        // Guidance banner
        BioHerdCard(
          backgroundColor: AppColors.info50,
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(PhosphorIconsRegular.camera, color: AppColors.info600, size: 24),
              AppSpacing.hSpace12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photography Protocol / छायाचित्र टिप्स', style: AppTextStyles.label(color: AppColors.info800)),
                    const SizedBox(height: 4),
                    Text(
                      '• Photograph under direct bright daylight\n• Keep camera 1–2 feet away from lesions\n• Visual analysis contributes 35% weight to BIOHERD AI ensemble',
                      style: AppTextStyles.caption(color: AppColors.info700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vSpace16,

        // Photos Grid or empty state
        if (state.photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neutral300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.neutral50,
            ),
            child: Column(
              children: [
                const Icon(PhosphorIconsRegular.image, size: 44, color: AppColors.neutral400),
                const SizedBox(height: 10),
                Text('No photos attached yet', style: AppTextStyles.body(color: AppColors.neutral600)),
                const SizedBox(height: 4),
                Text('Add lesion photos for computer vision diagnostic boost', style: AppTextStyles.caption(color: AppColors.neutral500)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final photo = state.photos[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary300),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsRegular.fileImage, size: 32, color: AppColors.primary700),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              photo.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: AppColors.primary900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => context.read<SymptomBloc>().add(RemoveWizardPhotoEvent(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsRegular.x, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        AppSpacing.vSpace16,

        // Quick simulation buttons
        Text('Quick Sample Lesions / प्रात्यक्षिक फोटो:', style: AppTextStyles.label()),
        AppSpacing.vSpace8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(PhosphorIconsRegular.plus, size: 14),
              label: const Text('Nodular Bumps (LSD)'),
              onPressed: () {
                context.read<SymptomBloc>().add(const AddWizardPhotoEvent('nodular_skin_lesions.jpg'));
              },
            ),
            ActionChip(
              avatar: const Icon(PhosphorIconsRegular.plus, size: 14),
              label: const Text('Oral Blisters (FMD)'),
              onPressed: () {
                context.read<SymptomBloc>().add(const AddWizardPhotoEvent('mouth_tongue_blisters.jpg'));
              },
            ),
            ActionChip(
              avatar: const Icon(PhosphorIconsRegular.plus, size: 14),
              label: const Text('Udder Swelling (Mastitis)'),
              onPressed: () {
                context.read<SymptomBloc>().add(const AddWizardPhotoEvent('udder_swelling_mastitis.jpg'));
              },
            ),
            ActionChip(
              avatar: const Icon(PhosphorIconsRegular.plus, size: 14),
              label: const Text('Leg Muscle Swelling (BQ)'),
              onPressed: () {
                context.read<SymptomBloc>().add(const AddWizardPhotoEvent('muscle_swelling_bq.jpg'));
              },
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 2: MULTI-SYSTEM CHECKLIST =================
  Widget _buildChecklistStep(BuildContext context, SymptomWizardState state) {
    final categories = context.read<SymptomBloc>().repository.getBodySystemCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clinical Symptoms Checklist', style: AppTextStyles.h3()),
                Text('दिसणारी लक्षणे निवडा (४५% AI वेटेज)', style: AppTextStyles.caption(color: AppColors.neutral500)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${state.totalSymptomsSelected} Selected',
                style: AppTextStyles.caption(color: AppColors.primary700).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        AppSpacing.vSpace16,

        // Categories list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, catIndex) {
            final cat = categories[catIndex];
            final selectedInCat = state.selectedSymptoms[cat.id] ?? <String>{};

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: BioHerdCard(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: ExpansionTile(
                  initiallyExpanded: catIndex == 0 || selectedInCat.isNotEmpty,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedInCat.isNotEmpty ? AppColors.primary100 : AppColors.neutral100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(cat.iconKey),
                      size: 20,
                      color: selectedInCat.isNotEmpty ? AppColors.primary700 : AppColors.neutral600,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.nameEn, style: AppTextStyles.label().copyWith(fontWeight: FontWeight.bold)),
                            Text(cat.nameMr, style: AppTextStyles.caption(color: AppColors.neutral500)),
                          ],
                        ),
                      ),
                      if (selectedInCat.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${selectedInCat.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cat.symptoms.map((symptom) {
                          final isSelected = selectedInCat.contains(symptom.id);
                          return FilterChip(
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(symptom.nameEn),
                                Text(symptom.nameMr, style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary100,
                            checkmarkColor: AppColors.primary700,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary800 : AppColors.neutral800,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            onSelected: (_) {
                              context.read<SymptomBloc>().add(
                                    ToggleWizardSymptomEvent(
                                      systemId: cat.id,
                                      symptomId: symptom.id,
                                    ),
                                  );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'thermometer':
        return PhosphorIconsRegular.thermometer;
      case 'shield':
        return PhosphorIconsRegular.shieldCheck;
      case 'drop':
        return PhosphorIconsRegular.drop;
      case 'pawPrint':
        return PhosphorIconsRegular.pawPrint;
      case 'cow':
        return PhosphorIconsRegular.cow;
      case 'heartbeat':
      default:
        return PhosphorIconsRegular.heartbeat;
    }
  }

  // ================= STEP 3: VERNACULAR NOTE & VOICE =================
  Widget _buildVernacularNoteStep(BuildContext context, SymptomWizardState state) {
    if (_descController.text.isEmpty && state.vernacularDescription.isNotEmpty) {
      _descController.text = state.vernacularDescription;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vernacular Marathi / Voice Input', style: AppTextStyles.h3()),
        Text('आपल्या स्थानिक भाषेत लक्षणे सांगा किंवा नोंदवा (२०% AI वेटेज)', style: AppTextStyles.caption(color: AppColors.neutral500)),
        AppSpacing.vSpace16,

        // Fast Marathi phrases
        Text('Common Vernacular Phrases (एक क्लिक मध्ये जोडा):', style: AppTextStyles.label()),
        AppSpacing.vSpace8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('अंगावर भरपूर गाठी व ताप (LSD)'),
              onPressed: () => _appendPhrase('अंगावर भरपूर गाठी व ताप आहे'),
            ),
            ActionChip(
              label: const Text('तोंडातून फेस, सतत लाळ व जीभ लाल (FMD)'),
              onPressed: () => _appendPhrase('तोंडाला फेस येत आहे व लाळ गळते आहे'),
            ),
            ActionChip(
              label: const Text('कास गरम, सुजलेली व दुधात गाठी (Mastitis)'),
              onPressed: () => _appendPhrase('कास खूप सुजली आहे आणि दुधात गाठी येतात'),
            ),
            ActionChip(
              label: const Text('मांडीवर चरचर वाजणारी सूज (Black Quarter)'),
              onPressed: () => _appendPhrase('मांडीवर सूज आहे आणि लंगडत चालते'),
            ),
            ActionChip(
              label: const Text('घसा सुजला व घरघर आवाज (HS)'),
              onPressed: () => _appendPhrase('घसा सुजला आहे आणि श्वास घेताना त्रास होतो'),
            ),
            ActionChip(
              label: const Text('लघवी गडद लाल / कॉफी रंग (Babesiosis)'),
              onPressed: () => _appendPhrase('लघवी कॉफी रंगाची येत आहे'),
            ),
          ],
        ),
        AppSpacing.vSpace16,

        // Text area
        BioHerdInputField(
          label: 'Farmer Symptoms Description / सविस्तर वर्णन',
          hintText: 'उदा. दोन दिवसांपासून चारा खात नाही, अंगावर गाठी आहेत...',
          controller: _descController,
          maxLines: 4,
          onChanged: (val) {
            context.read<SymptomBloc>().add(SetWizardDescriptionEvent(val));
          },
        ),
        AppSpacing.vSpace20,

        // Voice Note Card
        BioHerdCard(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.microphone, color: AppColors.primary600, size: 24),
                  AppSpacing.hSpace12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marathi Voice Note / आवाजी नोंद', style: AppTextStyles.label().copyWith(fontWeight: FontWeight.bold)),
                        Text('ग्रामीण शेतकऱ्यांसाठी सुलभ व्हॉइस रेकॉर्डिंग', style: AppTextStyles.caption(color: AppColors.neutral500)),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpace16,
              if (state.voiceNoteUrl == null)
                BioHerdButton(
                  label: 'Record 4s Marathi Audio Note',
                  icon: const Icon(PhosphorIconsRegular.record, color: Colors.white, size: 18),
                  variant: BioHerdButtonVariant.danger,
                  onPressed: () {
                    context.read<SymptomBloc>().add(const SetWizardVoiceNoteEvent('audio_note_mh_019.wav'));
                    if (_descController.text.isEmpty) {
                      _descController.text = 'गाय चारा खात नाही, अंगावर गोल गाठी आल्या आहेत व ताप आहे.';
                      context.read<SymptomBloc>().add(SetWizardDescriptionEvent(_descController.text));
                    }
                  },
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success50,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success200),
                      ),
                      child: const Icon(PhosphorIconsRegular.play, color: AppColors.success600, size: 20),
                    ),
                    AppSpacing.hSpace12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recorded Voice Note (0:04)', style: AppTextStyles.label()),
                          Text('Transcribed into Marathi clinical NLP', style: AppTextStyles.caption(color: AppColors.neutral500)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger600),
                      onPressed: () {
                        context.read<SymptomBloc>().add(const SetWizardVoiceNoteEvent(''));
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _appendPhrase(String phrase) {
    if (_descController.text.trim().isEmpty) {
      _descController.text = phrase;
    } else {
      _descController.text = '${_descController.text}, $phrase';
    }
    context.read<SymptomBloc>().add(SetWizardDescriptionEvent(_descController.text));
  }

  // ================= STEP 4: REVIEW & AI DIAGNOSIS =================
  Widget _buildReviewAndDiagnosisStep(BuildContext context, SymptomWizardState state) {
    final animal = state.selectedAnimal;
    final diag = state.diagnosisResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Multi-Modal Diagnosis', style: AppTextStyles.h3()),
        Text('सर्व माहिती तपासा आणि BIOHERD AI विश्लेषण चालवा', style: AppTextStyles.caption(color: AppColors.neutral500)),
        AppSpacing.vSpace16,

        // Summary Card
        BioHerdCard(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Case Summary / सारांश', style: AppTextStyles.label().copyWith(fontWeight: FontWeight.bold)),
              const Divider(),
              _buildSummaryRow('Animal Tag:', animal?.tagId ?? 'None'),
              _buildSummaryRow('Species & Breed:', '${animal?.species.displayName} (${animal?.breed})'),
              _buildSummaryRow('Photos Attached:', '${state.photos.length} photos'),
              _buildSummaryRow('Selected Symptoms:', '${state.totalSymptomsSelected} clinical items'),
              if (state.vernacularDescription.isNotEmpty)
                _buildSummaryRow('Marathi Note:', state.vernacularDescription),
              if (state.voiceNoteUrl != null)
                _buildSummaryRow('Voice Recording:', 'Attached (0:04)'),
            ],
          ),
        ),
        AppSpacing.vSpace16,

        // If not yet analyzed
        if (diag == null) ...[
          BioHerdCard(
            backgroundColor: AppColors.primary50,
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.sparkle, color: AppColors.primary600, size: 24),
                    AppSpacing.hSpace12,
                    Text('BIOHERD Ensemble Model', style: AppTextStyles.h3(color: AppColors.primary700).copyWith(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Fuses Multi-System Checklist (45%), Computer Vision (35%), and Marathi Vernacular NLP (20%) calibrated against 10 endemic Maharashtra livestock diseases.',
                  style: AppTextStyles.caption(color: AppColors.primary800),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace24,

          if (state.isSubmitting)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary600),
                  const SizedBox(height: 16),
                  Text('Running AI Diagnosis Ensemble...', style: AppTextStyles.label()),
                  const SizedBox(height: 4),
                  Text('Calibrating softmax differential ranking...', style: AppTextStyles.caption(color: AppColors.neutral500)),
                ],
              ),
            )
          else
            BioHerdButton(
              label: 'Run AI Disease Diagnosis / AI विश्लेषण करा',
              icon: const Icon(PhosphorIconsRegular.sparkle, color: Colors.white, size: 20),
              onPressed: () {
                context.read<SymptomBloc>().add(const SubmitWizardReportEvent());
              },
            ),
        ] else ...[
          // Analysis Result Card
          BioHerdCard(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Primary AI Prediction', style: AppTextStyles.label(color: AppColors.neutral500)),
                    SeverityBadge(level: diag.severity),
                  ],
                ),
                AppSpacing.vSpace8,
                Text(diag.primaryDiagnosis.diseaseNameEn, style: AppTextStyles.h2()),
                Text(diag.primaryDiagnosis.diseaseNameMr, style: AppTextStyles.body(color: AppColors.primary700).copyWith(fontWeight: FontWeight.bold)),
                AppSpacing.vSpace12,

                // Confidence
                AIConfidenceMeter(confidence: diag.primaryDiagnosis.confidence),
                AppSpacing.vSpace16,

                // Escalation banner
                if (diag.escalatedToVet)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger200),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.warningCircle, color: AppColors.danger600, size: 22),
                        AppSpacing.hSpace12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('District Vet Escalation Alert', style: AppTextStyles.label(color: AppColors.danger800).copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                'Case ${state.submittedReport?.escalatedCaseId ?? "MH-PUN-VET-001"} dispatched to Taluka Veterinary Dispensary.',
                                style: AppTextStyles.caption(color: AppColors.danger700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                AppSpacing.vSpace16,

                // Action buttons
                BioHerdButton(
                  label: 'View Treatment & Biosecurity Protocols',
                  icon: const Icon(PhosphorIconsRegular.firstAid, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AIResultsScreen(
                          result: diag,
                          animalTagId: animal?.tagId ?? 'MH-ANIMAL',
                          caseId: state.submittedReport?.escalatedCaseId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                BioHerdButton(
                  label: 'Finish & Back to Animals',
                  variant: BioHerdButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.caption(color: AppColors.neutral500)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.caption(color: AppColors.neutral800).copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM NAVIGATION BAR =================
  Widget _buildBottomActions(BuildContext context, SymptomWizardState state) {
    final step = state.currentStep;
    final canGoBack = step > 0;
    final canGoNext = step < 4 && (step != 0 || state.selectedAnimal != null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canGoBack)
            Expanded(
              child: BioHerdButton(
                label: 'Back / मागे',
                variant: BioHerdButtonVariant.secondary,
                onPressed: () {
                  context.read<SymptomBloc>().add(SetWizardStepEvent(step - 1));
                },
              ),
            ),
          if (canGoBack && canGoNext) AppSpacing.hSpace12,
          if (canGoNext)
            Expanded(
              child: BioHerdButton(
                label: 'Next / पुढे',
                onPressed: () {
                  context.read<SymptomBloc>().add(SetWizardStepEvent(step + 1));
                },
              ),
            ),
        ],
      ),
    );
  }
}
