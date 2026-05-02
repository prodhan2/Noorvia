// ============================================================
//  scheduled_notification_service.dart
//
//  প্রতিদিন ২টি Islamic notification schedule করে:
//    • সকাল ৮:০০  — morning reminder
//    • রাত  ৯:০০  — night reminder
//
//  App বন্ধ থাকলেও কাজ করে।
//  flutter_local_notifications এর zonedSchedule ব্যবহার করে।
//  timezone package দিয়ে Asia/Dhaka timezone handle করা হয়।
//
//  scheduleDaily() → প্রতিদিনের জন্য schedule করে
//  cancel()        → সব scheduled notification বাতিল করে
// ============================================================

import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_model.dart';
import 'notification_cache_service.dart';

class ScheduledNotificationService {
  ScheduledNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _tzInitialised = false;

  // ── Notification IDs (fixed, যাতে reschedule এ replace হয়) ──
  static const int _morningId = 1001;
  static const int _nightId   = 1002;

  // ── Notification channel ──────────────────────────────────
  static const String _channelId   = 'islamic_scheduled';
  static const String _channelName = 'ইসলামিক দৈনিক বার্তা';
  static const String _channelDesc = 'সকাল ও রাতের ইসলামিক অনুপ্রেরণামূলক বার্তা';

  // ── Vibration pattern ─────────────────────────────────────
  static const List<int> _vibration = [0, 400, 200, 600];

  // ── SharedPreferences key — last scheduled date ───────────
  static const String _lastScheduledKey = 'scheduled_notif_last_date';

  // ── Timezone ──────────────────────────────────────────────
  static const String _timezone = 'Asia/Dhaka';

  // ─────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────

  /// App start এ একবার call করো।
  /// আজকের notification schedule না থাকলে schedule করে।
  static Future<void> init() async {
    await _initTimezone();
    await _initPlugin();
    await _ensureScheduled();
  }

  /// Force reschedule (settings থেকে বা debug এ কাজে লাগে)
  static Future<void> reschedule() async {
    await _initTimezone();
    await _initPlugin();
    await _scheduleToday();
  }

  /// সব scheduled notification বাতিল করো
  static Future<void> cancel() async {
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_nightId);
  }

  // ─────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────

  static Future<void> _initTimezone() async {
    if (_tzInitialised) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_timezone));
    _tzInitialised = true;
  }

  static Future<void> _initPlugin() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // POST_NOTIFICATIONS permission (Android 13+)
    await androidImpl?.requestNotificationsPermission();

    // SCHEDULE_EXACT_ALARM permission (Android 12+) — exact alarm এর জন্য দরকার
    await androidImpl?.requestExactAlarmsPermission();

    // Channel তৈরি করো
    final channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibration),
    );
    await androidImpl?.createNotificationChannel(channel);
  }

  /// আজকে schedule করা হয়েছে কিনা check করো, না হলে করো
  static Future<void> _ensureScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastScheduled = prefs.getString(_lastScheduledKey) ?? '';

    if (lastScheduled != today) {
      await _scheduleToday();
      await prefs.setString(_lastScheduledKey, today);
    }
  }

  /// আজকের সকাল ও রাতের notification schedule করো
  static Future<void> _scheduleToday() async {
    // Cache থেকে notification data লোড করো
    final notifications = await _loadNotifications();
    if (notifications.isEmpty) return;

    final morning = _pickRandom(notifications, seed: 'morning');
    final night   = _pickRandom(notifications, seed: 'night');

    // আজকের সকাল ৮:০০ এবং রাত ৯:০০
    final now = tz.TZDateTime.now(tz.local);

    final morningTime = _nextOccurrence(now, hour: 8,  minute: 0);
    final nightTime   = _nextOccurrence(now, hour: 21, minute: 0);

    // পুরনো schedule বাতিল করো
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_nightId);

    // সকালের notification
    await _scheduleOne(
      id: _morningId,
      notif: morning,
      scheduledTime: morningTime,
      prefix: '🌅 সকালের বার্তা',
    );

    // রাতের notification
    await _scheduleOne(
      id: _nightId,
      notif: night,
      scheduledTime: nightTime,
      prefix: '🌙 রাতের বার্তা',
    );
  }

  /// একটি notification schedule করো
  static Future<void> _scheduleOne({
    required int id,
    required IslamicNotification notif,
    required tz.TZDateTime scheduledTime,
    required String prefix,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        notif.message,
        contentTitle: '$prefix — ${notif.title}',
        summaryText: notif.reference.isNotEmpty ? notif.reference : null,
      ),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibration),
    );

    await _plugin.zonedSchedule(
      id,
      '$prefix — ${notif.title}',
      notif.message,
      scheduledTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // প্রতিদিন repeat
    );
  }

  // ─────────────────────────────────────────────────────────
  // Utility helpers
  // ─────────────────────────────────────────────────────────

  /// Cache বা fallback থেকে notification list লোড করো
  static Future<List<IslamicNotification>> _loadNotifications() async {
    try {
      final cached = await NotificationCacheService.loadFromCache();
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {}
    return NotificationCacheService.loadFallback();
  }

  /// Seed দিয়ে deterministic random pick (সকাল ও রাতে আলাদা)
  static IslamicNotification _pickRandom(
    List<IslamicNotification> list, {
    required String seed,
  }) {
    final today = _todayString();
    final hash  = (today + seed).codeUnits.fold(0, (a, b) => a + b);
    final index = hash % list.length;
    return list[index];
  }

  /// আজকের date string (YYYY-MM-DD)
  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// আজকের নির্দিষ্ট সময় — যদি পেরিয়ে গেছে তাহলে কাল
  static tz.TZDateTime _nextOccurrence(
    tz.TZDateTime now, {
    required int hour,
    required int minute,
  }) {
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // সময় পেরিয়ে গেলে পরের দিন
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
