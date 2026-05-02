// ============================================================
//  local_notification_service.dart
//  Wraps flutter_local_notifications for Islamic daily alerts.
//  - Initialises the plugin once at app startup
//  - showNotification() fires an immediate notification with vibration
// ============================================================

import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  // ── Notification channel (Android 8+) ────────────────────
  static const String _channelId = 'islamic_daily';
  static const String _channelName = 'ইসলামিক দৈনিক বার্তা';
  static const String _channelDesc =
      'প্রতিদিনের ইসলামিক অনুপ্রেরণামূলক বার্তা';

  // ── Vibration pattern: wait 0ms → vibrate 400ms → wait 200ms → vibrate 600ms
  static const List<int> _vibrationPattern = [0, 400, 200, 600];

  // ── Initialise once ───────────────────────────────────────
  static Future<void> init() async {
    if (_initialised) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Create the notification channel with vibration enabled (Android 8+)
    final channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibrationPattern),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request POST_NOTIFICATIONS permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request SCHEDULE_EXACT_ALARM permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialised = true;
  }

  // ── Show a notification immediately with vibration ────────
  static Future<void> showNotification(IslamicNotification notif) async {
    if (!_initialised) await init();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        notif.message,
        contentTitle: '${notif.typeIcon} ${notif.title}',
        summaryText: notif.reference.isNotEmpty ? notif.reference : null,
      ),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibrationPattern),
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      notif.id,                           // unique notification id
      '${notif.typeIcon} ${notif.title}', // title with emoji
      notif.message,                      // body
      details,
    );
  }

  // ── Cancel all pending notifications ─────────────────────
  static Future<void> cancelAll() => _plugin.cancelAll();
}

