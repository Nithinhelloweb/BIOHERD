import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/layout/bioherd_shell.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/rbac_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bioherd_button.dart';
import '../../../core/widgets/severity_badge.dart';
import '../bloc/surveillance_bloc.dart';
import '../models/surveillance_model.dart';
import '../models/eco_climate_model.dart';
import '../services/epizootic_prediction_service.dart';
import 'widgets/what_if_intervention_dialog.dart';
import '../models/edge_vision_model.dart';
import 'widgets/edge_vision_inspection_dialog.dart';
import '../models/crisis_dispatch_model.dart';
import 'widgets/crisis_dispatch_copilot_dialog.dart';
import 'widgets/containment_cordon_config_dialog.dart';
import 'widgets/district_tactical_dossier_dialog.dart';
import 'widgets/district_risk_card.dart';
import 'widgets/outbreak_alert_banner.dart';
import 'widgets/quarantine_protocols_dialog.dart';
import 'widgets/simulation_outbreak_dialog.dart';
import 'widgets/telemetry_feed_dialog.dart';
import 'widgets/transit_manifest_sheet.dart';

class SurveillanceMapScreen extends StatefulWidget {
  const SurveillanceMapScreen({super.key});

  @override
  State<SurveillanceMapScreen> createState() => _SurveillanceMapScreenState();
}

