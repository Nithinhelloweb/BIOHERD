import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/layout/bioherd_shell.dart';
import 'package:bioherd/core/theme/app_colors.dart';
import 'package:bioherd/core/theme/app_spacing.dart';
import 'package:bioherd/core/theme/app_text_styles.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';
import 'package:bioherd/core/widgets/bioherd_card.dart';

/// Telecom, IVR, SMS & Offline Sync Management Screen
/// Covers SIH26128 Feature #1 (IVR reporting, SMS fallback) & Feature #9 (Offline-first data sync).
class TelecomOfflineScreen extends StatefulWidget {
  const TelecomOfflineScreen({super.key});

  @override
  State<TelecomOfflineScreen> createState() => _TelecomOfflineScreenState();
}

class _TelecomOfflineScreenState extends State<TelecomOfflineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // IVR State Machine
  bool _isCallActive = false;
  int _ivrStep = 0; // 0: Lang, 1: Service, 2: Symptoms, 3: Completed
  String _selectedIvrLanguage = 'Marathi';
  String _currentIvrPrompt = '';
  String _lastDtmfKey = '';
  String? _ivrTicketId;

  // SMS Simulator State
  final _smsController = TextEditingController(text: 'REPORT MH-12-8842 FEVER BLISTERS SALIVATION');
  final _smsHistory = <Map<String, String>>[];

  // Offline Sync State
  bool _isSimulatingOffline = false;
  bool _isSyncing = false;
  final List<Map<String, dynamic>> _pendingSyncItems = [
    {
      'id': 'OFF-8821',
      'type': 'Symptom Report',
      'animal_tag': 'MH-14-3091',
      'symptoms': 'High Fever, Skin Nodules',
      'timestamp': '10 mins ago',
      'status': 'Pending Sync',
    },
    {
      'id': 'OFF-8822',
      'type': 'Mortality Incident',
      'animal_tag': 'MH-14-2204',
      'symptoms': 'Sudden Death, Unclotted Blood',
      'timestamp': '25 mins ago',
      'status': 'Pending Sync',
    },
    {
      'id': 'OFF-8823',
      'type': 'Vaccination Dose Entry',
      'animal_tag': 'MH-12-7719',
      'symptoms': 'FMD Booster Round II',
      'timestamp': '1 hour ago',
      'status': 'Pending Sync',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _smsHistory.add({
      'sender': 'Gateway (56161)',
      'text':
          'Welcome to Maharashtra AHD Livestock SMS Helpline. Send REPORT <TAG> <SYMPTOMS> or DEATH <SPECIES> <COUNT> <VILLAGE> to register.',
      'time': 'System Ready',
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  // ─── IVR Logic ──────────────────────────────────────────────

  void _startIvrCall() {
    setState(() {
      _isCallActive = true;
      _ivrStep = 0;
      _lastDtmfKey = '';
      _ivrTicketId = null;
      _currentIvrPrompt =
          'नमस्कार! महाराष्ट्र पशुसंवर्धन विभाग रोगनिगरानी प्रणालीमध्ये आपले स्वागत आहे.\n\n'
          '• मराठीसाठी [१] दाबा\n'
          '• हिंदी के लिए [२] दबाएं\n'
          '• For English press [३]';
    });
  }

  void _endIvrCall() {
    setState(() {
      _isCallActive = false;
      _ivrStep = 0;
      _lastDtmfKey = '';
      _currentIvrPrompt = '';
    });
  }

  void _pressDtmf(String key) {
    if (!_isCallActive) return;

    setState(() {
      _lastDtmfKey = key;
    });

    if (_ivrStep == 0) {
      // Language selected
      if (key == '1') {
        _selectedIvrLanguage = 'Marathi';
      } else if (key == '2') {
        _selectedIvrLanguage = 'Hindi';
      } else {
        _selectedIvrLanguage = 'English';
      }

      setState(() {
        _ivrStep = 1;
        _currentIvrPrompt = _selectedIvrLanguage == 'Marathi'
            ? 'सेवा निवडा:\n'
                '• आजारी जनावराची लक्षणे नोंदवण्यासाठी [१] दाबा\n'
                '• जनावराचा अचानक मृत्यू नोंदवण्यासाठी [२] दाबा\n'
                '• चालू लसीकरण मोहिमेच्या माहितीसाठी [३] दाबा'
            : (_selectedIvrLanguage == 'Hindi'
                ? 'सेवा चुनें:\n'
                    '• बीमार पशु के लक्षण दर्ज करने के लिए [१] दबाएं\n'
                    '• अचानक मृत्यु दर्ज करने के लिए [२] दबाएं\n'
                    '• टीकाकरण शिविर की जानकारी के लिए [३] दबाएं'
                : 'Choose Service:\n'
                    '• Press [1] to report sick livestock\n'
                    '• Press [2] to report sudden livestock mortality\n'
                    '• Press [3] for active vaccination drive status');
      });
    } else if (_ivrStep == 1) {
      // Service chosen
      if (key == '1') {
        // Sick livestock
        setState(() {
          _ivrStep = 2;
          _currentIvrPrompt = _selectedIvrLanguage == 'Marathi'
              ? 'मुख्य लक्षण निवडा:\n'
                  '• लाळ गळणे, तोंडात व खुरांवर फोड: [१] दाबा (लाळ्या खुरकूत संशय)\n'
                  '• अंगावर गाठी व डोळ्यातून पाणी: [२] दाबा (लम्पी त्वचा संशय)\n'
                  '• उच्च ताप, धाप लागणे व मान सुजणे: [३] दाबा (घटसर्प संशय)'
              : 'Select primary symptom:\n'
                  '• Salivation and blisters: Press [1] (FMD suspect)\n'
                  '• Nodular skin lumps: Press [2] (LSD suspect)\n'
                  '• High fever and throat swelling: Press [3] (HS suspect)';
        });
      } else if (key == '2') {
        // Sudden death
        _completeIvrIncident('Sudden Death / Zoonotic Suspect (Anthrax Warning Issued)');
      } else {
        // Advisory
        _completeIvrIncident('Vaccination Drive Inquiry (SMS Sent with Schedule)');
      }
    } else if (_ivrStep == 2) {
      // Symptom chosen
      String diseaseSuspect = 'Foot and Mouth Disease (FMD)';
      if (key == '2') diseaseSuspect = 'Lumpy Skin Disease (LSD)';
      if (key == '3') diseaseSuspect = 'Haemorrhagic Septicaemia (HS)';
      _completeIvrIncident(diseaseSuspect);
    }
  }

  void _completeIvrIncident(String diagnosis) {
    final ticket = 'IVR-${1000 + DateTime.now().millisecond}';
    setState(() {
      _ivrStep = 3;
      _ivrTicketId = ticket;
      _currentIvrPrompt = _selectedIvrLanguage == 'Marathi'
          ? 'धन्यवाद! आपली तक्रार यशस्वीरित्या नोंदवली गेली आहे.\n\n'
              '• तिकीट क्रमांक: $ticket\n'
              '• प्राथमिक निष्कर्ष: $diagnosis\n'
              '• हवेली तालुका पशुवैद्यकीय अधिकाऱ्यांना (Field Vet) अलर्ट पाठवला गेला आहे.\n'
              '• कॉल समाप्त करण्यासाठी लाल बटण दाबा.'
          : 'Thank you! Your report has been registered via IVR Gateway.\n\n'
              '• Ticket No: $ticket\n'
              '• Preliminary Rule Classification: $diagnosis\n'
              '• Local Block Veterinary Officer has been alerted.\n'
              '• Press red button to end call.';
    });
  }

  // ─── SMS Logic ──────────────────────────────────────────────

  void _sendSms() {
    final text = _smsController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _smsHistory.insert(0, {
        'sender': 'Farmer (You)',
        'text': text,
        'time': timeStr,
      });
    });

    _smsController.clear();

    // Auto reply from gateway
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      String reply = '';
      final upper = text.toUpperCase();

      if (upper.startsWith('REPORT')) {
        reply =
            'AHD MAHA: Report registered. Animal: MH-12-8842. Symptoms triaged: FMD Suspect (High). Vet Dr. Deshmukh (Haveli) notified. Ticket: SMS-7741.';
      } else if (upper.startsWith('DEATH')) {
        reply =
            'CRITICAL: Death report noted. WARNING: Do NOT open carcass! Suspect Anthrax protocol active. Deep burial with quicklime mandated. Vet dispatched.';
      } else {
        reply =
            'AHD MAHA: Invalid format. Send REPORT <TAG_ID> <SYMPTOMS> or DEATH <SPECIES> <COUNT> <VILLAGE> to 56161.';
      }

      setState(() {
        _smsHistory.insert(0, {
          'sender': 'Gateway (56161)',
          'text': reply,
          'time': timeStr,
        });
      });
    });
  }

  // ─── Offline Sync Logic ──────────────────────────────────────

  void _syncNow() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      for (final item in _pendingSyncItems) {
        item['status'] = 'Synced';
      }
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All pending offline records synced with Central Surveillance Server!'),
        backgroundColor: AppColors.primary700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BioHerdHamburgerButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telecom & Offline Toolkit', style: AppTextStyles.h2(color: AppColors.neutral900)),
            Text(
              'Toll-Free IVR (1800) • SMS Fallback • Offline-First Sync',
              style: AppTextStyles.caption(color: AppColors.neutral500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary700,
          unselectedLabelColor: AppColors.neutral500,
          indicatorColor: AppColors.primary600,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.subtitle(color: AppColors.primary700)
              .copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(PhosphorIconsRegular.phoneCall, size: 18),
              text: 'IVR Voice Call (1800)',
            ),
            Tab(
              icon: Icon(PhosphorIconsRegular.chatCircleDots, size: 18),
              text: 'SMS Fallback (56161)',
            ),
            Tab(
              icon: Icon(PhosphorIconsRegular.cloudArrowUp, size: 18),
              text: 'Offline Data Sync',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIvrTab(),
          _buildSmsTab(),
          _buildOfflineSyncTab(),
        ],
      ),
    );
  }

  // ─── TAB 1: IVR ──────────────────────────────────────────────

  Widget _buildIvrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner for non-smartphone accessibility
          BioHerdCard(
            backgroundColor: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsFill.phoneCall, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farmer Toll-Free Helpline: 1800-246-4373',
                        style: TextStyle(
                          color: AppColors.primary800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Zero-cost reporting for basic feature phones. Interactive Voice Response (IVR) in Marathi, Hindi & English with DTMF numeric keypad input.',
                        style: AppTextStyles.caption(color: AppColors.primary700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // Call Screen Container
          Container(
            padding: const EdgeInsets.all(AppSpacing.space20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Call Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isCallActive ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCallActive ? 'CALL CONNECTED (Toll-Free 1800-BIO-HERD)' : 'IVR LINE READY (1800-246-4373)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Simulated Voice Wave & Audio Prompt Box
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCallActive ? PhosphorIconsFill.speakerHigh : PhosphorIconsRegular.phoneDisconnect,
                            color: _isCallActive ? Colors.greenAccent : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCallActive
                                ? 'Voice Audio Transcript (Playing...)'
                                : 'Press "Call 1800-BIO-HERD" to simulate voice flow',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                          const Spacer(),
                          if (_ivrTicketId != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$_ivrTicketId',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_lastDtmfKey.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DTMF: [ $_lastDtmfKey ]',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isCallActive
                            ? _currentIvrPrompt
                            : 'Interactive Voice Response engine automatically records cattle symptoms and routes biohazard flags to local veterinary officers.',
                        style: TextStyle(
                          color: _isCallActive ? Colors.white : Colors.white54,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Keypad Matrix
                Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 10),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 10),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 10),
                    _buildKeypadRow(['*', '0', '#']),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Call / End Call Button
                Center(
                  child: _isCallActive
                      ? FloatingActionButton(
                          backgroundColor: Colors.redAccent,
                          onPressed: _endIvrCall,
                          child: const Icon(PhosphorIconsFill.phoneDisconnect, color: Colors.white, size: 28),
                        )
                      : FloatingActionButton.extended(
                          backgroundColor: Colors.green,
                          onPressed: _startIvrCall,
                          icon: const Icon(PhosphorIconsFill.phoneCall, color: Colors.white),
                          label: const Text(
                            'Call Toll-Free 1800-BIO-HERD',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 58,
          height: 58,
          child: ElevatedButton(
            onPressed: () => _pressDtmf(key),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── TAB 2: SMS ──────────────────────────────────────────────

  Widget _buildSmsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Templates Header
          Text('SMS Command Formats (Short Code: 56161)', style: AppTextStyles.caption().copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _templateChip(
                  'Cattle Sick (FMD)',
                  'REPORT MH-12-8842 FEVER BLISTERS SALIVATION',
                ),
                const SizedBox(width: 8),
                _templateChip(
                  'Lumpy Skin (LSD)',
                  'REPORT MH-14-3091 NODULES SKIN LUMPS FEVER',
                ),
                const SizedBox(width: 8),
                _templateChip(
                  'Sudden Death',
                  'DEATH COW 2 WAGHOLI UNCLOTTED_BLOOD',
                ),
                const SizedBox(width: 8),
                _templateChip(
                  'Drive Status',
                  'STATUS HAVELI VACCINATION',
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // SMS Feed
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space12),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: ListView.builder(
                itemCount: _smsHistory.length,
                itemBuilder: (context, index) {
                  final msg = _smsHistory[index];
                  final isFarmer = msg['sender']!.contains('Farmer');

                  return Align(
                    alignment: isFarmer ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isFarmer ? AppColors.primary600 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg['sender']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isFarmer ? Colors.white70 : AppColors.primary700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                msg['time']!,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isFarmer ? Colors.white54 : AppColors.neutral400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['text']!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isFarmer ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          AppSpacing.vSpace12,

          // Input Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _smsController,
                  decoration: InputDecoration(
                    hintText: 'Type SMS command to 56161...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(PhosphorIconsFill.paperPlaneRight, size: 20),
                onPressed: _sendSms,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateChip(String label, String command) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        setState(() => _smsController.text = command);
      },
    );
  }

  // ─── TAB 3: OFFLINE SYNC ─────────────────────────────────────

  Widget _buildOfflineSyncTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connectivity Simulation Toggle
          BioHerdCard(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSimulatingOffline ? AppColors.danger50 : AppColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSimulatingOffline ? PhosphorIconsFill.wifiSlash : PhosphorIconsFill.wifiHigh,
                    color: _isSimulatingOffline ? AppColors.danger600 : AppColors.primary600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSimulatingOffline ? 'Network: Offline (Low Rural Connectivity)' : 'Network: Online (4G / Wi-Fi Active)',
                        style: AppTextStyles.subtitle().copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isSimulatingOffline
                            ? 'All actions are securely buffered into local SQLite & Hive storage.'
                            : 'Automatic background sync is active with Central AHD servers.',
                        style: AppTextStyles.caption(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !_isSimulatingOffline,
                  activeColor: AppColors.primary600,
                  onChanged: (val) {
                    setState(() => _isSimulatingOffline = !val);
                  },
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // Sync Queue Stats
          Row(
            children: [
              Expanded(
                child: BioHerdCard(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local Queue', style: AppTextStyles.caption()),
                      const SizedBox(height: 4),
                      Text('${_pendingSyncItems.where((i) => i['status'] != 'Synced').length} pending',
                          style: AppTextStyles.h3(color: AppColors.warning600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BioHerdCard(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Sync', style: AppTextStyles.caption()),
                      const SizedBox(height: 4),
                      Text('Just now', style: AppTextStyles.h3(color: AppColors.primary700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpace16,

          // Pending Items List
          Text('Local Offline Storage Queue', style: AppTextStyles.h3().copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          for (final item in _pendingSyncItems)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                children: [
                  Icon(
                    item['status'] == 'Synced'
                        ? PhosphorIconsFill.checkCircle
                        : PhosphorIconsRegular.clockCountdown,
                    color: item['status'] == 'Synced' ? AppColors.primary600 : AppColors.warning600,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${item['type']} (${item['id']})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(item['timestamp'], style: AppTextStyles.caption(color: AppColors.neutral400)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tag: ${item['animal_tag']} • ${item['symptoms']}',
                          style: AppTextStyles.caption(color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item['status'] == 'Synced' ? AppColors.primary50 : AppColors.warning50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item['status'] == 'Synced' ? AppColors.primary700 : AppColors.warning700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AppSpacing.vSpace16,

          // Sync Action Button
          SizedBox(
            width: double.infinity,
            child: BioHerdButton(
              label: _isSyncing ? 'Synchronizing with AHD Servers...' : 'Sync Pending Data Now',
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(PhosphorIconsRegular.arrowsClockwise, color: Colors.white, size: 20),
              onPressed: _isSyncing ? null : _syncNow,
            ),
          ),
        ],
      ),
    );
  }
}
