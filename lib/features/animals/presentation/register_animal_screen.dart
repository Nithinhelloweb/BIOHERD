import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/bioherd_input_field.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';

class RegisterAnimalScreen extends StatefulWidget {
  const RegisterAnimalScreen({super.key});

  @override
  State<RegisterAnimalScreen> createState() => _RegisterAnimalScreenState();
}

class _RegisterAnimalScreenState extends State<RegisterAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tagController;
  late final TextEditingController _notesController;

  AnimalSpeciesEnum _selectedSpecies = AnimalSpeciesEnum.cattle;
  String _selectedBreed = 'Gir';
  String _selectedSex = 'female';
  int _ageMonths = 24;
  double _weightKg = 380.0;
  final HealthStatus _initialHealthStatus = HealthStatus.healthy;

  List<Breed> _availableBreeds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: _generateEarTag(_selectedSpecies));
    _notesController = TextEditingController();
    _loadBreeds();
  }

  @override
  void dispose() {
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateEarTag(AnimalSpeciesEnum species) {
    final code = switch (species) {
      AnimalSpeciesEnum.cattle => 'CAT',
      AnimalSpeciesEnum.buffalo => 'BUF',
      AnimalSpeciesEnum.goat => 'GOT',
      AnimalSpeciesEnum.sheep => 'SHP',
      AnimalSpeciesEnum.poultry => 'PLT',
      AnimalSpeciesEnum.pig => 'PIG',
    };
    final rand = 100000 + Random().nextInt(900000);
    return 'IN-MH-$code-$rand';
  }

  Future<void> _loadBreeds() async {
    final repo = context.read<AnimalBloc>().repository;
    final breeds = await repo.getBreeds(species: _selectedSpecies);
    if (mounted) {
      setState(() {
        _availableBreeds = breeds;
        if (breeds.isNotEmpty && !breeds.any((b) => b.name == _selectedBreed)) {
          _selectedBreed = breeds.first.name;
        }
      });
    }
  }

  void _onSpeciesChanged(AnimalSpeciesEnum species) {
    setState(() {
      _selectedSpecies = species;
      _tagController.text = _generateEarTag(species);
      switch (species) {
        case AnimalSpeciesEnum.cattle:
          _weightKg = 380.0;
          break;
        case AnimalSpeciesEnum.buffalo:
          _weightKg = 520.0;
          break;
        case AnimalSpeciesEnum.goat:
          _weightKg = 35.0;
          break;
        case AnimalSpeciesEnum.sheep:
          _weightKg = 40.0;
          break;
        case AnimalSpeciesEnum.poultry:
          _weightKg = 1.8;
          break;
        case AnimalSpeciesEnum.pig:
          _weightKg = 120.0;
          break;
      }
    });
    _loadBreeds();
  }

  void _submitRegistration() {
    if (_tagController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ear tag ID is required'),
          backgroundColor: AppColors.danger600,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dob = DateTime.now().subtract(Duration(days: (_ageMonths * 30.44).round()));
    final newAnimal = Animal(
      id: 'anim-${DateTime.now().millisecondsSinceEpoch}',
      farmId: 'farm-shinde-01',
      species: _selectedSpecies,
      breed: _selectedBreed,
      sex: _selectedSex,
      dob: dob,
      weightKg: _weightKg,
      tagId: _tagController.text.trim().toUpperCase(),
      createdAt: DateTime.now(),
      healthStatus: _initialHealthStatus,
      lastCheckDate: 'Today (Registered)',
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    context.read<AnimalBloc>().add(RegisterAnimalEvent(newAnimal));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Livestock ${newAnimal.tagId} registered successfully!'),
        backgroundColor: AppColors.primary600,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text('Register Livestock', style: AppTextStyles.h3()),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction Banner
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space12),
                backgroundColor: AppColors.primary50,
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.info, color: AppColors.primary600, size: 24),
                    AppSpacing.hSpace12,
                    Expanded(
                      child: Text(
                        'Department of Animal Husbandry, Govt of Maharashtra official registry entry.',
                        style: AppTextStyles.caption(color: AppColors.neutral900),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // Ear Tag Section
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Ear Tag / RFID ID',
                      style: AppTextStyles.label(color: AppColors.neutral700).copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vSpace8,
                    Row(
                      children: [
                        Expanded(
                          child: BioHerdInputField(
                            label: 'Ear Tag ID (कानपट्टी क्रमांक)',
                            controller: _tagController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Regenerate Tag ID',
                          icon: const Icon(PhosphorIconsRegular.arrowsClockwise, color: AppColors.primary600),
                          onPressed: () {
                            setState(() {
                              _tagController.text = _generateEarTag(_selectedSpecies);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // Species Selection
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Species Category / प्रजाती',
                      style: AppTextStyles.label(color: AppColors.neutral700).copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vSpace12,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AnimalSpeciesEnum.values.map((s) {
                        final isSelected = _selectedSpecies == s;
                        return ChoiceChip(
                          selected: isSelected,
                          selectedColor: AppColors.primary100,
                          backgroundColor: AppColors.neutral50,
                          side: BorderSide(color: isSelected ? AppColors.primary600 : AppColors.neutral300),
                          avatar: Icon(s.icon, size: 16, color: isSelected ? AppColors.primary600 : AppColors.neutral500),
                          label: Text(
                            s.displayName,
                            style: AppTextStyles.caption(
                              color: isSelected ? AppColors.primary600 : AppColors.neutral700,
                            ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
                          ),
                          onSelected: (_) => _onSpeciesChanged(s),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // Breed & Sex Card
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breed & Gender / जात व लिंग',
                      style: AppTextStyles.label(color: AppColors.neutral700).copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppSpacing.vSpace12,

                    // Maharashtra Indigenous Breed Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _availableBreeds.any((b) => b.name == _selectedBreed)
                          ? _selectedBreed
                          : (_availableBreeds.isNotEmpty ? _availableBreeds.first.name : null),
                      decoration: InputDecoration(
                        labelText: 'Indigenous Breed (महाराष्ट्रातील देशी जात)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _availableBreeds.map((b) {
                        return DropdownMenuItem(
                          value: b.name,
                          child: Text(
                            '${b.name} (${b.nameMr}) • ${b.originRegion}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBreed = val);
                      },
                    ),
                    AppSpacing.vSpace16,

                    // Sex Radio
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedSex == 'female' ? AppColors.primary50 : Colors.white,
                              side: BorderSide(
                                color: _selectedSex == 'female' ? AppColors.primary600 : AppColors.neutral300,
                                width: _selectedSex == 'female' ? 2 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(
                              PhosphorIconsRegular.genderFemale,
                              color: _selectedSex == 'female' ? AppColors.primary600 : AppColors.neutral500,
                            ),
                            label: Text(
                              'Female / मादी',
                              style: AppTextStyles.body(
                                color: _selectedSex == 'female' ? AppColors.primary600 : AppColors.neutral700,
                              ).copyWith(fontWeight: _selectedSex == 'female' ? FontWeight.w700 : FontWeight.normal),
                            ),
                            onPressed: () => setState(() => _selectedSex = 'female'),
                          ),
                        ),
                        AppSpacing.hSpace12,
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedSex == 'male' ? AppColors.primary50 : Colors.white,
                              side: BorderSide(
                                color: _selectedSex == 'male' ? AppColors.primary600 : AppColors.neutral300,
                                width: _selectedSex == 'male' ? 2 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(
                              PhosphorIconsRegular.genderMale,
                              color: _selectedSex == 'male' ? AppColors.primary600 : AppColors.neutral500,
                            ),
                            label: Text(
                              'Male / नर',
                              style: AppTextStyles.body(
                                color: _selectedSex == 'male' ? AppColors.primary600 : AppColors.neutral700,
                              ).copyWith(fontWeight: _selectedSex == 'male' ? FontWeight.w700 : FontWeight.normal),
                            ),
                            onPressed: () => setState(() => _selectedSex = 'male'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // Age and Weight Row
              BioHerdCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  children: [
                    // Age Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Age / वय', style: AppTextStyles.label(color: AppColors.neutral700)),
                            Text('$_ageMonths months (${(_ageMonths / 12).toStringAsFixed(1)} yrs)',
                                style: AppTextStyles.h3(color: AppColors.primary600)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(PhosphorIconsRegular.minusCircle, color: AppColors.primary600),
                              onPressed: () {
                                if (_ageMonths > 1) setState(() => _ageMonths--);
                              },
                            ),
                            IconButton(
                              icon: const Icon(PhosphorIconsRegular.plusCircle, color: AppColors.primary600),
                              onPressed: () => setState(() => _ageMonths++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Weight Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weight / वजन', style: AppTextStyles.label(color: AppColors.neutral700)),
                            Text('${_weightKg.toStringAsFixed(1)} kg', style: AppTextStyles.h3(color: AppColors.primary600)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(PhosphorIconsRegular.minusCircle, color: AppColors.primary600),
                              onPressed: () {
                                if (_weightKg > 1.0) {
                                  setState(() => _weightKg = max(0.5, _weightKg - 5.0));
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(PhosphorIconsRegular.plusCircle, color: AppColors.primary600),
                              onPressed: () => setState(() => _weightKg += 5.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpace16,

              // Notes / Markings
              BioHerdInputField(
                label: 'Identification Markings & Notes (ओळख खूण)',
                hintText: 'e.g. White star on forehead, twin born, vaccinated',
                controller: _notesController,
                maxLines: 2,
              ),
              AppSpacing.vSpace24,

              // Submit Button
              BioHerdButton(
                label: 'Register Livestock / पशु नोंदणी पूर्ण करा',
                icon: const Icon(PhosphorIconsRegular.checkCircle, color: Colors.white, size: 20),
                isLoading: _isLoading,
                onPressed: _submitRegistration,
              ),
              AppSpacing.vSpace20,
            ],
          ),
        ),
      ),
    );
  }
}
