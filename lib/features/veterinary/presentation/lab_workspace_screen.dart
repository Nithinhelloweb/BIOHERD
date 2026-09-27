import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/layout/bioherd_shell.dart';

class LabSampleItem {
  final String id;
  final String sampleCode;
  final String animalTag;
  final String species;
  final String sampleType;
  final String suspectedDisease;
  String transitStatus;
  String testResult;
  String? testMethod;
  String? pathogenConfirmed;
  bool isZoonotic;
  String? referredTo;
  DateTime collectionDate;

  LabSampleItem({
    required this.id,
    required this.sampleCode,
    required this.animalTag,
    required this.species,
    required this.sampleType,
    required this.suspectedDisease,
    required this.transitStatus,
    this.testResult = 'pending',
    this.testMethod,
    this.pathogenConfirmed,
    this.isZoonotic = false,
    this.referredTo,
    required this.collectionDate,
  });
}

class LabWorkspaceScreen extends StatefulWidget {
  const LabWorkspaceScreen({super.key});

  @override
  State<LabWorkspaceScreen> createState() => _LabWorkspaceScreenState();
}

class _LabWorkspaceScreenState extends State<LabWorkspaceScreen> {
  String _selectedFilter = 'all';

  final List<LabSampleItem> _samples = [
    LabSampleItem(
      id: 'sample-001',
      sampleCode: 'SMP-2026-4412',
      animalTag: 'MH-PUN-2026-001',
      species: 'Cattle (Gir)',
      sampleType: 'Whole Blood (EDTA)',
      suspectedDisease: 'Lumpy Skin Disease',
      transitStatus: 'completed',
      testResult: 'positive',
      testMethod: 'Real-Time RT-PCR',
      pathogenConfirmed: 'Capripoxvirus (LSD)',
      isZoonotic: false,
      collectionDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LabSampleItem(
      id: 'sample-002',
      sampleCode: 'SMP-2026-4413',
      animalTag: 'MH-SOL-2026-089',
      species: 'Buffalo (Murrah)',
      sampleType: 'Nasal Swab & Vesicular Fluid',
      suspectedDisease: 'Foot and Mouth Disease (FMD)',
      transitStatus: 'received_at_lab',
      testResult: 'pending',
      isZoonotic: false,
      collectionDate: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    LabSampleItem(
      id: 'sample-003',
      sampleCode: 'SMP-2026-4414',
      animalTag: 'MH-AHM-2026-042',
      species: 'Cattle (Khillari)',
      sampleType: 'Peripheral Blood Smear (Giemsa)',
      suspectedDisease: 'Anthrax (Splenic Fever)',
      transitStatus: 'referred',
      testResult: 'positive',
      testMethod: 'Polychrome Methylene Blue (M\'Fadyean)',
      pathogenConfirmed: 'Bacillus anthracis',
      isZoonotic: true,
      referredTo: 'State Disease Diagnostic Lab (SDDL) Pune',
      collectionDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LabSampleItem(
      id: 'sample-004',
      sampleCode: 'SMP-2026-4415',
      animalTag: 'MH-KOL-2026-114',
      species: 'Goat (Osmanabadi)',
      sampleType: 'Ocular / Nasal Swab',
      suspectedDisease: 'Peste des Petits Ruminants (PPR)',
      transitStatus: 'in_transit',
      testResult: 'pending',
      isZoonotic: false,
      collectionDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  List<LabSampleItem> get _filteredSamples {
    if (_selectedFilter == 'all') return _samples;
    return _samples.where((s) => s.transitStatus == _selectedFilter).toList();
  }

  void _showResultDialog(LabSampleItem item) {
    String selectedMethod = 'Real-Time RT-PCR';
    String selectedResult = 'positive';
    final pathogenCtrl = TextEditingController(text: item.suspectedDisease);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(PhosphorIconsFill.flask, color: Color(0xFF0288D1), size: 24),
                const SizedBox(width: 10),
                Text('Upload Lab Result: ${item.sampleCode}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Test Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    items: const [
                      DropdownMenuItem(value: 'Real-Time RT-PCR', child: Text('Real-Time RT-PCR')),
                      DropdownMenuItem(value: 'Antigen-Capture ELISA', child: Text('Antigen-Capture ELISA')),
                      DropdownMenuItem(value: 'Giemsa Microscopy', child: Text('Giemsa Stain Microscopy')),
                      DropdownMenuItem(value: 'Bacterial Culture & Isolation', child: Text('Bacterial Culture & Isolation')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedMethod = v!),
                  ),
                  const SizedBox(height: 14),
                  const Text('Diagnostic Result', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedResult,
                    items: const [
                      DropdownMenuItem(value: 'positive', child: Text('Positive (Confirmed)')),
                      DropdownMenuItem(value: 'negative', child: Text('Negative')),
                      DropdownMenuItem(value: 'inconclusive', child: Text('Inconclusive / Repeat Needed')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedResult = v!),
                  ),
                  const SizedBox(height: 14),
                  const Text('Confirmed Pathogen / Strain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: pathogenCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1), foregroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    item.testMethod = selectedMethod;
                    item.testResult = selectedResult;
                    item.pathogenConfirmed = pathogenCtrl.text;
                    item.transitStatus = 'completed';
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Result recorded for ${item.sampleCode}: $selectedResult'),
                      backgroundColor: selectedResult == 'positive' ? Colors.orange[800] : Colors.green[700],
                    ),
                  );
                },
                child: const Text('Save & Certify'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReferralDialog(LabSampleItem item) {
    String selectedRefLab = 'State Disease Diagnostic Lab (SDDL) Pune';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refer to Higher Apex Laboratory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sample Code: ${item.sampleCode} (${item.suspectedDisease})'),
            const SizedBox(height: 16),
            const Text('Reference Destination:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedRefLab,
              items: const [
                DropdownMenuItem(
                  value: 'State Disease Diagnostic Lab (SDDL) Pune',
                  child: Text('SDDL Pune (State Apex Lab)'),
                ),
                DropdownMenuItem(
                  value: 'ICAR-NIHSAD Bhopal (BSL-3+ High Security)',
                  child: Text('NIHSAD Bhopal (BSL-3+ National)'),
                ),
                DropdownMenuItem(
                  value: 'IVRI Bangalore (Foot and Mouth Disease Reference)',
                  child: Text('IVRI Bangalore (FMD Reference)'),
                ),
              ],
              onChanged: (v) => selectedRefLab = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.transitStatus = 'referred';
                item.referredTo = selectedRefLab;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sample referred to $selectedRefLab')),
              );
            },
            child: const Text('Confirm Referral'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F7F6),
      appBar: AppBar(
        leading: const BioHerdHamburgerButton(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagnostic Laboratory Workspace', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('पशु रोग निदान प्रयोगशाळा • BSL-2 Diagnostic Network', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.funnel),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Row
            _buildMetricGrid(isDark),
            const SizedBox(height: 20),

            // Pipeline Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Specimens', 'all'),
                  _buildFilterChip('In Transit (Cold-Chain)', 'in_transit'),
                  _buildFilterChip('Received at Lab', 'received_at_lab'),
                  _buildFilterChip('Testing Completed', 'completed'),
                  _buildFilterChip('Referred to SDDL', 'referred'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sample list
            ..._filteredSamples.map((s) => _buildSampleCard(s, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile('Total Specimens', '${_samples.length}', PhosphorIconsFill.flask, const Color(0xFF0288D1), cardWidth, isDark),
            _buildMetricTile('Positive Confirmed', '2', PhosphorIconsFill.checkCircle, const Color(0xFFE65100), cardWidth, isDark),
            _buildMetricTile('In Cold Chain', '1', PhosphorIconsFill.truck, const Color(0xFF6A1B9A), cardWidth, isDark),
            _buildMetricTile('Zoonotic Alerts', '1', PhosphorIconsFill.warningOctagon, const Color(0xFFC62828), cardWidth, isDark),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(String title, String count, IconData icon, Color color, double width, bool isDark) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = value),
        selectedColor: const Color(0xFF0288D1).withValues(alpha: 0.2),
        checkmarkColor: const Color(0xFF0288D1),
      ),
    );
  }

  Widget _buildSampleCard(LabSampleItem s, bool isDark) {
    Color statusColor;
    String statusLabel;

    switch (s.transitStatus) {
      case 'in_transit':
        statusColor = const Color(0xFF6A1B9A);
        statusLabel = 'In Transit';
        break;
      case 'received_at_lab':
        statusColor = const Color(0xFF0288D1);
        statusLabel = 'Received at Lab';
        break;
      case 'completed':
        statusColor = s.testResult == 'positive' ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
        statusLabel = s.testResult == 'positive' ? 'Positive Confirmed' : 'Completed (Negative)';
        break;
      case 'referred':
        statusColor = const Color(0xFFD81B60);
        statusLabel = 'Referred to Apex Lab';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = s.transitStatus;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.isZoonotic ? Colors.red.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: code & badges
          Row(
            children: [
              Text(
                s.sampleCode,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              if (s.isZoonotic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('ZOONOTIC', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Suspected: ${s.suspectedDisease}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Animal: ${s.animalTag} (${s.species}) • Specimen: ${s.sampleType}',
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),

          if (s.pathogenConfirmed != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.dna, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text('Confirmed: ${s.pathogenConfirmed} (${s.testMethod})',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor)),
                ],
              ),
            ),
          ],

          if (s.referredTo != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(PhosphorIconsFill.arrowSquareOut, size: 14, color: Color(0xFFD81B60)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Apex Referral: ${s.referredTo}', style: const TextStyle(fontSize: 11, color: Color(0xFFD81B60), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (s.transitStatus == 'in_transit')
                OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.checkCircle, size: 16),
                  label: const Text('Mark Received', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() => s.transitStatus = 'received_at_lab');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sample ${s.sampleCode} received at laboratory')),
                    );
                  },
                ),
              if (s.transitStatus == 'received_at_lab' || s.transitStatus == 'completed') ...[
                OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 16),
                  label: const Text('Refer SDDL', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showReferralDialog(s),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(PhosphorIconsRegular.flask, size: 16),
                  label: const Text('Enter Result', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showResultDialog(s),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
