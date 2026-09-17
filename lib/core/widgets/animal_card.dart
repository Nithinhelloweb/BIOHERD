import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'bioherd_card.dart';
import 'severity_badge.dart';

/// AnimalCard
/// Primary list and summary card representing a registered livestock animal.
/// Displays species icon, ear tag / RFID code, breed, recent activity, and optional health triage badge.
class AnimalCard extends StatelessWidget {
  final String tagId;
  final String species;
  final String breed;
  final String? lastHealthEventDate;
  final SeverityLevel? activeSeverity;
  final VoidCallback? onTap;

  const AnimalCard({
    super.key,
    required this.tagId,
    required this.species,
    required this.breed,
    this.lastHealthEventDate,
    this.activeSeverity,
    this.onTap,
  });

  IconData _getSpeciesIcon(String speciesName) {
    final lower = speciesName.toLowerCase();
    if (lower.contains('cow') || lower.contains('cattle') || lower.contains('bull') || lower.contains('गाय')) {
      return PhosphorIconsRegular.cow;
    }
    if (lower.contains('buffalo') || lower.contains('म्हैस')) {
      return PhosphorIconsRegular.shieldChevron;
    }
    if (lower.contains('sheep') || lower.contains('goat') || lower.contains('शेळी') || lower.contains('मेंढी')) {
      return PhosphorIconsRegular.pawPrint;
    }
    if (lower.contains('poultry') || lower.contains('chicken') || lower.contains('कोंबडी')) {
      return PhosphorIconsRegular.egg;
    }
    return PhosphorIconsRegular.cow;
  }

  @override
  Widget build(BuildContext context) {
    final speciesIcon = _getSpeciesIcon(species);

    return Semantics(
      button: onTap != null,
      label: 'Animal tag: $tagId, Species: $species, Breed: $breed${activeSeverity != null ? ", Severity: ${activeSeverity!.name}" : ""}',
      child: BioHerdCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
        child: Row(
          children: [
            // Species Circular Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary100, width: 1.5),
              ),
              child: Icon(
                speciesIcon,
                color: AppColors.primary600,
                size: 26,
              ),
            ),
            AppSpacing.hSpace16,

            // Center details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tagId,
                    style: AppTextStyles.h3().copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$species • $breed',
                    style: AppTextStyles.bodySmall(color: AppColors.neutral700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lastHealthEventDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last check: $lastHealthEventDate',
                      style: AppTextStyles.caption(color: AppColors.neutral500),
                    ),
                  ],
                ],
              ),
            ),

            // Right: Severity Badge
            if (activeSeverity != null) ...[
              AppSpacing.hSpace8,
              SeverityBadge(level: activeSeverity!),
            ] else
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: AppColors.neutral300,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
