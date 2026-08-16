import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../models/prayer_alarm_settings.dart';
import 'native_prayer_alarm_service.dart';

enum AlarmImplementation { native, flutter }

class IntegratedPrayerAlarmService {
  static final IntegratedPrayerAlarmService _instance = IntegratedPrayerAlarmService._internal();
  factory IntegratedPrayerAlarmService() => _instance;
  IntegratedPrayerAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  AudioPlayer? _audioPlayer;
  bool _initialized = false;
  PrayerAlarmSettings? _settings;

  static const int _fajrId = 100;
  static const int _dhuhrId = 101;
  static const int _asrId = 102;
  static const int _maghribId = 103;
  static const int _ishaId = 104;

  static AlarmImplementation _implementation = AlarmImplementation.native;
  static bool get useNative => NativePrayerAlarmService.isPlatformSupported && _implementation == AlarmImplementation.native;

  static void setImplementation(AlarmImplementation impl) {
    _implementation = impl;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (!useNative) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

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
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _requestPermissions();
    }

    await _loadSettings();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      const migrationKey = 'alarm_default_off_v1';
      final migrated = prefs.getBool(migrationKey) ?? false;
      if (!migrated) {
        await prefs.remove('prayer_alarm_settings');
        await prefs.setBool(migrationKey, true);
      }

      final json = prefs.getString('prayer_alarm_settings');
      if (json != null) {
        _settings = PrayerAlarmSettings.fromJson(jsonDecode(json));
      } else {
        _settings = PrayerAlarmSettings();
        await _saveSettings();
      }
    } catch (_) {
      _settings = PrayerAlarmSettings();
    }
  }

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

  Future<PrayerAlarmSettings> getSettings() async {
    if (_settings == null) await _loadSettings();
    return _settings!;
  }

  Future<void> updateSettings(PrayerAlarmSettings settings) async {
    _settings = settings;
    await _saveSettings();
  }

  Future<void> scheduleAllAlarms(Map<String, String> prayerTimes) async {
    if (!_initialized) await initialize();
    if (_settings == null) await _loadSettings();

    if (useNative) {
      await NativePrayerAlarmService.cancelAllAlarms();
    } else {
      await _notifications.cancelAll();
    }

    final prayers = [
      ('ফজর', 'fajr', _fajrId, _settings!.fajrEnabled, _settings!.fajrPreAlarm),
      ('যোহর', 'dhuhr', _dhuhrId, _settings!.dhuhrEnabled, _settings!.dhuhrPreAlarm),
      ('আসর', 'asr', _asrId, _settings!.asrEnabled, _settings!.asrPreAlarm),
      ('মাগরিব', 'maghrib', _maghribId, _settings!.maghribEnabled, _settings!.maghribPreAlarm),
      ('ইশা', 'isha', _ishaId, _settings!.ishaEnabled, _settings!.ishaPreAlarm),
    ];

    for (final prayer in prayers) {
      final (bnName, enName, id, enabled, preAlarm) = prayer;
      if (enabled && prayerTimes.containsKey(enName)) {
        if (useNative) {
          final time = prayerTimes[enName]!;
          final parts = time.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            await NativePrayerAlarmService.scheduleAlarm(
              prayerId: id,
              prayerName: bnName,
              hour: hour,
              minute: minute,
              preAlarmMinutes: preAlarm,
              vibrationEnabled: _settings!.vibrationEnabled,
              volume: _settings!.volume,
            );
          }
        } else {
          await _scheduleAlarm(bnName, prayerTimes[enName]!, preAlarm, id);
        }
      }
    }
  }

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
            actions: const [
              AndroidNotificationAction(
                'play_azan',
                '▶️ আযান শুনুন',
                showsUserInterface: true,
              ),
              AndroidNotificationAction('dismiss', '✖️ বন্ধ করুন'),
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
        matchDateTimeComponents: DateTimeComponents.time,
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

  Future<void> cancelAllAlarms() async {
    if (useNative) {
      await NativePrayerAlarmService.cancelAllAlarms();
    } else {
      await _notifications.cancelAll();
    }
  }

  Future<void> cancelPrayerAlarm(String prayerName) async {
    final id = _idForPrayer(prayerName);
    if (id != null) {
      if (useNative) {
        await NativePrayerAlarmService.cancelAlarm(id);
      } else {
        await _notifications.cancel(id);
      }
    }
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

  Future<void> playAzan() async {
    if (_settings == null) await _loadSettings();

    if (kIsWeb) {
      debugPrint(
        '⚠️ Azan audio is not supported on web platform. Use Android/iOS app.',
      );
      return;
    }

    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer!.setVolume(_settings!.volume);

      await _audioPlayer!.play(AssetSource('audio/azan.mp3'));
      debugPrint('✅ Playing local azan: assets/audio/azan.mp3');
    } catch (e) {
      debugPrint('❌ Error playing azan: $e');
    }
  }

  Future<void> stopAzan() async {
    await _audioPlayer?.stop();
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId == 'play_azan' || response.payload != null) {
      playAzan();
    }
  }

  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    if (useNative) {
      final nativeAlarms = await NativePrayerAlarmService.getScheduledAlarms();
      return [];
    }
    return await _notifications.pendingNotificationRequests();
  }

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == 'play_azan' || response.payload != null) {
    final service = IntegratedPrayerAlarmService();
    service.playAzan();
  }
}
