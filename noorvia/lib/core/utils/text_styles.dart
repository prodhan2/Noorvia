// ════════════════════════════════════════════════════════════
// TEXT STYLES HELPER — Global Settings থেকে TextStyle তৈরি করুন
// ════════════════════════════════════════════════════════════
//
// এই helper ব্যবহার করলে সব screen-এ automatically global settings
// apply হবে — font, size, weight, color সব।
//
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════════
// EXTENSION — BuildContext-এ সরাসরি text style পাবেন
// ════════════════════════════════════════════════════════════
extension TextStyleHelper on BuildContext {
  /// SettingsProvider instance
  SettingsProvider get settings => watch<SettingsProvider>();
  
  /// ThemeProvider instance
  ThemeProvider get themeProvider => watch<ThemeProvider>();
  
  /// Is dark mode active
  bool get isDark => themeProvider.isDark;
  
  /// Current accent color
  Color get accentColor => settings.effectivePrimary;
  
  // ── Theme colors ──────────────────────────────────────────
  Color get textColor => isDark ? AppColors.darkText : AppColors.lightText;
  Color get subTextColor => isDark ? AppColors.darkSubText : AppColors.lightSubText;
  Color get bgColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  
  // ── Bangla text styles ────────────────────────────────────
  
  /// বাংলা body text — default size, weight
  TextStyle get banglaBody => settings.getCurrentFontStyle(
    fontSize: settings.fontSize,
    fontWeight: settings.fontWeight,
    color: textColor,
  );
  
  /// বাংলা heading — বড় + bold
  TextStyle get banglaHeading => settings.getCurrentFontStyle(
    fontSize: settings.fontSize + 8,
    fontWeight: FontWeight.w700,
    color: textColor,
  );
  
  /// বাংলা title — medium size + semibold
  TextStyle get banglaTitle => settings.getCurrentFontStyle(
    fontSize: settings.fontSize + 4,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  /// বাংলা subtitle — ছোট + light color
  TextStyle get banglaSubtitle => settings.getCurrentFontStyle(
    fontSize: settings.fontSize - 2,
    fontWeight: FontWeight.w400,
    color: subTextColor,
  );
  
  /// বাংলা caption — সবচেয়ে ছোট
  TextStyle get banglaCaption => settings.getCurrentFontStyle(
    fontSize: settings.fontSize - 4,
    fontWeight: FontWeight.w400,
    color: subTextColor,
  );
  
  /// বাংলা button text
  TextStyle get banglaButton => settings.getCurrentFontStyle(
    fontSize: settings.fontSize,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // ── Arabic text styles ────────────────────────────────────
  
  /// আরবি text — Quran, Dua
  TextStyle get arabicText => settings.arabicFont.style(
    fontSize: settings.arabicFontSize,
    color: textColor,
  );
  
  /// আরবি heading — বড়
  TextStyle get arabicHeading => settings.arabicFont.style(
    fontSize: settings.arabicFontSize + 6,
    color: textColor,
  );
  
  /// আরবি subtitle — ছোট
  TextStyle get arabicSubtitle => settings.arabicFont.style(
    fontSize: settings.arabicFontSize - 4,
    color: subTextColor,
  );
  
  // ── Custom styles with parameters ─────────────────────────
  
  /// Custom bangla style
  TextStyle banglaCust({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) => settings.getCurrentFontStyle(
    fontSize: fontSize ?? settings.fontSize,
    fontWeight: fontWeight ?? settings.fontWeight,
    color: color ?? textColor,
  );
  
  /// Custom arabic style
  TextStyle arabicCust({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) => settings.arabicFont.style(
    fontSize: fontSize ?? settings.arabicFontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color ?? textColor,
  );
}

// ════════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ════════════════════════════════════════════════════════════
/*

✅ সহজ ব্যবহার:

  Text('আসসালামু আলাইকুম', style: context.banglaBody)
  Text('ইসলামিক জ্ঞান', style: context.banglaHeading)
  Text('বিস্তারিত', style: context.banglaSubtitle)
  
  Text('بِسْمِ اللَّهِ', style: context.arabicText, textDirection: TextDirection.rtl)

✅ Custom parameters:

  Text('কাস্টম', style: context.banglaCust(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.red,
  ))

✅ Theme colors:

  Container(color: context.bgColor)
  Text('টেক্সট', style: TextStyle(color: context.textColor))
  Icon(Icons.star, color: context.accentColor)

✅ Settings access:

  final fontSize = context.settings.fontSize;
  final isDark = context.isDark;
  final accent = context.accentColor;

*/
