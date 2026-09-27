import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/layout/bioherd_shell.dart';

class VaccinationDriveItem {
  final String id;
  final String title;
  final String targetDisease;
  final String vaccineName;
  final String district;
  final String block;
  final String village;
  final int targetCount;
  int completedCount;
  String status;
  final DateTime startDate;
  final DateTime endDate;

  VaccinationDriveItem({
    required this.id,
    required this.title,
    required this.targetDisease,
    required this.vaccineName,
    required this.district,
    required this.block,
    required this.village,
    required this.targetCount,
    required this.completedCount,
    this.status = 'in_progress',
    required this.startDate,
    required this.endDate,
  });

  double get coveragePct => (completedCount / (targetCount > 0 ? targetCount : 1)).clamp(0.0, 1.0);
}

class VaccinationDrivesScreen extends StatefulWidget {
  const VaccinationDrivesScreen({super.key});

  @override
  State<VaccinationDrivesScreen> createState() => _VaccinationDrivesScreenState();
}

class _VaccinationDrivesScreenState extends State<VaccinationDrivesScreen> {
  final List<VaccinationDriveItem> _drives = [
    VaccinationDriveItem(
      id: 'drv-001',
      title: 'Haveli Block FMD Ring Immunization Mission 2026',
      targetDisease: 'Foot and Mouth Disease (FMD)',
      vaccineName: 'Raksha-Ovac Polyvalent',
      district: 'Pune',
      block: 'Haveli',
      village: 'Wagholi & Khed',
      targetCount: 1200,
      completedCount: 940,
      status: 'in_progress',
      startDate: DateTime.now().subtract(const Duration(days: 8)),
      endDate: DateTime.now().add(const Duration(days: 22)),
    ),
    VaccinationDriveItem(
      id: 'drv-002',
      title: 'Monsoon Lumpy Skin Disease Vector Defense Drive',
      targetDisease: 'Lumpy Skin Disease (LSD)',
      vaccineName: 'Lumpi-ProVacInd Live Attenuated',
      district: 'Kolhapur',
      block: 'Karveer',
      village: 'Panchganga Basin',
      targetCount: 850,
      completedCount: 720,
      status: 'in_progress',
      startDate: DateTime.now().subtract(const Duration(days: 14)),
      endDate: DateTime.now().add(const Duration(days: 10)),
    ),
    VaccinationDriveItem(
      id: 'drv-003',
      title: 'National Small Ruminants PPR Eradication Campaign',
      targetDisease: 'PPR (Goat Plague)',
      vaccineName: 'Sungri 96 Live PPR Vaccine',
      district: 'Ahmednagar',
      block: 'Sangamner',
      village: 'Panchayat Cluster A',
      targetCount: 1500,
      completedCount: 1500,
      status: 'completed',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  void _showAddDosesDialog(VaccinationDriveItem item) {
    int addDoses = 50;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: Text('Record Doses: ${item.targetDisease}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current: ${item.completedCount} / ${item.targetCount}'),
              const SizedBox(height: 16),
              const Text('Add Administered Doses:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.minusCircle),
                    onPressed: addDoses > 10 ? () => setDState(() => addDoses -= 10) : null,
                  ),
                  Text('$addDoses doses', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.plusCircle),
                    onPressed: () => setDState(() => addDoses += 10),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  item.completedCount += addDoses;
                  if (item.completedCount >= item.targetCount) {
                    item.status = 'completed';
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $addDoses doses to ${item.title}')),
                );
              },
              child: const Text('Update Progress'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewDriveDialog() {
    final titleCtrl = TextEditingController(text: 'District Preventive Vaccination Drive 2026');
    String selectedDisease = 'Foot and Mouth Disease (FMD)';
    String selectedVaccine = 'Raksha-Ovac Polyvalent';
    final targetCtrl = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule New Vaccination Drive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Campaign Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Text('Target Disease', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedDisease,
                items: const [
                  DropdownMenuItem(value: 'Foot and Mouth Disease (FMD)', child: Text('FMD (लाळ्या खुरकूत)')),
                  DropdownMenuItem(value: 'Lumpy Skin Disease (LSD)', child: Text('LSD (लम्पी स्कीन)')),
                  DropdownMenuItem(value: 'Black Quarter (BQ)', child: Text('BQ (एकटांग्या)')),
                  DropdownMenuItem(value: 'Haemorrhagic Septicaemia (HS)', child: Text('HS (घटसर्प)')),
                  DropdownMenuItem(value: 'PPR (Goat Plague)', child: Text('PPR (शेळी प्लेग)')),
                ],
                onChanged: (v) => selectedDisease = v!,
              ),
              const SizedBox(height: 12),
              const Text('Target Population Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final target = int.tryParse(targetCtrl.text) ?? 500;
              setState(() {
                _drives.insert(
                  0,
                  VaccinationDriveItem(
                    id: 'drv-${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text,
                    targetDisease: selectedDisease,
                    vaccineName: selectedVaccine,
                    district: 'Pune',
                    block: 'Haveli',
                    village: 'Panchayat Area',
                    targetCount: target,
                    completedCount: 0,
                    status: 'in_progress',
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 30)),
                  ),
                );
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New Vaccination Drive scheduled successfully!')),
              );
            },
            child: const Text('Schedule Campaign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalTarget = _drives.fold<int>(0, (sum, d) => sum + d.targetCount);
    final totalCompleted = _drives.fold<int>(0, (sum, d) => sum + d.completedCount);
    final overallPct = totalTarget > 0 ? (totalCompleted / totalTarget * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F7F6),
      appBar: AppBar(
        leading: const BioHerdHamburgerButton(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vaccination Drives & Coverage', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('लसीकरण मोहीम व कव्हरेज अहवाल • Mission Indradhanush Pashu', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.plusCircle),
            onPressed: _showNewDriveDialog,
            tooltip: 'Schedule Drive',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Coverage Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1B5E20), const Color(0xFF0D3B13)]
                      : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statewide Immunization Coverage',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: Text('$overallPct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: totalTarget > 0 ? totalCompleted / totalTarget : 0,
                    backgroundColor: Colors.white24,
                    color: const Color(0xFF69F0AE),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Completed: $totalCompleted Doses', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Target: $totalTarget Animals', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Drives Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Vaccination Campaigns (${_drives.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0D2137),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(PhosphorIconsRegular.plus, size: 14),
                  label: const Text('Schedule', style: TextStyle(fontSize: 12)),
                  onPressed: _showNewDriveDialog,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Drives List
            ..._drives.map((d) => _buildDriveCard(d, isDark)),

            const SizedBox(height: 16),
            // Village / Block Coverage Table Header
            Text(
              'Block / Village Coverage Breakdown',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0D2137),
              ),
            ),
            const SizedBox(height: 10),
            _buildCoverageTable(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveCard(VaccinationDriveItem d, bool isDark) {
    final isDone = d.status == 'completed';
    final pctText = (d.coveragePct * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withValues(alpha: 0.15)
                      : const Color(0xFF0288D1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDone ? 'Completed' : 'Active ($pctText%)',
                  style: TextStyle(
                    color: isDone ? Colors.green : const Color(0xFF0288D1),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target Disease: ${d.targetDisease} • Vaccine: ${d.vaccineName}',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Scope: ${d.district} District • ${d.block} Block • ${d.village}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // Progress bar
          LinearProgressIndicator(
            value: d.coveragePct,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            color: isDone ? const Color(0xFF2E7D32) : const Color(0xFF0288D1),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${d.completedCount} / ${d.targetCount} doses completed',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              ),
              if (!isDone)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(PhosphorIconsRegular.plus, size: 14),
                  label: const Text('Add Doses', style: TextStyle(fontSize: 11)),
                  onPressed: () => _showAddDosesDialog(d),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageTable(bool isDark) {
    const data = [
      {'block': 'Haveli', 'village': 'Wagholi', 'target': '600', 'completed': '520', 'pct': '86.6%'},
      {'block': 'Haveli', 'village': 'Khed', 'target': '600', 'completed': '420', 'pct': '70.0%'},
      {'block': 'Karveer', 'village': 'Panchganga', 'target': '850', 'completed': '720', 'pct': '84.7%'},
      {'block': 'Sangamner', 'village': 'Panchayat A', 'target': '1500', 'completed': '1500', 'pct': '100.0%'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF1F8E9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Block / Village', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Coverage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          ...data.map((row) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('${row['block']} - ${row['village']}', style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 2, child: Text(row['target']!, style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 2, child: Text(row['completed']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text(row['pct']!, style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
