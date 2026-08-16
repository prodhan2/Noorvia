// ============================================================
//  prayer_times_navigation.dart
//  Helper widgets for navigating to prayer times and alarm pages
// ============================================================

import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:muslim_view/core/localization/app_i18n.dart';
import 'prayer_times_page.dart';
import 'prayer_alarm_settings_page.dart';

/// Navigate to Prayer Times Page
void navigateToPrayerTimes(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PrayerTimesPage()),
  );
}

/// Navigate to Prayer Alarm Settings Page
void navigateToPrayerAlarmSettings(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PrayerAlarmSettingsPage()),
  );
}

/// Prayer Times Card Widget - Use this in your dashboard
class PrayerTimesCard extends StatelessWidget {
  final VoidCallback? onTap;

  const PrayerTimesCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap ?? () => navigateToPrayerTimes(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'নামাজের সময়সূচি',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'আজকের নামাজের সময় দেখুন এবং আযান সেট করুন',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prayer Alarm Card Widget - Use this in your dashboard
class PrayerAlarmCard extends StatelessWidget {
  final VoidCallback? onTap;

  const PrayerAlarmCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap ?? () => navigateToPrayerAlarmSettings(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal,
                Colors.teal.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'আযান সেটিংস',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'প্রতিটি নামাজের জন্য আযান এবং রিমাইন্ডার সেট করুন',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List Tile for Prayer Times - Use in drawer or settings
class PrayerTimesListTile extends StatelessWidget {
  const PrayerTimesListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time_rounded),
      title: const Text('নামাজের সময়সূচি'),
      subtitle: const Text('আজকের নামাজের সময় দেখুন'),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () => navigateToPrayerTimes(context),
    );
  }
}

/// List Tile for Prayer Alarm Settings - Use in drawer or settings
class PrayerAlarmListTile extends StatelessWidget {
  const PrayerAlarmListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm_rounded),
      title: const Text('আযান সেটিংস'),
      subtitle: const Text('নামাজের আযান কনফিগার করুন'),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () => navigateToPrayerAlarmSettings(context),
    );
  }
}

/// Icon Button for Prayer Times - Use in app bar
class PrayerTimesIconButton extends StatelessWidget {
  const PrayerTimesIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.access_time_rounded),
      tooltip: AppI18n.current('নামাজের সময়'),
      onPressed: () => navigateToPrayerTimes(context),
    );
  }
}

/// Icon Button for Prayer Alarm - Use in app bar
class PrayerAlarmIconButton extends StatelessWidget {
  const PrayerAlarmIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.alarm_rounded),
      tooltip: AppI18n.current('আযান সেটিংস'),
      onPressed: () => navigateToPrayerAlarmSettings(context),
    );
  }
}
