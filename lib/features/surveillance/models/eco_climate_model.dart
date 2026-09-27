/// Eco-climatic and satellite environmental indices model
/// Derived from INSAT-3DR, Sentinel-2A MSI, Landsat-9, and EOS-04 SAR sensors.
class DistrictEcoClimateModel {
  final String districtId;
  final String districtName;
  final double vectorViabilityIndex; // 0.0 to 1.0 (Culicoides midges, ticks, mosquitoes)
  final double landSurfaceTempC; // Land Surface Temperature in °C from INSAT-3DR/Landsat
  final double vegetationIndexNdvi; // -0.2 to +1.0 (Grazing concentration)
  final double soilMoistureSaturationPct; // % soil saturation from EOS-04 SAR
  final double stagnantWaterIndex; // 0.0 to 1.0 (Waterlogged breeding grounds)
  final double windSpeedKmH; // Surface wind speed in km/h
  final double windBearingDeg; // Wind direction in degrees (0-360)
  final String primaryVector; // e.g. 'Culicoides biting midges', 'Boophilus microplus ticks'
  final String vectorBreedingRiskLevel; // 'LOW', 'MODERATE', 'HIGH', 'CRITICAL'
  final String environmentalNotes;

  const DistrictEcoClimateModel({
    required this.districtId,
    required this.districtName,
    required this.vectorViabilityIndex,
    required this.landSurfaceTempC,
    required this.vegetationIndexNdvi,
    required this.soilMoistureSaturationPct,
    required this.stagnantWaterIndex,
    required this.windSpeedKmH,
    required this.windBearingDeg,
    required this.primaryVector,
    required this.vectorBreedingRiskLevel,
    required this.environmentalNotes,
  });

  /// Computes combined microclimatic contagion multiplier
  double get microclimateContagionMultiplier {
    // High temp (28-36°C) + High moisture + High stagnant water creates explosive vector breeding
    double factor = 1.0;
    if (landSurfaceTempC >= 26.0 && landSurfaceTempC <= 36.0) {
      factor += 0.25;
    }
    if (soilMoistureSaturationPct >= 60.0) {
      factor += 0.20;
    }
    if (stagnantWaterIndex >= 0.50) {
      factor += 0.20;
    }
    factor += (vectorViabilityIndex * 0.35);
    return double.parse(factor.toStringAsFixed(2));
  }

