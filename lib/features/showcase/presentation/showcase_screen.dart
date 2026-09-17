import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/ai_confidence_meter.dart';
import '../../../core/widgets/animal_card.dart';
import '../../../core/widgets/bioherd_button.dart';
import '../../../core/widgets/bioherd_card.dart';
import '../../../core/widgets/bioherd_input_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/severity_badge.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// ShowcaseScreen
/// Phase 1 Design System & Component Verification Screen.
/// Proves design fidelity across all breakpoints, color tokens, component states, and multilingual switches.
class ShowcaseScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final Locale currentLocale;

  const ShowcaseScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
    required this.currentLocale,
  });

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  bool _isButtonLoading = false;
  bool _isOffline = false;
  bool _isSyncing = false;
  final int _syncPendingCount = 3;
  double _aiConfidence = 0.884;
  final TextEditingController _symptomInputController = TextEditingController();
  String? _inputError;

  @override
  void dispose() {
    _symptomInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDevanagari = widget.currentLocale.languageCode == 'mr' || widget.currentLocale.languageCode == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(PhosphorIconsFill.cow, color: Colors.white, size: 20),
            ),
            AppSpacing.hSpace12,
            Expanded(
              child: Text(
                'BIOHERD Design System',
                style: AppTextStyles.h2(
                  color: isDark ? AppColors.darkText : AppColors.primary600,
                  isDevanagari: isDevanagari,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Dropdown
          DropdownButton<String>(
            value: widget.currentLocale.languageCode,
            underline: const SizedBox(),
            icon: const Icon(PhosphorIconsRegular.globe),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
              DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
            ],
            onChanged: (lang) {
              if (lang != null) {
                widget.onLocaleChanged(Locale(lang));
              }
            },
          ),
          AppSpacing.hSpace12,

          // Dark/Light Mode Toggle
          IconButton(
            icon: Icon(
              isDark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
              size: 22,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              widget.onThemeModeChanged(newMode);
            },
          ),
          AppSpacing.hSpace16,
        ],
      ),
      body: Column(
        children: [
          // Persistent Offline & Sync Status Banner
          OfflineBanner(
            isOffline: _isOffline,
            isSyncing: _isSyncing,
            pendingSyncCount: _syncPendingCount,
          ),

          // Scrollable Design Catalog
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AdaptiveLayout.isMobile(context)
                    ? AppSpacing.screenMarginMobile
                    : AppSpacing.screenMarginWeb,
                vertical: AppSpacing.space20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(isDark, isDevanagari),
                      AppSpacing.vSpace24,

                      // Section 1: Color Tokens
                      _buildSectionTitle('1. Brand & Semantic Color Tokens', isDark),
                      AppSpacing.vSpace12,
                      _buildColorPaletteGrid(),
                      AppSpacing.vSpace32,

                      // Section 2: Typography Scale
                      _buildSectionTitle('2. Typography Scale (Nunito + Noto Sans Devanagari)', isDark),
                      AppSpacing.vSpace12,
                      _buildTypographyScale(isDevanagari),
                      AppSpacing.vSpace32,

                      // Section 3: Buttons & States (Hallmark 8-state verification)
                      _buildSectionTitle('3. Buttons (Primary, Secondary, Danger, Loading & Disabled)', isDark),
                      AppSpacing.vSpace12,
                      _buildButtonsGrid(),
                      AppSpacing.vSpace32,

                      // Section 4: Input Field & Voice Trigger
                      _buildSectionTitle('4. BioHerdInputField (Floating Label + Voice Input Attachment)', isDark),
                      AppSpacing.vSpace12,
                      _buildInputFieldsDemo(),
                      AppSpacing.vSpace32,

                      // Section 5: Cards & Severity Badges
                      _buildSectionTitle('5. SeverityBadges & Border-Tinted BioHerdCards', isDark),
                      AppSpacing.vSpace12,
                      _buildSeverityCardsDemo(),
                      AppSpacing.vSpace32,

                      // Section 6: AI Confidence Meter
                      _buildSectionTitle('6. AI Diagnostic Confidence Meter', isDark),
                      AppSpacing.vSpace12,
                      _buildConfidenceMeterDemo(),
                      AppSpacing.vSpace32,

                      // Section 7: Animal Registry Cards
                      _buildSectionTitle('7. AnimalCard Component (Species Avatars & Health Tags)', isDark),
                      AppSpacing.vSpace12,
                      _buildAnimalCardsDemo(),
                      AppSpacing.vSpace32,

                      // Section 8: Skeletons & Offline Controls
                      _buildSectionTitle('8. Offline Simulation & Shimmer Skeleton Loaders', isDark),
                      AppSpacing.vSpace12,
                      _buildSkeletonAndOfflineDemo(),
                      AppSpacing.vSpace48,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.h2(color: isDark ? AppColors.darkPrimary : AppColors.primary600),
    );
  }

  Widget _buildHeaderCard(bool isDark, bool isDevanagari) {
    return BioHerdCard(
      severity: CardSeverity.low,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.primary50,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(PhosphorIconsFill.shieldCheck, color: Colors.white, size: 32),
          ),
          AppSpacing.hSpace16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIOHERD — Phase 1 Design System',
                  style: AppTextStyles.h1().copyWith(fontSize: 20),
                ),
                AppSpacing.vSpace4,
                Text(
                  isDevanagari
                      ? 'निरोगी जनावरे. समृद्ध शेतकरी. (महाराष्ट्र शासन - स्मार्ट इंडिया हॅकेथॉन २०२६)'
                      : 'Healthy Animals. Prosperous Farmers. (Govt. of Maharashtra • SIH26128)',
                  style: AppTextStyles.body(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.neutral700,
                    isDevanagari: isDevanagari,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPaletteGrid() {
    final colors = [
      {'name': 'primary-600', 'color': AppColors.primary600, 'label': '#1B6B3A'},
      {'name': 'primary-500', 'color': AppColors.primary500, 'label': '#228B47'},
      {'name': 'primary-400', 'color': AppColors.primary400, 'label': '#2DAE5A'},
      {'name': 'primary-100', 'color': AppColors.primary100, 'label': '#D4EDDA'},
      {'name': 'danger-600', 'color': AppColors.danger600, 'label': '#C0392B'},
      {'name': 'warning-600', 'color': AppColors.warning600, 'label': '#D35400'},
      {'name': 'info-600', 'color': AppColors.info600, 'label': '#1A5276'},
      {'name': 'success-600', 'color': AppColors.success600, 'label': '#1E8449'},
    ];

    return Wrap(
      spacing: AppSpacing.space12,
      runSpacing: AppSpacing.space12,
      children: colors.map((c) {
        final color = c['color'] as Color;
        final isBright = color == AppColors.primary100;
        return Container(
          width: 130,
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c['name'] as String,
                style: AppTextStyles.label(color: isBright ? Colors.black87 : Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                c['label'] as String,
                style: AppTextStyles.caption(color: isBright ? Colors.black54 : Colors.white70),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypographyScale(bool isDevanagari) {
    return BioHerdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display (28sp, Bold) — BIOHERD Bio-surveillance',
              style: AppTextStyles.display(isDevanagari: isDevanagari)),
          const Divider(height: 20),
          Text('Headline 1 (24sp, Bold) — Disease Outbreak Monitor',
              style: AppTextStyles.h1(isDevanagari: isDevanagari)),
          const Divider(height: 20),
          Text('Headline 2 (20sp, Semi-Bold) — Clinical Case Queue',
              style: AppTextStyles.h2(isDevanagari: isDevanagari)),
          const Divider(height: 20),
          Text('Headline 3 (18sp, Semi-Bold) — Animal Health Profile',
              style: AppTextStyles.h3(isDevanagari: isDevanagari)),
          const Divider(height: 20),
          Text(
            'Body Large (16sp, Regular) — Rural farmers receive plain-language vernacular guidance.',
            style: AppTextStyles.bodyLarge(isDevanagari: isDevanagari),
          ),
          const Divider(height: 20),
          Text(
            'Body (14sp, Regular) — High contrast and readable at small sizes even under direct sunlight.',
            style: AppTextStyles.body(isDevanagari: isDevanagari),
          ),
          const Divider(height: 20),
          Text('Label (12sp, Semi-Bold) • Tag ID: MH-PUN-2026-9182',
              style: AppTextStyles.label(isDevanagari: isDevanagari)),
          const Divider(height: 20),
          Text('Caption (11sp, Regular Floor) — Verified by Animal Husbandry Dept. • Maharashtra',
              style: AppTextStyles.caption(isDevanagari: isDevanagari)),
        ],
      ),
    );
  }

  Widget _buildButtonsGrid() {
    return Wrap(
      spacing: AppSpacing.space16,
      runSpacing: AppSpacing.space16,
      children: [
        SizedBox(
          width: 200,
          child: BioHerdButton(
            label: 'Primary Button',
            icon: const Icon(PhosphorIconsRegular.paperPlaneRight, color: Colors.white, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Primary Action Triggered!')),
              );
            },
          ),
        ),
        SizedBox(
          width: 200,
          child: BioHerdButton(
            label: 'Secondary Action',
            variant: BioHerdButtonVariant.secondary,
            icon: const Icon(PhosphorIconsRegular.qrCode, color: AppColors.primary600, size: 18),
            onPressed: () {},
          ),
        ),
        SizedBox(
          width: 200,
          child: BioHerdButton(
            label: 'Danger Action',
            variant: BioHerdButtonVariant.danger,
            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.white, size: 18),
            onPressed: () {},
          ),
        ),
        SizedBox(
          width: 200,
          child: BioHerdButton(
            label: _isButtonLoading ? 'Processing...' : 'Toggle Loading',
            isLoading: _isButtonLoading,
            onPressed: () {
              setState(() => _isButtonLoading = !_isButtonLoading);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _isButtonLoading = false);
              });
            },
          ),
        ),
        SizedBox(
          width: 200,
          child: BioHerdButton(
            label: 'Disabled Button',
            onPressed: null,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldsDemo() {
    return BioHerdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BioHerdInputField(
            label: 'Symptom Description (लक्षण वर्णन)',
            hintText: 'e.g., High fever, swelling in legs, appetite loss...',
            helperText: 'Voice input supported in Marathi, Hindi & English (400 char max)',
            controller: _symptomInputController,
            errorText: _inputError,
            enableVoiceInput: true,
            maxLines: 3,
            onVoiceInputTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input recording started... (बोलणे सुरू करा)')),
              );
            },
            onChanged: (val) {
              if (val.length > 50 && _inputError == null) {
                setState(() => _inputError = 'Keep descriptions concise for better AI accuracy');
              } else if (val.length <= 50 && _inputError != null) {
                setState(() => _inputError = null);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCardsDemo() {
    return Column(
      children: [
        Row(
          children: const [
            SeverityBadge(level: SeverityLevel.low),
            AppSpacing.hSpace12,
            SeverityBadge(level: SeverityLevel.medium),
            AppSpacing.hSpace12,
            SeverityBadge(level: SeverityLevel.high),
            AppSpacing.hSpace12,
            SeverityBadge(level: SeverityLevel.critical),
          ],
        ),
        AppSpacing.vSpace16,
        BioHerdCard(
          severity: CardSeverity.critical,
          child: Row(
            children: [
              const Icon(PhosphorIconsFill.warning, color: AppColors.danger600, size: 24),
              AppSpacing.hSpace12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active High-Risk Alert Detected', style: AppTextStyles.h3()),
                    Text(
                      'Foot-and-Mouth Disease (FMD) symptoms reported in 3 neighbouring farms.',
                      style: AppTextStyles.bodySmall(color: AppColors.neutral700),
                    ),
                  ],
                ),
              ),
              const SeverityBadge(level: SeverityLevel.critical),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceMeterDemo() {
    return BioHerdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AIConfidenceMeter(
            confidence: _aiConfidence,
            modelName: 'EfficientNet-B4 + IndicBERT (Multilingual)',
          ),
          AppSpacing.vSpace16,
          Row(
            children: [
              Text('Adjust Confidence Score:', style: AppTextStyles.label()),
              Expanded(
                child: Slider(
                  value: _aiConfidence,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primary600,
                  onChanged: (val) => setState(() => _aiConfidence = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCardsDemo() {
    return Column(
      children: [
        AnimalCard(
          tagId: 'MH-12-PUN-0941',
          species: 'Gir Cow (गाय)',
          breed: 'Indigenous Dairy',
          lastHealthEventDate: '02 Sep 2026',
          activeSeverity: SeverityLevel.high,
          onTap: () {},
        ),
        AppSpacing.vSpace12,
        AnimalCard(
          tagId: 'MH-14-SAT-3021',
          species: 'Murrah Buffalo (म्हैस)',
          breed: 'High Yield Dairy',
          lastHealthEventDate: '28 Aug 2026',
          activeSeverity: SeverityLevel.low,
          onTap: () {},
        ),
        AppSpacing.vSpace12,
        AnimalCard(
          tagId: 'MH-19-KOP-7712',
          species: 'Osmanabadi Goat (शेळी)',
          breed: 'Meat & Milk Dual',
          lastHealthEventDate: '15 Aug 2026',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSkeletonAndOfflineDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilterChip(
              label: Text(_isOffline ? 'Offline Mode ON' : 'Offline Mode OFF'),
              selected: _isOffline,
              onSelected: (val) => setState(() => _isOffline = val),
            ),
            AppSpacing.hSpace12,
            FilterChip(
              label: Text(_isSyncing ? 'Syncing Queue Active' : 'Start Queue Sync'),
              selected: _isSyncing,
              onSelected: (val) => setState(() {
                _isSyncing = val;
                if (val) _isOffline = false;
              }),
            ),
          ],
        ),
        AppSpacing.vSpace16,
        Text('Loading Skeleton Placeholder:', style: AppTextStyles.label()),
        AppSpacing.vSpace8,
        const AnimalCardSkeleton(),
      ],
    );
  }
}
