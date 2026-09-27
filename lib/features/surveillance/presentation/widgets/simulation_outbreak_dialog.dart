import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bioherd_button.dart';
import '../../bloc/surveillance_bloc.dart';
import '../../models/surveillance_model.dart';

class SimulationOutbreakDialog extends StatefulWidget {
  final List<DistrictRiskModel> districts;

  const SimulationOutbreakDialog({super.key, required this.districts});

  static Future<void> show(BuildContext context, List<DistrictRiskModel> districts) {
    return showDialog(
      context: context,
      builder: (_) => SimulationOutbreakDialog(districts: districts),
    );
  }

  @override
  State<SimulationOutbreakDialog> createState() => _SimulationOutbreakDialogState();
}

class _SimulationOutbreakDialogState extends State<SimulationOutbreakDialog> {
  late String _selectedDistrict;
  String _selectedDisease = 'Foot and Mouth Disease (FMD)';

  final List<String> _diseases = const [
    'Foot and Mouth Disease (FMD)',
    'Lumpy Skin Disease (LSD)',
    'Haemorrhagic Septicaemia (HS)',
    'Black Quarter (BQ)',
    'Bovine Brucellosis',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.districts.isNotEmpty ? widget.districts.first.districtName : 'Solapur';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsFill.lightning, color: AppColors.alertRed, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulate Outbreak Surge',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Trigger instant contagion telemetry event',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // District selector
              const Text('Target District', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedDistrict,
                    items: widget.districts.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.districtName,
                        child: Text('${d.districtName} (Current Risk: ${d.riskScore.toInt()})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDistrict = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Disease selector
              const Text('Pathogen / Disease', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedDisease,
                    items: _diseases.map((dis) {
                      return DropdownMenuItem<String>(
                        value: dis,
                        child: Text(dis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDisease = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Impact Preview
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.alertRed),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Will inject +18 suspected cases, surge district risk by +28 pts, and broadcast critical biosecurity alerts.',
                        style: TextStyle(fontSize: 11, color: AppColors.alertRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
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
                    flex: 2,
                    child: BioHerdButton(
                      label: 'Inject Outbreak Surge',
                      icon: PhosphorIconsFill.lightning,
                      onPressed: () {
                        context.read<SurveillanceBloc>().add(
                              TriggerMockOutbreakEvent(_selectedDistrict, disease: _selectedDisease),
                            );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Simulated $_selectedDisease outbreak injected into $_selectedDistrict.'),
                            backgroundColor: AppColors.alertRed,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
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
