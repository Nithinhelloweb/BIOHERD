import 'package:bioherd/features/auth/models/user_model.dart';

/// Fine-grained permission enum for all BIOHERD actions.
/// Enforced at widget-level (RbacGuard), screen-level, and repository-level.
enum Permission {
  // 1. Reporting & Data Capture
  submitSymptomReport,
  submitMortalityReport,
  viewAreaReports,
  viewAllSymptomReports,
  verifyReports,
  overrideReports,
  attachPhotoGps,
  viewPhotoGps,
  offlineSync,
  configureOfflineSync,
  ivrReporting,
  configureIvr,

  // 2. AI / Rule-Based Triage & Early Warning
  viewAiTriage,
  overrideAiTriage,
  receiveOutbreakAlert,
  flagOutbreakAlert,
  createOutbreakAlert,
  manageOutbreakAlert,
  receiveZoonoticFlag,
  createZoonoticFlag,
  manageZoonoticFlag,

  // 3. Geospatial Risk Mapping
  viewSurveillanceMap,
  viewHeatmapBlock,
  viewHeatmapDistrict,
  viewHeatmapState,
  viewHistoricalOverlay,
  exportHistoricalOverlay,
  viewWeatherIntegration,

  // 4. Animal & Herd Health Records
  registerAnimal,
  viewOwnAnimalsOnly,
  viewAllAnimals,
  manageAreaAnimals,
  editAnimalRecord,
  verifyAnimalRecord,
  auditAnimals,
  viewVaccinationHistory,
  recordVaccination,
  verifyVaccination,
  auditVaccination,
  viewTreatmentHistory,
  recordTreatment,
  prescribeTreatment,
  auditTreatment,

  // 5. Vaccination & Treatment Management
  viewVaccinationDrives,
  createLocalDrive,
  manageDrives,
  approveDrives,
  viewDrugInventory,
  manageDrugInventory,
  auditInventory,

  // 6. Laboratory & Sample Management
  initiateSampleRequest,
  createTrackSample,
  enterLabResult,
  uploadLabReport,
  referLabSample,

  // Case Lifecycle
  viewCaseQueue,
  acceptCase,
  flagCaseForVet,
  escalateCase,
  manageCaseEscalation,
  initiateTelemedicine,

  // 7. Alerts & Advisories
  receiveMultilingualAlerts,
  broadcastAlertBlock,
  broadcastAlertDistrict,
  broadcastAlertState,
  contributeAdvisory,
  publishAdvisory,

  // 8. Dashboards & Analytics
  viewSurveillanceDashboard,
  viewLabDashboard,
  viewDistrictDashboard,
  viewStateDashboard,
  viewAllDistricts,
  declareOutbreak,
  declareQuarantine,
  exportReports,
  viewDiagnosisResults,

  // 9. Administration
  manageUsers,
  viewAuditLog,
  viewSystemHealth,
  configureAlerts,
  configureSystem,
  seedMockData,
}

