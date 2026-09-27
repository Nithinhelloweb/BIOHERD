import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MortalityReportDialog extends StatefulWidget {
  final VoidCallback? onReportSubmitted;

  const MortalityReportDialog({super.key, this.onReportSubmitted});

  static Future<void> show(BuildContext context, {VoidCallback? onReportSubmitted}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MortalityReportDialog(onReportSubmitted: onReportSubmitted),
    );
  }

  @override
  State<MortalityReportDialog> createState() => _MortalityReportDialogState();
}

class _MortalityReportDialogState extends State<MortalityReportDialog> {
  String _selectedSpecies = 'cattle';
  int _animalCount = 1;
  final _causeCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  String _disposalMethod = 'deep_burial';
  bool _postMortemConducted = false;
  bool _gpsTagged = true;
  final double _lat = 18.5204;
  final double _lng = 73.8567;
  bool _isSubmitting = false;

  bool get _isAnthraxSuspected {
    final text = '${_causeCtrl.text} ${_symptomsCtrl.text}'.toLowerCase();
    return text.contains('anthrax') ||
        text.contains('काळपुळी') ||
        text.contains('unclotted') ||
        text.contains('blood from nose') ||
        text.contains('काळे रक्त');
  }

  @override
  void dispose() {
    _causeCtrl.dispose();
    _symptomsCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      widget.onReportSubmitted?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isAnthraxSuspected
                      ? '⚠️ CRITICAL: Mortality report logged. ZOONOTIC ALERT sent to DVO & PHC!'
                      : 'Mortality report logged successfully. Incident reference generated.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _isAnthraxSuspected ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF141C2E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsFill.skull, color: Color(0xFFC62828), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Livestock Mortality Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0D2137),
                          ),
                        ),
                        const Text(
                          'पशु मृत्यू नोंदणी • SIH26128 Rapid Triage',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
              const SizedBox(height: 16),
              const Divider(),

              Expanded(
                child: ListView(
                  children: [
                    // Zoonotic warning banner if Anthrax suspected
                    if (_isAnthraxSuspected)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withValues(alpha: 0.12),
                          border: Border.all(color: const Color(0xFFC62828)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(PhosphorIconsFill.warningOctagon, color: Color(0xFFC62828), size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'EXTREME BIO-HAZARD (ZOONOTIC): Unclotted blood from orifices indicates suspected Anthrax. DO NOT open carcass. Mandatory deep burial with quicklime.',
                                style: TextStyle(color: Color(0xFFC62828), fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Species & Count row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Species / प्रजाती', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedSpecies,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'cattle', child: Text('Cattle (गाय)')),
                                  DropdownMenuItem(value: 'buffalo', child: Text('Buffalo (म्हैस)')),
                                  DropdownMenuItem(value: 'goat', child: Text('Goat (शेळी)')),
                                  DropdownMenuItem(value: 'sheep', child: Text('Sheep (मेंढी)')),
                                  DropdownMenuItem(value: 'poultry', child: Text('Poultry (कुक्कुट)')),
                                ],
                                onChanged: (v) => setState(() => _selectedSpecies = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Animal Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(PhosphorIconsRegular.minusCircle),
                                    onPressed: _animalCount > 1 ? () => setState(() => _animalCount--) : null,
                                  ),
                                  Text(
                                    '$_animalCount',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(PhosphorIconsRegular.plusCircle),
                                    onPressed: () => setState(() => _animalCount++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Probable Cause
                    const Text('Probable Cause / संभाव्य कारण', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _causeCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Sudden death, high fever, bloat, poisoning...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Symptoms Observed Prior
                    const Text('Symptoms Observed Prior to Death', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _symptomsCtrl,
                      onChanged: (_) => setState(() {}),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Swollen throat, non-clotting dark blood discharge, tremors',
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Disposal Method
                    const Text('Safe Disposal Method / विल्हेवाट पद्धत', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _disposalMethod,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'deep_burial', child: Text('Deep Burial with Quicklime (खोल खड्ड्यात चुना)')),
                        DropdownMenuItem(value: 'incineration', child: Text('Controlled Incineration (जाळणे)')),
                        DropdownMenuItem(value: 'rendering', child: Text('Sanitary Rendering Facility')),
                      ],
                      onChanged: (v) => setState(() => _disposalMethod = v!),
                    ),
                    const SizedBox(height: 14),

                    // Post-Mortem Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _postMortemConducted,
                      title: const Text('Post-Mortem Conducted (शवविच्छेदन)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _isAnthraxSuspected
                            ? 'PROHIBITED for suspected Anthrax cases.'
                            : 'Field Vet post-mortem examination report available.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isAnthraxSuspected ? Colors.red : Colors.grey,
                        ),
                      ),
                      onChanged: _isAnthraxSuspected ? null : (v) => setState(() => _postMortemConducted = v!),
                    ),

                    // GPS Tagging
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsFill.mapPin, color: Color(0xFF2E7D32), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'GPS Tagged: $_lat, $_lng (Haveli, Pune)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Switch(
                            value: _gpsTagged,
                            onChanged: (v) => setState(() => _gpsTagged = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
