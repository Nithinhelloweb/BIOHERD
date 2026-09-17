import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bioherd_button.dart';
import '../../../core/widgets/severity_badge.dart';
import '../bloc/surveillance_bloc.dart';
import '../models/surveillance_model.dart';
import 'widgets/district_risk_card.dart';
import 'widgets/outbreak_alert_banner.dart';
import 'widgets/quarantine_protocols_dialog.dart';

class SurveillanceMapScreen extends StatefulWidget {
  const SurveillanceMapScreen({super.key});

  @override
  State<SurveillanceMapScreen> createState() => _SurveillanceMapScreenState();
}

class _SurveillanceMapScreenState extends State<SurveillanceMapScreen>
    with SingleTickerProviderStateMixin {
  int _viewModeIndex = 0; // 0: Interactive Map, 1: District Rankings
  String _searchQuery = '';
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  late AnimationController _pulseController;

  final List<String> _diseaseFilterOptions = const [
    'All',
    'Foot and Mouth Disease',
    'Lumpy Skin Disease',
    'Haemorrhagic Septicaemia',
    'Black Quarter',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Initial load
    context.read<SurveillanceBloc>().add(const LoadSurveillanceDataEvent());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _resetMapTransform() {
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outbreak Surveillance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'रोग प्रादुर्भाव व भौगोलिक देखरेख (Maharashtra GIS)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.shieldCheck),
            tooltip: 'Quarantine Directives',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const QuarantineProtocolsDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowClockwise),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<SurveillanceBloc>().add(const RefreshSurveillanceEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<SurveillanceBloc, SurveillanceState>(
        builder: (context, state) {
          if (state.isLoading && state.districts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Maharashtra Surveillance Data...'),
                  SizedBox(height: 4),
                  Text('महाराष्ट्र प्रादुर्भाव डेटा लोड होत आहे...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 1. Top Alert Banner if alerts exist
              if (state.alerts.isNotEmpty)
                OutbreakAlertBanner(alert: state.alerts.first),

              // 2. Control Bar: View Switcher & Disease Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Segmented view toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[150],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildViewToggleItem(0, PhosphorIconsRegular.mapTrifold, 'Map'),
                          _buildViewToggleItem(1, PhosphorIconsRegular.listNumbers, 'Districts'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildStatBadge(
                            label: 'Hotspots',
                            value: '${state.clusters.length}',
                            color: AppColors.alertRed,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildStatBadge(
                            label: 'Quarantine',
                            value: '${state.activeQuarantineZonesCount}',
                            color: AppColors.alertAmber,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Disease Filter Chips Horizontal Scroll
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: _diseaseFilterOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final opt = _diseaseFilterOptions[idx];
                    final isSelected = state.selectedDiseaseFilter.toLowerCase() == opt.toLowerCase();
                    return ChoiceChip(
                      label: Text(
                        opt == 'All'
                            ? 'All Diseases (सर्व)'
                            : opt == 'Foot and Mouth Disease'
                                ? 'FMD (लाळ्या खुरकूत)'
                                : opt == 'Lumpy Skin Disease'
                                    ? 'LSD (गाठींचा त्वचा रोग)'
                                    : opt == 'Haemorrhagic Septicaemia'
                                        ? 'HS (घटसर्प)'
                                        : 'BQ (एकटांग्या)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryGreen,
                      onSelected: (_) {
                        context.read<SurveillanceBloc>().add(FilterByDiseaseEvent(opt));
                      },
                    );
                  },
                ),
              ),

              // 4. Main Body: Either Interactive Map or District Rankings List
              Expanded(
                child: _viewModeIndex == 0
                    ? _buildInteractiveMapView(context, state, isDark)
                    : _buildDistrictRankingsListView(context, state, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewToggleItem(int index, IconData icon, String label) {
    final isSelected = _viewModeIndex == index;
    return InkWell(
      onTap: () => setState(() => _viewModeIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // --- Map View with Custom Canvas & Epidemic Bottom Sheet ---
  Widget _buildInteractiveMapView(
    BuildContext context,
    SurveillanceState state,
    bool isDark,
  ) {
    final clusters = state.filteredClusters;
    final selectedCluster = state.selectedCluster;

    return Stack(
      children: [
        // Custom Canvas Interactive Map
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _panOffset += details.delta;
            });
          },
          onTapUp: (details) {
            final hitCluster = _hitTestCluster(details.localPosition, clusters);
            if (hitCluster != null) {
              context.read<SurveillanceBloc>().add(SelectClusterEvent(hitCluster));
            }
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: MaharashtraMapPainter(
                  clusters: clusters,
                  districts: state.districts,
                  selectedCluster: selectedCluster,
                  pulseValue: _pulseController.value,
                  zoomScale: _zoomScale,
                  panOffset: _panOffset,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),

        // Map Float Controls (Zoom In, Zoom Out, Reset, Legend)
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _buildMapActionButton(
                icon: PhosphorIconsRegular.plus,
                tooltip: 'Zoom In',
                onPressed: () => setState(() => _zoomScale = math.min(3.0, _zoomScale + 0.25)),
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.minus,
                tooltip: 'Zoom Out',
                onPressed: () => setState(() => _zoomScale = math.max(0.6, _zoomScale - 0.25)),
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.arrowsClockwise,
                tooltip: 'Reset View',
                onPressed: _resetMapTransform,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Map Legend Indicator (Left Top)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(AppColors.alertRed, '5km Containment (नियंत्रण)'),
                const SizedBox(height: 3),
                _buildLegendItem(AppColors.alertAmber, '10km Surveillance (देखरेख)'),
              ],
            ),
          ),
        ),

        // Cluster Selected Bottom Sheet Card
        if (selectedCluster != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildClusterDetailCard(context, selectedCluster, isDark),
          ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            border: Border.all(color: color, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.grey[750]! : Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  OutbreakClusterModel? _hitTestCluster(Offset localPos, List<OutbreakClusterModel> clusters) {
    for (final c in clusters) {
      final center = _projectCoordToCanvas(c.latitude, c.longitude);
      final dist = (center - localPos).distance;
      if (dist < 32.0) {
        return c;
      }
    }
    return null;
  }

  Offset _projectCoordToCanvas(double lat, double lon) {
    const minLat = 15.6;
    const maxLat = 22.1;
    const minLon = 72.6;
    const maxLon = 80.9;

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height * 0.55;

    final nx = (lon - minLon) / (maxLon - minLon);
    final ny = 1.0 - ((lat - minLat) / (maxLat - minLat));

    final mapCenterX = width * 0.5;
    final mapCenterY = height * 0.5;

    final rawX = 20 + nx * (width - 40);
    final rawY = 20 + ny * (height - 40);

    final scaledX = mapCenterX + (rawX - mapCenterX) * _zoomScale + _panOffset.dx;
    final scaledY = mapCenterY + (rawY - mapCenterY) * _zoomScale + _panOffset.dy;

    return Offset(scaledX, scaledY);
  }

  Widget _buildClusterDetailCard(
    BuildContext context,
    OutbreakClusterModel cluster,
    bool isDark,
  ) {
    final r0Color = cluster.r0Estimate >= 1.5
        ? AppColors.alertRed
        : cluster.r0Estimate >= 1.0
            ? AppColors.alertAmber
            : AppColors.primaryGreen;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cluster.riskLevel == SeverityLevel.critical
              ? AppColors.alertRed
              : AppColors.alertAmber,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Disease & District
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cluster.diseaseName} (${cluster.diseaseNameMr})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Epicenter: ${cluster.districtName} (${cluster.districtNameMr})',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              SeverityBadge(severity: cluster.riskLevel),
            ],
          ),
          const SizedBox(height: 10),
          // Metric Tiles: Cases, Affected Farms, R0, Radii
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailMetric(
                label: 'Cases',
                value: '${cluster.caseCount}',
                color: AppColors.alertRed,
                icon: PhosphorIconsRegular.warning,
              ),
              _buildDetailMetric(
                label: 'Farms',
                value: '${cluster.affectedFarmsCount}',
                color: Colors.blue,
                icon: PhosphorIconsRegular.houseLine,
              ),
              _buildDetailMetric(
                label: 'R₀ Rate',
                value: cluster.r0Estimate.toStringAsFixed(2),
                color: r0Color,
                icon: PhosphorIconsRegular.chartLineUp,
              ),
              _buildDetailMetric(
                label: 'Containment',
                value: '${cluster.containmentRadiusKm.toInt()} km',
                color: AppColors.primaryGreen,
                icon: PhosphorIconsRegular.circle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Notes
          if (cluster.notesMr.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cluster.notesMr,
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          const SizedBox(height: 12),
          // Actions: Quarantine & Directives
          Row(
            children: [
              Expanded(
                child: BioHerdButton(
                  label: cluster.quarantineDeclared
                      ? 'Quarantine Active (लागू)'
                      : 'Enact Quarantine',
                  icon: Icon(
                    cluster.quarantineDeclared
                        ? PhosphorIconsFill.checkCircle
                        : PhosphorIconsRegular.shieldCheck,
                    size: 18,
                  ),
                  variant: cluster.quarantineDeclared
                      ? BioHerdButtonVariant.primary
                      : BioHerdButtonVariant.danger,
                  onPressed: cluster.quarantineDeclared
                      ? null
                      : () {
                          context
                              .read<SurveillanceBloc>()
                              .add(DeclareQuarantineEvent(cluster.id));
                        },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(PhosphorIconsRegular.bookOpen),
                tooltip: 'Read Directives',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const QuarantineProtocolsDialog(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // --- District Rankings Leaderboard Tab ---
  Widget _buildDistrictRankingsListView(
    BuildContext context,
    SurveillanceState state,
    bool isDark,
  ) {
    final filteredDistricts = state.districts.where((d) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return d.districtName.toLowerCase().contains(q) ||
          d.districtNameMr.toLowerCase().contains(q) ||
          d.primaryDisease.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // District Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search 36 districts (उदा. सोलापूर, Pune)...',
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredDistricts.length,
            itemBuilder: (context, idx) {
              final dist = filteredDistricts[idx];
              final isSelected = state.selectedDistrict?.districtId == dist.districtId;
              return DistrictRiskCard(
                district: dist,
                isSelected: isSelected,
                onTap: () {
                  context.read<SurveillanceBloc>().add(SelectDistrictEvent(dist));
                  // Auto-switch to Map tab to visualize the district
                  setState(() => _viewModeIndex = 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Maharashtra Map & Outbreak Rings
class MaharashtraMapPainter extends CustomPainter {
  final List<OutbreakClusterModel> clusters;
  final List<DistrictRiskModel> districts;
  final OutbreakClusterModel? selectedCluster;
  final double pulseValue;
  final double zoomScale;
  final Offset panOffset;
  final bool isDark;

  MaharashtraMapPainter({
    required this.clusters,
    required this.districts,
    required this.selectedCluster,
    required this.pulseValue,
    required this.zoomScale,
    required this.panOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle regional grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw District Centroids
    for (final d in districts) {
      final pos = _coordToCanvas(d.latitude, d.longitude, size);
      final distColor = d.severity == SeverityLevel.critical
          ? AppColors.alertRed
          : d.severity == SeverityLevel.high
              ? AppColors.alertAmber
              : isDark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!;

      // Centroid bubble
      canvas.drawCircle(
        pos,
        4.0 * zoomScale,
        Paint()..color = distColor.withValues(alpha: 0.6),
      );

      // Label major cities
      if (['Solapur', 'Kolhapur', 'Ahmednagar', 'Pune', 'Nashik', 'Nagpur'].contains(d.districtName)) {
        final textSpan = TextSpan(
          text: d.districtName,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
            fontSize: 9.0 * math.min(1.4, zoomScale),
            fontWeight: FontWeight.w600,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(pos.dx + 6, pos.dy - 6));
      }
    }

    // 3. Draw Outbreak Buffer Rings (10km Surveillance & 5km Containment)
    for (final c in clusters) {
      final pos = _coordToCanvas(c.latitude, c.longitude, size);
      final isSelected = selectedCluster?.id == c.id;

      // 10km Surveillance Buffer Ring (Amber)
      final r10 = (c.surveillanceRadiusKm * 3.5) * zoomScale;
      canvas.drawCircle(
        pos,
        r10,
        Paint()
          ..color = AppColors.alertAmber.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        r10,
        Paint()
          ..color = AppColors.alertAmber.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // 5km Containment Ring (Red)
      final r5 = (c.containmentRadiusKm * 3.5) * zoomScale;
      canvas.drawCircle(
        pos,
        r5,
        Paint()
          ..color = AppColors.alertRed.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        r5,
        Paint()
          ..color = AppColors.alertRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      // Pulsating Epicenter Pin
      final pulseRadius = (12.0 + (pulseValue * 8.0)) * zoomScale;
      canvas.drawCircle(
        pos,
        pulseRadius,
        Paint()
          ..color = AppColors.alertRed.withValues(alpha: 0.25 * (1.0 - pulseValue * 0.5))
          ..style = PaintingStyle.fill,
      );

      // Core Epicenter Marker
      canvas.drawCircle(
        pos,
        (isSelected ? 9.0 : 7.0) * zoomScale,
        Paint()..color = AppColors.alertRed,
      );
      canvas.drawCircle(
        pos,
        (isSelected ? 9.0 : 7.0) * zoomScale,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  Offset _coordToCanvas(double lat, double lon, Size size) {
    const minLat = 15.6;
    const maxLat = 22.1;
    const minLon = 72.6;
    const maxLon = 80.9;

    final nx = (lon - minLon) / (maxLon - minLon);
    final ny = 1.0 - ((lat - minLat) / (maxLat - minLat));

    final mapCenterX = size.width * 0.5;
    final mapCenterY = size.height * 0.5;

    final rawX = 20 + nx * (size.width - 40);
    final rawY = 20 + ny * (size.height - 40);

    final scaledX = mapCenterX + (rawX - mapCenterX) * zoomScale + panOffset.dx;
    final scaledY = mapCenterY + (rawY - mapCenterY) * zoomScale + panOffset.dy;

    return Offset(scaledX, scaledY);
  }

  @override
  bool shouldRepaint(covariant MaharashtraMapPainter oldDelegate) {
    return oldDelegate.clusters != clusters ||
        oldDelegate.selectedCluster != selectedCluster ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.isDark != isDark;
  }
}
