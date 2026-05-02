import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// BanglaFont — supported Bangla fonts
// ═══════════════════════════════════════════════════════════════
enum BanglaFont {
  hindSiliguri,
  baloo2,
  notoSansBengali,
  galada,
  tiroDevanagariHindi,
}

extension BanglaFontExt on BanglaFont {
  String get displayName {
    switch (this) {
      case BanglaFont.hindSiliguri:       return 'Hind Siliguri';
      case BanglaFont.baloo2:             return 'Baloo 2';
      case BanglaFont.notoSansBengali:    return 'Noto Sans Bengali';
      case BanglaFont.galada:             return 'Galada';
      case BanglaFont.tiroDevanagariHindi:return 'Tiro Devanagari';
    }
  }

  String get key {
    switch (this) {
      case BanglaFont.hindSiliguri:       return 'hindSiliguri';
      case BanglaFont.baloo2:             return 'baloo2';
      case BanglaFont.notoSansBengali:    return 'notoSansBengali';
      case BanglaFont.galada:             return 'galada';
      case BanglaFont.tiroDevanagariHindi:return 'tiroDevanagari';
    }
  }

  String get sampleText => 'আল্লাহু আকবার';

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
      case BanglaFont.galada:
        return GoogleFonts.galada(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case BanglaFont.tiroDevanagariHindi:
        return GoogleFonts.tiroDevanagariHindi(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }

  TextTheme textTheme() {
    switch (this) {
      case BanglaFont.hindSiliguri:       return GoogleFonts.hindSiliguriTextTheme();
      case BanglaFont.baloo2:             return GoogleFonts.baloo2TextTheme();
      case BanglaFont.notoSansBengali:    return GoogleFonts.notoSansBengaliTextTheme();
      case BanglaFont.galada:             return GoogleFonts.galadaTextTheme();
      case BanglaFont.tiroDevanagariHindi:return GoogleFonts.tiroDevanagariHindiTextTheme();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ArabicFont — supported Arabic / Quran fonts
// ═══════════════════════════════════════════════════════════════
enum ArabicFont {
  amiri,
  scheherazadeNew,
  notoNaskhArabic,
  lateef,
  reem,
}

extension ArabicFontExt on ArabicFont {
  String get displayName {
    switch (this) {
      case ArabicFont.amiri:             return 'Amiri';
      case ArabicFont.scheherazadeNew:   return 'Scheherazade New';
      case ArabicFont.notoNaskhArabic:   return 'Noto Naskh Arabic';
      case ArabicFont.lateef:            return 'Lateef';
      case ArabicFont.reem:              return 'Reem Kufi';
    }
  }

  String get key {
    switch (this) {
      case ArabicFont.amiri:             return 'amiri';
      case ArabicFont.scheherazadeNew:   return 'scheherazadeNew';
      case ArabicFont.notoNaskhArabic:   return 'notoNaskhArabic';
      case ArabicFont.lateef:            return 'lateef';
      case ArabicFont.reem:              return 'reemKufi';
    }
  }

  String get sampleText => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  TextStyle style({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    switch (this) {
      case ArabicFont.amiri:
        return GoogleFonts.amiri(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case ArabicFont.scheherazadeNew:
        return GoogleFonts.scheherazadeNew(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case ArabicFont.notoNaskhArabic:
        return GoogleFonts.notoNaskhArabic(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case ArabicFont.lateef:
        return GoogleFonts.lateef(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case ArabicFont.reem:
        return GoogleFonts.reemKufi(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// AppAccentOption — preset accent color options
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
    label: 'ডিফল্ট পার্পেল',
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
    label: 'কমলা',
    primary: Color(0xFFE65100),
    light:   Color(0xFFFF8A50),
    dark:    Color(0xFFAC1900),
    key: 'orange',
  ),
  AppAccentOption(
    label: 'বেগুনি',
    primary: Color(0xFF7B1FA2),
    light:   Color(0xFFAE52D4),
    dark:    Color(0xFF4A0072),
    key: 'violet',
  ),
  AppAccentOption(
    label: 'টিল',
    primary: Color(0xFF00695C),
    light:   Color(0xFF4DB6AC),
    dark:    Color(0xFF00352A),
    key: 'teal',
  ),
  AppAccentOption(
    label: 'লাল',
    primary: Color(0xFFC62828),
    light:   Color(0xFFEF9A9A),
    dark:    Color(0xFF8E0000),
    key: 'red',
  ),
];

// ═══════════════════════════════════════════════════════════════
// SettingsProvider — সব settings এখানে, পুরো app এ apply হয়
// ═══════════════════════════════════════════════════════════════
class SettingsProvider extends ChangeNotifier {
  // ── Bangla Font ───────────────────────────────────────────
  BanglaFont _banglaFont = BanglaFont.hindSiliguri;

  // ── Arabic Font ───────────────────────────────────────────
  ArabicFont _arabicFont = ArabicFont.amiri;

  // ── Font size & style ─────────────────────────────────────
  double _fontSize = 16.0;
  FontWeight _fontWeight = FontWeight.w500;
  double _lineHeight = 1.5;
  double _arabicFontSize = 22.0;

  // ── Accent color ──────────────────────────────────────────
  String _accentKey = 'purple';

  // ── Display options ───────────────────────────────────────
  bool _coloredCards  = true;
  bool _useAnimations = true;
  bool _compactMode   = false;
  double _textScale   = 1.0;

  // ── Getters ───────────────────────────────────────────────
  BanglaFont get banglaFont    => _banglaFont;
  ArabicFont get arabicFont    => _arabicFont;
  double     get fontSize      => _fontSize;
  double     get arabicFontSize => _arabicFontSize;
  FontWeight get fontWeight    => _fontWeight;
  double     get lineHeight    => _lineHeight;
  bool       get coloredCards  => _coloredCards;
  bool       get useAnimations => _useAnimations;
  bool       get compactMode   => _compactMode;
  double     get textScale     => _textScale;

  AppAccentOption get accent =>
      kAccentOptions.firstWhere((a) => a.key == _accentKey,
          orElse: () => kAccentOptions.first);

  Color get effectivePrimary => accent.primary;

  SettingsProvider() {
    _load();
  }

  // ── Load from SharedPreferences ───────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Bangla font
    final fontKey = prefs.getString('banglaFont') ?? 'hindSiliguri';
    _banglaFont = BanglaFont.values.firstWhere(
      (f) => f.key == fontKey,
      orElse: () => BanglaFont.hindSiliguri,
    );

    // Arabic font
    final arabicKey = prefs.getString('arabicFont') ?? 'amiri';
    _arabicFont = ArabicFont.values.firstWhere(
      (f) => f.key == arabicKey,
      orElse: () => ArabicFont.amiri,
    );

    _fontSize       = prefs.getDouble('fontSize') ?? 16.0;
    _arabicFontSize = prefs.getDouble('arabicFontSize') ?? 22.0;
    final weightIndex = prefs.getInt('fontWeightIndex') ?? 2;
    _fontWeight     = _weightFromIndex(weightIndex);
    _lineHeight     = prefs.getDouble('lineHeight') ?? 1.5;

    _accentKey      = prefs.getString('accentColor') ?? 'purple';

    _coloredCards   = prefs.getBool('coloredCards') ?? true;
    _useAnimations  = prefs.getBool('useAnimations') ?? true;
    _compactMode    = prefs.getBool('compactMode') ?? false;
    _textScale      = prefs.getDouble('textScale') ?? 1.0;

    notifyListeners();
  }

  // ── Bangla font setter ────────────────────────────────────
  Future<void> setFont(BanglaFont font) async {
    _banglaFont = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('banglaFont', font.key);
    notifyListeners();
  }

  // ── Arabic font setter ────────────────────────────────────
  Future<void> setArabicFont(ArabicFont font) async {
    _arabicFont = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('arabicFont', font.key);
    notifyListeners();
  }

  // ── Font size setters ─────────────────────────────────────
  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(10.0, 26.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> setArabicFontSize(double size) async {
    _arabicFontSize = size.clamp(14.0, 36.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('arabicFontSize', _arabicFontSize);
    notifyListeners();
  }

  Future<void> setFontWeight(FontWeight weight) async {
    _fontWeight = weight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontWeightIndex', _weightToIndex(weight));
    notifyListeners();
  }

  Future<void> setLineHeight(double height) async {
    _lineHeight = height.clamp(1.0, 2.5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lineHeight', _lineHeight);
    notifyListeners();
  }

  // ── Accent setter ─────────────────────────────────────────
  Future<void> setAccent(AppAccentOption option) async {
    _accentKey = option.key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentColor', option.key);
    notifyListeners();
  }

  // ── Display setters ───────────────────────────────────────
  Future<void> setColoredCards(bool v) async {
    _coloredCards = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coloredCards', v);
    notifyListeners();
  }

  Future<void> setUseAnimations(bool v) async {
    _useAnimations = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useAnimations', v);
    notifyListeners();
  }

  Future<void> setCompactMode(bool v) async {
    _compactMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('compactMode', v);
    notifyListeners();
  }

  Future<void> setTextScale(double v) async {
    _textScale = v.clamp(0.8, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', _textScale);
    notifyListeners();
  }

  // ── Reset all to defaults ─────────────────────────────────
  Future<void> resetAll() async {
    _banglaFont     = BanglaFont.hindSiliguri;
    _arabicFont     = ArabicFont.amiri;
    _fontSize       = 16.0;
    _arabicFontSize = 22.0;
    _fontWeight     = FontWeight.w500;
    _lineHeight     = 1.5;
    _accentKey      = 'purple';
    _coloredCards   = true;
    _useAnimations  = true;
    _compactMode    = false;
    _textScale      = 1.0;

    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'banglaFont', 'arabicFont', 'fontSize', 'arabicFontSize',
      'fontWeightIndex', 'lineHeight', 'accentColor',
      'coloredCards', 'useAnimations', 'compactMode', 'textScale',
    ]) {
      await prefs.remove(key);
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  FontWeight _weightFromIndex(int index) {
    switch (index) {
      case 0:  return FontWeight.w300;
      case 1:  return FontWeight.w400;
      case 2:  return FontWeight.w500;
      case 3:  return FontWeight.w600;
      case 4:  return FontWeight.w700;
      default: return FontWeight.w500;
    }
  }

  int _weightToIndex(FontWeight w) {
    switch (w) {
      case FontWeight.w300: return 0;
      case FontWeight.w400: return 1;
      case FontWeight.w500: return 2;
      case FontWeight.w600: return 3;
      case FontWeight.w700: return 4;
      default:              return 2;
    }
  }
}
