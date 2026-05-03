// ============================================================
//  prayer_alarm_settings_page.dart
//  UI for configuring prayer alarms with individual customization
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/prayer_alarm_provider.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/prayer_alarm_settings.dart';

class PrayerAlarmSettingsPage extends StatefulWidget {
  const PrayerAlarmSettingsPage({super.key});

  @override
  State<PrayerAlarmSettingsPage> createState() => _PrayerAlarmSettingsPageState();
}

class _PrayerAlarmSettingsPageState extends State<PrayerAlarmSettingsPage> {
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
      body: Consumer2<PrayerAlarmProvider, PrayerProvider>(
        builder: (context, alarmProvider, prayerProvider, _) {
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
              // ── AppBar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 120,
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
                              'নামাজের আযান সেটিংস',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'প্রতিটি নামাজের জন্য আলাদা সেটিংস করুন',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
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
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Prayer Alarms ─────────────────────
                      _PrayerAlarmCard(
                        prayerName: 'ফজর',
                        prayerNameEn: 'fajr',
                        prayerTime: prayerTimes?.fajr ?? '--:--',
                        icon: Icons.wb_twilight_rounded,
                        enabled: settings.fajrEnabled,
                        preAlarmMinutes: settings.fajrPreAlarm,
                        onToggle: (val) => alarmProvider.togglePrayerAlarm('ফজর', val),
                        onPreAlarmChanged: (val) =>
                            alarmProvider.updatePreAlarmMinutes('ফজর', val),
                        onSchedule: _scheduleAlarms,
                      ),
                      const SizedBox(height: 12),

                      _PrayerAlarmCard(
                        prayerName: 'যোহর',
                        prayerNameEn: 'dhuhr',
                        prayerTime: prayerTimes?.dhuhr ?? '--:--',
                        icon: Icons.wb_sunny_rounded,
                        enabled: settings.dhuhrEnabled,
                        preAlarmMinutes: settings.dhuhrPreAlarm,
                        onToggle: (val) => alarmProvider.togglePrayerAlarm('যোহর', val),
                        onPreAlarmChanged: (val) =>
                            alarmProvider.updatePreAlarmMinutes('যোহর', val),
                        onSchedule: _scheduleAlarms,
                      ),
                      const SizedBox(height: 12),

                      _PrayerAlarmCard(
                        prayerName: 'আসর',
                        prayerNameEn: 'asr',
                        prayerTime: prayerTimes?.asr ?? '--:--',
                        icon: Icons.wb_cloudy_rounded,
                        enabled: settings.asrEnabled,
                        preAlarmMinutes: settings.asrPreAlarm,
                        onToggle: (val) => alarmProvider.togglePrayerAlarm('আসর', val),
                        onPreAlarmChanged: (val) =>
                            alarmProvider.updatePreAlarmMinutes('আসর', val),
                        onSchedule: _scheduleAlarms,
                      ),
                      const SizedBox(height: 12),

                      _PrayerAlarmCard(
                        prayerName: 'মাগরিব',
                        prayerNameEn: 'maghrib',
                        prayerTime: prayerTimes?.maghrib ?? '--:--',
                        icon: Icons.nights_stay_rounded,
                        enabled: settings.maghribEnabled,
                        preAlarmMinutes: settings.maghribPreAlarm,
                        onToggle: (val) => alarmProvider.togglePrayerAlarm('মাগরিব', val),
                        onPreAlarmChanged: (val) =>
                            alarmProvider.updatePreAlarmMinutes('মাগরিব', val),
                        onSchedule: _scheduleAlarms,
                      ),
                      const SizedBox(height: 12),

                      _PrayerAlarmCard(
                        prayerName: 'ইশা',
                        prayerNameEn: 'isha',
                        prayerTime: prayerTimes?.isha ?? '--:--',
                        icon: Icons.dark_mode_rounded,
                        enabled: settings.ishaEnabled,
                        preAlarmMinutes: settings.ishaPreAlarm,
                        onToggle: (val) => alarmProvider.togglePrayerAlarm('ইশা', val),
                        onPreAlarmChanged: (val) =>
                            alarmProvider.updatePreAlarmMinutes('ইশা', val),
                        onSchedule: _scheduleAlarms,
                      ),
                      const SizedBox(height: 24),

                      // ── Azan Selection ────────────────────
                      _AzanSelectionCard(
                        selectedAzan: settings.selectedAzanName,
                        onSelect: () => _showAzanPicker(context, alarmProvider),
                        onTest: () => alarmProvider.playTestAzan(),
                        onStop: () => alarmProvider.stopAzan(),
                      ),
                      const SizedBox(height: 16),

                      // ── Volume Control ────────────────────
                      _VolumeControlCard(
                        volume: settings.volume,
                        onChanged: (val) => alarmProvider.updateVolume(val),
                      ),
                      const SizedBox(height: 16),

                      // ── Vibration Toggle ──────────────────
                      _VibrationToggleCard(
                        enabled: settings.vibrationEnabled,
                        onToggle: (val) => alarmProvider.toggleVibration(val),
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

  void _showAzanPicker(BuildContext context, PrayerAlarmProvider provider) {
    final azanList = OnlineAzanList.getAzanList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'আযান নির্বাচন করুন',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${azanList.length} টি আযান উপলব্ধ (islamcan.com)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Azan List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: azanList.length,
                  itemBuilder: (context, index) {
                    final azan = azanList[index];
                    final url = azan['url']!;
                    final name = azan['name']!;
                    final isSelected = provider.settings?.selectedAzanPath == url;
                    final isLoading = provider.azanLoadingStatus[url] ?? false;
                    final isCached = provider.azanCachedStatus[url] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          isLoading
                              ? 'লোড হচ্ছে...'
                              : isCached
                                  ? 'প্রস্তুত ✓'
                                  : 'অনলাইন',
                          style: TextStyle(
                            fontSize: 11,
                            color: isLoading
                                ? Colors.orange
                                : isCached
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                        onTap: () {
                          provider.selectAzan(url, name);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Prayer Alarm Card ────────────────────────────────────────
class _PrayerAlarmCard extends StatelessWidget {
  final String prayerName;
  final String prayerNameEn;
  final String prayerTime;
  final IconData icon;
  final bool enabled;
  final int preAlarmMinutes;
  final Function(bool) onToggle;
  final Function(int) onPreAlarmChanged;
  final VoidCallback onSchedule;

  const _PrayerAlarmCard({
    required this.prayerName,
    required this.prayerNameEn,
    required this.prayerTime,
    required this.icon,
    required this.enabled,
    required this.preAlarmMinutes,
    required this.onToggle,
    required this.onPreAlarmChanged,
    required this.onSchedule,
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayerName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTime(prayerTime),
                      style: TextStyle(
                        color: subColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (val) {
                  onToggle(val);
                  if (val) onSchedule();
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.alarm_rounded, color: subColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'আযান বাজবে:',
                  style: TextStyle(color: subColor, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$preAlarmMinutes মিনিট আগে',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: preAlarmMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12,
                    label: '$preAlarmMinutes মিনিট',
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      onPreAlarmChanged(val.toInt());
                      onSchedule();
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('০ মিনিট', style: TextStyle(color: subColor, fontSize: 11)),
                Text('৬০ মিনিট', style: TextStyle(color: subColor, fontSize: 11)),
              ],
            ),
          ],
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

// ─── Azan Selection Card ──────────────────────────────────────
class _AzanSelectionCard extends StatelessWidget {
  final String selectedAzan;
  final VoidCallback onSelect;
  final VoidCallback onTest;
  final VoidCallback onStop;

  const _AzanSelectionCard({
    required this.selectedAzan,
    required this.onSelect,
    required this.onTest,
    required this.onStop,
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
        borderRadius: BorderRadius.circular(16),
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
            children: [
              const Icon(Icons.music_note_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'আযান নির্বাচন',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedAzan,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('টেস্ট করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('বন্ধ করুন'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Volume Control Card ──────────────────────────────────────
class _VolumeControlCard extends StatelessWidget {
  final double volume;
  final Function(double) onChanged;

  const _VolumeControlCard({
    required this.volume,
    required this.onChanged,
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
        borderRadius: BorderRadius.circular(16),
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
            children: [
              const Icon(Icons.volume_up_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'ভলিউম',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(volume * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Vibration Toggle Card ────────────────────────────────────
class _VibrationToggleCard extends StatelessWidget {
  final bool enabled;
  final Function(bool) onToggle;

  const _VibrationToggleCard({
    required this.enabled,
    required this.onToggle,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.vibration_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ভাইব্রেশন',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'আযানের সাথে ভাইব্রেশন চালু করুন',
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