class _SurveillanceMapScreenState extends State<SurveillanceMapScreen>
    with TickerProviderStateMixin {
  // Phase 2: Spatio-Temporal Prediction & Eco-Climatic Intelligence
  PredictionHorizon _selectedHorizon = PredictionHorizon.now;
  PolicyIntervention _activePolicies = const PolicyIntervention();
  bool _showEcoVectorLayer = false;
  bool _showDownwindPlumes = true;
  final List<BiosecurityCheckpoint> _checkpoints = BiosecurityCheckpoint.getPreseededCheckpoints();
  bool _showCheckpoints = true;

  int _viewModeIndex = 0; // 0: Interactive Map, 1: District Rankings
  MapViewStyle _mapStyle = MapViewStyle.standard;
  Size _lastCanvasSize = Size.zero;
  String _searchQuery = '';
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;

  // Real-world Geographic Basemap Engine
  late final MapController _mapController;
  MapCamera? _mapCamera;

  // eStream Real-Time Satellite Constellation Engine
  List<OrbitalSatellite> _satellites = OrbitalSatellite.defaultConstellation();
  OrbitalSatellite? _selectedSatellite;
  bool _isZenMode = false;
  bool _showSatelliteSwaths = true;
  bool _isAlertBannerDismissed = false;

  late AnimationController _pulseController;
  late AnimationController _cameraController;
  late AnimationController _orbitalFlightController;
  Animation<Offset>? _cameraPanAnimation;
  Animation<double>? _cameraZoomAnimation;

  Timer? _autoPatrolTimer;
  int _patrolTargetIndex = 0;

  final List<String> _diseaseFilterOptions = const [
    'All',
    'Foot and Mouth Disease',
    'Lumpy Skin Disease',
    'Haemorrhagic Septicaemia',
    'Black Quarter',
  ];

  // Hotspots for Auto-Patrol camera touring
  final List<Map<String, dynamic>> _patrolHotspots = const [
    {'name': 'Solapur Epicenter', 'lat': 17.6599, 'lon': 75.9064, 'zoom': 1.45},
    {'name': 'Osmanabad Containment', 'lat': 18.1856, 'lon': 76.0419, 'zoom': 1.50},
    {'name': 'Kolhapur Buffer Zone', 'lat': 16.7050, 'lon': 74.2433, 'zoom': 1.40},
    {'name': 'Ahmednagar Transit Corridor', 'lat': 19.0948, 'lon': 74.7480, 'zoom': 1.35},
    {'name': 'Pune Central Command', 'lat': 18.5204, 'lon': 73.8567, 'zoom': 1.30},
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 24s Continuous Orbit for eStream Real-Time Satellites
    _orbitalFlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _orbitalFlightController.addListener(_updateOrbitalPositions);

    // Initial load
    context.read<SurveillanceBloc>().add(const LoadSurveillanceDataEvent());
  }


  StatewideEpizooticForecast _getCurrentForecast(
    List<DistrictRiskModel> districts,
    List<OutbreakClusterModel> clusters,
  ) {
    return EpizooticPredictionService.computeForecast(
      districts: districts,
      clusters: clusters,
      horizon: _selectedHorizon,
      policies: _activePolicies,
    );
  }

  @override
  void dispose() {
    _autoPatrolTimer?.cancel();
    _pulseController.dispose();
    _cameraController.dispose();
    _orbitalFlightController.removeListener(_updateOrbitalPositions);
    _orbitalFlightController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _getTileUrlForStyle(MapViewStyle style) {
    switch (style) {
      case MapViewStyle.satellite:
        // Genuine high-resolution Earth satellite imagery tiles (Esri World Imagery)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapViewStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _updateOrbitalPositions() {
    if (!mounted || _mapStyle != MapViewStyle.satellite) return;

    final t = _orbitalFlightController.value;
    final updated = <OrbitalSatellite>[];

    for (final sat in _satellites) {
      final pts = sat.trajectoryPoints;
      if (pts.length < 2) {
        updated.add(sat);
        continue;
      }

      final totalSegs = pts.length - 1;
      final progressInSegs = (t * totalSegs) % totalSegs;
      final segIdx = progressInSegs.floor();
      final frac = progressInSegs - segIdx;

      final p1 = pts[segIdx];
      final p2 = pts[math.min(segIdx + 1, pts.length - 1)];

      final currLat = p1[0] + (p2[0] - p1[0]) * frac;
      final currLon = p1[1] + (p2[1] - p1[1]) * frac;

      final dLat = p2[0] - p1[0];
      final dLon = p2[1] - p1[1];
      final heading = (math.atan2(dLon, dLat) * 180 / math.pi) % 360;

      // Proximity to Outbreak Epicenters
      String lockName = '';
      bool locked = false;

      final distSolapur = math.sqrt(math.pow(currLat - 17.6599, 2) + math.pow(currLon - 75.9064, 2));
      final distOsmanabad = math.sqrt(math.pow(currLat - 18.1856, 2) + math.pow(currLon - 76.0419, 2));
      final distKolhapur = math.sqrt(math.pow(currLat - 16.7050, 2) + math.pow(currLon - 74.2433, 2));

      if (distSolapur < 1.35) {
        locked = true;
        lockName = 'Solapur Outbreak Epicenter';
      } else if (distOsmanabad < 1.25) {
        locked = true;
        lockName = 'Osmanabad Containment Zone';
      } else if (distKolhapur < 1.20) {
        locked = true;
        lockName = 'Kolhapur Buffer Zone';
      }

      updated.add(sat.copyWith(
        currentLat: currLat,
        currentLon: currLon,
        headingDeg: heading,
        isTargetLocked: locked,
        targetLockName: lockName,
      ));
    }

    setState(() {
      _satellites = updated;
      if (_selectedSatellite != null) {
        _selectedSatellite = updated.firstWhere(
          (s) => s.id == _selectedSatellite!.id,
          orElse: () => _selectedSatellite!,
        );
      }
    });
  }

  void _resetMapTransform() {
    _cameraController.stop();
    try {
      _mapController.move(const LatLng(19.2, 76.2), 6.8);
    } catch (_) {}
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
      _selectedSatellite = null;
    });
  }

  void _panMap(double deltaLat, double deltaLon) {
    try {
      final currentCenter = _mapController.camera.center;
      final newCenter = LatLng(
        (currentCenter.latitude + deltaLat).clamp(-85.0, 85.0),
        (currentCenter.longitude + deltaLon).clamp(-180.0, 180.0),
      );
      _mapController.move(newCenter, _mapController.camera.zoom);
    } catch (_) {}
  }

  void _toggleAutoPatrol(bool isEnabled) {
    context.read<SurveillanceBloc>().add(const ToggleAutoPatrolEvent());
    if (!isEnabled) {
      // Starting auto-patrol
      _startAutoPatrolTimer();
    } else {
      // Stopping auto-patrol
      _autoPatrolTimer?.cancel();
    }
  }

  void _startAutoPatrolTimer() {
    _autoPatrolTimer?.cancel();
    _autoPatrolTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _patrolTargetIndex = (_patrolTargetIndex + 1) % _patrolHotspots.length;
      final target = _patrolHotspots[_patrolTargetIndex];
      _glideCameraTo(target['lat'] as double, target['lon'] as double, target['zoom'] as double);
    });
  }

  void _glideCameraTo(double lat, double lon, double targetZoom) {
    try {
      _mapController.move(LatLng(lat, lon), 6.8 + (targetZoom - 1.0) * 1.5);
    } catch (_) {}
    const minLat = 15.6;
    const maxLat = 22.1;
    const minLon = 72.6;
    const maxLon = 80.9;

    final width = _lastCanvasSize.width > 0 ? _lastCanvasSize.width : MediaQuery.of(context).size.width;
    final height = _lastCanvasSize.height > 0 ? _lastCanvasSize.height : (MediaQuery.of(context).size.height * 0.55);

    final nx = (lon - minLon) / (maxLon - minLon);
    final ny = 1.0 - ((lat - minLat) / (maxLat - minLat));

    final mapCenterX = width * 0.5;
    final mapCenterY = height * 0.5;

    final rawX = 20 + nx * (width - 40);
    final rawY = 20 + ny * (height - 40);

    // Calculate required panOffset so target rawX, rawY aligns with map center
    final targetPanX = -(rawX - mapCenterX) * targetZoom;
    final targetPanY = -(rawY - mapCenterY) * targetZoom;

    final startPan = _panOffset;
    final startZoom = _zoomScale;

    _cameraPanAnimation = Tween<Offset>(begin: startPan, end: Offset(targetPanX, targetPanY))
        .animate(CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic));
    _cameraZoomAnimation = Tween<double>(begin: startZoom, end: targetZoom)
        .animate(CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic));

    _cameraController.reset();
    _cameraController.forward();
    _cameraController.addListener(() {
      if (_cameraPanAnimation != null && _cameraZoomAnimation != null) {
        setState(() {
          _panOffset = _cameraPanAnimation!.value;
          _zoomScale = _cameraZoomAnimation!.value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Full-Immersion Zen / Clean View Mode
    if (_isZenMode && _viewModeIndex == 0) {
      return Scaffold(
        body: BlocBuilder<SurveillanceBloc, SurveillanceState>(
          builder: (context, state) {
            return _buildInteractiveMapView(context, state, isDark);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BioHerdHamburgerButton(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outbreak Surveillance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Disease Outbreaks & Geospatial Surveillance (Maharashtra GIS)',
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
                ],
              ),
            );
          }

          return Column(
            children: [
              // 1. Top Alert Banner if alerts exist and not dismissed
              if (state.alerts.isNotEmpty && !_isAlertBannerDismissed)
                Stack(
                  children: [
                    OutbreakAlertBanner(alert: state.alerts.first),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => setState(() => _isAlertBannerDismissed = true),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(PhosphorIconsRegular.x, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

              // 2. Control Bar: View Switcher & Live Simulation Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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

                      // Clean / Zen Simulation Toggle
                      if (_viewModeIndex == 0) ...[
                        InkWell(
                          onTap: () => setState(() => _isZenMode = true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(PhosphorIconsRegular.cornersOut, size: 14, color: Color(0xFF00E5FF)),
                                SizedBox(width: 4),
                                Text(
                                  'Clean View',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Map Style Selector (Normal Map, Satellite View)
                      if (_viewModeIndex == 0) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[150],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              _buildStyleToggleItem(MapViewStyle.standard, PhosphorIconsRegular.mapTrifold, 'Normal Map'),
                              _buildStyleToggleItem(MapViewStyle.satellite, PhosphorIconsFill.planet, 'Satellite View'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Quick stats & Simulation indicator
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
                      const SizedBox(width: 6),
                      _buildStatBadge(
                        label: 'Transits',
                        value: '${state.transitVehicles.length}',
                        color: AppColors.primaryGreen,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Disease Filter Chips
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
                            ? 'All Diseases'
                            : opt == 'Foot and Mouth Disease'
                                ? 'FMD'
                                : opt == 'Lumpy Skin Disease'
                                    ? 'LSD'
                                    : opt == 'Haemorrhagic Septicaemia'
                                        ? 'HS'
                                        : 'BQ',
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

              // 4. Main Body: Map Canvas or District Rankings List
              Expanded(
                child: _viewModeIndex == 0
                    ? _buildInteractiveMapView(context, state, isDark)
                    : _buildDistrictRankingsView(context, state, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewToggleItem(int index, IconData icon, String label) {
    final isSelected = _viewModeIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _viewModeIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleToggleItem(MapViewStyle style, IconData icon, String label) {
    final isSelected = _mapStyle == style;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _mapStyle = style),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFF00B0FF).withValues(alpha: 0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0277BD))
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF01579B))
                    : (isDark ? Colors.grey[300] : Colors.grey[800]),
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
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
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

  // --- Map View with Custom Canvas, Heatmap Layer & Auto-Moving Vectors ---
  Widget _buildInteractiveMapView(
    BuildContext context,
    SurveillanceState state,
    bool isDark,
  ) {
    final clusters = state.filteredClusters;
    final selectedCluster = state.selectedCluster;
    final vehicles = state.transitVehicles;
    final isHeatmapOn = state.visibleLayers.contains('heatmap');
    final isTransitOn = state.visibleLayers.contains('transit');
    final isRingsOn = state.visibleLayers.contains('rings');
    final isDistrictsOn = state.visibleLayers.contains('districts');

    return Stack(
      children: [
        // 1. Real Satellite & Geographic Basemap Engine (FlutterMap)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(19.2, 76.2),
            initialZoom: 6.8,
            minZoom: 4.8,
            maxZoom: 16.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              if (mounted) {
                setState(() {
                  _mapCamera = _mapController.camera;
                });
              }
            },
            onPositionChanged: (camera, hasGesture) {
              if (mounted) {
                setState(() {
                  _mapCamera = camera;
                });
              }
            },
            onTap: (tapPosition, point) {
              _handleMapTap(
                tapPosition.relative ?? Offset.zero,
                point,
                clusters,
                vehicles,
                state.districts,
                isTransitOn,
                selectedCluster,
              );
            },
          ),
          children: [
            TileLayer(
              urlTemplate: _getTileUrlForStyle(_mapStyle),
              userAgentPackageName: 'org.bioherd.biov1',
              maxZoom: 18,
            ),
          ],
        ),

        // 2. Animated Real-Time Simulation Layer (CustomPaint Overlay - Transparent to Gestures)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _lastCanvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _orbitalFlightController]),
                  builder: (context, _) {
                    final forecast = _getCurrentForecast(state.districts, clusters);
                    return CustomPaint(
                      size: Size.infinite,
                      painter: MaharashtraMapPainter(
                        camera: _mapCamera,
                        clusters: clusters,
                        districts: state.districts,
                        vehicles: vehicles,
                        satellites: _satellites,
                        selectedSatellite: _selectedSatellite,
                        showSatelliteSwaths: _showSatelliteSwaths,
                        selectedCluster: selectedCluster,
                        selectedVehicle: state.selectedVehicle,
                        pulseValue: _pulseController.value,
                        zoomScale: _zoomScale,
                        panOffset: _panOffset,
                        isDark: isDark,
                        mapStyle: _mapStyle,
                        showHeatmap: isHeatmapOn,
                        showTransit: isTransitOn,
                        showRings: isRingsOn,
                        showDistricts: isDistrictsOn,
                        forecast: forecast,
                        horizon: _selectedHorizon,
                        showEcoVectorLayer: _showEcoVectorLayer,
                        showDownwindPlumes: _showDownwindPlumes,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Live Simulation Control HUD Bar (Top Center/Left) - Hidden in Zen Mode
        if (!_isZenMode)
          Positioned(
            top: 10,
            left: 12,
            right: 64,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Play / Pause Simulation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.grey[900]! : Colors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<SurveillanceBloc>().add(const ToggleSimulationEvent());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              state.simulationRunning ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
                              size: 16,
                              color: state.simulationRunning ? AppColors.alertAmber : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Speed Pill
                        InkWell(
                          onTap: () {
                            final nextSpeed = state.simulationSpeed == 1.0
                                ? 2.0
                                : state.simulationSpeed == 2.0
                                    ? 4.0
                                    : 1.0;
                            context.read<SurveillanceBloc>().add(SetSimulationSpeedEvent(nextSpeed));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.simulationSpeed.toInt()}x',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Live Pulsing Dot
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: state.simulationRunning ? AppColors.primaryGreen : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.simulationRunning ? 'SIM LIVE' : 'PAUSED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: state.simulationRunning ? AppColors.primaryGreen : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Auto-Patrol Camera Toggle
                  InkWell(
                    onTap: () => _toggleAutoPatrol(state.autoPatrolEnabled),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.autoPatrolEnabled
                            ? AppColors.primaryGreen
                            : (isDark ? Colors.grey[900]! : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.autoPatrolEnabled ? AppColors.primaryGreen : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsFill.navigationArrow,
                            size: 13,
                            color: state.autoPatrolEnabled ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.autoPatrolEnabled ? 'Auto-Patrol: Active' : 'Auto-Patrol',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: state.autoPatrolEnabled ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Map Style Switcher Chips
                  _buildLayerChip('style_std', '🗺️ Normal Map', _mapStyle == MapViewStyle.standard, isDark,
                      onCustomTap: () => setState(() => _mapStyle = MapViewStyle.standard)),
                  const SizedBox(width: 6),
                  _buildLayerChip('style_sat', '🛰️ Satellite View', _mapStyle == MapViewStyle.satellite, isDark,
                      onCustomTap: () => setState(() => _mapStyle = MapViewStyle.satellite)),
                  const SizedBox(width: 8),

                  // Layer Toggles
                  _buildLayerChip('heatmap', '🔥 Heatmap', isHeatmapOn, isDark),
                  const SizedBox(width: 6),
                  _buildLayerChip('transit', '🚛 Transit Vectors', isTransitOn, isDark),
                  const SizedBox(width: 6),
                                    _buildLayerChip('rings', '🔴 Buffer Rings', isRingsOn, isDark),
                  const SizedBox(width: 6),
                  _buildLayerChip('districts', '🏛️ Districts', isDistrictsOn, isDark),
                  const SizedBox(width: 6),
                  _buildLayerChip('eco_vectors', '🦟 Eco-Vectors', _showEcoVectorLayer, isDark,
                      onCustomTap: () => setState(() => _showEcoVectorLayer = !_showEcoVectorLayer)),
                  const SizedBox(width: 6),
                  _buildLayerChip('wind_plumes', '🌬️ Wind Plumes', _showDownwindPlumes, isDark,
                      onCustomTap: () => setState(() => _showDownwindPlumes = !_showDownwindPlumes)),
                  const SizedBox(width: 6),
                  _buildLayerChip('gates', '🚪 Smart Gates', _showCheckpoints, isDark,
                      onCustomTap: () => setState(() => _showCheckpoints = !_showCheckpoints)),
                  const SizedBox(width: 8),

                  // Button 1: Edge Vision C4I Terminal (Phase 3)
                  InkWell(
                    onTap: () {
                      if (_checkpoints.isNotEmpty) {
                        EdgeVisionInspectionDialog.show(
                          context,
                          checkpoint: _checkpoints.first,
                          onGateStatusChanged: (newStatus) {
                            setState(() {
                              _checkpoints.first.gateBarrierStatus = newStatus;
                            });
                          },
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00FFCC), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FFCC).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.videoCamera, size: 13, color: Color(0xFF00FFCC)),
                          SizedBox(width: 4),
                          Text(
                            'Edge Vision C4I',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FFCC),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Button 2: Crisis Dispatch & AI SitRep Co-Pilot (Phase 4)
                  InkWell(
                    onTap: () {
                      CrisisDispatchCopilotDialog.show(
                        context,
                        activeDistrict: 'Solapur',
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1744).withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.siren, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Crisis Dispatch & SitRep',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // "What-If" Policy Simulator Button
                  InkWell(
                    onTap: () {
                      WhatIfInterventionDialog.show(
                        context,
                        districts: state.districts,
                        clusters: clusters,
                        initialHorizon: _selectedHorizon,
                        initialPolicies: _activePolicies,
                        onApplyPolicies: (h, p) {
                          setState(() {
                            _selectedHorizon = h;
                            _activePolicies = p;
                          });
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.chartLineUp, size: 13, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'What-If Simulator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // C4I Ring Cordon Generator Button
                  InkWell(
                    onTap: () {
                      final epicenterDistrict = state.districts.firstWhere(
                        (d) => d.severity == SeverityLevel.critical,
                        orElse: () => state.districts.first,
                      );
                      final assocCluster = clusters.cast<OutbreakClusterModel?>().firstWhere(
                        (c) => c != null && (c.districtId == epicenterDistrict.districtId || c.districtName.toLowerCase() == epicenterDistrict.districtName.toLowerCase()),
                        orElse: () => null,
                      );
                      ContainmentCordonConfigDialog.show(
                        context,
                        district: epicenterDistrict,
                        cluster: assocCluster,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.alertRed.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.shieldPlus, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Ring Cordon Tool',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Inject Outbreak Spike Button
                  InkWell(
                    onTap: () {
                      SimulationOutbreakDialog.show(context, state.districts);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.alertRed.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.alertRed.withValues(alpha: 0.3), blurRadius: 6),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.lightning, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Simulate Spike',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // eStream Satellite Recon Orbital Status Banner - Hidden in Zen Mode
        if (_mapStyle == MapViewStyle.satellite && !_isZenMode)
          Positioned(
            top: 48,
            left: 12,
            child: _buildSatelliteReconBanner(isDark),
          ),

        // Map Float Controls (Top-Right): Zen Mode, Satellite Mode, Zoom, Reset
        Positioned(
          top: 10,
          right: 12,
          child: Column(
            children: [
              _buildMapActionButton(
                icon: _isZenMode ? PhosphorIconsFill.cornersIn : PhosphorIconsRegular.cornersOut,
                tooltip: _isZenMode ? 'Exit Clean View' : 'Clean / Zen View (Hide Overlays)',
                onPressed: () => setState(() => _isZenMode = !_isZenMode),
                isDark: isDark,
                highlightColor: _isZenMode ? const Color(0xFF00E5FF) : null,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: _mapStyle == MapViewStyle.satellite
                    ? PhosphorIconsFill.planet
                    : PhosphorIconsRegular.planet,
                tooltip: _mapStyle == MapViewStyle.satellite ? 'Switch to Normal Map' : 'Switch to Satellite View',
                onPressed: () {
                  setState(() {
                    _mapStyle = _mapStyle == MapViewStyle.satellite
                        ? MapViewStyle.standard
                        : MapViewStyle.satellite;
                  });
                },
                isDark: isDark,
                highlightColor: _mapStyle == MapViewStyle.satellite ? const Color(0xFF00E5FF) : null,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.plus,
                tooltip: 'Zoom In',
                onPressed: () {
                  try {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 0.5);
                  } catch (_) {}
                  setState(() => _zoomScale = math.min(3.5, _zoomScale + 0.3));
                },
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.minus,
                tooltip: 'Zoom Out',
                onPressed: () {
                  try {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 0.5);
                  } catch (_) {}
                  setState(() => _zoomScale = math.max(0.6, _zoomScale - 0.3));
                },
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.caretUp,
                tooltip: 'Pan North',
                onPressed: () => _panMap(0.5, 0.0),
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapActionButton(
                    icon: PhosphorIconsRegular.caretLeft,
                    tooltip: 'Pan West',
                    onPressed: () => _panMap(0.0, -0.5),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                  _buildMapActionButton(
                    icon: PhosphorIconsRegular.caretRight,
                    tooltip: 'Pan East',
                    onPressed: () => _panMap(0.0, 0.5),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.caretDown,
                tooltip: 'Pan South',
                onPressed: () => _panMap(-0.5, 0.0),
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: PhosphorIconsRegular.arrowsClockwise,
                tooltip: 'Reset / Center View',
                onPressed: _resetMapTransform,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Floating Zen Exit Pill (when in Zen Mode)
        if (_isZenMode)
          Positioned(
            top: 14,
            left: 14,
            child: _buildZenExitButton(isDark),
          ),

        // Live Telemetry Ticker (Floating Pill at Bottom-Left) - Hidden in Zen Mode
        if (state.telemetryLogs.isNotEmpty && !_isZenMode)
          Positioned(
            left: 14,
            bottom: 14,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: selectedCluster != null
                    ? math.max(160, MediaQuery.of(context).size.width - 400)
                    : math.min(380, MediaQuery.of(context).size.width - 28),
              ),
              child: _buildTelemetryTicker(context, state, isDark),
            ),
          ),

        // eStream Satellite Selected Telemetry Inspector - Floating Non-Blocking Card
        if (_selectedSatellite != null && !_isZenMode && _mapStyle == MapViewStyle.satellite)
          Positioned(
            left: 14,
            bottom: state.telemetryLogs.isNotEmpty ? 54 : 14,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(320, MediaQuery.of(context).size.width - 28),
              ),
              child: _buildSatelliteDetailCard(context, _selectedSatellite!, isDark),
            ),
          ),

        // Cluster Selected Floating Non-Blocking Card (Bottom-Right, Does NOT block the map!)
        if (selectedCluster != null && !_isZenMode)
          Positioned(
            right: 14,
            bottom: 14,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(370, MediaQuery.of(context).size.width - 28),
              ),
              child: _buildClusterDetailCard(context, selectedCluster, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildSatelliteReconBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1424).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.8), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(PhosphorIconsFill.planet, size: 12, color: Color(0xFF00E5FF)),
          const SizedBox(width: 4),
          const Text(
            'eStream™ ORBITAL SATELLITE RECON',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00E5FF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 10, color: Colors.white24),
          const SizedBox(width: 6),
          const Text(
            'SENTINEL-2 SAR COMPOSITE (10m) | ACTIVE PASS',
            style: TextStyle(fontSize: 9, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _showSatelliteSwaths = !_showSatelliteSwaths),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: _showSatelliteSwaths ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _showSatelliteSwaths ? const Color(0xFF00E5FF) : Colors.white24, width: 0.8),
              ),
              child: Text(
                _showSatelliteSwaths ? 'Swaths: ON' : 'Swaths: OFF',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: _showSatelliteSwaths ? const Color(0xFF00E5FF) : Colors.white60,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerChip(String layerId, String label, bool isSelected, bool isDark, {VoidCallback? onCustomTap}) {
    return InkWell(
      onTap: () {
        if (onCustomTap != null) {
          onCustomTap();
        } else {
          context.read<SurveillanceBloc>().add(ToggleSurveillanceLayerEvent(layerId));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
              : (isDark ? Colors.grey[900]! : Colors.white).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? (isDark ? Colors.white : AppColors.primaryGreen) : Colors.grey,
          ),
        ),
      ),
    );
  }


  Widget _buildPredictionHorizonDock(
    bool isDark,
    List<OutbreakClusterModel> clusters,
    List<DistrictRiskModel> districts,
  ) {
    final forecast = _getCurrentForecast(districts, clusters);
    final isForecasting = _selectedHorizon != PredictionHorizon.now;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xDD0F172A) : Colors.white.withValues(alpha: 0.94)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isForecasting
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isForecasting ? const Color(0xFF00E5FF) : Colors.black).withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isForecasting ? const Color(0xFF00E5FF) : AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isForecasting
                        ? 'SEIR FORECAST [${_selectedHorizon.label}]'
                        : 'REAL-TIME TELEMETRY [T-0]',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isForecasting ? const Color(0xFF00E5FF) : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_activePolicies.activePolicyCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_activePolicies.activePolicyCount} Policies Active',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHorizonButton(PredictionHorizon.now, 'NOW', isDark),
                  const SizedBox(width: 6),
                  _buildHorizonButton(PredictionHorizon.day7, '+7D', isDark),
                  const SizedBox(width: 6),
                  _buildHorizonButton(PredictionHorizon.day14, '+14D', isDark),
                  const SizedBox(width: 6),
                  _buildHorizonButton(PredictionHorizon.day30, '+30D', isDark),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isForecasting
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : (isDark ? Colors.grey[850] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isForecasting ? const Color(0xFF00E5FF) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '${forecast.totalProjectedCases} Cases',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isForecasting ? const Color(0xFF00E5FF) : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizonButton(PredictionHorizon horizon, String label, bool isDark) {
    final isSelected = _selectedHorizon == horizon;
    return InkWell(
      onTap: () => setState(() => _selectedHorizon = horizon),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : (isDark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
    Color? highlightColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: highlightColor != null
            ? highlightColor.withValues(alpha: 0.18)
            : (isDark ? Colors.grey[850] : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: highlightColor ?? (isDark ? Colors.grey[750]! : Colors.grey[300]!),
          width: highlightColor != null ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (highlightColor ?? Colors.black).withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: highlightColor ?? (isDark ? Colors.white : Colors.black87)),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _handleMapTap(
    Offset localPos,
    LatLng? point,
    List<OutbreakClusterModel> clusters,
    List<LivestockTransitVehicle> vehicles,
    List<DistrictRiskModel> districts,
    bool isTransitOn,
    OutbreakClusterModel? selectedCluster,
  ) {
    // Hit test satellites in satellite mode
    if (_mapStyle == MapViewStyle.satellite) {
      final hitSat = _hitTestSatellite(localPos, _satellites);
      if (hitSat != null) {
        setState(() {
          _selectedSatellite = _selectedSatellite?.id == hitSat.id ? null : hitSat;
        });
        return;
      }
    }

    // Phase 3: Hit test biosecurity checkpoints
    if (_showCheckpoints) {
      final hitCkp = _hitTestCheckpoint(localPos, _checkpoints, point: point);
      if (hitCkp != null) {
        EdgeVisionInspectionDialog.show(
          context,
          checkpoint: hitCkp,
          onGateStatusChanged: (newStatus) {
            setState(() {
              hitCkp.gateBarrierStatus = newStatus;
            });
          },
        );
        return;
      }
    }

    // Hit test vehicles first
    if (isTransitOn) {
      final hitVehicle = _hitTestVehicle(localPos, vehicles, point: point);
      if (hitVehicle != null) {
        context.read<SurveillanceBloc>().add(SelectTransitVehicleEvent(hitVehicle));
        TransitManifestSheet.show(context, hitVehicle, onCleared: () {
          context.read<SurveillanceBloc>().add(const SelectTransitVehicleEvent(null));
        });
        return;
      }
    }

    // Hit test clusters
    final hitCluster = _hitTestCluster(localPos, clusters, point: point);
    if (hitCluster != null) {
      context.read<SurveillanceBloc>().add(SelectClusterEvent(hitCluster));
      return;
    }

    // Hit test districts
    final hitDistrict = _hitTestDistrict(localPos, districts, point: point);
    if (hitDistrict != null) {
      context.read<SurveillanceBloc>().add(SelectDistrictEvent(hitDistrict));
      final assocCluster = clusters.cast<OutbreakClusterModel?>().firstWhere(
        (c) => c != null && (c.districtId == hitDistrict.districtId || c.districtName.toLowerCase() == hitDistrict.districtName.toLowerCase()),
        orElse: () => null,
      );
      DistrictTacticalDossierDialog.show(
        context,
        hitDistrict,
        associatedCluster: assocCluster,
      );
      return;
    }

    // Empty map tap: dismiss active selections to keep the view neat
    if (selectedCluster != null) {
      context.read<SurveillanceBloc>().add(const SelectClusterEvent(null));
    }
    if (_selectedSatellite != null) {
      setState(() => _selectedSatellite = null);
    }
  }

  BiosecurityCheckpoint? _hitTestCheckpoint(Offset localPos, List<BiosecurityCheckpoint> checkpoints, {LatLng? point}) {
    for (final ckp in checkpoints) {
      final center = _projectCoordToCanvas(ckp.latitude, ckp.longitude);
      final dist = (center - localPos).distance;
      if (dist < 32.0) return ckp;
      if (point != null) {
        final km = const Distance().as(LengthUnit.Kilometer, point, LatLng(ckp.latitude, ckp.longitude));
        if (km < 25.0) return ckp;
      }
    }
    return null;
  }

  OrbitalSatellite? _hitTestSatellite(Offset localPos, List<OrbitalSatellite> satellites) {
    if (_mapStyle != MapViewStyle.satellite) return null;
    for (final s in satellites) {
      final center = _projectCoordToCanvas(s.currentLat, s.currentLon);
      final dist = (center - localPos).distance;
      if (dist < 36.0) {
        return s;
      }
    }
    return null;
  }

  OutbreakClusterModel? _hitTestCluster(Offset localPos, List<OutbreakClusterModel> clusters, {LatLng? point}) {
    for (final c in clusters) {
      final center = _projectCoordToCanvas(c.latitude, c.longitude);
      final dist = (center - localPos).distance;
      if (dist < 36.0) return c;
      if (point != null) {
        final km = const Distance().as(LengthUnit.Kilometer, point, LatLng(c.latitude, c.longitude));
        if (km < 35.0) return c;
      }
    }
    return null;
  }

  LivestockTransitVehicle? _hitTestVehicle(Offset localPos, List<LivestockTransitVehicle> vehicles, {LatLng? point}) {
    for (final v in vehicles) {
      final center = _projectCoordToCanvas(v.currentLat, v.currentLon);
      final dist = (center - localPos).distance;
      if (dist < 30.0) return v;
      if (point != null) {
        final km = const Distance().as(LengthUnit.Kilometer, point, LatLng(v.currentLat, v.currentLon));
        if (km < 20.0) return v;
      }
    }
    return null;
  }

  DistrictRiskModel? _hitTestDistrict(Offset localPos, List<DistrictRiskModel> districts, {LatLng? point}) {
    for (final d in districts) {
      final center = _projectCoordToCanvas(d.latitude, d.longitude);
      final dist = (center - localPos).distance;
      if (dist < 26.0) return d;
      if (point != null) {
        final km = const Distance().as(LengthUnit.Kilometer, point, LatLng(d.latitude, d.longitude));
        if (km < 40.0) return d;
      }
    }
    return null;
  }

  Offset _projectCoordToCanvas(double lat, double lon) {
    if (_mapCamera != null) {
      return _mapCamera!.latLngToScreenOffset(LatLng(lat, lon));
    }
    const minLat = 15.6;
    const maxLat = 22.1;
    const minLon = 72.6;
    const maxLon = 80.9;

    final width = _lastCanvasSize.width > 0 ? _lastCanvasSize.width : MediaQuery.of(context).size.width;
    final height = _lastCanvasSize.height > 0 ? _lastCanvasSize.height : (MediaQuery.of(context).size.height * 0.55);

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xDD0D1626) : Colors.white.withValues(alpha: 0.94)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cluster.riskLevel == SeverityLevel.critical
                  ? AppColors.alertRed
                  : AppColors.alertAmber,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (cluster.riskLevel == SeverityLevel.critical ? AppColors.alertRed : AppColors.alertAmber).withValues(alpha: 0.25),
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
                          cluster.diseaseName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Epicenter: ${cluster.districtName}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 18),
                    onPressed: () {
                      context.read<SurveillanceBloc>().add(const SelectClusterEvent(null));
                    },
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
              const SizedBox(height: 12),
              // Actions: Quarantine (RBAC-gated) & Directives
              Row(
                children: [
                  Expanded(
                    child: RbacGuard(
                      permission: Permission.declareQuarantine,
                      showLockedState: true,
                      child: BioHerdButton(
                        label: cluster.quarantineDeclared
                            ? 'Quarantine Active'
                            : 'Enact Quarantine',
                        icon: cluster.quarantineDeclared
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsRegular.shieldCheck,
                        onPressed: () {
                          context.read<SurveillanceBloc>().add(
                                DeclareQuarantineEvent(cluster.id),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('5km Containment Zone enacted for ${cluster.districtName}. Transit restrictions active.'),
                              backgroundColor: AppColors.alertRed,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(PhosphorIconsRegular.bookOpen, size: 16),
                    label: const Text('Directives'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
        ),
      ),
    );
  }

  Widget _buildSatelliteDetailCard(
    BuildContext context,
    OrbitalSatellite sat,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xEE0A1424),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sat.color.withValues(alpha: 0.65), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: sat.color.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sat.color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: sat.color, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sat.name,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: sat.color),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedSatellite = null),
                    child: const Icon(PhosphorIconsRegular.x, size: 15, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${sat.agency} • ${sat.noradCatalog}',
                style: const TextStyle(fontSize: 9.5, color: Colors.white60),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSatMetricItem('Altitude', '${sat.altitudeKm.toInt()} km', sat.color),
                    _buildSatMetricItem('Velocity', '${sat.velocityKmS.toStringAsFixed(2)} km/s', Colors.white),
                    _buildSatMetricItem('Downlink', sat.streamBandwidth.split(' ').first, const Color(0xFF00E676)),
                    _buildSatMetricItem('SNR', '${sat.snrDb} dB', Colors.amber),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Payload: ${sat.sensorType}',
                style: const TextStyle(fontSize: 9, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sat.isTargetLocked) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.target, size: 11, color: AppColors.alertRed),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'eStream LOCK: ${sat.targetLockName}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.alertRed),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSatMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 8.5, color: Colors.white54)),
      ],
    );
  }

  Widget _buildZenExitButton(bool isDark) {
    return InkWell(
      onTap: () => setState(() => _isZenMode = false),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xDD0A1424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.cornersIn, size: 14, color: Color(0xFF00E5FF)),
            SizedBox(width: 6),
            Text(
              'Exit Clean View',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryTicker(BuildContext context, SurveillanceState state, bool isDark) {
    return InkWell(
      onTap: () {
        TelemetryFeedDialog.show(context, state.telemetryLogs);
      },
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xDD111827) : Colors.white.withValues(alpha: 0.92)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'eStream FEED:',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.telemetryLogs.first.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(PhosphorIconsRegular.caretRight, size: 13, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
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
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      ],
    );
  }

  // --- District Rankings Leaderboard View with Live Real-time Deltas ---
  Widget _buildDistrictRankingsView(
    BuildContext context,
    SurveillanceState state,
    bool isDark,
  ) {
    var districts = state.districts;

    // Filter by disease if set
    if (state.selectedDiseaseFilter != 'All' && state.selectedDiseaseFilter.isNotEmpty) {
      districts = districts
          .where((d) => d.primaryDisease.toLowerCase().contains(state.selectedDiseaseFilter.toLowerCase()))
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      districts = districts
          .where((d) =>
              d.districtName.toLowerCase().contains(q) ||
              d.primaryDisease.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      children: [
        // Search & Filter Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search 36 Maharashtra Districts...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // Live Telemetry Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsFill.chartLineUp, size: 14, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Text(
                'Live Telemetry: Avg Risk ${state.averageRiskIndex}/100 • ${state.totalSimulationTicks} Sim Ticks',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
            ],
          ),
        ),

        // Districts List
        Expanded(
          child: ListView.builder(
            itemCount: districts.length,
            itemBuilder: (context, idx) {
              final district = districts[idx];
              return DistrictRiskCard(
                district: district,
                isSelected: state.selectedDistrict?.districtId == district.districtId,
                onTap: () {
                  context.read<SurveillanceBloc>().add(SelectDistrictEvent(district));
                  // Switch to Map and focus on selected district
                  setState(() => _viewModeIndex = 0);
                  _glideCameraTo(district.latitude, district.longitude, 1.4);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Custom Painter for Maharashtra Heatmap, Auto-Moving Vectors & Outbreak Rings ───

class MaharashtraMapPainter extends CustomPainter {
  final MapCamera? camera;
  final List<OutbreakClusterModel> clusters;
  final List<DistrictRiskModel> districts;
  final List<LivestockTransitVehicle> vehicles;
  final List<OrbitalSatellite> satellites;
  final OrbitalSatellite? selectedSatellite;
  final bool showSatelliteSwaths;
  final OutbreakClusterModel? selectedCluster;
  final LivestockTransitVehicle? selectedVehicle;
  final double pulseValue;
  final double zoomScale;
  final Offset panOffset;
  final bool isDark;
  final MapViewStyle mapStyle;
  final bool showHeatmap;
  final bool showTransit;
  final bool showRings;
  final bool showDistricts;
  final StatewideEpizooticForecast? forecast;
  final PredictionHorizon horizon;
  final bool showEcoVectorLayer;
  final bool showDownwindPlumes;
  final List<BiosecurityCheckpoint> checkpoints;
  final bool showCheckpoints;

  MaharashtraMapPainter({
    this.camera,
    required this.clusters,
    required this.districts,
    required this.vehicles,
    this.satellites = const [],
    this.selectedSatellite,
    this.showSatelliteSwaths = true,
    required this.selectedCluster,
    required this.selectedVehicle,
    required this.pulseValue,
    required this.zoomScale,
    required this.panOffset,
    required this.isDark,
    this.mapStyle = MapViewStyle.standard,
    required this.showHeatmap,
    required this.showTransit,
    required this.showRings,
    required this.showDistricts,
    this.forecast,
    this.horizon = PredictionHorizon.now,
    this.showEcoVectorLayer = false,
    this.showDownwindPlumes = true,
    this.checkpoints = const [],
    this.showCheckpoints = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ─── 1. BASEMAP OVERLAY (Real Map Tiles rendered beneath by FlutterMap) ───
    if (mapStyle == MapViewStyle.satellite) {
      // Luminous Neon Maharashtra Geodetic Boundary on Real Satellite Earth
      final borderCoords = const [
        [19.97, 72.75], // Dahanu / Palghar coast
        [19.45, 72.78], // Vasai
        [18.95, 72.82], // Mumbai Salsette
        [18.50, 72.90], // Alibag
        [17.95, 73.10], // Murud
        [17.30, 73.20], // Guhagar
        [16.70, 73.30], // Ratnagiri
        [16.15, 73.50], // Malvan
        [15.80, 73.65], // Vengurla
        [15.75, 74.00], // Sawantwadi
        [15.85, 74.30], // Chandgad
        [16.20, 74.50], // Ajara / Belgaum border
        [16.65, 74.90], // Kagal / Kolhapur
        [16.90, 75.30], // Sangli southern border
        [17.30, 75.80], // Solapur / Bijapur border
        [17.75, 76.40], // Omerga / Osmanabad border
        [18.25, 77.10], // Degloor / Nanded
        [18.80, 77.90], // Kinwat / Adilabad border
        [19.30, 78.60], // Yavatmal southern border
        [19.40, 79.30], // Chandrapur southern border
        [18.80, 80.00], // Sironcha / Pranhita confluence
        [19.20, 80.50], // Bhamragad
        [19.80, 80.60], // Gadchiroli eastern border
        [20.70, 80.40], // Gondia eastern border
        [21.40, 80.10], // Tiroda
        [21.60, 79.50], // Ramtek / Nagpur north
        [21.50, 78.80], // Katol
        [21.40, 78.10], // Morshi / Amravati
        [21.65, 77.20], // Melghat / Satpura
        [21.30, 76.30], // Jalgaon Jamod / Buldhana
        [21.20, 75.40], // Raver / Jalgaon
        [21.35, 74.60], // Shirpur / Dhule
        [21.75, 74.20], // Shahada / Nandurbar
        [21.95, 73.90], // Akrani / Narmada border
        [21.20, 73.70], // Nawapur
        [20.60, 73.60], // Surgana / Nashik
        [20.20, 73.30], // Jawhar / Palghar
        [19.97, 72.75], // Close loop
      ];

      final landPath = Path();
      for (int i = 0; i < borderCoords.length; i++) {
        final p = _coordToCanvas(borderCoords[i][0], borderCoords[i][1], size);
        if (i == 0) {
          landPath.moveTo(p.dx, p.dy);
        } else {
          landPath.lineTo(p.dx, p.dy);
        }
      }
      landPath.close();

      // Glowing boundary stroke
      canvas.drawPath(
        landPath,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.drawPath(
        landPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // eStream Real-Time Satellite Constellation Layer
      if (satellites.isNotEmpty) {
        _paintSatelliteConstellation(canvas, size);
      }
    }

  // ─── 2. TRUE GAUSSIAN THERMAL HEATMAP LAYER ───
    // ── 1.5 SATELLITE ECO-CLIMATIC VECTOR RISK LAYER (INSAT-3DR / S2A) ──
    if (showEcoVectorLayer) {
      for (final d in districts) {
        final pos = _coordToCanvas(d.latitude, d.longitude, size);
        final eco = DistrictEcoClimateModel.getProfileForDistrict(d.districtName);
        final vvi = eco.vectorViabilityIndex;
        final vRadius = (32.0 + vvi * 36.0) * zoomScale;

        Color ecoColor;
        if (vvi >= 0.75) {
          ecoColor = const Color(0xFFFF1744);
        } else if (vvi >= 0.60) {
          ecoColor = const Color(0xFFFF9100);
        } else {
          ecoColor = const Color(0xFF00E5FF);
        }

        final ecoPaint = Paint()
          ..shader = ui.Gradient.radial(
            pos,
            vRadius,
            [
              ecoColor.withValues(alpha: 0.35 * vvi),
              ecoColor.withValues(alpha: 0.12 * vvi),
              Colors.transparent,
            ],
            [0.0, 0.60, 1.0],
          );
        canvas.drawCircle(pos, vRadius, ecoPaint);

        // Vector Telemetry Tag
        final vviTag = TextPainter(
          text: TextSpan(
            text: 'VVI: ${(vvi * 100).toInt()}% [${eco.landSurfaceTempC}°C]',
            style: TextStyle(
              color: ecoColor,
              fontSize: 8.5 * zoomScale,
              fontWeight: FontWeight.bold,
              backgroundColor: const Color(0xDD0F172A),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        vviTag.layout();
        vviTag.paint(canvas, Offset(pos.dx - vviTag.width / 2, pos.dy - vRadius - 2));
      }
    }

    // ── 1.6 DOWNWIND AEROSOL DISPERSION PLUMES (AIRBORNE CONTAGION) ──
    if (showDownwindPlumes) {
      for (final c in clusters) {
        final pos = _coordToCanvas(c.latitude, c.longitude, size);
        final eco = DistrictEcoClimateModel.getProfileForDistrict(c.districtName);
        final angleRad = eco.windBearingDeg * math.pi / 180.0;
        final plumeDist = (eco.windSpeedKmH * (horizon == PredictionHorizon.now ? 1.0 : (horizon == PredictionHorizon.day7 ? 1.8 : 2.5))).clamp(14.0, 52.0) * zoomScale;
        const spread = 0.52; // ~30 deg cone

        final p1 = Offset(pos.dx + math.cos(angleRad - spread) * plumeDist, pos.dy + math.sin(angleRad - spread) * plumeDist);
        final p2 = Offset(pos.dx + math.cos(angleRad + spread) * plumeDist, pos.dy + math.sin(angleRad + spread) * plumeDist);

        final plumePath = Path()
          ..moveTo(pos.dx, pos.dy)
          ..lineTo(p1.dx, p1.dy)
          ..arcToPoint(p2, radius: Radius.circular(plumeDist * 0.8))
          ..close();

        final plumeGradient = Paint()
          ..shader = ui.Gradient.linear(
            pos,
            Offset(pos.dx + math.cos(angleRad) * plumeDist, pos.dy + math.sin(angleRad) * plumeDist),
            [
              const Color(0xFFFF9100).withValues(alpha: 0.38),
              const Color(0xFFFF1744).withValues(alpha: 0.15),
              Colors.transparent,
            ],
            [0.0, 0.65, 1.0],
          );
        canvas.drawPath(plumePath, plumeGradient);

        // Plume border
        canvas.drawPath(
          plumePath,
          Paint()
            ..color = const Color(0xFFFF9100).withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );

        // Wind vector indicator tag
        final arrowTip = Offset(pos.dx + math.cos(angleRad) * (plumeDist + 6), pos.dy + math.sin(angleRad) * (plumeDist + 6));
        final arrowPainter = TextPainter(
          text: TextSpan(
            text: 'WIND: ${eco.windSpeedKmH} km/h (${eco.windBearingDeg.toInt()}°)',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 8.5 * zoomScale,
              fontWeight: FontWeight.bold,
              backgroundColor: const Color(0xDD0F172A),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        arrowPainter.layout();
        arrowPainter.paint(canvas, Offset(arrowTip.dx - arrowPainter.width / 2, arrowTip.dy));
      }
    }

    if (showHeatmap) {
      for (final d in districts) {
        if (d.riskScore < 5.0) continue;
        final pos = _coordToCanvas(d.latitude, d.longitude, size);
        final intensity = (d.riskScore / 100.0).clamp(0.0, 1.0);
        final radius = (45.0 + intensity * 80.0) * zoomScale;

        Color thermalColor;
        if (mapStyle == MapViewStyle.satellite) {
          // Multispectral FLIR infrared false color in Satellite mode
          if (intensity >= 0.75) {
            thermalColor = const Color(0xFFFF1744); // Electric incandescent crimson
          } else if (intensity >= 0.50) {
            thermalColor = const Color(0xFFFF9100); // Solar infrared amber
          } else if (intensity >= 0.25) {
            thermalColor = const Color(0xFFFFD600); // Thermal yellow
          } else {
            thermalColor = const Color(0xFF00E5FF); // Cold cyan edge
          }
        } else {
          if (intensity >= 0.75) {
            thermalColor = AppColors.alertRed;
          } else if (intensity >= 0.50) {
            thermalColor = AppColors.alertAmber;
          } else if (intensity >= 0.25) {
            thermalColor = const Color(0xFFFFD600);
          } else {
            thermalColor = AppColors.primaryGreen;
          }
        }

        final heatPaint = Paint()
          ..shader = ui.Gradient.radial(
            pos,
            radius,
            [
              thermalColor.withValues(alpha: 0.45 * intensity),
              thermalColor.withValues(alpha: 0.20 * intensity),
              thermalColor.withValues(alpha: 0.0),
            ],
            [0.0, 0.55, 1.0],
          );

        canvas.drawCircle(pos, radius, heatPaint);
      }
    }

    // ─── 3. Draw Highway Transit Route Corridors (Network Trails) ───
    if (showTransit) {
      final highwayPaint = Paint()
        ..color = mapStyle == MapViewStyle.satellite
            ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
            : (isDark ? Colors.grey[700]! : Colors.grey[300]!).withValues(alpha: 0.4)
        ..strokeWidth = 1.5 * zoomScale
        ..style = PaintingStyle.stroke;

      for (final v in vehicles) {
        final originPos = _coordToCanvas(v.originLat, v.originLon, size);
        final destPos = _coordToCanvas(v.destLat, v.destLon, size);
        canvas.drawLine(originPos, destPos, highwayPaint);
      }
    }

    // ─── 4. Draw Outbreak Buffer Rings & Expanding Waves ───
    if (showRings) {
      for (final c in clusters) {
        final pos = _coordToCanvas(c.latitude, c.longitude, size);
        final isSelected = selectedCluster?.id == c.id;

        // Radiating Contagion Shockwave
        final waveRadius = (c.containmentRadiusKm * 3.5 + (pulseValue * 32.0)) * zoomScale;
        canvas.drawCircle(
          pos,
          waveRadius,
          Paint()
            ..color = AppColors.alertRed.withValues(alpha: (1.0 - pulseValue) * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );

        // ══════════════════════════════════════════════════════════════════════
        // TIER 3: 3-10km MANDATORY RING VACCINATION BUFFER SHIELD (Cyan/Emerald)
        // ══════════════════════════════════════════════════════════════════════
        final rBuffer = (c.surveillanceRadiusKm * 3.5) * zoomScale;
        canvas.drawCircle(
          pos,
          rBuffer,
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.07)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          rBuffer,
          Paint()
            ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );

        // ══════════════════════════════════════════════════════════════════════
        // TIER 2: 1-3km ACTIVE SURVEILLANCE ZONE (Amber)
        // ══════════════════════════════════════════════════════════════════════
        final rSurveillance = (c.containmentRadiusKm * 3.5) * zoomScale;
        canvas.drawCircle(
          pos,
          rSurveillance,
          Paint()
            ..color = AppColors.alertAmber.withValues(alpha: 0.14)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          rSurveillance,
          Paint()
            ..color = AppColors.alertAmber.withValues(alpha: 0.90)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );

        // Radar tick marks along surveillance perimeter
        for (int i = 0; i < 12; i++) {
          final rad = (i * 30.0) * math.pi / 180.0;
          final pOuter = Offset(pos.dx + math.cos(rad) * (rSurveillance + 4), pos.dy + math.sin(rad) * (rSurveillance + 4));
          final pInner = Offset(pos.dx + math.cos(rad) * (rSurveillance - 4), pos.dy + math.sin(rad) * (rSurveillance - 4));
          canvas.drawLine(pInner, pOuter, Paint()..color = AppColors.alertAmber..strokeWidth = 1.2);
        }

        // ══════════════════════════════════════════════════════════════════════
        // TIER 1: 0-1km INFECTED ZONE CORDON (Crimson Red Total Lockdown)
        // ══════════════════════════════════════════════════════════════════════
        final rInfected = (rSurveillance * 0.38).clamp(16.0, 36.0) * zoomScale;
        canvas.drawCircle(
          pos,
          rInfected,
          Paint()
            ..color = AppColors.alertRed.withValues(alpha: 0.28)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          rInfected,
          Paint()
            ..color = const Color(0xFFFF1744)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );

        // Hazard Crosshatch marks inside Tier 1 Cordon
        for (int i = 0; i < 8; i++) {
          final rad = (i * 45.0 + (pulseValue * 15.0)) * math.pi / 180.0;
          final pOuter = Offset(pos.dx + math.cos(rad) * (rInfected + 3), pos.dy + math.sin(rad) * (rInfected + 3));
          final pInner = Offset(pos.dx + math.cos(rad) * (rInfected - 3), pos.dy + math.sin(rad) * (rInfected - 3));
          canvas.drawLine(pInner, pOuter, Paint()..color = const Color(0xFFFF1744)..strokeWidth = 1.5);
        }

        // Tactical Reticle Crosshairs at Epicenter
        final crossArm = 14.0 * zoomScale;
        final reticlePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(pos.dx - crossArm, pos.dy), Offset(pos.dx - 5, pos.dy), reticlePaint);
        canvas.drawLine(Offset(pos.dx + 5, pos.dy), Offset(pos.dx + crossArm, pos.dy), reticlePaint);
        canvas.drawLine(Offset(pos.dx, pos.dy - crossArm), Offset(pos.dx, pos.dy - 5), reticlePaint);
        canvas.drawLine(Offset(pos.dx, pos.dy + 5), Offset(pos.dx, pos.dy + crossArm), reticlePaint);

        // Pulsating Beacon Pin
        final pulseRadius = (14.0 + (pulseValue * 9.0)) * zoomScale;
        canvas.drawCircle(
          pos,
          pulseRadius,
          Paint()
            ..color = AppColors.alertRed.withValues(alpha: 0.30 * (1.0 - pulseValue * 0.5))
            ..style = PaintingStyle.fill,
        );

        // Core Epicenter Pin
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

        // Tactical Cordon HUD Text Badge
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'CORDON: ${c.districtName.toUpperCase()} [${c.containmentRadiusKm.toInt()}km CORDON]',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5 * zoomScale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              backgroundColor: const Color(0xDD0F172A),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + rInfected + 4));
      }
    }

    // ─── 5. Draw Auto-Moving Livestock Transit Vehicles ───
    if (showTransit) {
      for (final v in vehicles) {
        final pos = _coordToCanvas(v.currentLat, v.currentLon, size);
        final isSelected = selectedVehicle?.id == v.id;
        final isIntercepted = v.biosecurityStatus == 'containment_intercepted';

        // Headlight beam cones in satellite mode illuminating forward highway corridor
        if (mapStyle == MapViewStyle.satellite) {
          final destPos = _coordToCanvas(v.destLat, v.destLon, size);
          final angle = math.atan2(destPos.dy - pos.dy, destPos.dx - pos.dx);
          final beamDist = 32.0 * zoomScale;
          const beamSpread = 0.45;

          final beamPath = Path()
            ..moveTo(pos.dx, pos.dy)
            ..lineTo(pos.dx + math.cos(angle - beamSpread) * beamDist, pos.dy + math.sin(angle - beamSpread) * beamDist)
            ..lineTo(pos.dx + math.cos(angle + beamSpread) * beamDist, pos.dy + math.sin(angle + beamSpread) * beamDist)
            ..close();

          final headlightShader = ui.Gradient.radial(
            pos,
            beamDist,
            [
              const Color(0xFFFFF9C4).withValues(alpha: 0.4),
              const Color(0xFFFFEE58).withValues(alpha: 0.15),
              Colors.transparent,
            ],
            [0.0, 0.4, 1.0],
          );
          canvas.drawPath(beamPath, Paint()..shader = headlightShader);
        }

        // Vehicle halo
        Color vehColor = isIntercepted
            ? AppColors.alertRed
            : v.biosecurityStatus == 'screening_required'
                ? AppColors.alertAmber
                : AppColors.primaryGreen;

        if (isIntercepted) {
          // Pulsing warning ring around intercepted carrier
          canvas.drawCircle(
            pos,
            (16.0 + pulseValue * 6.0) * zoomScale,
            Paint()
              ..color = AppColors.alertRed.withValues(alpha: 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
        }

        // Vehicle badge circle
        final vehRadius = (isSelected ? 10.0 : 8.0) * zoomScale;
        canvas.drawCircle(
          pos,
          vehRadius,
          Paint()..color = vehColor,
        );
        canvas.drawCircle(
          pos,
          vehRadius,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        // Vehicle license badge text
        final textSpan = TextSpan(
          text: v.licensePlate.substring(0, math.min(5, v.licensePlate.length)),
          style: TextStyle(
            color: mapStyle == MapViewStyle.satellite ? const Color(0xFF00E5FF) : (isDark ? Colors.white : Colors.black87),
            fontSize: 8.0 * math.min(1.3, zoomScale),
            fontWeight: FontWeight.bold,
            backgroundColor: (isDark || mapStyle == MapViewStyle.satellite ? Colors.black87 : Colors.white).withValues(alpha: 0.8),
          ),
        );
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
        textPainter.paint(canvas, Offset(pos.dx + 8, pos.dy - 6));
      }
    }

    // ─── 6. Draw District Centroids & Labels ───
    if (showDistricts) {
      for (final d in districts) {
        final pos = _coordToCanvas(d.latitude, d.longitude, size);
        final distColor = d.severity == SeverityLevel.critical
            ? AppColors.alertRed
            : d.severity == SeverityLevel.high
                ? AppColors.alertAmber
                : (mapStyle == MapViewStyle.satellite
                    ? const Color(0xFF00E5FF)
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!));

        // Centroid bubble
        canvas.drawCircle(
          pos,
          4.0 * zoomScale,
          Paint()..color = distColor.withValues(alpha: 0.7),
        );

        // Label major cities
        if (['Solapur', 'Kolhapur', 'Ahmednagar', 'Pune', 'Nashik', 'Nagpur', 'Amravati', 'Latur'].contains(d.districtName)) {
          final textSpan = TextSpan(
            text: d.districtName,
            style: TextStyle(
              color: mapStyle == MapViewStyle.satellite ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
              fontSize: 9.0 * math.min(1.3, zoomScale),
              fontWeight: FontWeight.w600,
              backgroundColor: mapStyle == MapViewStyle.satellite ? Colors.black54 : null,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(canvas, Offset(pos.dx + 6, pos.dy - 6));
        }

        // Phase 2: Spatio-Temporal Prediction Projection Tag
        if (horizon != PredictionHorizon.now && forecast != null) {
          final res = forecast!.districtForecasts[d.districtId];
          if (res != null && res.projectedCases > 0) {
            final projText = TextSpan(
              text: ' +${horizon.days}D: ${res.projectedCases} ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5 * math.min(1.3, zoomScale),
                fontWeight: FontWeight.w900,
                backgroundColor: res.projectedSeverity == SeverityLevel.critical
                    ? const Color(0xFFFF1744)
                    : const Color(0xFF00E5FF),
              ),
            );
            final projPainter = TextPainter(
              text: projText,
              textDirection: TextDirection.ltr,
            )..layout();
            projPainter.paint(canvas, Offset(pos.dx + 6, pos.dy + 6));
          }
        }
      }
    }

    // --- 7. BIOSECURITY CHECKPOINTS & SMART GATES (Phase 3) ---
    if (showCheckpoints && checkpoints.isNotEmpty) {
      _drawCheckpoints(canvas, size);
    }
  }

  void _drawCheckpoints(Canvas canvas, Size size) {
    for (final ckp in checkpoints) {
      final pos = _coordToCanvas(ckp.latitude, ckp.longitude, size);

      // Pulsing radar ripple
      final pulseRadius = (16.0 + 8.0 * pulseValue) * zoomScale;
      canvas.drawCircle(
        pos,
        pulseRadius,
        Paint()
          ..color = ckp.statusColor.withValues(alpha: 0.35 * (1.0 - pulseValue))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Outer gate marker disc
      final bgPaint = Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white;
      canvas.drawCircle(pos, 10.0 * zoomScale, bgPaint);

      final rimPaint = Paint()
        ..color = ckp.statusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(pos, 10.0 * zoomScale, rimPaint);

      // Center status core
      canvas.drawCircle(pos, 4.5 * zoomScale, Paint()..color = ckp.statusColor);

      // Gate badge label
      final labelSpan = TextSpan(
        text: ' [GATE] ${ckp.district} (${ckp.highway.split(" ")[0]}) ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5 * math.min(1.3, zoomScale),
          fontWeight: FontWeight.bold,
          backgroundColor: const Color(0xDD0F172A),
        ),
      );
      final textPainter = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(pos.dx + 12, pos.dy - 6));
    }
  }

  Offset _coordToCanvas(double lat, double lon, Size size) {
    if (camera != null) {
      return camera!.latLngToScreenOffset(LatLng(lat, lon));
    }
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

  void _paintSatelliteConstellation(Canvas canvas, Size size) {
    for (final sat in satellites) {
      final satColor = sat.color;
      final isSelected = selectedSatellite?.id == sat.id;

      // A. Orbital Ground Track Trajectory
      if (sat.trajectoryPoints.length >= 2) {
        final trackPath = Path();
        for (int i = 0; i < sat.trajectoryPoints.length; i++) {
          final pt = _coordToCanvas(sat.trajectoryPoints[i][0], sat.trajectoryPoints[i][1], size);
          if (i == 0) {
            trackPath.moveTo(pt.dx, pt.dy);
          } else {
            trackPath.lineTo(pt.dx, pt.dy);
          }
        }

        // Soft Outer Glow
        canvas.drawPath(
          trackPath,
          Paint()
            ..color = satColor.withValues(alpha: isSelected ? 0.35 : 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (isSelected ? 3.0 : 1.5) * zoomScale
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
        );

        // Core Dashed Trajectory Line
        final dashPaint = Paint()
          ..color = satColor.withValues(alpha: isSelected ? 0.85 : 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (isSelected ? 1.8 : 1.0) * zoomScale;
        _drawDashedPath(canvas, trackPath, dashPaint, 8.0, 6.0);
      }

      final satPos = _coordToCanvas(sat.currentLat, sat.currentLon, size);

      // B. Sensor Ground Swath Footprint Cone
      if (showSatelliteSwaths) {
        final swathRadius = (sat.swathRadiusKm * 0.48) * zoomScale;

        // Ground footprint radial gradient
        final swathPaint = Paint()
          ..shader = ui.Gradient.radial(
            satPos,
            swathRadius,
            [
              satColor.withValues(alpha: isSelected ? 0.22 : 0.10),
              satColor.withValues(alpha: isSelected ? 0.08 : 0.03),
              Colors.transparent,
            ],
            [0.0, 0.65, 1.0],
          );
        canvas.drawCircle(satPos, swathRadius, swathPaint);

        // Swath border ring
        canvas.drawCircle(
          satPos,
          swathRadius,
          Paint()
            ..color = satColor.withValues(alpha: isSelected ? 0.65 : 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );

        // Sweeping raster scan beam inside swath
        final scanOffset = ((pulseValue * 2.0) % 1.0) * swathRadius;
        canvas.drawLine(
          Offset(satPos.dx - swathRadius * 0.7, satPos.dy + scanOffset - (swathRadius * 0.5)),
          Offset(satPos.dx + swathRadius * 0.7, satPos.dy + scanOffset - (swathRadius * 0.5)),
          Paint()
            ..color = satColor.withValues(alpha: 0.3)
            ..strokeWidth = 1.2,
        );
      }

      // C. Dynamic Target Lock-On Telemetry & Reticle
      if (sat.isTargetLocked) {
        final targetCoord = sat.targetLockName.contains('Solapur')
            ? const [17.6599, 75.9064]
            : sat.targetLockName.contains('Osmanabad')
                ? const [18.1856, 76.0419]
                : const [16.7050, 74.2433];
        final targetPos = _coordToCanvas(targetCoord[0], targetCoord[1], size);

        // Laser telemetry downlink beam from satellite to target
        canvas.drawLine(
          satPos,
          targetPos,
          Paint()
            ..color = satColor.withValues(alpha: 0.45)
            ..strokeWidth = 1.2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
        );

        // Dynamic Targeting Reticle over hotspot
        _drawTargetReticle(canvas, targetPos, satColor, sat.targetLockName, sat.sensorType);
      }

      // D. High-Detail Satellite Spacecraft Icon
      _drawSatelliteCraft(canvas, satPos, sat, isSelected);
    }
  }

  void _drawSatelliteCraft(Canvas canvas, Offset pos, OrbitalSatellite sat, bool isSelected) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final angleRad = (sat.headingDeg * math.pi / 180.0);
    canvas.rotate(angleRad);

    final scale = (isSelected ? 1.3 : 1.0) * zoomScale;
    canvas.scale(scale);

    // 1. Dual Photovoltaic Solar Panel Arrays
    const panelWidth = 16.0;
    const panelHeight = 8.0;
    const panelY = -panelHeight / 2;

    const leftPanelRect = Rect.fromLTWH(-24.0, panelY, panelWidth, panelHeight);
    const rightPanelRect = Rect.fromLTWH(8.0, panelY, panelWidth, panelHeight);

    final panelShader = ui.Gradient.linear(
      const Offset(-24, 0),
      const Offset(24, 0),
      [
        const Color(0xFF0D47A1),
        const Color(0xFF1976D2),
        sat.color.withValues(alpha: 0.8),
        const Color(0xFF1976D2),
        const Color(0xFF0D47A1),
      ],
      [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final panelPaint = Paint()..shader = panelShader;
    canvas.drawRect(leftPanelRect, panelPaint);
    canvas.drawRect(rightPanelRect, panelPaint);

    final framePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(leftPanelRect, framePaint);
    canvas.drawRect(rightPanelRect, framePaint);
    canvas.drawLine(const Offset(-16, -4), const Offset(-16, 4), framePaint);
    canvas.drawLine(const Offset(16, -4), const Offset(16, 4), framePaint);

    // 2. Central Spacecraft Bus (Chassis)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-6.0, -7.0, 12.0, 14.0),
      const Radius.circular(2.5),
    );
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-6, -7),
        const Offset(6, 7),
        [const Color(0xFFE0E0E0), const Color(0xFF757575)],
      );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = sat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 3. Central Sensor Aperture Lens / Payload
    canvas.drawCircle(
      Offset.zero,
      3.0,
      Paint()..color = sat.color,
    );

    // 4. High-Gain Communications Dish Antenna
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 9), radius: 5.0),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      const Offset(0, 7),
      const Offset(0, 11),
      Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 1.0,
    );

    canvas.restore();

    // 5. Radio Telemetry Beacon Pulse (drawn unrotated)
    final beaconRadius = (10.0 + (pulseValue * 14.0)) * zoomScale;
    canvas.drawCircle(
      pos,
      beaconRadius,
      Paint()
        ..color = sat.color.withValues(alpha: (1.0 - pulseValue) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 6. Floating Callsign HUD Label
    final labelSpan = TextSpan(
      children: [
        TextSpan(
          text: '${sat.code} ',
          style: TextStyle(
            color: sat.color,
            fontSize: 8.5 * math.min(1.2, zoomScale),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        TextSpan(
          text: sat.isTargetLocked ? '● LOCKED' : 'eStream',
          style: TextStyle(
            color: sat.isTargetLocked ? AppColors.alertRed : Colors.white70,
            fontSize: 7.5 * math.min(1.2, zoomScale),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
    final labelPainter = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
    final badgeWidth = labelPainter.width + 10;
    final badgeHeight = labelPainter.height + 4;
    final badgeOffset = Offset(pos.dx + 16, pos.dy - 8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeOffset.dx, badgeOffset.dy, badgeWidth, badgeHeight),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xDD0A1424),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeOffset.dx, badgeOffset.dy, badgeWidth, badgeHeight),
        const Radius.circular(4),
      ),
      Paint()
        ..color = sat.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    labelPainter.paint(canvas, Offset(badgeOffset.dx + 5, badgeOffset.dy + 2));
  }

  void _drawTargetReticle(Canvas canvas, Offset pos, Color color, String targetName, String sensor) {
    final reticleRadius = (18.0 + (pulseValue * 4.0)) * zoomScale;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(pulseValue * math.pi * 0.25);

    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const bLen = 6.0;
    // Top-left
    canvas.drawLine(Offset(-reticleRadius, -reticleRadius + bLen), Offset(-reticleRadius, -reticleRadius), bracketPaint);
    canvas.drawLine(Offset(-reticleRadius, -reticleRadius), Offset(-reticleRadius + bLen, -reticleRadius), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(reticleRadius - bLen, -reticleRadius), Offset(reticleRadius, -reticleRadius), bracketPaint);
    canvas.drawLine(Offset(reticleRadius, -reticleRadius), Offset(reticleRadius, -reticleRadius + bLen), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(-reticleRadius, reticleRadius - bLen), Offset(-reticleRadius, reticleRadius), bracketPaint);
    canvas.drawLine(Offset(-reticleRadius, reticleRadius), Offset(-reticleRadius + bLen, reticleRadius), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(reticleRadius - bLen, reticleRadius), Offset(reticleRadius, reticleRadius), bracketPaint);
    canvas.drawLine(Offset(reticleRadius, reticleRadius), Offset(reticleRadius, reticleRadius - bLen), bracketPaint);

    canvas.restore();

    // Central crosshair
    canvas.drawLine(Offset(pos.dx - 4, pos.dy), Offset(pos.dx + 4, pos.dy), Paint()..color = color..strokeWidth = 1.0);
    canvas.drawLine(Offset(pos.dx, pos.dy - 4), Offset(pos.dx, pos.dy + 4), Paint()..color = color..strokeWidth = 1.0);

    // Target lock text tag
    final tagSpan = TextSpan(
      text: 'eStream LOCK: $targetName',
      style: TextStyle(
        color: color,
        fontSize: 7.5 * math.min(1.2, zoomScale),
        fontWeight: FontWeight.w800,
        backgroundColor: Colors.black87,
      ),
    );
    final tagPainter = TextPainter(text: tagSpan, textDirection: TextDirection.ltr)..layout();
    tagPainter.paint(canvas, Offset(pos.dx - tagPainter.width / 2, pos.dy + reticleRadius + 4));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(distance, math.min(nextDistance, metric.length));
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MaharashtraMapPainter oldDelegate) {
    return oldDelegate.camera != camera ||
        oldDelegate.clusters != clusters ||
        oldDelegate.districts != districts ||
        oldDelegate.vehicles != vehicles ||
        oldDelegate.satellites != satellites ||
        oldDelegate.selectedSatellite != selectedSatellite ||
        oldDelegate.showSatelliteSwaths != showSatelliteSwaths ||
        oldDelegate.selectedCluster != selectedCluster ||
        oldDelegate.selectedVehicle != selectedVehicle ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.isDark != isDark ||
        oldDelegate.mapStyle != mapStyle ||
        oldDelegate.showHeatmap != showHeatmap ||
        oldDelegate.showTransit != showTransit ||
        oldDelegate.showRings != showRings ||
        oldDelegate.showDistricts != showDistricts;
  }
}

