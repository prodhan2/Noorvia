// ============================================================
//  prayer_alarm_service.dart
//  Manages prayer alarms using flutter_local_notifications
//  Background-safe: works even when app is closed
//  Audio: local asset only (assets/audio/azan.mp3)
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../models/prayer_alarm_settings.dart';

// ── Background notification handler (top-level, vm:entry-point) ──
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background tap: play azan via a fresh service instance
  if (response.actionId == 'play_azan' || response.payload != null) {
    final service = PrayerAlarmService();
    service.playAzan();
  }
}

class PrayerAlarmService {
  // Singleton
  static final PrayerAlarmService _instance = PrayerAlarmService._internal();
  factory PrayerAlarmService() => _instance;
  PrayerAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  AudioPlayer? _audioPlayer;

  bool _initialized = false;
  PrayerAlarmSettings? _settings;

  // Notification IDs for each prayer
  static const int _fajrId = 100;
  static const int _dhuhrId = 101;
  static const int _asrId = 102;
  static const int _maghribId = 103;
  static const int _ishaId = 104;

  // ── Initialize service ────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create high-importance notification channel (no custom sound file
    // needed — the azan is played via AudioPlayer on notification tap /
    // alarm trigger, not via the system sound slot)
    const channel = AndroidNotificationChannel(
      'prayer_alarm_channel',
      'নামাজের আযান',
      description: 'নামাজের সময় আযান বাজানোর জন্য',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request permissions
    await _requestPermissions();

    // Load settings
    await _loadSettings();

    _initialized = true;
  }