/// Maps each [UserRole] to the complete set of [Permission]s they hold.
final Map<UserRole, Set<Permission>> _rolePermissions = {
  // ── Farmer ────────────────────────────────────────────────────────
  UserRole.farmer: {
    Permission.submitSymptomReport,
    Permission.submitMortalityReport,
    Permission.attachPhotoGps,
    Permission.offlineSync,
    Permission.ivrReporting,
    Permission.viewAiTriage,
    Permission.receiveOutbreakAlert,
    Permission.receiveZoonoticFlag,
    Permission.registerAnimal,
    Permission.viewOwnAnimalsOnly,
    Permission.editAnimalRecord,
    Permission.viewVaccinationHistory,
    Permission.viewTreatmentHistory,
    Permission.initiateSampleRequest,
    Permission.receiveMultilingualAlerts,
    Permission.viewDiagnosisResults,
    Permission.initiateTelemedicine,
    Permission.viewSurveillanceMap, // read-only alerts
  },

  // ── Para-Vet (Field Worker) ───────────────────────────────────────
  UserRole.paravet: {
    Permission.submitSymptomReport,
    Permission.submitMortalityReport,
    Permission.viewAreaReports,
    Permission.attachPhotoGps,
    Permission.offlineSync,
    Permission.ivrReporting,
    Permission.viewAiTriage,
    Permission.receiveOutbreakAlert,
    Permission.flagOutbreakAlert,
    Permission.receiveZoonoticFlag,
    Permission.viewHeatmapBlock,
    Permission.viewSurveillanceMap,
    Permission.registerAnimal,
    Permission.manageAreaAnimals,
    Permission.editAnimalRecord,
    Permission.viewVaccinationHistory,
    Permission.recordVaccination,
    Permission.viewTreatmentHistory,
    Permission.recordTreatment,
    Permission.viewVaccinationDrives,
    Permission.viewDrugInventory,
    Permission.initiateSampleRequest,
    Permission.flagCaseForVet,
    Permission.receiveMultilingualAlerts,
    Permission.viewDiagnosisResults,
    Permission.viewSurveillanceDashboard,
  },

  // ── Field Veterinarian ───────────────────────────────────────────
  UserRole.veterinarian: {
    Permission.submitSymptomReport,
    Permission.submitMortalityReport,
    Permission.viewAreaReports,
    Permission.verifyReports,
    Permission.attachPhotoGps,
    Permission.offlineSync,
    Permission.viewAiTriage,
    Permission.overrideAiTriage,
    Permission.receiveOutbreakAlert,
    Permission.createOutbreakAlert,
    Permission.createZoonoticFlag,
    Permission.viewHeatmapBlock,
    Permission.viewHistoricalOverlay,
    Permission.viewWeatherIntegration,
    Permission.viewSurveillanceMap,
    Permission.registerAnimal,
    Permission.editAnimalRecord,
    Permission.verifyAnimalRecord,
    Permission.viewAllAnimals,
    Permission.viewVaccinationHistory,
    Permission.recordVaccination,
    Permission.verifyVaccination,
    Permission.viewTreatmentHistory,
    Permission.prescribeTreatment,
    Permission.createLocalDrive,
    Permission.viewVaccinationDrives,
    Permission.viewDrugInventory,
    Permission.manageDrugInventory,
    Permission.createTrackSample,
    Permission.viewCaseQueue,
    Permission.acceptCase,
    Permission.escalateCase,
    Permission.initiateTelemedicine,
    Permission.receiveMultilingualAlerts,
    Permission.broadcastAlertBlock,
    Permission.viewDiagnosisResults,
    Permission.viewAllSymptomReports,
    Permission.viewSurveillanceDashboard,
    Permission.exportReports,
  },

  // ── Lab Technician ───────────────────────────────────────────────
  UserRole.labTechnician: {
    Permission.viewAreaReports,
    Permission.receiveOutbreakAlert,
    Permission.createTrackSample,
    Permission.enterLabResult,
    Permission.uploadLabReport,
    Permission.referLabSample,
    Permission.flagCaseForVet,
    Permission.receiveMultilingualAlerts,
    Permission.viewLabDashboard,
    Permission.exportReports,
  },

  // ── Dairy Cooperative ────────────────────────────────────────────
  UserRole.dairyCoop: {
    Permission.viewOwnAnimalsOnly,
    Permission.viewAllAnimals,
    Permission.viewDiagnosisResults,
    Permission.viewSurveillanceMap,
    Permission.viewDrugInventory,
  },

  // ── District Vet Officer (DVO) ───────────────────────────────────
  UserRole.dvoOfficer: {
    Permission.viewAreaReports,
    Permission.overrideReports,
    Permission.viewPhotoGps,
    Permission.viewAiTriage,
    Permission.overrideAiTriage,
    Permission.receiveOutbreakAlert,
    Permission.createOutbreakAlert,
    Permission.manageOutbreakAlert,
    Permission.manageZoonoticFlag,
    Permission.viewHeatmapDistrict,
    Permission.viewHistoricalOverlay,
    Permission.viewWeatherIntegration,
    Permission.viewSurveillanceMap,
    Permission.viewAllDistricts,
    Permission.auditAnimals,
    Permission.viewAllAnimals,
    Permission.auditVaccination,
    Permission.auditTreatment,
    Permission.manageDrives,
    Permission.viewVaccinationDrives,
    Permission.auditInventory,
    Permission.viewDrugInventory,
    Permission.manageDrugInventory,
    Permission.createTrackSample,
    Permission.manageCaseEscalation,
    Permission.viewCaseQueue,
    Permission.declareOutbreak,
    Permission.declareQuarantine,
    Permission.receiveMultilingualAlerts,
    Permission.broadcastAlertDistrict,
    Permission.contributeAdvisory,
    Permission.viewDistrictDashboard,
    Permission.viewSurveillanceDashboard,
    Permission.exportReports,
    Permission.manageUsers,
    Permission.viewAuditLog,
    Permission.configureAlerts,
    Permission.viewDiagnosisResults,
    Permission.viewAllSymptomReports,
  },

  // ── State Official / Admin ───────────────────────────────────────
  UserRole.stateAdmin: {
    // State official holds full clinical, policy, quarantine, and administrative authority
    ...Permission.values.toSet(),
  },

  // ── Super Admin ──────────────────────────────────────────────────
  UserRole.superAdmin: {
    ...Permission.values.toSet(),
  },
};

/// Service for checking RBAC permissions.
class RbacService {
  const RbacService._();

  /// Returns true if [role] holds the given [permission].
  static bool hasPermission(UserRole role, Permission permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Returns true if [role] holds ALL of the given [permissions].
  static bool hasAllPermissions(UserRole role, List<Permission> permissions) {
    return permissions.every((p) => hasPermission(role, p));
  }

  /// Returns true if [role] holds ANY of the given [permissions].
  static bool hasAnyPermission(UserRole role, List<Permission> permissions) {
    return permissions.any((p) => hasPermission(role, p));
  }

  /// Returns the display label for a role.
  static String roleLabel(UserRole role) => role.displayName;

  /// Returns a short tag for compact display.
  static String roleTag(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return 'FARMER';
      case UserRole.paravet:
        return 'PARAVET';
      case UserRole.veterinarian:
        return 'VET';
      case UserRole.labTechnician:
        return 'LAB';
      case UserRole.dairyCoop:
        return 'DAIRY';
      case UserRole.dvoOfficer:
        return 'DVO';
      case UserRole.stateAdmin:
        return 'STATE';
      case UserRole.superAdmin:
        return 'ADMIN';
    }
  }
}

/// Extension on [UserModel] to allow convenient permission checks.
extension UserModelPermissionExtension on UserModel {
  bool hasPermission(Permission permission) {
    return RbacService.hasPermission(role, permission);
  }

  bool hasAnyPermission(List<Permission> permissions) {
    return RbacService.hasAnyPermission(role, permissions);
  }
}
