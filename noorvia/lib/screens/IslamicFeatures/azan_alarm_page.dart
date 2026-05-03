// ============================================================
//  azan_alarm_page.dart
//  আযান অ্যালার্ম পেজ - সম্পূর্ণ আলাদা পেজ
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/prayer_alarm_provider.dart';
import '../../core/theme/app_theme.dart';
import 'prayer_alarm_settings_page.dart';

class AzanAlarmPage extends StatefulWidget {
  const AzanAlarmPage({super.key});

  @override
  State<AzanAlarmPage> createState() => _AzanAlarmPageState();
}

class _AzanAlarmPageState extends State<AzanAlarmPage> {
  @override
  void initState() {
    super.initState();
    // Schedule alarms when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleAlarms();
    });
  }

  Future<void> _scheduleAlarms() async {
    final prayerProvider = context.read<PrayerProvider>();
    final alarmProvider = context.read<PrayerAlarmProvider>();
    
    if (prayerProvider.prayerTimes != null) {
      await alarmProvider.scheduleAlarms({
        'fajr': prayerProvider.prayerTimes!.fajr,
        'dhuhr': prayerProvider.prayerTimes!.dhuhr,
        'asr': prayerProvider.prayerTimes!.asr,
        'maghrib': prayerProvider.prayerTimes!.maghrib,
        'isha': prayerProvider.prayerTimes!.isha,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Consumer2<PrayerProvider, PrayerAlarmProvider>(
        builder: (context, prayerProvider, alarmProvider, _) {
          if (alarmProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = alarmProvider.settings;
          if (settings == null) {
            return const Center(child: Text('সেটিংস লোড করা যায়নি'));
          }

          final prayerTimes = prayerProvider.prayerTimes;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── AppBar (Small & Fixed) ──────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 2,
                backgroundColor: AppColors.primary,
                title: const Row(
                  children: [
                    Icon(Icons.alarm_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'আযান অ্যালার্ম',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded,
                        color: Colors.white, size: 22),
                    tooltip: 'বিস্তারিত সেটিংস',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrayerAlarmSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Location & Date Info Card ─────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      prayerProvider.cityDisplayName,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkText
                                            : AppColors.lightText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      prayerProvider.banglaDate,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkText
                                            : AppColors.lightText,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Quick Status Card ─────────────────
                      _QuickStatusCard(
                        settings: settings,
                        prayerTimes: prayerTimes,
                      ),
                      const SizedBox(height: 16),

                      // ── Today's Prayer Alarms ─────────────
                      _TodayAlarmsCard(
                        settings: settings,
                        prayerTimes: prayerTimes,
                        onToggle: (prayer, enabled) async {
                          await alarmProvider.togglePrayerAlarm(prayer, enabled);
                          await _scheduleAlarms();
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Quick Actions ─────────────────────
                      _QuickActionsCard(
                        onAdvancedSettings: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrayerAlarmSettingsPage(),
                            ),
                          );
                        },
                        onTestAzan: () => alarmProvider.playTestAzan(),
                        onStopAzan: () => alarmProvider.stopAzan(),
                      ),
                      const SizedBox(height: 16),

                      // ── Current Settings Summary ──────────
                      _SettingsSummaryCard(
                        settings: settings,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrayerAlarmSettingsPage(),
                            ),
                          );
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
}

// ─── Quick Status Card ────────────────────────────────────────
class _QuickStatusCard extends StatelessWidget {
  final dynamic settings;
  final dynamic prayerTimes;

  const _QuickStatusCard({
    required this.settings,
    required this.prayerTimes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    // Count enabled alarms
    int enabledCount = 0;
    if (settings.fajrEnabled) enabledCount++;
    if (settings.dhuhrEnabled) enabledCount++;
    if (settings.asrEnabled) enabledCount++;
    if (settings.maghribEnabled) enabledCount++;
    if (settings.ishaEnabled) enabledCount++;

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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alarm_on_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$enabledCount টি আযান চালু আছে',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enabledCount == 5
                      ? 'সব নামাজের আযান চালু আছে'
                      : enabledCount == 0
                          ? 'কোনো আযান চালু নেই'
                          : '${5 - enabledCount} টি আযান বন্ধ আছে',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            enabledCount > 0
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: enabledCount > 0 ? Colors.green : Colors.orange,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// ─── Today's Alarms Card ──────────────────────────────────────
class _TodayAlarmsCard extends StatelessWidget {
  final dynamic settings;
  final dynamic prayerTimes;
  final Function(String, bool) onToggle;

  const _TodayAlarmsCard({
    required this.settings,
    required this.prayerTimes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    final prayers = [
      {
        'name': 'ফজর',
        'nameEn': 'fajr',
        'time': prayerTimes?.fajr ?? '--:--',
        'icon': Icons.wb_twilight_rounded,
        'enabled': settings.fajrEnabled,
        'preAlarm': settings.fajrPreAlarm,
      },
      {
        'name': 'যোহর',
        'nameEn': 'dhuhr',
        'time': prayerTimes?.dhuhr ?? '--:--',
        'icon': Icons.wb_sunny_rounded,
        'enabled': settings.dhuhrEnabled,
        'preAlarm': settings.dhuhrPreAlarm,
      },
      {
        'name': 'আসর',
        'nameEn': 'asr',
        'time': prayerTimes?.asr ?? '--:--',
        'icon': Icons.wb_cloudy_rounded,
        'enabled': settings.asrEnabled,
        'preAlarm': settings.asrPreAlarm,
      },
      {
        'name': 'মাগরিব',
        'nameEn': 'maghrib',
        'time': prayerTimes?.maghrib ?? '--:--',
        'icon': Icons.nights_stay_rounded,
        'enabled': settings.maghribEnabled,
        'preAlarm': settings.maghribPreAlarm,
      },
      {
        'name': 'ইশা',
        'nameEn': 'isha',
        'time': prayerTimes?.isha ?? '--:--',
        'icon': Icons.dark_mode_rounded,
        'enabled': settings.ishaEnabled,
        'preAlarm': settings.ishaPreAlarm,
      },
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
            'আজকের নামাজের আযান',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...prayers.map((prayer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlarmRow(
                name: prayer['name'] as String,
                time: _formatTime(prayer['time'] as String),
                icon: prayer['icon'] as IconData,
                enabled: prayer['enabled'] as bool,
                preAlarm: prayer['preAlarm'] as int,
                onToggle: (val) => onToggle(prayer['name'] as String, val),
                textColor: textColor,
                subColor: subColor,
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

class _AlarmRow extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final bool enabled;
  final int preAlarm;
  final Function(bool) onToggle;
  final Color textColor;
  final Color subColor;

  const _AlarmRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.enabled,
    required this.preAlarm,
    required this.onToggle,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primary : subColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? '$time ($preAlarm মিনিট আগে)'
                      : time,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Card ───────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onAdvancedSettings;
  final VoidCallback onTestAzan;
  final VoidCallback onStopAzan;

  const _QuickActionsCard({
    required this.onAdvancedSettings,
    required this.onTestAzan,
    required this.onStopAzan,
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
            icon: Icons.settings_rounded,
            label: 'বিস্তারিত সেটিংস',
            subtitle: 'প্রতিটি নামাজের জন্য আলাদা সেটিংস',
            color: AppColors.primary,
            onTap: onAdvancedSettings,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'আযান টেস্ট করুন',
                  color: Colors.green,
                  onTap: onTestAzan,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.stop_rounded,
                  label: 'বন্ধ করুন',
                  color: Colors.red,
                  onTap: onStopAzan,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: compact
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: color, size: 16),
                ],
              ),
      ),
    );
  }
}

// ─── Settings Summary Card ────────────────────────────────────
class _SettingsSummaryCard extends StatelessWidget {
  final dynamic settings;
  final VoidCallback onEdit;

  const _SettingsSummaryCard({
    required this.settings,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'বর্তমান সেটিংস',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('পরিবর্তন করুন'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.music_note_rounded,
            label: 'নির্বাচিত আযান',
            value: settings.selectedAzanName,
            textColor: textColor,
            subColor: subColor,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.volume_up_rounded,
            label: 'ভলিউম',
            value: '${(settings.volume * 100).toInt()}%',
            textColor: textColor,
            subColor: subColor,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.vibration_rounded,
            label: 'ভাইব্রেশন',
            value: settings.vibrationEnabled ? 'চালু' : 'বন্ধ',
            textColor: textColor,
            subColor: subColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color subColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: subColor,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