  // ── Request permissions ───────────────────────────────────
  Future<void> _requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ── Check if permissions are granted ──────────────────────
  Future<bool> arePermissionsGranted() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return (await android.areNotificationsEnabled()) ?? false;
    }
    return true;
  }

  // ── Load settings from storage ────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── One-time migration: reset old settings that had alarms ON by default ──
      const migrationKey = 'alarm_default_off_v1';
      final migrated = prefs.getBool(migrationKey) ?? false;
      if (!migrated) {
        // Clear old settings so new defaults (all OFF) take effect
        await prefs.remove('prayer_alarm_settings');
        await prefs.setBool(migrationKey, true);
      }

      final json = prefs.getString('prayer_alarm_settings');
      if (json != null) {
        _settings = PrayerAlarmSettings.fromJson(jsonDecode(json));
      } else {
        _settings = PrayerAlarmSettings(); // all alarms OFF by default
        await _saveSettings();
      }
    } catch (_) {
      _settings = PrayerAlarmSettings();
    }
  }

  // ── Save settings to storage ──────────────────────────────
  Future<void> _saveSettings() async {
    if (_settings == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'prayer_alarm_settings',
        jsonEncode(_settings!.toJson()),
      );
    } catch (_) {}
  }

  // ── Get current settings ──────────────────────────────────
  Future<PrayerAlarmSettings> getSettings() async {
    if (_settings == null) await _loadSettings();
    return _settings!;
  }

  // ── Update settings ───────────────────────────────────────
  Future<void> updateSettings(PrayerAlarmSettings settings) async {
    _settings = settings;
    await _saveSettings();
  }

  // ── Schedule all prayer alarms ────────────────────────────
  Future<void> scheduleAllAlarms(Map<String, String> prayerTimes) async {
    if (!_initialized) await initialize();
    if (_settings == null) await _loadSettings();

    await cancelAllAlarms();

    if (_settings!.fajrEnabled && prayerTimes.containsKey('fajr')) {
      await _scheduleAlarm(
        'ফজর',
        prayerTimes['fajr']!,
        _settings!.fajrPreAlarm,
        _fajrId,
      );
    }
    if (_settings!.dhuhrEnabled && prayerTimes.containsKey('dhuhr')) {
      await _scheduleAlarm(
        'যোহর',
        prayerTimes['dhuhr']!,
        _settings!.dhuhrPreAlarm,
        _dhuhrId,
      );
    }
    if (_settings!.asrEnabled && prayerTimes.containsKey('asr')) {
      await _scheduleAlarm(
        'আসর',
        prayerTimes['asr']!,
        _settings!.asrPreAlarm,
        _asrId,
      );
    }
    if (_settings!.maghribEnabled && prayerTimes.containsKey('maghrib')) {
      await _scheduleAlarm(
        'মাগরিব',
        prayerTimes['maghrib']!,
        _settings!.maghribPreAlarm,
        _maghribId,
      );
    }
    if (_settings!.ishaEnabled && prayerTimes.containsKey('isha')) {
      await _scheduleAlarm(
        'ইশা',
        prayerTimes['isha']!,
        _settings!.ishaPreAlarm,
        _ishaId,
      );
    }
  }

  // ── Schedule individual alarm ─────────────────────────────
  Future<void> _scheduleAlarm(
    String prayerName,
    String prayerTime,
    int preAlarmMinutes,
    int notificationId,
  ) async {
    try {
      final parts = prayerTime.split(':');
      if (parts.length != 2) return;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      var alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).subtract(Duration(minutes: preAlarmMinutes));

      // If already passed today → schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      final tzAlarmTime = tz.TZDateTime(
        tz.local,
        alarmTime.year,
        alarmTime.month,
        alarmTime.day,
        alarmTime.hour,
        alarmTime.minute,
      );

      final actualPrayerTime = alarmTime.add(
        Duration(minutes: preAlarmMinutes),
      );
      final prayerTimeStr =
          '${actualPrayerTime.hour.toString().padLeft(2, '0')}:'
          '${actualPrayerTime.minute.toString().padLeft(2, '0')}';

      await _notifications.zonedSchedule(
        notificationId,
        '🕌 $prayerName নামাজের সময়',
        preAlarmMinutes > 0
            ? '$preAlarmMinutes মিনিট পরে $prayerName নামাজের সময় হবে ($prayerTimeStr)'
            : '$prayerName নামাজের সময় হয়েছে ($prayerTimeStr)',
        tzAlarmTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_alarm_channel',
            'নামাজের আযান',
            channelDescription: 'নামাজের সময় আযান বাজানোর জন্য',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: _settings!.vibrationEnabled,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            visibility: NotificationVisibility.public,
            ongoing: false,
            autoCancel: false,
            styleInformation: BigTextStyleInformation(
              preAlarmMinutes > 0
                  ? '$preAlarmMinutes মিনিট পরে $prayerName নামাজের সময় হবে। প্রস্তুতি নিন।'
                  : '$prayerName নামাজের সময় হয়েছে। এখনই নামাজ পড়ুন।',
              contentTitle: '🕌 $prayerName নামাজ',
              summaryText: 'Noorvia - ইসলামিক অ্যাপ',
            ),
            actions: [
              const AndroidNotificationAction(
                'play_azan',
                '▶️ আযান শুনুন',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction('dismiss', '✖️ বন্ধ করুন'),
            ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: preAlarmMinutes > 0
                ? '$preAlarmMinutes মিনিট পরে নামাজের সময়'
                : 'নামাজের সময় হয়েছে',
            threadIdentifier: 'prayer_alarm',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // daily repeat
        payload: jsonEncode({
          'prayer': prayerName,
          'time': prayerTimeStr,
          'preAlarm': preAlarmMinutes,
        }),
      );

      debugPrint('✅ Alarm scheduled: $prayerName at $tzAlarmTime (daily)');
    } catch (e) {
      debugPrint('❌ Error scheduling alarm for $prayerName: $e');
    }
  }

  // ── Cancel all alarms ─────────────────────────────────────
  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }

  // ── Cancel specific prayer alarm ──────────────────────────
  Future<void> cancelPrayerAlarm(String prayerName) async {
    final id = _idForPrayer(prayerName);
    if (id != null) await _notifications.cancel(id);
  }

  int? _idForPrayer(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        return _fajrId;
      case 'dhuhr':
      case 'যোহর':
        return _dhuhrId;
      case 'asr':
      case 'আসর':
        return _asrId;
      case 'maghrib':
      case 'মাগরিব':
        return _maghribId;
      case 'isha':
      case 'ইশা':
        return _ishaId;
      default:
        return null;
    }
  }

  // ── Play Azan audio (local asset only) ────────────────────
  Future<void> playAzan() async {
    if (_settings == null) await _loadSettings();

    // Web platform does not support local asset audio via audioplayers
    if (kIsWeb) {
      debugPrint(
        '⚠️ Azan audio is not supported on web platform. Use Android/iOS app.',
      );
      return;
    }

    try {
      // Dispose previous player if any
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer!.setVolume(_settings!.volume);

      // Always play from local asset
      await _audioPlayer!.play(AssetSource('audio/azan.mp3'));
      debugPrint('✅ Playing local azan: assets/audio/azan.mp3');
    } catch (e) {
      debugPrint('❌ Error playing azan: $e');
    }
  }

  // ── Stop Azan audio ───────────────────────────────────────
  Future<void> stopAzan() async {
    await _audioPlayer?.stop();
  }

  // ── Handle notification tap (foreground) ─────────────────
  void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId == 'play_azan' || response.payload != null) {
      playAzan();
    }
    // 'dismiss' action → do nothing
  }

  // ── Get pending notifications ─────────────────────────────
  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ── Dispose ───────────────────────────────────────────────
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
