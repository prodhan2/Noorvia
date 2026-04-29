import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

class DowaScreen extends StatelessWidget {
  const DowaScreen({super.key});

  final List<Map<String, String>> categories = const [
    {'emoji': '🌅', 'title': 'সকালের দু\'আ', 'count': '১৫টি দু\'আ'},
    {'emoji': '🌙', 'title': 'রাতের দু\'আ', 'count': '১২টি দু\'আ'},
    {'emoji': '🍽️', 'title': 'খাওয়ার দু\'আ', 'count': '৮টি দু\'আ'},
    {'emoji': '🚗', 'title': 'সফরের দু\'আ', 'count': '১০টি দু\'আ'},
    {'emoji': '🤲', 'title': 'নামাজের দু\'আ', 'count': '২০টি দু\'আ'},
    {'emoji': '😴', 'title': 'ঘুমের দু\'আ', 'count': '৬টি দু\'আ'},
    {'emoji': '🏠', 'title': 'ঘরে প্রবেশের দু\'আ', 'count': '৪টি দু\'আ'},
    {'emoji': '💊', 'title': 'অসুস্থতার দু\'আ', 'count': '৯টি দু\'আ'},
    {'emoji': '📿', 'title': 'তাসবীহ ও যিকির', 'count': '২৫টি'},
    {'emoji': '🌿', 'title': 'ইস্তিগফার', 'count': '১৪টি দু\'আ'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'দু\'আ ও যিকির',
              style: GoogleFonts.hindSiliguri(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          // Featured dua
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4D2A), Color(0xFF2E8B57)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'বিসমিল্লাহির রাহমানির রাহিম',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'পরম করুণাময় অতি দয়ালু আল্লাহর নামে',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'বিভাগসমূহ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 6),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(cat['emoji']!,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    title: Text(
                      cat['title']!,
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      cat['count']!,
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
