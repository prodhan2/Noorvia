import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// BanglaFont — supported readable Bangla fonts
// ═══════════════════════════════════════════════════════════════
enum BanglaFont {
  hindSiliguri,
  baloo2,
  notoSansBengali,
  mukti,
  galada,
}

extension BanglaFontExt on BanglaFont {
  String get displayName {
    switch (this) {
      case BanglaFont.hindSiliguri:   return 'হিন্দ সিলিগুড়ি';
      case BanglaFont.baloo2:         return 'বালু ২';
      case BanglaFont.notoSansBengali:return 'নোটো সান্স বাংলা';
      case BanglaFont.mukti:          return 'মুক্তি';
      case BanglaFont.galada:         return 'গালাদা';
    }
  }

  String get key {
    switch (this) {
      case BanglaFont.hindSiliguri:   return 'hindSiliguri';
      case BanglaFont.baloo2:         return 'baloo2';
      case BanglaFont.notoSansBengali:return 'notoSansBengali';
      case BanglaFont.mukti:          return 'mukti';
      case BanglaFont.galada:         return 'galada';
    }
  }

  /// Sample Bangla text to preview the font
  String get sampleText => 'আল্লাহু আকবার';

  /// Build a TextStyle using this font
  TextStyle style({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    switch (this) {
      case BanglaFont.hindSiliguri:
        return GoogleFonts.hindSiliguri(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case BanglaFont.baloo2:
        return GoogleFonts.baloo2(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case BanglaFont.notoSansBengali:
        return GoogleFonts.notoSansBengali(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case BanglaFont.mukti:
        // Mukti not in google_fonts — fallback to Noto Sans Bengali
        return GoogleFonts.notoSansBengali(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case BanglaFont.galada:
        return GoogleFonts.galada(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }

  /// Build a full TextTheme using this font
  TextTheme textTheme() {
    switch (this) {
      case BanglaFont.hindSiliguri:
        return GoogleFonts.hindSiliguriTextTheme();
      case BanglaFont.baloo2:
        return GoogleFonts.baloo2TextTheme();
      case BanglaFont.notoSansBengali:
        return GoogleFonts.notoSansBengaliTextTheme();
      case BanglaFont.mukti:
        return GoogleFonts.notoSansBengaliTextTheme();
      case BanglaFont.galada:
        return GoogleFonts.galadaTextTheme();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// AppAccentColor — preset accent color options
// ═══════════════════════════════════════════════════════════════
class AppAccentOption {
  final String label;
  final Color primary;
  final Color light;
  final Color dark;
  final String key;

  const AppAccentOption({
    required this.label,
    required this.primary,
    required this.light,
    required this.dark,
    required this.key,
  });
}

const List<AppAccentOption> kAccentOptions = [
  AppAccentOption(
    label: 'বেগুনি (ডিফল্ট)',
    primary: Color(0xFF6C3CE1),
    light:   Color(0xFF9B6FF5),
    dark:    Color(0xFF4A2BAD),
    key: 'purple',
  ),
  AppAccentOption(
    label: 'নীল',
    primary: Color(0xFF1565C0),
    light:   Color(0xFF5E92F3),
    dark:    Color(0xFF003C8F),
    key: 'blue',
  ),
  AppAccentOption(
    label: 'সবুজ',
    primary: Color(0xFF2E7D32),
    light:   Color(0xFF60AD5E),
    dark:    Color(0xFF005005),
    key: 'green',
  ),
  AppAccentOption(
    label: 'সোনালি',
    primary: Color(0xFFF59E0B),
    light:   Color(0xFFFFD54F),
    dark:    Color(0xFFB45309),
    key: 'gold',
  ),
  AppAccentOption(
    label: 'গোলাপি',
    primary: Color(0xFFAD1457),
    light:   Color(0xFFE35183),
    dark:    Color(0xFF78002E),
    key: 'pink',
  ),
  AppAccentOption(
    label: 'টিল',
    primary: Color(0xFF00695C),
    light:   Color(0xFF439889),
    dark:    Color(0xFF003D33),
    key: 'teal',
  ),
];

// ═══════════════════════════════════════════════════════════════
// SettingsProvider
// ═══════════════════════════════════════════════════════════════
class SettingsProvider extends ChangeNotifier {
  BanglaFont _banglaFont = BanglaFont.hindSiliguri;
  String _accentKey = 'purple';

  BanglaFont get banglaFont => _banglaFont;

  AppAccentOption get accent =>
      kAccentOptions.firstWhere((a) => a.key == _accentKey,
          orElse: () => kAccentOptions.first);

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final fontKey = prefs.getString('banglaFont') ?? 'hindSiliguri';
    _banglaFont = BanglaFont.values.firstWhere(
      (f) => f.key == fontKey,
      orElse: () => BanglaFont.hindSiliguri,
    );
    _accentKey = prefs.getString('accentColor') ?? 'purple';
    notifyListeners();
  }

  Future<void> setFont(BanglaFont font) async {
    _banglaFont = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('banglaFont', font.key);
    notifyListeners();
  }

  Future<void> setAccent(AppAccentOption option) async {
    _accentKey = option.key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentColor', option.key);
    notifyListeners();
  }
}
