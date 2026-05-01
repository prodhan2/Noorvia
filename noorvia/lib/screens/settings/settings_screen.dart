import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════════
// SettingsScreen — Font, Accent Color, Theme
// ═══════════════════════════════════════════════════════════════
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final settings = context.watch<SettingsProvider>();
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Header ──────────────────────────────────────────
          _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'সেটিংস',
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // ── Theme section ────────────────────────────────────
          _CardSection(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                    label: 'থিম', icon: Icons.brightness_6_rounded, isDark: isDark),
                const SizedBox(height: 12),
                _ThemeToggleRow(isDark: isDark, textColor: textColor, subColor: subColor),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Accent color section ─────────────────────────────
          _CardSection(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                    label: 'অ্যাকসেন্ট রঙ', icon: Icons.palette_rounded, isDark: isDark),
                const SizedBox(height: 14),
                _AccentColorPicker(
                  selected: settings.accent,
                  isDark: isDark,
                  textColor: textColor,
                  onSelect: (opt) => settings.setAccent(opt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Font section ─────────────────────────────────────
          _CardSection(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                    label: 'বাংলা ফন্ট', icon: Icons.font_download_rounded, isDark: isDark),
                const SizedBox(height: 4),
                Text(
                  'পুরো অ্যাপে এই ফন্ট ব্যবহার হবে',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12, color: subColor),
                ),
                const SizedBox(height: 14),
                _FontPicker(
                  selected: settings.banglaFont,
                  isDark: isDark,
                  accent: settings.accent,
                  textColor: textColor,
                  onSelect: (font) => settings.setFont(font),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── App info ─────────────────────────────────────────
          _CardSection(
            isDark: isDark,
            cardBg: cardBg,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.info_outline_rounded,
                  label: 'সংস্করণ',
                  value: '১.০.০',
                  isDark: isDark,
                  textColor: textColor,
                  subColor: subColor,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withValues(alpha: 0.15)),
                _InfoRow(
                  icon: Icons.mosque_outlined,
                  label: 'অ্যাপের নাম',
                  value: 'নূরভিয়া',
                  isDark: isDark,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Theme toggle row
// ─────────────────────────────────────────────────────────────
class _ThemeToggleRow extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final Color subColor;

  const _ThemeToggleRow({
    required this.isDark,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Column(
      children: [
        // Auto mode toggle
        _ToggleRow(
          icon: Icons.auto_mode_rounded,
          label: 'অটো মোড',
          subtitle: 'সময় অনুযায়ী স্বয়ংক্রিয় (সকাল ৬টা–সন্ধ্যা ৬টা)',
          value: theme.autoMode,
          isDark: isDark,
          textColor: textColor,
          subColor: subColor,
          onChanged: (v) {
            if (v) {
              theme.enableAutoMode();
            } else {
              theme.toggleTheme();
            }
          },
        ),
        const SizedBox(height: 8),
        // Manual dark mode toggle
        AnimatedOpacity(
          opacity: theme.autoMode ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _ToggleRow(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            label: isDark ? 'ডার্ক মোড' : 'লাইট মোড',
            subtitle: theme.autoMode ? 'অটো মোড চালু আছে' : 'ম্যানুয়ালি নিয়ন্ত্রণ করুন',
            value: isDark,
            isDark: isDark,
            textColor: textColor,
            subColor: subColor,
            onChanged: theme.autoMode ? null : (_) => theme.toggleTheme(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Accent color picker
// ─────────────────────────────────────────────────────────────
class _AccentColorPicker extends StatelessWidget {
  final AppAccentOption selected;
  final bool isDark;
  final Color textColor;
  final ValueChanged<AppAccentOption> onSelect;

  const _AccentColorPicker({
    required this.selected,
    required this.isDark,
    required this.textColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kAccentOptions.map((opt) {
        final isSelected = opt.key == selected.key;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? opt.primary.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? opt.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: opt.primary,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: opt.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  opt.label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? opt.primary : textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Font picker
// ─────────────────────────────────────────────────────────────
class _FontPicker extends StatelessWidget {
  final BanglaFont selected;
  final bool isDark;
  final AppAccentOption accent;
  final Color textColor;
  final ValueChanged<BanglaFont> onSelect;

  const _FontPicker({
    required this.selected,
    required this.isDark,
    required this.accent,
    required this.textColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: BanglaFont.values.map((font) {
        final isSelected = font == selected;
        return GestureDetector(
          onTap: () => onSelect(font),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.primary.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Font name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        font.displayName,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? accent.primary : textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Preview in the actual font
                      Text(
                        font.sampleText,
                        style: font.style(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? accent.primary
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                // Selected indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? accent.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? accent.primary
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;

  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Widget child;

  const _CardSection({
    required this.isDark,
    required this.cardBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final ValueChanged<bool>? onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color textColor;
  final Color subColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}
