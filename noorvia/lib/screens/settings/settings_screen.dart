// ============================================================
//  settings_screen.dart  —  থিম, ফন্ট ও ডিসপ্লে সেটিংস
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/custom_font_loader.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark      = context.watch<ThemeProvider>().isDark;
    final settings    = context.watch<SettingsProvider>();
    final bg          = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final textColor   = isDark ? AppColors.darkText     : AppColors.lightText;
    final subColor    = isDark ? AppColors.darkSubText  : AppColors.lightSubText;
    final accent      = settings.accent.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'সেটিংস',
                style: settings.banglaFont.style(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),

            // ── Profile card ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('অতিথি ব্যবহারকারী',
                              style: settings.banglaFont.style(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('লগইন করুন বা অ্যাকাউন্ট তৈরি করুন',
                              style: settings.banglaFont.style(
                                  fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ════════════════════════════════════════════════
            // SECTION 1 — থিম
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'থিম', textColor: subColor),
            _Card(
              isDark: isDark,
              children: [
                // Dark mode toggle
                _SettingsTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  label: 'ডার্ক মোড',
                  textColor: textColor,
                  accent: accent,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) =>
                        context.read<ThemeProvider>().toggleTheme(),
                    activeColor: accent,
                  ),
                ),
                _Divider(isDark: isDark),
                // Auto theme
                _SettingsTile(
                  icon: Icons.brightness_auto_rounded,
                  label: 'অটো থিম (সময় অনুযায়ী)',
                  textColor: textColor,
                  accent: accent,
                  trailing: Switch(
                    value: context.watch<ThemeProvider>().autoMode,
                    onChanged: (v) {
                      if (v) {
                        context.read<ThemeProvider>().enableAutoMode();
                      } else {
                        context.read<ThemeProvider>().toggleTheme();
                      }
                    },
                    activeColor: accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // SECTION 2 — অ্যাকসেন্ট কালার
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'অ্যাকসেন্ট কালার', textColor: subColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AccentColorPicker(
                isDark: isDark,
                settings: settings,
              ),
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // SECTION 3 — বাংলা ফন্ট
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'বাংলা ফন্ট', textColor: subColor),
            _Card(
              isDark: isDark,
              children: [
                // Bangla font dropdown
                _DropdownTile<BanglaFont>(
                  icon: Icons.font_download_outlined,
                  label: 'ফন্ট নির্বাচন',
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  value: settings.banglaFont,
                  items: BanglaFont.values,
                  itemLabel: (f) => f.displayName,
                  onChanged: (f) =>
                      context.read<SettingsProvider>().setFont(f!),
                ),
                _Divider(isDark: isDark),
                // Preview
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('প্রিভিউ',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 11,
                              color: subColor,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'আল্লাহু আকবার — সুবহানাল্লাহ — আলহামদুলিল্লাহ',
                        style: settings.banglaFont.style(
                          fontSize: settings.fontSize,
                          fontWeight: settings.fontWeight,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _Divider(isDark: isDark),
                // Font size slider
                _SliderTile(
                  icon: Icons.format_size_rounded,
                  label: 'বাংলা ফন্ট সাইজ',
                  value: settings.fontSize,
                  min: 10,
                  max: 26,
                  divisions: 16,
                  displayValue: settings.fontSize.toStringAsFixed(0),
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) =>
                      context.read<SettingsProvider>().setFontSize(v),
                ),
                _Divider(isDark: isDark),
                // Font weight
                _DropdownTile<FontWeight>(
                  icon: Icons.line_weight_rounded,
                  label: 'ফন্ট ওজন',
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  value: settings.fontWeight,
                  items: const [
                    FontWeight.w300,
                    FontWeight.w400,
                    FontWeight.w500,
                    FontWeight.w600,
                    FontWeight.w700,
                  ],
                  itemLabel: (w) {
                    switch (w) {
                      case FontWeight.w300: return 'লাইট (300)';
                      case FontWeight.w400: return 'রেগুলার (400)';
                      case FontWeight.w500: return 'মিডিয়াম (500)';
                      case FontWeight.w600: return 'সেমিবোল্ড (600)';
                      case FontWeight.w700: return 'বোল্ড (700)';
                      default:              return 'মিডিয়াম';
                    }
                  },
                  onChanged: (w) =>
                      context.read<SettingsProvider>().setFontWeight(w!),
                ),
                _Divider(isDark: isDark),
                // Line height
                _SliderTile(
                  icon: Icons.format_line_spacing_rounded,
                  label: 'লাইন স্পেসিং',
                  value: settings.lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  displayValue: settings.lineHeight.toStringAsFixed(1),
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) =>
                      context.read<SettingsProvider>().setLineHeight(v),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // SECTION 3.5 — কাস্টম বাংলা ফন্ট (GitHub)
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'কাস্টম বাংলা ফন্ট', textColor: subColor),
            _Card(
              isDark: isDark,
              children: [
                if (settings.isLoadingCustomFonts)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: accent),
                          const SizedBox(height: 12),
                          Text('ফন্ট লোড হচ্ছে...',
                              style: settings.banglaFont.style(
                                  fontSize: 13, color: subColor)),
                        ],
                      ),
                    ),
                  )
                else if (settings.customFonts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 40, color: subColor),
                        const SizedBox(height: 8),
                        Text('কাস্টম ফন্ট লোড করা যায়নি',
                            style: settings.banglaFont.style(
                                fontSize: 13, color: subColor)),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              context.read<SettingsProvider>().refreshCustomFonts(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('আবার চেষ্টা করুন',
                              style: settings.banglaFont.style(fontSize: 13)),
                          style: TextButton.styleFrom(foregroundColor: accent),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Custom font dropdown
                  _CustomFontDropdownTile(
                    icon: Icons.font_download_rounded,
                    label: 'কাস্টম ফন্ট নির্বাচন',
                    textColor: textColor,
                    accent: accent,
                    isDark: isDark,
                    settings: settings,
                  ),
                  if (settings.selectedCustomFont != null) ...[
                    _Divider(isDark: isDark),
                    // Preview
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('প্রিভিউ',
                                  style: GoogleFonts.hindSiliguri(
                                      fontSize: 11,
                                      color: subColor,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(settings.selectedCustomFont!.displayName,
                                  style: GoogleFonts.hindSiliguri(
                                      fontSize: 11,
                                      color: accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'আল্লাহু আকবার — সুবহানাল্লাহ — আলহামদুলিল্লাহ',
                            style: settings.getCurrentFontStyle(
                              fontSize: settings.fontSize,
                              fontWeight: settings.fontWeight,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Divider(isDark: isDark),
                    // Clear custom font button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.read<SettingsProvider>().setFont(settings.banglaFont),
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          label: Text('বিল্ট-ইন ফন্টে ফিরে যান',
                              style: settings.banglaFont.style(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // SECTION 4 — আরবি ফন্ট
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'আরবি ফন্ট', textColor: subColor),
            _Card(
              isDark: isDark,
              children: [
                // Arabic font dropdown
                _DropdownTile<ArabicFont>(
                  icon: Icons.translate_rounded,
                  label: 'আরবি ফন্ট নির্বাচন',
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  value: settings.arabicFont,
                  items: ArabicFont.values,
                  itemLabel: (f) => f.displayName,
                  onChanged: (f) =>
                      context.read<SettingsProvider>().setArabicFont(f!),
                ),
                _Divider(isDark: isDark),
                // Arabic preview
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('প্রিভিউ',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 11,
                              color: subColor,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        style: settings.arabicFont.style(
                          fontSize: settings.arabicFontSize,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                        textDirection: TextDirection.rtl,
                        style: settings.arabicFont.style(
                          fontSize: settings.arabicFontSize,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _Divider(isDark: isDark),
                // Arabic font size slider
                _SliderTile(
                  icon: Icons.format_size_rounded,
                  label: 'আরবি ফন্ট সাইজ',
                  value: settings.arabicFontSize,
                  min: 14,
                  max: 36,
                  divisions: 22,
                  displayValue: settings.arabicFontSize.toStringAsFixed(0),
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) =>
                      context.read<SettingsProvider>().setArabicFontSize(v),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // SECTION 5 — ডিসপ্লে
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'ডিসপ্লে', textColor: subColor),
            _Card(
              isDark: isDark,
              children: [
                // Text scale
                _SliderTile(
                  icon: Icons.text_fields_rounded,
                  label: 'টেক্সট স্কেল',
                  value: settings.textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  displayValue: '${(settings.textScale * 100).toInt()}%',
                  textColor: textColor,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) =>
                      context.read<SettingsProvider>().setTextScale(v),
                ),
                _Divider(isDark: isDark),
                // Colored cards
                _SettingsTile(
                  icon: Icons.style_rounded,
                  label: 'কালারড কার্ড',
                  textColor: textColor,
                  accent: accent,
                  trailing: Switch(
                    value: settings.coloredCards,
                    onChanged: (v) =>
                        context.read<SettingsProvider>().setColoredCards(v),
                    activeColor: accent,
                  ),
                ),
                _Divider(isDark: isDark),
                // Animations
                _SettingsTile(
                  icon: Icons.animation_rounded,
                  label: 'অ্যানিমেশন',
                  textColor: textColor,
                  accent: accent,
                  trailing: Switch(
                    value: settings.useAnimations,
                    onChanged: (v) =>
                        context.read<SettingsProvider>().setUseAnimations(v),
                    activeColor: accent,
                  ),
                ),
                _Divider(isDark: isDark),
                // Compact mode
                _SettingsTile(
                  icon: Icons.compress_rounded,
                  label: 'কম্প্যাক্ট মোড',
                  textColor: textColor,
                  accent: accent,
                  trailing: Switch(
                    value: settings.compactMode,
                    onChanged: (v) =>
                        context.read<SettingsProvider>().setCompactMode(v),
                    activeColor: accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════════════
            // SECTION 6 — অ্যাপ সম্পর্কে
            // ════════════════════════════════════════════════
            _SectionHeader(label: 'অ্যাপ সম্পর্কে', textColor: subColor),
            _Card(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'অ্যাপ সংস্করণ',
                  textColor: textColor,
                  accent: accent,
                  trailing: Text('1.0.0',
                      style: GoogleFonts.hindSiliguri(
                          color: subColor, fontSize: 13)),
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'গোপনীয়তা নীতি',
                  textColor: textColor,
                  accent: accent,
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 14, color: accent),
                  onTap: () {},
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  label: 'অ্যাপ রেট করুন',
                  textColor: textColor,
                  accent: accent,
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 14, color: accent),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Reset button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, settings),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text('ডিফল্টে ফিরে যান',
                      style: settings.banglaFont
                          .style(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('রিসেট করবেন?',
            style: settings.banglaFont
                .style(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('সব সেটিংস ডিফল্টে ফিরে যাবে।',
            style: settings.banglaFont.style(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('বাতিল',
                style: settings.banglaFont.style(fontSize: 14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              settings.resetAll();
            },
            child: Text('রিসেট',
                style: settings.banglaFont.style(
                    fontSize: 14, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Accent Color Picker
// ════════════════════════════════════════════════════════════
class _AccentColorPicker extends StatelessWidget {
  final bool isDark;
  final SettingsProvider settings;

  const _AccentColorPicker({required this.isDark, required this.settings});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kAccentOptions.map((option) {
          final isSelected = settings.accent.key == option.key;
          return GestureDetector(
            onTap: () =>
                context.read<SettingsProvider>().setAccent(option),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: option.primary,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: option.primary.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  option.label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkSubText
                        : AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Reusable widgets
// ════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionHeader({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _Card({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color accent;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.accent,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: accent),
      ),
      title: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing,
    );
  }
}

// ── Dropdown tile ─────────────────────────────────────────────
class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color accent;
  final bool isDark;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.accent,
    required this.isDark,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: accent, size: 20),
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabel(item),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Slider tile ───────────────────────────────────────────────
class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final Color textColor;
  final Color accent;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.textColor,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValue,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: accent.withValues(alpha: 0.2),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

// ── Custom Font Dropdown Tile ─────────────────────────────────
class _CustomFontDropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color accent;
  final bool isDark;
  final SettingsProvider settings;

  const _CustomFontDropdownTile({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.accent,
    required this.isDark,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          DropdownButton<CustomBanglaFont?>(
            value: settings.selectedCustomFont,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: accent, size: 20),
            hint: Text(
              'নির্বাচন করুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            items: [
              // None option
              DropdownMenuItem<CustomBanglaFont?>(
                value: null,
                child: Text(
                  'কোনটি নয়',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              // Custom fonts
              ...settings.customFonts.map((font) => DropdownMenuItem<CustomBanglaFont?>(
                    value: font,
                    child: Text(
                      font.displayName,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  )),
            ],
            onChanged: (font) {
              if (font == null) {
                context.read<SettingsProvider>().setFont(settings.banglaFont);
              } else {
                context.read<SettingsProvider>().setCustomFont(font);
              }
            },
          ),
        ],
      ),
    );
  }
}
