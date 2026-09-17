import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/app_colors.dart';

class QuarantineProtocolsDialog extends StatelessWidget {
  const QuarantineProtocolsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
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
                      color: AppColors.alertRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.shieldWarning,
                      color: AppColors.alertRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GOVT. OF MAHARASHTRA • ANIMAL HUSBANDRY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quarantine & Biosecurity Directives',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.alertAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.alertAmber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(PhosphorIconsFill.warningCircle, size: 16, color: AppColors.alertAmber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'साथीचे रोग प्रतिबंधक कायदा (Epidemic Diseases Act) अन्वये आदेश',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Protocol List
              Expanded(
                child: ListView(
                  children: [
                    _buildProtocolItem(
                      number: '१',
                      titleMr: '५ किमी परिघात जनावरांच्या वाहतुकीस पूर्ण बंदी',
                      titleEn: 'Complete 5km Livestock Movement Ban',
                      descMr: 'बाधित क्षेत्रातील जनावरे बाहेर नेणे किंवा नवीन जनावरे गोठ्यात आणणे सक्त मनाई आहे.',
                      descEn: 'Zero animal transit into or out of the containment zone.',
                      icon: PhosphorIconsRegular.prohibit,
                      color: AppColors.alertRed,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '२',
                      titleMr: 'बाधित जनावरांचे त्वरित विलगीकरण',
                      titleEn: 'Mandatory Strict Isolation',
                      descMr: 'लक्षणे दिसणाऱ्या जनावरांना निरोगी जनावरांपासून किमान ५० मीटर अंतरावर स्वतंत्र बांधावे.',
                      descEn: 'Isolate symptomatic animals immediately in a separate dry shelter.',
                      icon: PhosphorIconsRegular.arrowsSplit,
                      color: AppColors.alertAmber,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '३',
                      titleMr: 'गोठ्यात दैनंदिन निर्जंतुकीकरण फवारणी',
                      titleEn: 'Daily Disinfection Protocol',
                      descMr: '४% सोडियम कार्बोनेट किंवा २% कॉस्टिक सोडा द्रावणाने गोठ्याची जमीन व गव्हाणी धुवून काढाव्यात.',
                      descEn: 'Wash stall floors and mangers with 4% sodium carbonate solution.',
                      icon: PhosphorIconsRegular.sparkle,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '४',
                      titleMr: '५ ते १० किमी परिघात रिंग लसीकरण',
                      titleEn: 'Emergency Ring Vaccination',
                      descMr: 'शासकीय पशुवैद्यकीय पथकाकडून प्रादुर्भाव केंद्राभोवती १० किमी परिघात सर्व निरोगी जनावरांचे लसीकरण करून घ्यावे.',
                      descEn: 'Mandatory ring vaccination of all healthy animals within the 10km buffer.',
                      icon: PhosphorIconsRegular.syringe,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '५',
                      titleMr: 'दूध व पाण्याचे जैविक सुरक्षेचे नियम',
                      titleEn: 'Milk & Water Biosecurity',
                      descMr: 'बाधित जनावरांचे दूध इतर दुधात मिसळू नये. दूध चांगले उकळूनच वापरावे. पाण्याच्या टाक्या स्वच्छ ठेवाव्यात.',
                      descEn: 'Do not sell or mix milk from infected animals. Boil before consumption.',
                      icon: PhosphorIconsRegular.drop,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    _buildProtocolItem(
                      number: '६',
                      titleMr: '१९६२ हेल्पलाइनवर त्वरित अहवाल देणे',
                      titleEn: 'Daily Reporting to 1962 Toll-Free',
                      descMr: 'कोणतेही नवे जनावर आजारी आढळल्यास किंवा दगावल्यास १९६२ वर लगेच कॉल करा.',
                      descEn: 'Report any fresh fever, blisters, or casualties to the 1962 district desk.',
                      icon: PhosphorIconsRegular.phoneCall,
                      color: AppColors.primaryGreen,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('समजले / Acknowledged', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolItem({
    required String number,
    required String titleMr,
    required String titleEn,
    required String descMr,
    required String descEn,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.grey[750]! : Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $titleMr',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  titleEn,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descMr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                Text(
                  descEn,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
