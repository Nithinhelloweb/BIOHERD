import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/animal_card.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/bioherd_input_field.dart';
import 'package:bioherd/core/widgets/skeleton_loader.dart';
import 'package:bioherd/features/animals/bloc/animal_bloc.dart';
import 'package:bioherd/features/animals/models/animal_model.dart';
import 'package:bioherd/features/animals/presentation/animal_detail_screen.dart';
import 'package:bioherd/features/animals/presentation/register_animal_screen.dart';
import 'package:bioherd/features/animals/presentation/widgets/qr_scan_dialog.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AnimalBloc>();
    if (bloc.state is! AnimalLoaded) {
      bloc.add(const LoadAnimalsEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScannerModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => QRScanDialog(
        onTagDetected: (scannedTag) {
          context.read<AnimalBloc>().add(LookupTagEvent(scannedTag));
        },
      ),
    );
  }

  void _onSpeciesSelected(AnimalSpeciesEnum? species) {
    context.read<AnimalBloc>().add(FilterAnimalsEvent(
      species: species,
      searchQuery: _searchController.text,
    ));
  }

  void _onSearchChanged(String query) {
    final state = context.read<AnimalBloc>().state;
    final currentSpecies = state is AnimalLoaded ? state.selectedSpecies : null;
    context.read<AnimalBloc>().add(FilterAnimalsEvent(
      species: currentSpecies,
      searchQuery: query,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnimalBloc, AnimalState>(
      listener: (context, state) {
        if (state is AnimalLoaded && state.lookedUpAnimal != null) {
          final found = state.lookedUpAnimal!;
          context.read<AnimalBloc>().add(const ClearLookupTagEvent());
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AnimalBloc>(),
                child: AnimalDetailScreen(animal: found),
              ),
            ),
          );
        } else if (state is AnimalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger600,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.neutral50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Livestock Registry', style: AppTextStyles.h3()),
                Text('पशुधन नोंदणी व आरोग्य व्यवस्थापन', style: AppTextStyles.caption(color: AppColors.neutral500)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Scan QR Tag',
                icon: const Icon(PhosphorIconsRegular.qrCode, color: AppColors.primary600, size: 26),
                onPressed: _openScannerModal,
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
            icon: const Icon(PhosphorIconsRegular.plus, size: 20),
            label: Text(
              'Register Animal / नोंदणी',
              style: AppTextStyles.label(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AnimalBloc>(),
                    child: const RegisterAnimalScreen(),
                  ),
                ),
              );
            },
          ),
          body: RefreshIndicator(
            color: AppColors.primary600,
            onRefresh: () async {
              context.read<AnimalBloc>().add(const LoadAnimalsEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Stats Row
                  if (state is AnimalLoaded) ...[
                    _buildStatsRow(state.stats),
                    AppSpacing.vSpace16,
                  ],

                  // Search Bar with QR Shortcut
                  Row(
                    children: [
                      Expanded(
                        child: BioHerdInputField(
                          label: 'Search Livestock',
                          hintText: 'Search by Tag ID, breed, notes...',
                          controller: _searchController,
                          prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.neutral500),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary100),
                        ),
                        child: IconButton(
                          tooltip: 'Scan Ear Tag QR',
                          icon: const Icon(PhosphorIconsRegular.scan, color: AppColors.primary600),
                          onPressed: _openScannerModal,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSpace16,

                  // Species Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All / सर्व',
                          isSelected: state is AnimalLoaded && state.selectedSpecies == null,
                          onTap: () => _onSpeciesSelected(null),
                        ),
                        const SizedBox(width: 8),
                        ...AnimalSpeciesEnum.values.map((species) {
                          final isSelected = state is AnimalLoaded && state.selectedSpecies == species;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: species.displayName,
                              icon: species.icon,
                              isSelected: isSelected,
                              onTap: () => _onSpeciesSelected(species),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  AppSpacing.vSpace16,

                  // Animal List
                  if (state is AnimalLoading) ...[
                    for (int i = 0; i < 4; i++) ...[
                      const AnimalCardSkeleton(),
                      AppSpacing.vSpace12,
                    ],
                  ] else if (state is AnimalLoaded) ...[
                    if (state.filteredAnimals.isEmpty)
                      _buildEmptyState()
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Registered Herd (${state.filteredAnimals.length})',
                            style: AppTextStyles.h3().copyWith(fontSize: 16),
                          ),
                          if (state.pendingSyncCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.warning600.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIconsRegular.cloudArrowUp, size: 14, color: AppColors.warning600),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${state.pendingSyncCount} offline changes',
                                    style: AppTextStyles.caption(color: AppColors.warning600).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.vSpace12,

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.filteredAnimals.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final animal = state.filteredAnimals[index];
                          return AnimalCard(
                            tagId: animal.tagId,
                            species: animal.species.displayName,
                            breed: animal.breed,
                            lastHealthEventDate: animal.lastCheckDate,
                            activeSeverity: animal.healthStatus.severityLevel,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<AnimalBloc>(),
                                    child: AnimalDetailScreen(animal: animal),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80), // padding for FAB
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(AnimalStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Herd', '${stats.total}', AppColors.primary600, AppColors.primary50),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('Healthy', '${stats.healthy}', AppColors.success600, AppColors.success100),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('Under Obs', '${stats.underObservation}', AppColors.warning600, AppColors.warning100),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('Alert/Sick', '${stats.sick}', AppColors.danger600, AppColors.danger100),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h2(color: textColor).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(color: textColor).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.neutral700),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.caption(
              color: isSelected ? Colors.white : AppColors.neutral700,
            ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
          ),
        ],
      ),
      selectedColor: AppColors.primary600,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary600 : AppColors.neutral300,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildEmptyState() {
    return BioHerdCard(
      padding: const EdgeInsets.all(AppSpacing.space24),
      child: Center(
        child: Column(
          children: [
            const Icon(PhosphorIconsRegular.cow, size: 48, color: AppColors.neutral300),
            const SizedBox(height: 12),
            Text(
              'No Livestock Found',
              style: AppTextStyles.h3(color: AppColors.neutral900),
            ),
            const SizedBox(height: 4),
            Text(
              'No animals match the selected filters or search query.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _onSpeciesSelected(null);
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
