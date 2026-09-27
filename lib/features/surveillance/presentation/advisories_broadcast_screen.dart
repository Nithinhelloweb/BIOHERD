import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/layout/bioherd_shell.dart';
import 'package:bioherd/core/rbac/permission.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';
import 'package:bioherd/core/widgets/severity_badge.dart';
import 'package:bioherd/features/auth/bloc/auth_bloc.dart';
import 'package:bioherd/features/auth/bloc/auth_state.dart';
import 'package:bioherd/features/auth/models/user_model.dart';

/// Multilingual Advisories & Mass Broadcast Center
/// Supports English, Marathi (मराठी), and Hindi (हिंदी).
/// Enables farmers to receive verified preventive advice and emergency alerts,
/// and allows Vets, DVOs, and State Officials to broadcast targeted mass warnings.
class AdvisoriesBroadcastScreen extends StatefulWidget {
  const AdvisoriesBroadcastScreen({super.key});

  @override
  State<AdvisoriesBroadcastScreen> createState() => _AdvisoriesBroadcastScreenState();
}

class _AdvisoriesBroadcastScreenState extends State<AdvisoriesBroadcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLanguage = 'mr'; // 'en', 'mr', 'hi' - default Marathi for Maharashtra AHD

  // In-memory list of advisories with multilingual content
  late List<Map<String, dynamic>> _advisories;

  // In-memory list of active emergency broadcasts with acknowledgment state
  late List<Map<String, dynamic>> _broadcasts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSeedData();
  }

  void _initializeSeedData() {
    _advisories = [
      {
        'id': 'adv-001',
        'category': 'Vector-Borne / Biosecurity',
        'disease': 'Lumpy Skin Disease (LSD)',
        'severity': 'high',
        'author': 'State Disease Surveillance Cell, Pune',
        'date': '24 Sep 2026',
        'en': {
          'title': 'Lumpy Skin Disease: Fly Control & Isolation Mandate',
          'description':
              'Vector insects spread LSD rapidly during post-monsoon weeks. Disinfect cattle sheds with 1% formalin or 2% sodium hypochlorite. Isolate animals with nodular skin lumps immediately.',
          'action_points': [
            'Isolate suspected cattle 10 meters away from healthy herd.',
            'Apply neem oil / fly repellents twice daily on healthy stock.',
            'Do not mix common grazing or water troughs.',
            'Report sudden nodular eruptions to local Para-Vet immediately.'
          ],
        },
        'mr': {
          'title': 'लम्पी त्वचा रोग: कीटक नियंत्रण व विलगीकरण नियमावली',
          'description':
              'पावसाळ्यानंतर डास, माशा व गोचीड यांच्यामुळे लम्पी रोगाचा प्रसार वेगाने होतो. गोठा १% फॉर्मेलिन किंवा २% सोडियम हायपोक्लोराईटने स्वच्छ करा. अंगावर गाठी आलेल्या गुरांना त्वरित वेगळे करा.',
          'action_points': [
            'संशयित जनावरांना निरोगी जनावरांपासून १० मीटर लांब बांधा.',
            'निरोगी गुरांना दिवसातून दोनदा कडुनिंब तेल किंवा डास प्रतिबंधक लावा.',
            'एकत्र चराई व एकाच हौदावर पाणी पाजणे त्वरित थांबवा.',
            'त्वचेवर गाठी आढळल्यास स्थानिक पशुवैद्यकीय दवाखान्याशी संपर्क साधा.'
          ],
        },
        'hi': {
          'title': 'लम्पी त्वचा रोग: कीट नियंत्रण व अलगाव दिशा-निर्देश',
          'description':
              'मानसून के बाद मक्खियों और कीड़ों से लम्पी रोग तेजी से फैलता है। मवेशी बाड़े को कीटाणुरहित करें और गांठ वाले पशुओं को तुरंत अलग करें।',
          'action_points': [
            'संदिग्ध पशुओं को स्वस्थ मवेशियों से अलग रखें।',
            'स्वस्थ पशुओं पर नीम का तेल या मक्खी विकर्षक लगाएं।',
            'संयुक्त चारागाह और साझा जल स्रोतों पर रोक लगाएं।',
            'लक्षण दिखने पर तुरंत नजदीकी पशु चिकित्सक को सूचित करें।'
          ],
        },
      },
      {
        'id': 'adv-002',
        'category': 'Zoonotic Emergency / Biohazard',
        'disease': 'Anthrax (Bacillus anthracis)',
        'severity': 'critical',
        'author': 'Commissioner of Animal Husbandry, MS',
        'date': '23 Sep 2026',
        'en': {
          'title': 'DO NOT OPEN CARCASS: Sudden Livestock Death Protocol',
          'description':
              'If an animal dies suddenly with dark, unclotted blood oozing from mouth, nostrils, or rectum, suspect Anthrax. NEVER perform a post-mortem or skin the carcass.',
          'action_points': [
            'Do not cut open or touch the carcass with bare hands.',
            'Dig a 6-foot deep pit away from water bodies and cover with quicklime.',
            'Vaccinate all herd members within 5km radius.',
            'Persons in contact must report to PHC for prophylactic antibiotics.'
          ],
        },
        'mr': {
          'title': 'मृत जनावराचे शवविच्छेदन करू नका: अचानक मृत्यू बाबत सतर्कता',
          'description':
              'तोंड, नाक किंवा गुदद्वारातून काळे न गोठणारे रक्त येऊन जनावर अचानक दगावल्यास अँथ्रॅक्सचा संशय घ्यावा. शव कधीही कापू नका किंवा कातडी काढू नका.',
          'action_points': [
            'मृत जनावराला उघडे पाडू नका आणि उघड्या हाताने स्पर्श करू नका.',
            'पाण्याच्या स्त्रोतापासून दूर ६ फूट खोल खड्डा खणून कळीच्या चुन्यात पुरावे.',
            '५ किमी परिसरातील सर्व गुरांचे तातडीने लसीकरण करा.',
            'संपर्कात आलेल्या व्यक्तींनी त्वरित प्राथमिक आरोग्य केंद्रात (PHC) संपर्क साधावा.'
          ],
        },
        'hi': {
          'title': 'मृत पशु का शव न चीरें: अचानक मृत्यु पर अनिवार्य प्रोटोकॉल',
          'description':
              'नाक, मुंह या गुदा से गहरा रक्तस्राव होकर अचानक मृत्यु होने पर एंथ्रेक्स की आशंका रहती है। शव को कभी भी न काटें।',
          'action_points': [
            'शव को न चीरें और बिना सुरक्षा उपकरणों के न छुएं।',
            'पानी के स्रोत से दूर 6 फीट गहरे गड्ढे में चूने के साथ दफनाएं।',
            '5 किमी के दायरे में रिंग टीकाकरण अनिवार्य रूप से कराएं।',
            'संपर्क में आए सभी लोग तुरंत स्वास्थ्य केंद्र में जांच कराएं।'
          ],
        },
      },
      {
        'id': 'adv-003',
        'category': 'Preventive Ring Vaccination',
        'disease': 'Foot and Mouth Disease (FMD)',
        'severity': 'high',
        'author': 'District Veterinary Office, Pune',
        'date': '20 Sep 2026',
        'en': {
          'title': 'FMD Ring Vaccination Phase II & Biosecurity Footbaths',
          'description':
              'Regular foot-bath with 4% sodium carbonate at shed entrances prevents FMD spread. Ensure bi-annual oil-adjuvant vaccination for all cattle and buffaloes above 4 months.',
          'action_points': [
            'Place 4% sodium carbonate / potassium permanganate footbaths at entrance.',
            'Wash mouth sores with 1% alum solution or boro-glycerine.',
            'Feed soft gruel or boiled mash to blistered cattle.',
            'Register for the free NADCP vaccination round at your village Gram Panchayat.'
          ],
        },
        'mr': {
          'title': 'लाळ्या खुरकूत (FMD) प्रतिबंधक लसीकरण व पादस्नान पद्धती',
          'description':
              'गोठ्याच्या दारात ४% खाण्याचा सोडा (सोडियम कार्बोनेट) किंवा पोटॅशियम परमँगनेटचे पादस्नान ठेवा. ४ महिन्यांवरील सर्व गाई-म्हशींना दर ६ महिन्यांनी लाळ्या खुरकूत लस टोचून घ्या.',
          'action_points': [
            'गोठ्याच्या प्रवेशद्वारावर जंतुनाशक पादस्नान (Footbath) तयार ठेवा.',
            'तोंडातील फोडांवर तुरटीचे पाणी किंवा बोरोग्लिसरीन लावा.',
            'आजारी जनावरांना मऊ पेज, तांदळाची लापशी किंवा उकडलेला चारा द्या.',
            'गावातील पशुवैद्यकीय दवाखान्यात जाऊन मोफत लसीकरणाची नोंद करा.'
          ],
        },
        'hi': {
          'title': 'खुरपका-मुंहपका (FMD) टीकाकरण व स्वच्छता उपाय',
          'description':
              'गोशाला के प्रवेश द्वार पर पोटेशियम परमैंगनेट का घोल रखें। 4 माह से अधिक आयु के सभी गोवंशीय पशुओं का वर्ष में दो बार नियमित टीकाकरण कराएं।',
          'action_points': [
            'प्रवेश द्वार पर कीटाणुनाशक फुटबाथ बनाएं।',
            'मुंह के छालों पर फिटकरी का पानी या बोरो-ग्लिसरीन लगाएं।',
            'बीमार पशु को नरम दलिया या पका हुआ चारा दें।',
            'नजदीकी केंद्र से संपर्क कर टीकाकरण पूर्ण कराएं।'
          ],
        },
      },
    ];

    _broadcasts = [
      {
        'id': 'bcast-101',
        'title': 'URGENT: Anthrax Alert in Haveli Taluka',
        'title_mr': 'अतितातडीचे: हवेली तालुक्यात अँथ्रॅक्स सतर्कता इशारा',
        'severity': 'critical',
        'scope': 'District: Pune | Taluka: Haveli (Villages: Wagholi, Theur, Lonikand)',
        'channels': 'SMS Blast (3,420 sent) • IVR Calls • WhatsApp',
        'timestamp': '25 Sep 2026, 14:30',
        'issuer': 'Dr. Kulkarni, District Veterinary Officer, Pune',
        'message':
            '2 sudden deaths confirmed in Wagholi. Strict ban on carcass opening and livestock movement in 10km radius. Ring vaccination drive initiated.',
        'message_mr':
            'वाघोली परिसरात २ जनावरांचा अचानक मृत्यू. १० किमी परिसरात शवविच्छेदन व जनावरांच्या वाहतुकीवर तात्काळ बंदी. रिंग लसीकरण मोहीम सुरू.',
        'acknowledged': false,
        'ack_count': 1840,
        'target_count': 3420,
      },
      {
        'id': 'bcast-102',
        'title': 'Lumpy Skin Disease Cluster Advisory',
        'title_mr': 'लम्पी त्वचा रोग समूह सतर्कता सूचना',
        'severity': 'high',
        'scope': 'District: Ahmednagar | Blocks: Rahata, Shrirampur',
        'channels': 'SMS Blast (5,100 sent) • Push Notification',
        'timestamp': '24 Sep 2026, 09:15',
        'issuer': 'State Surveillance Control Cell, AHD Maharashtra',
        'message':
            'Heightened vector activity detected due to recent rains. Goat Pox booster vaccination camps active in all local dairy collection centres.',
        'message_mr':
            'पावसामुळे गोचीड व माशांचा प्रादुर्भाव वाढला आहे. सर्व दूध संकलन केंद्रांवर गोट पॉक्स लसीकरण शिबिरे सुरू आहेत.',
        'acknowledged': true,
        'ack_count': 4210,
        'target_count': 5100,
      },
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _acknowledgeAlert(int index) {
    setState(() {
      _broadcasts[index]['acknowledged'] = true;
      _broadcasts[index]['ack_count'] = (_broadcasts[index]['ack_count'] as int) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Alert acknowledged. AHD Surveillance Cell notified.'),
          ],
        ),
        backgroundColor: AppColors.primary700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBroadcastDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateBroadcastDialog(
        user: user,
        onBroadcastCreated: (newBroadcast) {
          setState(() {
            _broadcasts.insert(0, newBroadcast);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    final canBroadcast = currentUser != null &&
        (currentUser.hasPermission(Permission.broadcastAlertBlock) ||
            currentUser.hasPermission(Permission.broadcastAlertDistrict) ||
            currentUser.hasPermission(Permission.broadcastAlertState) ||
            currentUser.role == UserRole.veterinarian ||
            currentUser.role == UserRole.dvoOfficer ||
            currentUser.role == UserRole.stateAdmin ||
            currentUser.role == UserRole.superAdmin);

    return Scaffold(
      appBar: AppBar(
        leading: const BioHerdHamburgerButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advisories & Alerts', style: AppTextStyles.h2(color: AppColors.neutral900)),
            Text(
              'Maharashtra AHD Surveillance & Decision Support',
              style: AppTextStyles.caption(color: AppColors.neutral500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Language Selector Dropdown
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                icon: const Icon(PhosphorIconsRegular.globe, size: 16, color: AppColors.primary700),
                style: AppTextStyles.caption(color: AppColors.neutral900)
                    .copyWith(fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'mr', child: Text('मराठी (MR)')),
                  DropdownMenuItem(value: 'en', child: Text('English (EN)')),
                  DropdownMenuItem(value: 'hi', child: Text('हिंदी (HI)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary700,
          unselectedLabelColor: AppColors.neutral500,
          indicatorColor: AppColors.primary600,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.subtitle(color: AppColors.primary700)
              .copyWith(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(PhosphorIconsRegular.shieldCheck, size: 18),
              text: _selectedLanguage == 'mr'
                  ? 'रोग प्रतिबंधक नियमावली'
                  : (_selectedLanguage == 'hi' ? 'रोग रोकथाम' : 'Advisories & First Aid'),
            ),
            Tab(
              icon: const Icon(PhosphorIconsRegular.broadcast, size: 18),
              text: _selectedLanguage == 'mr'
                  ? 'तातडीचे अलर्ट (${_broadcasts.length})'
                  : (_selectedLanguage == 'hi'
                      ? 'आपातकालीन अलर्ट (${_broadcasts.length})'
                      : 'Mass Alerts (${_broadcasts.length})'),
            ),
          ],
        ),
      ),
      floatingActionButton: canBroadcast
          ? FloatingActionButton.extended(
              onPressed: () => _openBroadcastDialog(currentUser),
              backgroundColor: AppColors.danger600,
              icon: const Icon(PhosphorIconsFill.broadcast, color: Colors.white, size: 20),
              label: const Text(
                'Broadcast Mass Alert',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdvisoriesList(),
          _buildBroadcastsList(),
        ],
      ),
    );
  }

  Widget _buildAdvisoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.space16),
      itemCount: _advisories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTollFreeHeader();
        }
        final adv = _advisories[index - 1];
        final content = adv[_selectedLanguage] ?? adv['en'];
        final severity = adv['severity'] == 'critical'
            ? SeverityLevel.critical
            : (adv['severity'] == 'high' ? SeverityLevel.high : SeverityLevel.medium);

        final isZoonotic = adv['severity'] == 'critical';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space16),
          child: BioHerdCard(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Severity row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isZoonotic ? AppColors.danger50 : AppColors.primary50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        adv['category'],
                        style: AppTextStyles.caption(
                          color: isZoonotic ? AppColors.danger700 : AppColors.primary700,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const Spacer(),
                    SeverityBadge(severity: severity),
                  ],
                ),
                AppSpacing.vSpace12,

                // Title
                Text(
                  content['title'],
                  style: AppTextStyles.h3(color: AppColors.neutral900).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),

                // Author & Date
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.buildingApartment, size: 14, color: AppColors.neutral500),
                    const SizedBox(width: 4),
                    Text(
                      '${adv['author']} • ${adv['date']}',
                      style: AppTextStyles.caption(color: AppColors.neutral500),
                    ),
                  ],
                ),
                AppSpacing.vSpace12,

                // Description
                Text(
                  content['description'],
                  style: AppTextStyles.body(color: AppColors.neutral700).copyWith(height: 1.4),
                ),
                AppSpacing.vSpace12,

                // Key Action Points Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLanguage == 'mr'
                            ? 'महत्त्वाच्या सूचना (Action Points):'
                            : (_selectedLanguage == 'hi' ? 'मुख्य निर्देश:' : 'Mandatory Action Points:'),
                        style: AppTextStyles.caption(color: AppColors.neutral800)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      for (final point in (content['action_points'] as List<dynamic>))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  point.toString(),
                                  style: AppTextStyles.caption(color: AppColors.neutral700),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                AppSpacing.vSpace12,

                // Audio advisory play button (Voice simulation)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _selectedLanguage == 'mr'
                                  ? 'मराठी ध्वनी संदेश चालू आहे: "${content['title']}"'
                                  : 'Playing audio advisory in $_selectedLanguage...',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary700,
                          ),
                        );
                      },
                      icon: const Icon(PhosphorIconsRegular.speakerHigh, size: 16),
                      label: Text(
                        _selectedLanguage == 'mr'
                            ? 'ध्वनी संदेश ऐका (Audio)'
                            : (_selectedLanguage == 'hi' ? 'ऑडियो सुनें' : 'Listen Voice Advisory'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary700,
                        side: const BorderSide(color: AppColors.primary600),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Share on WhatsApp',
                      icon: const Icon(PhosphorIconsRegular.shareNetwork, color: AppColors.neutral600),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Advisory link copied for WhatsApp sharing.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTollFreeHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space16),
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6E3C), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsFill.phoneCall, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kisan Toll-Free Animal Health Helpline',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                const Text(
                  '1800-246-4373 (1800-BIO-HERD) • 24/7 Marathi / Hindi',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.space16),
      itemCount: _broadcasts.length,
      itemBuilder: (context, index) {
        final bcast = _broadcasts[index];
        final isCritical = bcast['severity'] == 'critical';
        final isAcked = bcast['acknowledged'] as bool;
        final ackCount = bcast['ack_count'] as int;
        final targetCount = bcast['target_count'] as int;
        final ackPercentage = (ackCount / targetCount * 100).toStringAsFixed(1);

        final title = _selectedLanguage == 'mr' && bcast['title_mr'] != null
            ? bcast['title_mr']
            : bcast['title'];
        final message = _selectedLanguage == 'mr' && bcast['message_mr'] != null
            ? bcast['message_mr']
            : bcast['message'];

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical ? AppColors.danger500 : AppColors.warning400,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCritical ? AppColors.danger500 : AppColors.warning400).withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCritical ? AppColors.danger600 : AppColors.warning500,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical ? PhosphorIconsFill.warningOctagon : PhosphorIconsFill.warning,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCritical ? 'CRITICAL OUTBREAK BROADCAST' : 'HIGH PRIORITY ADVISORY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      bcast['timestamp'],
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3(color: AppColors.neutral900).copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 6),

                    // Target Geographic Scope
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin, size: 14, color: AppColors.neutral500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bcast['scope'],
                            style: AppTextStyles.caption(color: AppColors.neutral600)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Delivery Channels
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.paperPlaneTilt, size: 14, color: AppColors.neutral500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Channels: ${bcast['channels']}',
                            style: AppTextStyles.caption(color: AppColors.neutral500),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpace12,

                    // Message Body
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      decoration: BoxDecoration(
                        color: isCritical ? AppColors.danger50 : AppColors.warning50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        style: AppTextStyles.body(
                          color: isCritical ? AppColors.danger900 : AppColors.neutral900,
                        ).copyWith(height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                    AppSpacing.vSpace12,

                    // Acknowledgment Analytics Bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Farmer Acknowledgments: $ackCount / $targetCount',
                                    style: AppTextStyles.caption(color: AppColors.neutral600)
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '$ackPercentage%',
                                    style: AppTextStyles.caption(color: AppColors.primary700)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ackCount / targetCount,
                                  minHeight: 6,
                                  backgroundColor: AppColors.neutral200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpace16,

                    // Interactive Acknowledge Action
                    Row(
                      children: [
                        Expanded(
                          child: isAcked
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(PhosphorIconsFill.checkCircle,
                                          color: AppColors.primary700, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Acknowledged by You',
                                        style: TextStyle(
                                          color: AppColors.primary700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : BioHerdButton(
                                  label: 'Acknowledge Alert Receipt',
                                  icon: const Icon(PhosphorIconsFill.checkCircle,
                                      color: Colors.white, size: 18),
                                  onPressed: () => _acknowledgeAlert(index),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dialog for officials (Vet, DVO, State Official) to transmit emergency mass broadcast
class _CreateBroadcastDialog extends StatefulWidget {
  final UserModel user;
  final ValueChanged<Map<String, dynamic>> onBroadcastCreated;

  const _CreateBroadcastDialog({
    required this.user,
    required this.onBroadcastCreated,
  });

  @override
  State<_CreateBroadcastDialog> createState() => _CreateBroadcastDialogState();
}

class _CreateBroadcastDialogState extends State<_CreateBroadcastDialog> {
  final _titleController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _messageController = TextEditingController();
  final _messageMrController = TextEditingController();

  String _severity = 'critical';
  String _targetDistrict = 'Pune';
  String _targetTaluka = 'All Talukas';
  bool _sendSms = true;
  bool _sendIvr = true;
  bool _sendWhatsapp = true;
  bool _isBroadcasting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _titleMrController.dispose();
    _messageController.dispose();
    _messageMrController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out Title and Message content')),
      );
      return;
    }

    setState(() => _isBroadcasting = true);

    // Simulate multi-channel transmission to telecom gateway
    await Future.delayed(const Duration(milliseconds: 1200));

    final newBroadcast = {
      'id': 'bcast-${DateTime.now().millisecondsSinceEpoch}',
      'title': _titleController.text.trim(),
      'title_mr': _titleMrController.text.trim().isNotEmpty
          ? _titleMrController.text.trim()
          : _titleController.text.trim(),
      'severity': _severity,
      'scope': 'District: $_targetDistrict | Taluka: $_targetTaluka',
      'channels': [
        if (_sendSms) 'SMS Blast',
        if (_sendIvr) 'IVR Calls',
        if (_sendWhatsapp) 'WhatsApp',
      ].join(' • '),
      'timestamp': 'Just now',
      'issuer': '${widget.user.name} (${widget.user.role.name.toUpperCase()})',
      'message': _messageController.text.trim(),
      'message_mr': _messageMrController.text.trim().isNotEmpty
          ? _messageMrController.text.trim()
          : _messageController.text.trim(),
      'acknowledged': false,
      'ack_count': 1,
      'target_count': 2500,
    };

    if (mounted) {
      widget.onBroadcastCreated(newBroadcast);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency Mass Broadcast transmitted successfully across channels!'),
          backgroundColor: AppColors.primary700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.danger100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(PhosphorIconsFill.broadcast, color: AppColors.danger600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Broadcast Mass Alert', style: AppTextStyles.h3()),
                          Text('Emergency Geo-Targeted Notification', style: AppTextStyles.caption()),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Severity Level
                Text('Severity Level', style: AppTextStyles.subtitle().copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _severityChip('Critical / Zoonotic', 'critical', AppColors.danger600),
                    const SizedBox(width: 8),
                    _severityChip('High Outbreak', 'high', AppColors.warning600),
                    const SizedBox(width: 8),
                    _severityChip('Advisory', 'medium', AppColors.primary600),
                  ],
                ),
                AppSpacing.vSpace16,

                // Target District & Taluka
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _targetDistrict,
                        decoration: const InputDecoration(
                          labelText: 'Target District',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Pune', child: Text('Pune')),
                          DropdownMenuItem(value: 'Ahmednagar', child: Text('Ahmednagar')),
                          DropdownMenuItem(value: 'Solapur', child: Text('Solapur')),
                          DropdownMenuItem(value: 'Satara', child: Text('Satara')),
                          DropdownMenuItem(value: 'Kolhapur', child: Text('Kolhapur')),
                          DropdownMenuItem(value: 'All Maharashtra', child: Text('All Maharashtra (State-wide)')),
                        ],
                        onChanged: (val) => setState(() => _targetDistrict = val ?? 'Pune'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _targetTaluka,
                        decoration: const InputDecoration(
                          labelText: 'Target Taluka',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All Talukas', child: Text('All Talukas')),
                          DropdownMenuItem(value: 'Haveli', child: Text('Haveli')),
                          DropdownMenuItem(value: 'Shirur', child: Text('Shirur')),
                          DropdownMenuItem(value: 'Khed', child: Text('Khed')),
                          DropdownMenuItem(value: 'Baramati', child: Text('Baramati')),
                        ],
                        onChanged: (val) => setState(() => _targetTaluka = val ?? 'All Talukas'),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpace16,

                // Alert Title (English)
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Headline (English) *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Immediate Ring Vaccination Alert',
                  ),
                ),
                AppSpacing.vSpace12,

                // Alert Title (Marathi)
                TextFormField(
                  controller: _titleMrController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Headline (मराठी)',
                    border: OutlineInputBorder(),
                    hintText: 'उदा. तातडीचा रिंग लसीकरण इशारा',
                  ),
                ),
                AppSpacing.vSpace12,

                // Message (English)
                TextFormField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Broadcast Instructions (English) *',
                    border: OutlineInputBorder(),
                    hintText: 'Actionable veterinary advice for farmers...',
                  ),
                ),
                AppSpacing.vSpace12,

                // Message (Marathi)
                TextFormField(
                  controller: _messageMrController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Broadcast Instructions (मराठी)',
                    border: OutlineInputBorder(),
                    hintText: 'शेतकऱ्यांसाठी तातडीच्या उपाययोजना...',
                  ),
                ),
                AppSpacing.vSpace16,

                // Channels Checkboxes
                Text('Delivery Channels', style: AppTextStyles.caption().copyWith(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('SMS Blast (Telecom Gateway)', style: TextStyle(fontSize: 13)),
                  dense: true,
                  value: _sendSms,
                  onChanged: (v) => setState(() => _sendSms = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('IVR Toll-Free Voice Call Tree', style: TextStyle(fontSize: 13)),
                  dense: true,
                  value: _sendIvr,
                  onChanged: (v) => setState(() => _sendIvr = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('WhatsApp Helpline Broadcast', style: TextStyle(fontSize: 13)),
                  dense: true,
                  value: _sendWhatsapp,
                  onChanged: (v) => setState(() => _sendWhatsapp = v ?? true),
                ),
                AppSpacing.vSpace16,

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: BioHerdButton(
                    label: _isBroadcasting ? 'Broadcasting to 2,500+ Farmers...' : 'Transmit Mass Broadcast Now',
                    icon: _isBroadcasting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(PhosphorIconsFill.broadcast, color: Colors.white, size: 20),
                    onPressed: _isBroadcasting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _severityChip(String label, String value, Color color) {
    final selected = _severity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _severity = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: selected ? 2 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
