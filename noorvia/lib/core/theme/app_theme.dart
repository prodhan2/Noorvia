import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

class AppColors {
  // ── Airkom Gradient tokens ────────────────────────────────
  static const Color gradientStart = Color(0xFF6C3CE1); // deep purple
  static const Color gradientMid   = Color(0xFF4A6FE3); // indigo-blue
  static const Color gradientEnd   = Color(0xFF4A90D9); // sky blue

  static LinearGradient get gradient => const LinearGradient(
    colors: [gradientStart, gradientMid, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get gradientVertical => const LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get gradientDark => const LinearGradient(
    colors: [Color(0xCC6C3CE1), Color(0xCC4A90D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Airkom accent colors ──────────────────────────────────
  static const Color primary      = Color(0xFF6C3CE1); // purple
  static const Color primaryLight = Color(0xFF9B6FF5); // light purple
  static const Color primaryDark  = Color(0xFF4A2BAD); // dark purple
  static const Color accent       = Color(0xFF4A90D9); // blue accent

  // ── Airkom section colors ─────────────────────────────────
  static const Color ilomColor    = Color(0xFF5B3CC4); // purple
  static const Color amolColor    = Color(0xFF2563EB); // blue
  static const Color sebaColor    = Color(0xFF0891B2); // teal
  static const Color bibidhoColor = Color(0xFF7C3AED); // violet

  // ── Light theme ───────────────────────────────────────────
  static const Color lightBg      = Color(0xFFF5F4FF); // very light purple tint
  static const Color lightCard    = Color(0xFFFFFFFF);
  static const Color lightText    = Color(0xFF1A1A2E);
  static const Color lightSubText = Color(0xFF6B7280);

  // ── Dark theme ────────────────────────────────────────────
  static const Color darkBg       = Color(0xFF0F0E1A); // deep dark purple
  static const Color darkCard     = Color(0xFF1C1B2E); // dark purple card
  static const Color darkText     = Color(0xFFEEEEFF);
  static const Color darkSubText  = Color(0xFF9CA3AF);

  // ── Misc ──────────────────────────────────────────────────
  static const Color notifRed     = Color(0xFFEF4444);
  static const Color gold         = Color(0xFFF59E0B);

  // ── Airkom card gradient (subtle) ─────────────────────────
  static LinearGradient get cardGradient => const LinearGradient(
    colors: [Color(0xFF7B4FE8), Color(0xFF5B8DEF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Prayer row highlight ──────────────────────────────────
  static LinearGradient get prayerHighlight => const LinearGradient(
    colors: [Color(0xFF6C3CE1), Color(0xFF4A90D9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  // ── Static defaults (used before settings load) ───────────
  static ThemeData lightTheme = _buildLight(
    BanglaFont.hindSiliguri,
    kAccentOptions.first,
  );

  static ThemeData darkTheme = _buildDark(
    BanglaFont.hindSiliguri,
    kAccentOptions.first,
  );

  // ── Dynamic builders — called from main.dart via Consumer ─
  static ThemeData buildLight(BanglaFont font, AppAccentOption accent) =>
      _buildLight(font, accent);

  static ThemeData buildDark(BanglaFont font, AppAccentOption accent) =>
      _buildDark(font, accent);

  static ThemeData _buildLight(BanglaFont font, AppAccentOption accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accent.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: accent.primary,
        secondary: accent.light,
        surface: AppColors.lightCard,
      ),
      textTheme: font.textTheme().apply(
        bodyColor: AppColors.lightText,
        displayColor: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: accent.primary,
        unselectedItemColor: AppColors.lightSubText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData _buildDark(BanglaFont font, AppAccentOption accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accent.primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: accent.primary,
        secondary: accent.light,
        surface: AppColors.darkCard,
      ),
      textTheme: font.textTheme().apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: accent.primary,
        unselectedItemColor: AppColors.darkSubText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
