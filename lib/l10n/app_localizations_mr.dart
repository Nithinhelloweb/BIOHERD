// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'बायोहर्ड';

  @override
  String get tagline => 'निरोगी जनावरे. समृद्ध शेतकरी.';

  @override
  String get namaste => 'नमस्ते';

  @override
  String welcomeMessage(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get farmSummary => 'गोठा सारांश';

  @override
  String get myAnimals => 'माझी जनावरे';

  @override
  String get scanQr => 'क्यूआर स्कॅन करा';

  @override
  String get reportSymptom => 'लक्षणे नोंदवा';

  @override
  String get vaccinations => 'लसीकरण';

  @override
  String get upcomingVaccinations => 'आगामी लसीकरण';

  @override
  String get recentActivity => 'अलीकडील हालचाली';

  @override
  String get activeAlerts => 'सक्रिय सूचना';

  @override
  String get noActiveAlerts => 'आपल्या भागात कोणतीही सक्रिय रोग सूचना नाही.';

  @override
  String get viewAll => 'सर्व पहा';

  @override
  String get severityLow => 'कमी';

  @override
  String get severityMedium => 'मध्यम';

  @override
  String get severityHigh => 'गंभीर';

  @override
  String get severityCritical => 'अतिगंभीर';

  @override
  String get offlineBanner =>
      'आपण ऑफलाइन आहात. इंटरनेट सुरू झाल्यावर माहिती समक्रमित होईल.';

  @override
  String syncingBanner(int count) {
    return 'समक्रमित होत आहे... $count बाबी प्रलंबित';
  }

  @override
  String get aiAssisted => 'एआय-सहाय्यित निदान';

  @override
  String confidenceScore(int percent) {
    return 'अचूकता: $percent%';
  }

  @override
  String get whatToDoNext => 'पुढील उपाययोजना';

  @override
  String get submit => 'सादर करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get loading => 'लोड होत आहे...';

  @override
  String get emptyStateNoAnimals =>
      'अद्याप कोणतीही जनावरे नोंदणीकृत नाहीत. आरोग्य ट्रॅक करण्यासाठी आपले पहिले जनावर जोडा.';

  @override
  String get errorStateGeneral =>
      'काहीतरी चूक झाली. कृपया आपले कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

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
  String get register => 'नोंदणी करा';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get password => 'पासवर्ड';

  @override
  String get fullName => 'पूर्ण नाव';

  @override
  String get role => 'भूमिका';

  @override
  String get district => 'जिल्हा';

  @override
  String get farmer => 'शेतकरी';

  @override
  String get veterinarian => 'पशुवैद्यक';

  @override
  String get dairyCooperative => 'दुग्ध सहकारी संस्था';

  @override
  String get dvoOfficer => 'जिल्हा पशुसंवर्धन अधिकारी';

  @override
  String get twoFactorAuth => 'द्वि-घटक प्रमाणीकरण';

  @override
  String get enterOtp => '६ अंकी ऑथेंटिकेटर कोड प्रविष्ट करा';

  @override
  String get verify => 'पडताळणी करा';

  @override
  String get logout => 'बाहेर पडा';

  @override
  String get dontHaveAccount => 'खाते नाही? नोंदणी करा';

  @override
  String get alreadyHaveAccount => 'आधीच खाते आहे? लॉगिन करा';

  @override
  String get invalidPhone => 'कृपया वैध १० अंकी फोन नंबर टाका';

  @override
  String get passwordRequired => 'पासवर्ड किमान ८ अक्षरांचा असावा';
}
