// ============================================================
//  prayer_alarm_service.dart
//  Manages prayer alarms using flutter_local_notifications
//  and workmanager for background scheduling
// ============================================================

import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../models/prayer_alarm_settings.dart';

class PrayerAlarmService {
  static final PrayerAlarmService _instance = PrayerAlarmService._internal();
  factory PrayerAlarmService() => _instance;
  PrayerAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
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
    
    // Configure audio player
    await _configureAudioPlayer();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'prayer_alarm_channel',
      'নামাজের আযান',
      description: 'নামাজের সময় আযান বাজানোর জন্য',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('azan_notification'),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions
    await _requestPermissions();

    // Load settings
    await _loadSettings();

    _initialized = true;
  }
  
  // ── Configure audio player ────────────────────────────────
  Future<void> _configureAudioPlayer() async {
    try {
      // Set audio context for better compatibility
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      // Set player mode for low latency
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      
      // Listen to player state changes
      _audioPlayer.onPlayerStateChanged.listen((state) {
        print('🎵 Audio player state: $state');
      });
      
      // Listen to errors
      _audioPlayer.onLog.listen((message) {
        print('🎵 Audio player log: $message');
      });
      
      print('✅ Audio player configured successfully');
    } catch (e) {
      print('⚠️ Error configuring audio player: $e');
    }
  }

  // ── Request permissions ───────────────────────────────────
  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (ios != null) {
      await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ── Load settings from storage ────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('prayer_alarm_settings');
      
      if (json != null) {
        _settings = PrayerAlarmSettings.fromJson(jsonDecode(json));
      } else {
        _settings = PrayerAlarmSettings();
        await _saveSettings();
      }
    } catch (e) {
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
    } catch (e) {
      // Handle error
    }
  }

  // ── Get current settings ──────────────────────────────────
  Future<PrayerAlarmSettings> getSettings() async {
    if (_settings == null) {
      await _loadSettings();
    }
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

    // Cancel existing alarms
    await cancelAllAlarms();

    // Schedule each prayer
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
      // Parse prayer time (format: "HH:mm")
      final parts = prayerTime.split(':');
      if (parts.length != 2) return;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Calculate alarm time (prayer time - pre-alarm minutes)
      final now = DateTime.now();
      var alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).subtract(Duration(minutes: preAlarmMinutes));

      // If alarm time has passed today, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      // Convert to timezone
      final tzAlarmTime = tz.TZDateTime.from(alarmTime, tz.local);

      // Calculate actual prayer time for notification
      final actualPrayerTime = alarmTime.add(Duration(minutes: preAlarmMinutes));
      final prayerTimeStr = '${actualPrayerTime.hour.toString().padLeft(2, '0')}:${actualPrayerTime.minute.toString().padLeft(2, '0')}';

      // Schedule notification
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
            sound: const RawResourceAndroidNotificationSound('azan_notification'),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(
              preAlarmMinutes > 0
                  ? '$preAlarmMinutes মিনিট পরে $prayerName নামাজের সময় হবে। প্রস্তুতি নিন।'
                  : '$prayerName নামাজের সময় হয়েছে। এখনই নামাজ পড়ুন।',
              contentTitle: '🕌 $prayerName নামাজ',
              summaryText: 'নূরভিয়া - ইসলামিক অ্যাপ',
            ),
            actions: [
              const AndroidNotificationAction(
                'play_azan',
                '▶️ আযান শুনুন',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'dismiss',
                '✖️ বন্ধ করুন',
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'azan_notification.mp3',
            subtitle: preAlarmMinutes > 0
                ? '$preAlarmMinutes মিনিট পরে নামাজের সময়'
                : 'নামাজের সময় হয়েছে',
            threadIdentifier: 'prayer_alarm',
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
          'azanPath': _settings!.selectedAzanPath,
        }),
      );

      print('✅ Alarm scheduled for $prayerName at ${tzAlarmTime.toString()}');
    } catch (e) {
      // Handle error
      print('❌ Error scheduling alarm for $prayerName: $e');
    }
  }

  // ── Cancel all alarms ─────────────────────────────────────
  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }

  // ── Cancel specific prayer alarm ──────────────────────────
  Future<void> cancelPrayerAlarm(String prayerName) async {
    int id;
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        id = _fajrId;
        break;
      case 'dhuhr':
      case 'যোহর':
        id = _dhuhrId;
        break;
      case 'asr':
      case 'আসর':
        id = _asrId;
        break;
      case 'maghrib':
      case 'মাগরিব':
        id = _maghribId;
        break;
      case 'isha':
      case 'ইশা':
        id = _ishaId;
        break;
      default:
        return;
    }
    await _notifications.cancel(id);
  }

  // ── Play Azan audio ───────────────────────────────────────
  Future<void> playAzan() async {
    if (_settings == null) await _loadSettings();
    
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();
      
      // Set audio context for web (fixes CORS issues)
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      // Set volume
      await _audioPlayer.setVolume(_settings!.volume);
      
      print('🎵 Playing azan: ${_settings!.selectedAzanPath}');
      
      // Play from online URL or local asset
      if (_settings!.isOnlineAzan) {
        // Check if running on web
        if (kIsWeb) {
          print('⚠️ Running on web platform - CORS may cause issues');
          print('💡 For best experience, use mobile app (Android/iOS)');
        }
        
        // Play from online URL with proper configuration
        final source = UrlSource(
          _settings!.selectedAzanPath,
          mimeType: 'audio/mpeg', // Specify MIME type for better compatibility
        );
        await _audioPlayer.play(source);
        print('✅ Started playing online azan');
      } else if (_settings!.selectedAzanPath.startsWith('assets/')) {
        // Play from asset
        final assetPath = _settings!.selectedAzanPath.replaceFirst('assets/', '');
        await _audioPlayer.play(AssetSource(assetPath));
        print('✅ Started playing asset azan');
      } else {
        // Play from device file
        await _audioPlayer.play(DeviceFileSource(_settings!.selectedAzanPath));
        print('✅ Started playing device file azan');
      }
    } catch (e) {
      print('❌ Error playing azan: $e');
      // Show user-friendly error message
      _showAzanError(e.toString());
    }
  }
  
  // ── Show error message ────────────────────────────────────
  void _showAzanError(String error) {
    // This will be caught by the UI layer
    if (error.contains('CORS') || error.contains('WebAudioError')) {
      print('⚠️ CORS error detected. This usually happens on web platform.');
      print('💡 Solution 1: Use mobile app (Android/iOS) - works perfectly!');
      print('💡 Solution 2: Download azan files and use local assets');
      print('💡 Solution 3: Run on desktop app instead of web browser');
    } else if (error.contains('Format error')) {
      print('⚠️ Audio format error. The file might be corrupted or unsupported.');
      print('💡 Try selecting a different azan from the list');
    } else if (error.contains('Network')) {
      print('⚠️ Network error. Check your internet connection.');
    } else {
      print('⚠️ Unknown error: $error');
    }
  }

  // ── Stop Azan audio ───────────────────────────────────────
  Future<void> stopAzan() async {
    await _audioPlayer.stop();
  }

  // ── Handle notification tap ──────────────────────────────
  void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId == 'play_azan') {
      // Play azan when "আযান শুনুন" button is tapped
      playAzan();
    } else if (response.actionId == 'dismiss') {
      // Just dismiss the notification
      return;
    } else if (response.payload != null) {
      // Notification body tapped - play azan
      playAzan();
    }
  }

  // ── Handle background notification tap ───────────────────
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Background handler - create new instance to play azan
    if (response.actionId == 'play_azan' || response.payload != null) {
      final service = PrayerAlarmService();
      service.playAzan();
    }
  }

  // ── Get pending notifications ─────────────────────────────
  Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ── Dispose ───────────────────────────────────────────────
  void dispose() {
    _audioPlayer.dispose();
  }
}
