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
      case BanglaFont.hindSiliguri:    return 'Hind Siliguri';
      case BanglaFont.baloo2:          return 'Baloo 2';
      case BanglaFont.notoSansBengali: return 'Noto Sans Bengali';
      case BanglaFont.mukti:           return 'Mukti';
      case BanglaFont.galada:          return 'Galada';
    }
  }

  String get key {
    switch (this) {
      case BanglaFont.hindSiliguri:    return 'hindSiliguri';
      case BanglaFont.baloo2:          return 'baloo2';
      case BanglaFont.notoSansBengali: return 'notoSansBengali';
      case BanglaFont.mukti:           return 'mukti';
      case BanglaFont.galada:          return 'galada';
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
      case BanglaFont.mukti:
        return GoogleFonts.notoSansBengali(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
      case BanglaFont.galada:
        return GoogleFonts.galada(
            fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }

  TextTheme textTheme() {
    switch (this) {
      case BanglaFont.hindSiliguri:    return GoogleFonts.hindSiliguriTextTheme();
      case BanglaFont.baloo2:          return GoogleFonts.baloo2TextTheme();
      case BanglaFont.notoSansBengali: return GoogleFonts.notoSansBengaliTextTheme();
      case BanglaFont.mukti:           return GoogleFonts.notoSansBengaliTextTheme();
      case BanglaFont.galada:          return GoogleFonts.galadaTextTheme();
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
    label: 'ডিফল্ট (গ্রেডিয়েন্ট)',
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
];

// ═══════════════════════════════════════════════════════════════
// SettingsProvider — সব settings এখানে, পুরো app এ apply হয়
// ═══════════════════════════════════════════════════════════════
class SettingsProvider extends ChangeNotifier {
  // ── Font ──────────────────────────────────────────────────
  BanglaFont _banglaFont = BanglaFont.hindSiliguri;
  double _fontSize = 16.0;
  FontWeight _fontWeight = FontWeight.w500;
  double _lineHeight = 1.5;

  // ── Accent color ──────────────────────────────────────────
  String _accentKey = 'purple';
  Color? _customColor; // null = use preset

  // ── Display options ───────────────────────────────────────
  bool _useSystemTheme = true;   // সিস্টেম থিম ফলো করুন
  bool _coloredCards = true;     // কার্ড কালারকোড
  bool _useAnimations = true;    // অ্যানিমেশন ব্যবহার করুন
  bool _compactMode = false;     // কম্প্যাক্ট মোড
  double _textScale = 1.0;       // টেক্সট স্কেল (0.8 – 1.4)

  // ── Getters ───────────────────────────────────────────────
  BanglaFont get banglaFont => _banglaFont;
  double get fontSize => _fontSize;
  FontWeight get fontWeight => _fontWeight;
  double get lineHeight => _lineHeight;

  AppAccentOption get accent =>
      kAccentOptions.firstWhere((a) => a.key == _accentKey,
          orElse: () => kAccentOptions.first);

  Color? get customColor => _customColor;

  /// Effective primary color — custom overrides preset
  Color get effectivePrimary => _customColor ?? accent.primary;

  bool get useSystemTheme => _useSystemTheme;
  bool get coloredCards => _coloredCards;
  bool get useAnimations => _useAnimations;
  bool get compactMode => _compactMode;
  double get textScale => _textScale;

  SettingsProvider() {
    _load();
  }

  // ── Load from SharedPreferences ───────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Font
    final fontKey = prefs.getString('banglaFont') ?? 'hindSiliguri';
    _banglaFont = BanglaFont.values.firstWhere(
      (f) => f.key == fontKey,
      orElse: () => BanglaFont.hindSiliguri,
    );
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    final weightIndex = prefs.getInt('fontWeightIndex') ?? 2; // w500
    _fontWeight = _weightFromIndex(weightIndex);
    _lineHeight = prefs.getDouble('lineHeight') ?? 1.5;

    // Accent
    _accentKey = prefs.getString('accentColor') ?? 'purple';
    final customColorValue = prefs.getInt('customColor');
    _customColor = customColorValue != null ? Color(customColorValue) : null;

    // Display
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    _coloredCards   = prefs.getBool('coloredCards') ?? true;
    _useAnimations  = prefs.getBool('useAnimations') ?? true;
    _compactMode    = prefs.getBool('compactMode') ?? false;
    _textScale      = prefs.getDouble('textScale') ?? 1.0;

    notifyListeners();
  }

  // ── Font setters ──────────────────────────────────────────
  Future<void> setFont(BanglaFont font) async {
    _banglaFont = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('banglaFont', font.key);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(10.0, 24.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
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

  // ── Accent setters ────────────────────────────────────────
  Future<void> setAccent(AppAccentOption option) async {
    _accentKey = option.key;
    _customColor = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentColor', option.key);
    await prefs.remove('customColor');
    notifyListeners();
  }

  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customColor', color.toARGB32());
    notifyListeners();
  }

  // ── Display setters ───────────────────────────────────────
  Future<void> setUseSystemTheme(bool v) async {
    _useSystemTheme = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', v);
    notifyListeners();
  }

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
    _banglaFont   = BanglaFont.hindSiliguri;
    _fontSize     = 16.0;
    _fontWeight   = FontWeight.w500;
    _lineHeight   = 1.5;
    _accentKey    = 'purple';
    _customColor  = null;
    _useSystemTheme = true;
    _coloredCards = true;
    _useAnimations = true;
    _compactMode  = false;
    _textScale    = 1.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('banglaFont');
    await prefs.remove('fontSize');
    await prefs.remove('fontWeightIndex');
    await prefs.remove('lineHeight');
    await prefs.remove('accentColor');
    await prefs.remove('customColor');
    await prefs.remove('useSystemTheme');
    await prefs.remove('coloredCards');
    await prefs.remove('useAnimations');
    await prefs.remove('compactMode');
    await prefs.remove('textScale');

    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  FontWeight _weightFromIndex(int index) {
    switch (index) {
      case 0: return FontWeight.w400;
      case 1: return FontWeight.w500;
      case 2: return FontWeight.w500;
      case 3: return FontWeight.w600;
      case 4: return FontWeight.w700;
      default: return FontWeight.w500;
    }
  }

  int _weightToIndex(FontWeight w) {
    switch (w) {
      case FontWeight.w400: return 0;
      case FontWeight.w500: return 2;
      case FontWeight.w600: return 3;
      case FontWeight.w700: return 4;
      default: return 2;
    }
  }
}
