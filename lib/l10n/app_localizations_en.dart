// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BIOHERD';

  @override
  String get tagline => 'Healthy Animals. Prosperous Farmers.';

  @override
  String get namaste => 'Namaste';

  @override
  String welcomeMessage(String name) {
    return 'Namaste, $name';
  }

  @override
  String get farmSummary => 'Farm Summary';

  @override
  String get myAnimals => 'My Animals';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get reportSymptom => 'Report Symptom';

  @override
  String get vaccinations => 'Vaccinations';

  @override
  String get upcomingVaccinations => 'Upcoming Vaccinations';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get activeAlerts => 'Active Alerts';

  @override
  String get noActiveAlerts => 'No active disease alerts in your area.';

  @override
  String get viewAll => 'See all';

  @override
  String get severityLow => 'Low';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityHigh => 'High';

  @override
  String get severityCritical => 'Critical';

  @override
  String get offlineBanner => 'You\'re offline. Data will sync when connected.';

  @override
  String syncingBanner(int count) {
    return 'Syncing... $count items pending';
  }

  @override
  String get aiAssisted => 'AI-Assisted Diagnostic';

  @override
  String confidenceScore(int percent) {
    return 'Confidence: $percent%';
  }

  @override
  String get whatToDoNext => 'Recommended Next Steps';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get loading => 'Loading...';

  @override
  String get emptyStateNoAnimals =>
      'No animals registered yet. Add your first animal to track its health.';

  @override
  String get errorStateGeneral =>
      'Something went wrong. Please check your connection and try again.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get marathi => 'मराठी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get role => 'Role';

  @override
  String get district => 'District';

  @override
  String get farmer => 'Farmer';

  @override
  String get veterinarian => 'Veterinarian';

  @override
  String get dairyCooperative => 'Dairy Cooperative';

  @override
  String get dvoOfficer => 'DVO Officer';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get enterOtp => 'Enter 6-digit Authenticator Code';

  @override
  String get verify => 'Verify';

  @override
  String get logout => 'Logout';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get invalidPhone => 'Please enter a valid 10-digit phone number';

  @override
  String get passwordRequired => 'Password must be at least 8 characters';
}
