// ════════════════════════════════════════════════════════════
// GLOBAL SETTINGS USAGE GUIDE
// ════════════════════════════════════════════════════════════
//
// এই ফাইলটি দেখায় কিভাবে পুরো অ্যাপে global settings ব্যবহার করবেন।
// সব settings SettingsProvider-এ আছে এবং পুরো অ্যাপে automatically apply হয়।
//
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════════
// উদাহরণ ১: কোনো স্ক্রিনে বাংলা টেক্সট দেখানো
// ════════════════════════════════════════════════════════════
class ExampleBanglaTextScreen extends StatelessWidget {
  const ExampleBanglaTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // SettingsProvider থেকে সব settings পাবেন
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ বাংলা টেক্সট — user-এর selected font, size, weight সব apply হবে
            Text(
              'আসসালামু আলাইকুম',
              style: settings.banglaFont.style(
                fontSize: settings.fontSize,
                fontWeight: settings.fontWeight,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Heading — বড় font size
            Text(
              'ইসলামিক জ্ঞান',
              style: settings.banglaFont.style(
                fontSize: settings.fontSize + 8, // heading বড় করতে
                fontWeight: FontWeight.w700,
                color: settings.effectivePrimary, // user-এর accent color
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Body text — line height সহ
            Text(
              'আল্লাহ তায়ালা আমাদের সবাইকে সঠিক পথে পরিচালিত করুন। '
              'আমরা যেন সর্বদা তাঁর নির্দেশনা অনুসরণ করতে পারি।',
              style: settings.banglaFont.style(
                fontSize: settings.fontSize,
                fontWeight: settings.fontWeight,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              // Line height apply করুন
              textScaleFactor: settings.textScale,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// উদাহরণ ২: আরবি টেক্সট দেখানো (কুরআন, দু'আ)
// ════════════════════════════════════════════════════════════
class ExampleArabicTextScreen extends StatelessWidget {
  const ExampleArabicTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // RTL জন্য
          children: [
            // ✅ আরবি টেক্সট — user-এর selected Arabic font + size
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textDirection: TextDirection.rtl,
              style: settings.arabicFont.style(
                fontSize: settings.arabicFontSize,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ✅ আরবি + বাংলা একসাথে
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // আরবি
                Text(
                  'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                  textDirection: TextDirection.rtl,
                  style: settings.arabicFont.style(
                    fontSize: settings.arabicFontSize,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                // বাংলা অনুবাদ
                Text(
                  'সমস্ত প্রশংসা আল্লাহর জন্য, যিনি সকল সৃষ্টির প্রতিপালক।',
                  textAlign: TextAlign.right,
                  style: settings.banglaFont.style(
                    fontSize: settings.fontSize - 2, // translation একটু ছোট
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// উদাহরণ ৩: Card/Container-এ accent color ব্যবহার
// ════════════════════════════════════════════════════════════
class ExampleAccentColorScreen extends StatelessWidget {
  const ExampleAccentColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Card with accent color border
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: settings.effectivePrimary, // user-এর accent color
                  width: 2,
                ),
              ),
              child: Text(
                'এই কার্ডের border user-এর selected accent color',
                style: settings.banglaFont.style(
                  fontSize: settings.fontSize,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Button with accent color
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.effectivePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'বাটন',
                style: settings.banglaFont.style(
                  fontSize: settings.fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Icon with accent color
            Icon(
              Icons.star,
              size: 48,
              color: settings.effectivePrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// উদাহরণ ৪: ListView/GridView-এ settings apply
// ════════════════════════════════════════════════════════════
class ExampleListScreen extends StatelessWidget {
  const ExampleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return Scaffold(
      body: ListView.builder(
        padding: EdgeInsets.all(settings.compactMode ? 8 : 16), // compact mode
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(
              bottom: settings.compactMode ? 8 : 12, // compact spacing
            ),
            padding: EdgeInsets.all(settings.compactMode ? 12 : 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: settings.coloredCards // colored cards option
                  ? Border.all(
                      color: settings.effectivePrimary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: settings.effectivePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book,
                    color: settings.effectivePrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Text(
                    'আইটেম ${index + 1}',
                    style: settings.banglaFont.style(
                      fontSize: settings.fontSize,
                      fontWeight: settings.fontWeight,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// QUICK REFERENCE — সব available settings
// ════════════════════════════════════════════════════════════
/*

✅ BANGLA FONT:
  - settings.banglaFont              → BanglaFont enum
  - settings.banglaFont.style(...)   → TextStyle with selected font
  - settings.fontSize                → double (10-26)
  - settings.fontWeight              → FontWeight
  - settings.lineHeight              → double (1.0-2.5)

✅ ARABIC FONT:
  - settings.arabicFont              → ArabicFont enum
  - settings.arabicFont.style(...)   → TextStyle with selected font
  - settings.arabicFontSize          → double (14-36)

✅ ACCENT COLOR:
  - settings.accent                  → AppAccentOption object
  - settings.effectivePrimary        → Color (user's selected accent)
  - settings.accent.primary          → Color
  - settings.accent.light            → Color
  - settings.accent.dark             → Color

✅ DISPLAY OPTIONS:
  - settings.textScale               → double (0.8-1.4)
  - settings.coloredCards            → bool
  - settings.useAnimations           → bool
  - settings.compactMode             → bool

✅ THEME:
  - isDark = context.watch<ThemeProvider>().isDark
  - AppColors.darkBg / AppColors.lightBg
  - AppColors.darkText / AppColors.lightText
  - AppColors.darkCard / AppColors.lightCard
  - AppColors.darkSubText / AppColors.lightSubText

✅ HOW TO USE:
  1. Import: import 'package:provider/provider.dart';
  2. Get settings: final settings = context.watch<SettingsProvider>();
  3. Get theme: final isDark = context.watch<ThemeProvider>().isDark;
  4. Apply to Text: settings.banglaFont.style(fontSize: settings.fontSize, ...)
  5. Apply to Arabic: settings.arabicFont.style(fontSize: settings.arabicFontSize, ...)
  6. Apply accent: color: settings.effectivePrimary

✅ IMPORTANT:
  - সব settings automatically save হয় SharedPreferences-এ
  - settings change করলে পুরো app rebuild হয় (notifyListeners)
  - MaterialApp-এ theme already connected আছে
  - কোনো screen-এ manually theme apply করার দরকার নেই

*/
