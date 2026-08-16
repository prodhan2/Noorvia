import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../IslamicFeatures/qibla_direction_page.dart';
import '../IslamicFeatures/tashbi.dart';
import '../IslamicFeatures/ramadancalender.dart';
import '../IslamicFeatures/calendar.dart';
import '../location/nearby_mosques_screen.dart';
import '../location/islamic_places_page.dart';
import '../services/halal_ingredient_page.dart';
import '../IslamicFeatures/hidithdemo.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});
  void _go(BuildContext c, Widget p) => Navigator.push(c, MaterialPageRoute(builder: (_) => p));

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final tools = <({String emoji, String label, Widget page})>[
      (emoji: '🧭', label: 'কিবলা নির্দেশক', page: const QiblaDirectionPage()),
      (emoji: '📿', label: 'তাসবীহ কাউন্টার', page: TasbihCounter()),
      (emoji: '📅', label: 'হিজরি ক্যালেন্ডার', page: PrayerTimesCalendarPage()),
      (emoji: '🌙', label: 'রোযার সময়সূচি', page: RamadanCalendarPage()),
      (emoji: '🕌', label: 'মসজিদ ও মুসাল্লা', page: const NearbyMosquesScreen()),
      (emoji: '🔎', label: 'হালাল উপাদান সহায়ক', page: const HalalIngredientPage()),
      (emoji: '📜', label: 'হাদিস লাইব্রেরি', page: const HadithDemoPage()),
      (emoji: '🗺️', label: 'ইসলামিক স্থান', page: const IslamicPlacesPage()),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ইসলামিক টুলস', style: settings.banglaFont.style(fontSize: settings.fontSize + 8, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 16),
          Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.35, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _go(context, tool.page),
                child: Container(
                  decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(tool.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(tool.label, style: settings.banglaFont.style(fontSize: settings.fontSize - 3, fontWeight: FontWeight.w600, color: textColor), textAlign: TextAlign.center),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}
