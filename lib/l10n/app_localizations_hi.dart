// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'बायोहर्ड';

  @override
  String get tagline => 'स्वस्थ पशु. समृद्ध किसान.';

  @override
  String get namaste => 'नमस्ते';

  @override
  String welcomeMessage(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get farmSummary => 'डेयरी सारांश';

  @override
  String get myAnimals => 'मेरे पशु';

  @override
  String get scanQr => 'क्यूआर स्कैन करें';

  @override
  String get reportSymptom => 'लक्षण दर्ज करें';

  @override
  String get vaccinations => 'टीकाकरण';

  @override
  String get upcomingVaccinations => 'आगामी टीकाकरण';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get activeAlerts => 'सक्रिय अलर्ट';

  @override
  String get noActiveAlerts =>
      'आपके क्षेत्र में कोई सक्रिय बीमारी अलर्ट नहीं है।';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get severityLow => 'कम';

  @override
  String get severityMedium => 'मध्यम';

  @override
  String get severityHigh => 'गंभीर';

  @override
  String get severityCritical => 'अति गंभीर';

  @override
  String get offlineBanner =>
      'आप ऑफ़लाइन हैं। कनेक्शन मिलने पर डेटा सिंक हो जाएगा।';

  @override
  String syncingBanner(int count) {
    return 'सिंक हो रहा है... $count आइटम बाकी';
  }

  @override
  String get aiAssisted => 'एआई-सहायक निदान';

  @override
  String confidenceScore(int percent) {
    return 'सटीकता: $percent%';
  }

  @override
  String get whatToDoNext => 'आगे क्या करें';

  @override
  String get submit => 'जमा करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get emptyStateNoAnimals =>
      'अभी तक कोई पशु पंजीकृत नहीं है। स्वास्थ्य ट्रैक करने के लिए अपना पहला पशु जोड़ें।';

  @override
  String get errorStateGeneral =>
      'कुछ गलत हो गया। कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'English';

  @override
  String get marathi => 'मराठी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get login => 'लॉगिन';

  @override
  String get register => 'पंजीकरण करें';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get password => 'पासवर्ड';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get role => 'भूमिका';

  @override
  String get district => 'ज़िला';

  @override
  String get farmer => 'किसान';

  @override
  String get veterinarian => 'पशुचिकित्सक';

  @override
  String get dairyCooperative => 'डेयरी सहकारी';

  @override
  String get dvoOfficer => 'डीवीओ अधिकारी';

  @override
  String get twoFactorAuth => 'दो-चरणीय प्रमाणीकरण';

  @override
  String get enterOtp => '६ अंकों का प्रमाणक कोड दर्ज करें';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get dontHaveAccount => 'खाता नहीं है? पंजीकरण करें';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? लॉगिन करें';

  @override
  String get invalidPhone => 'कृपया वैध १० अंकों का फ़ोन नंबर दर्ज करें';

  @override
  String get passwordRequired => 'पासवर्ड कम से कम ८ अक्षरों का होना चाहिए';
}