  /// Default Maharashtra satellite environmental profiles
  static Map<String, DistrictEcoClimateModel> defaultEcoProfiles() {
    return {
      'Solapur': const DistrictEcoClimateModel(
        districtId: 'dist-solapur',
        districtName: 'Solapur',
        vectorViabilityIndex: 0.82,
        landSurfaceTempC: 34.2,
        vegetationIndexNdvi: 0.46,
        soilMoistureSaturationPct: 62.0,
        stagnantWaterIndex: 0.68,
        windSpeedKmH: 22.4,
        windBearingDeg: 78.0, // ENE wind blowing towards Osmanabad/Latur
        primaryVector: 'Culicoides biting midges (LSD Vector)',
        vectorBreedingRiskLevel: 'CRITICAL',
        environmentalNotes: 'High Ujjani reservoir moisture + 34°C triggers massive midge swarm breeding.',
      ),
      'Osmanabad': const DistrictEcoClimateModel(
        districtId: 'dist-osmanabad',
        districtName: 'Osmanabad',
        vectorViabilityIndex: 0.76,
        landSurfaceTempC: 32.8,
        vegetationIndexNdvi: 0.42,
        soilMoistureSaturationPct: 58.0,
        stagnantWaterIndex: 0.55,
        windSpeedKmH: 18.2,
        windBearingDeg: 85.0, // East wind
        primaryVector: 'Boophilus microplus (Ticks) & Midges',
        vectorBreedingRiskLevel: 'HIGH',
        environmentalNotes: 'Downwind of Solapur plume; elevated aerosol infection vulnerability.',
      ),
      'Kolhapur': const DistrictEcoClimateModel(
        districtId: 'dist-kolhapur',
        districtName: 'Kolhapur',
        vectorViabilityIndex: 0.88,
        landSurfaceTempC: 28.5,
        vegetationIndexNdvi: 0.72,
        soilMoistureSaturationPct: 78.5,
        stagnantWaterIndex: 0.82,
        windSpeedKmH: 14.0,
        windBearingDeg: 120.0,
        primaryVector: 'Culicoides midges & Stomoxys flies',
        vectorBreedingRiskLevel: 'HIGH',
        environmentalNotes: 'Panchaganga river basin saturation; extreme vector breeding habitat.',
      ),
      'Ahmednagar': const DistrictEcoClimateModel(
        districtId: 'dist-ahmednagar',
        districtName: 'Ahmednagar',
        vectorViabilityIndex: 0.62,
        landSurfaceTempC: 33.0,
        vegetationIndexNdvi: 0.38,
        soilMoistureSaturationPct: 48.0,
        stagnantWaterIndex: 0.40,
        windSpeedKmH: 16.5,
        windBearingDeg: 65.0,
        primaryVector: 'Haemaphysalis ticks (Brucellosis & Theileriosis)',
        vectorBreedingRiskLevel: 'MODERATE',
        environmentalNotes: 'Semiarid plateau; primary transmission via inter-district milk transit routes.',
      ),
      'Pune': const DistrictEcoClimateModel(
        districtId: 'dist-pune',
        districtName: 'Pune',
        vectorViabilityIndex: 0.54,
        landSurfaceTempC: 29.2,
        vegetationIndexNdvi: 0.58,
        soilMoistureSaturationPct: 54.0,
        stagnantWaterIndex: 0.45,
        windSpeedKmH: 12.8,
        windBearingDeg: 90.0,
        primaryVector: 'Ixodid ticks & Houseflies',
        vectorBreedingRiskLevel: 'MODERATE',
        environmentalNotes: 'Central command zone; high dairy cooperative density.',
      ),
      'Nashik': const DistrictEcoClimateModel(
        districtId: 'dist-nashik',
        districtName: 'Nashik',
        vectorViabilityIndex: 0.58,
        landSurfaceTempC: 30.1,
        vegetationIndexNdvi: 0.64,
        soilMoistureSaturationPct: 52.0,
        stagnantWaterIndex: 0.48,
        windSpeedKmH: 15.2,
        windBearingDeg: 110.0,
        primaryVector: 'Hyalomma ticks & biting flies',
        vectorBreedingRiskLevel: 'MODERATE',
        environmentalNotes: 'Godavari headwaters; regulated grazing corridors.',
      ),
      'Latur': const DistrictEcoClimateModel(
        districtId: 'dist-latur',
        districtName: 'Latur',
        vectorViabilityIndex: 0.70,
        landSurfaceTempC: 33.4,
        vegetationIndexNdvi: 0.44,
        soilMoistureSaturationPct: 50.0,
        stagnantWaterIndex: 0.52,
        windSpeedKmH: 19.0,
        windBearingDeg: 80.0,
        primaryVector: 'Culicoides midges & lice',
        vectorBreedingRiskLevel: 'HIGH',
        environmentalNotes: 'Adjacent to Osmanabad containment zone; high spillover probability.',
      ),
    };
  }

  static DistrictEcoClimateModel getProfileForDistrict(String districtName) {
    final profiles = defaultEcoProfiles();
    for (final entry in profiles.entries) {
      if (districtName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    // Generic fallback model
    return DistrictEcoClimateModel(
      districtId: 'dist-generic',
      districtName: districtName,
      vectorViabilityIndex: 0.55,
      landSurfaceTempC: 30.0,
      vegetationIndexNdvi: 0.50,
      soilMoistureSaturationPct: 50.0,
      stagnantWaterIndex: 0.45,
      windSpeedKmH: 15.0,
      windBearingDeg: 90.0,
      primaryVector: 'Haematophagous midges & ticks',
      vectorBreedingRiskLevel: 'MODERATE',
      environmentalNotes: 'Standard agro-climatic profile across Maharashtra inland plains.',
    );
  }
}
