// ============================================================
//  prayer_times_page.dart
//  Enhanced prayer times page with alarm integration
// ============================================================

import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:noorvia/core/localization/app_i18n.dart';
import 'package:provider/provider.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/prayer_alarm_provider.dart';
import '../../core/theme/app_theme.dart';
import 'prayer_alarm_settings_page.dart';
import 'home_screen_widgets_page.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Consumer2<PrayerProvider, PrayerAlarmProvider>(
        builder: (context, prayerProvider, alarmProvider, _) {
          if (prayerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final prayerTimes = prayerProvider.prayerTimes;
          if (prayerTimes == null) {
            return const Center(child: Text('নামাজের সময় লোড করা যায়নি'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── AppBar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'নামাজের সময়সূচি',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  prayerProvider.cityDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prayerProvider.banglaDate,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            if (prayerProvider.hijriDisplayDate.isNotEmpty)
                              Text(
                                prayerProvider.hijriDisplayDate,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    tooltip: AppI18n.current('হোম স্ক্রিন উইজেট'),
                    icon: const Icon(Icons.widgets_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreenWidgetsPage(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.alarm_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrayerAlarmSettingsPage(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () => prayerProvider.requestLocationAndFetch(),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Current Time & Next Prayer ────────
                      _CurrentTimeCard(
                        currentTime: prayerProvider.currentTime,
                        nextPrayer: prayerProvider.nextPrayer,
                        nextPrayerTime: prayerProvider.nextPrayerTime,
                        timeRemaining: prayerProvider.timeRemaining,
                        progress: prayerProvider.prayerProgress,
                      ),
                      const SizedBox(height: 16),

                      // ── Today's Prayer Times ──────────────
                      _TodayPrayerTimesCard(
                        prayerTimes: prayerTimes,
                        currentPrayer: prayerProvider.currentPrayer,
                        nextPrayer: prayerProvider.nextPrayer,
                        alarmSettings: alarmProvider.settings,
                      ),
                      const SizedBox(height: 16),

                      // ── Quick Actions ─────────────────────
                      _QuickActionsCard(
                        onAlarmSettings: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrayerAlarmSettingsPage(),
                            ),
                          );
                        },
                        onChangeLocation: () {
                          _showLocationPicker(context, prayerProvider);
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLocationPicker(BuildContext context, PrayerProvider provider) {
    final cities = {
      'Dhaka': 'ঢাকা',
      'Chittagong': 'চট্টগ্রাম',
      'Sylhet': 'সিলেট',
      'Rajshahi': 'রাজশাহী',
      'Khulna': 'খুলনা',
      'Barisal': 'বরিশাল',
      'Rangpur': 'রংপুর',
      'Mymensingh': 'ময়মনসিংহ',
    };

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'শহর নির্বাচন করুন',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...cities.entries.map((entry) => ListTile(
                  leading: const Icon(Icons.location_city_rounded,
                      color: AppColors.primary),
                  title: Text(entry.value),
                  onTap: () {
                    provider.selectCity(entry.key, 'BD');
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Current Time Card ────────────────────────────────────────
class _CurrentTimeCard extends StatelessWidget {
  final String currentTime;
  final String nextPrayer;
  final String nextPrayerTime;
  final String timeRemaining;
  final double progress;

  const _CurrentTimeCard({
    required this.currentTime,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.timeRemaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'বর্তমান সময়',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentTime,
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'পরবর্তী নামাজ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      nextPrayerTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nextPrayer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeRemaining,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today Prayer Times Card ──────────────────────────────────
class _TodayPrayerTimesCard extends StatelessWidget {
  final dynamic prayerTimes;
  final String currentPrayer;
  final String nextPrayer;
  final dynamic alarmSettings;

  const _TodayPrayerTimesCard({
    required this.prayerTimes,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.alarmSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    final prayers = [
      {'name': 'ফজর', 'nameEn': 'fajr', 'time': prayerTimes.fajr, 'icon': Icons.wb_twilight_rounded},
      {'name': 'সূর্যোদয়', 'nameEn': 'sunrise', 'time': prayerTimes.sunrise, 'icon': Icons.wb_sunny_rounded},
      {'name': 'যোহর', 'nameEn': 'dhuhr', 'time': prayerTimes.dhuhr, 'icon': Icons.wb_sunny_rounded},
      {'name': 'আসর', 'nameEn': 'asr', 'time': prayerTimes.asr, 'icon': Icons.wb_cloudy_rounded},
      {'name': 'মাগরিব', 'nameEn': 'maghrib', 'time': prayerTimes.maghrib, 'icon': Icons.nights_stay_rounded},
      {'name': 'ইশা', 'nameEn': 'isha', 'time': prayerTimes.isha, 'icon': Icons.dark_mode_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আজকের নামাজের সময়',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...prayers.map((prayer) {
            final isNext = prayer['name'] == nextPrayer;
            final isCurrent = prayer['name'] == currentPrayer;
            final hasAlarm = alarmSettings?.isAlarmEnabled(prayer['nameEn'] as String) ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isNext
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      prayer['icon'] as IconData,
                      color: isNext ? AppColors.primary : subColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      prayer['name'] as String,
                      style: TextStyle(
                        color: isNext ? AppColors.primary : textColor,
                        fontSize: 15,
                        fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasAlarm && prayer['name'] != 'সূর্যোদয়')
                    Icon(
                      Icons.alarm_rounded,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      size: 16,
                    ),
                  if (hasAlarm && prayer['name'] != 'সূর্যোদয়')
                    const SizedBox(width: 8),
                  Text(
                    _formatTime(prayer['time'] as String),
                    style: TextStyle(
                      color: isNext ? AppColors.primary : textColor,
                      fontSize: 15,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTime(String t) {
    if (t == '--:--') return t;
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final bh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final ampm = h >= 12 ? 'PM' : 'AM';
      return '${_bn(bh)}:${_bn(m)} $ampm';
    } catch (_) {
      return t;
    }
  }

  String _bn(dynamic n) {
    const e = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const b = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }
}

// ─── Quick Actions Card ───────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onAlarmSettings;
  final VoidCallback onChangeLocation;

  const _QuickActionsCard({
    required this.onAlarmSettings,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionButton(
            icon: Icons.alarm_rounded,
            label: 'আযান সেটিংস',
            onTap: onAlarmSettings,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.location_on_rounded,
            label: 'শহর পরিবর্তন করুন',
            onTap: onChangeLocation,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
