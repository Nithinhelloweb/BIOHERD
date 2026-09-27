import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/crisis_dispatch_model.dart';

class CrisisDispatchCopilotDialog extends StatefulWidget {
  final String activeDistrict;
  final Function(String action, String details)? onActionExecuted;

  const CrisisDispatchCopilotDialog({
    super.key,
    this.activeDistrict = 'Solapur',
    this.onActionExecuted,
  });

  static Future<void> show(
    BuildContext context, {
    String activeDistrict = 'Solapur',
    Function(String action, String details)? onActionExecuted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CrisisDispatchCopilotDialog(
        activeDistrict: activeDistrict,
        onActionExecuted: onActionExecuted,
      ),
    );
  }

  @override
  State<CrisisDispatchCopilotDialog> createState() => _CrisisDispatchCopilotDialogState();
}

class _CrisisDispatchCopilotDialogState extends State<CrisisDispatchCopilotDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AiSitRepBriefing _sitRep;
  late List<RapidResponseTeam> _teams;
  late FarmerBroadcastCampaign _broadcastCampaign;

  final TextEditingController _queryController = TextEditingController();
  String? _lastAiAnswer;
  bool _isAiThinking = false;
  int _selectedScriptLangIndex = 0; // 0: Marathi, 1: Hindi, 2: English

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sitRep = AiSitRepBriefing.getLiveSitRep();
    _teams = RapidResponseTeam.getPreseededTeams();
    _broadcastCampaign = FarmerBroadcastCampaign.getDefaultCampaign(widget.activeDistrict);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _askAi(String question) {
    setState(() {
      _isAiThinking = true;
      _queryController.text = question;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          _lastAiAnswer = AiSitRepBriefing.answerQuery(question);
        });
      }
    });
  }

  void _reassignTeam(RapidResponseTeam team, RrtDeploymentStatus newStatus, String actionDesc) {
    setState(() {
      team.status = newStatus;
      if (newStatus == RrtDeploymentStatus.enRoute) {
        team.etaMinutes = 15;
      } else if (newStatus == RrtDeploymentStatus.onSiteContained || newStatus == RrtDeploymentStatus.vaccinating) {
        team.etaMinutes = 0;
      }
    });

    if (widget.onActionExecuted != null) {
      widget.onActionExecuted!('RRT_REASSIGN', actionDesc);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF3B82F6),
        content: Row(
          children: [
            const Icon(PhosphorIconsFill.truck, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(actionDesc, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _dispatchBroadcast() {
    setState(() {
      _broadcastCampaign.isDispatched = true;
    });

    if (widget.onActionExecuted != null) {
      widget.onActionExecuted!(
        'FARMER_BROADCAST',
        'Initiated emergency outbound voice IVR & SMS to ${_broadcastCampaign.recipientCount} farmers in ${widget.activeDistrict}',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(PhosphorIconsFill.broadcast, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'BROADCAST LIVE: ${_broadcastCampaign.recipientCount} automated IVR calls queued across ${widget.activeDistrict}.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final dialogWidth = math.min(size.width * 0.95, 860.0);
    final dialogHeight = math.min(size.height * 0.94, 820.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Emergency Banner & Header
            _buildHeader(isDark),

            // Tab Navigation Bar
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFEF4444),
                indicatorWeight: 3,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(PhosphorIconsFill.robot, size: 16), text: 'AI SitRep Co-Pilot'),
                  Tab(icon: Icon(PhosphorIconsFill.truck, size: 16), text: 'RRT Mobilization Matrix'),
                  Tab(icon: Icon(PhosphorIconsFill.broadcast, size: 16), text: 'Farmer Broadcast Studio'),
                ],
              ),
            ),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSitRepTab(isDark),
                  _buildRrtMatrixTab(isDark),
                  _buildBroadcastTab(isDark),
                ],
              ),
            ),

            // Footer Actions
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
            ),
            child: const Icon(PhosphorIconsFill.siren, color: Color(0xFFEF4444), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'C4I CRISIS DISPATCH & AI SITREP CO-PILOT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LEVEL 4 EMERGENCY',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Epicenters: Solapur, Latur • State Command Link Active • ${_sitRep.generatedTimestamp}',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: AI SITREP CO-PILOT ---
  Widget _buildSitRepTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Summary Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(PhosphorIconsFill.shieldWarning, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'OPERATIONAL SITREP BRIEFING (EXECUTIVE COMMAND)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _sitRep.executiveSummary,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive AI Co-Pilot Query Terminal
          const Text(
            'ASK STRATEGIC SITREP CO-PILOT',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPresetChip('What is the vaccine deficit in Solapur & Latur?'),
              _buildPresetChip('Draft an APMC Mandi closure order under Act 2009'),
              _buildPresetChip('Analyze interstate contagion risk from Karnataka'),
              _buildPresetChip('Generate morning briefing for District Collector'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    hintText: 'Type strategic inquiry for AI Co-Pilot...',
                    hintStyle: const TextStyle(fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: _askAi,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _askAi(_queryController.text),
                icon: const Icon(PhosphorIconsFill.paperPlaneRight, size: 16),
                label: const Text('Ask AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          if (_isAiThinking) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ],

          if (_lastAiAnswer != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(PhosphorIconsFill.sparkle, color: Colors.blueAccent, size: 16),
                      SizedBox(width: 6),
                      Text('CO-PILOT INTEL ADVISORY',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_lastAiAnswer!, style: const TextStyle(fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Operational Crisis Action Checklist
          const Text(
            'STATUTORY OPERATIONAL DIRECTIVE CHECKLIST',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          ..._sitRep.operationalChecklist.entries.map((entry) {
            final isChecked = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: CheckboxListTile(
                dense: true,
                value: isChecked,
                activeColor: const Color(0xFF10B981),
                title: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onChanged: (val) {
                  setState(() {
                    _sitRep.operationalChecklist[entry.key] = val ?? false;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 14),

          // Statutory Proclamation Notice Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('OFFICIAL GAZETTE PROCLAMATION (ACT 2009)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _sitRep.statutoryProclamation));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proclamation copied to clipboard.')),
                        );
                      },
                      icon: const Icon(PhosphorIconsRegular.copy, size: 14),
                      label: const Text('Copy Proclamation', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                Text(
                  _sitRep.statutoryProclamation,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 10.5)),
      onPressed: () => _askAi(text),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  // --- TAB 2: RRT MOBILIZATION MATRIX ---
  Widget _buildRrtMatrixTab(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, idx) {
        final team = _teams[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: team.statusColor.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsFill.shieldStar, color: team.statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: team.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: team.statusColor),
                    ),
                    child: Text(
                      team.statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: team.statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Lead: ${team.leadOfficer} (${team.contactNumber}) • Base: ${team.baseDepot}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              Text(
                'Vehicle: ${team.vehicleId} • Cold-Box: ${team.coldBoxTempC}°C',
                style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAssetCounter('LSD Doses', '${team.lsdDosesAvailable}', const Color(0xFF10B981)),
                  _buildAssetCounter('FMD Doses', '${team.fmdDosesAvailable}', const Color(0xFF3B82F6)),
                  _buildAssetCounter('PCR Kits', '${team.pcrCartridges}', const Color(0xFFF59E0B)),
                  _buildAssetCounter('PPE Sets', '${team.ppeKits}', const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _reassignTeam(
                      team,
                      RrtDeploymentStatus.enRoute,
                      '${team.teamName} routed to Solapur South Cordon.',
                    ),
                    icon: const Icon(PhosphorIconsFill.navigationArrow, size: 14),
                    label: const Text('Deploy Reinforcement', style: TextStyle(fontSize: 11)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _reassignTeam(
                      team,
                      RrtDeploymentStatus.vaccinating,
                      '${team.teamName} activated 5km Ring Vaccination Strike.',
                    ),
                    icon: const Icon(PhosphorIconsFill.needle, size: 14),
                    label: const Text('Start Ring Strike', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetCounter(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // --- TAB 3: FARMER BROADCAST STUDIO ---
  Widget _buildBroadcastTab(bool isDark) {
    final scripts = [
      _broadcastCampaign.marathiScript,
      _broadcastCampaign.hindiScript,
      _broadcastCampaign.englishScript,
    ];
    final langNames = ['मराठी (Marathi)', 'हिंदी (Hindi)', 'English'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Audience Metric Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsFill.usersThree, color: Color(0xFF3B82F6), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_broadcastCampaign.recipientCount} REGISTERED LIVESTOCK KEEPERS IN BUFFER',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                      ),
                      Text(
                        'Target: ${widget.activeDistrict} • Radius: ${_broadcastCampaign.radiusKm}km • Success Rate: ${(_broadcastCampaign.successRate * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Active Channels Badges
          const Text('ENGAGED DISSEMINATION CHANNELS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(avatar: Icon(PhosphorIconsFill.phoneCall, size: 14), label: Text('Voice IVR Outbound (1800)')),
              Chip(avatar: Icon(PhosphorIconsFill.chatCircleDots, size: 14), label: Text('Cell Broadcast SMS')),
              Chip(avatar: Icon(PhosphorIconsFill.speakerSimpleHigh, size: 14), label: Text('Gram Panchayat Siren')),
            ],
          ),
          const SizedBox(height: 14),

          // Language Selector Tabs
          Row(
            children: List.generate(3, (idx) {
              final isSelected = _selectedScriptLangIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(langNames[idx]),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedScriptLangIndex = idx),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Broadcast Script Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AUTOMATED AUDIO / SMS TRANSCRIPT',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                    const Icon(PhosphorIconsFill.waveform, size: 16, color: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  scripts[_selectedScriptLangIndex],
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big Broadcast Launch Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _dispatchBroadcast,
              icon: const Icon(PhosphorIconsFill.broadcast, size: 18),
              label: Text('Initiate Autonomous Outbound Voice IVR (${_broadcastCampaign.recipientCount} Calls)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.shieldCheck, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 6),
              Text(
                'Crisis Dispatch Matrix Synchronized',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close Console'),
          ),
        ],
      ),
    );
  }
}
