import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class NativePrayerAlarmService {
  static const MethodChannel _channel = MethodChannel(
    'com.butterflydevs.noorvia/prayer_alarm',
  );

  static const int fajrId = 100;
  static const int dhuhrId = 101;
  static const int asrId = 102;
  static const int maghribId = 103;
  static const int ishaId = 104;

  static bool get isPlatformSupported => !kIsWeb && Platform.isAndroid;

  static Future<bool> scheduleAlarm({
    required int prayerId,
    required String prayerName,
    required int hour,
    required int minute,
    int preAlarmMinutes = 0,
    bool vibrationEnabled = true,
    double volume = 1.0,
  }) async {
    if (!isPlatformSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'prayerId': prayerId,
        'prayerName': prayerName,
        'hour': hour,
        'minute': minute,
        'preAlarmMinutes': preAlarmMinutes,
        'vibrationEnabled': vibrationEnabled,
        'volume': volume,
      });
      return result ?? false;
    } catch (e) {
      print('Error scheduling native alarm: $e');
      return false;
    }
  }

  static Future<bool> cancelAlarm(int prayerId) async {
    if (!isPlatformSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('cancelAlarm', {
        'prayerId': prayerId,
      });
      return result ?? false;
    } catch (e) {
      print('Error canceling native alarm: $e');
      return false;
    }
  }

  static Future<bool> cancelAllAlarms() async {
    if (!isPlatformSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('cancelAllAlarms');
      return result ?? false;
    } catch (e) {
      print('Error canceling all native alarms: $e');
      return false;
    }
  }

  static Future<Map<int, Map<String, dynamic>>> getScheduledAlarms() async {
    if (!isPlatformSupported) return {};

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getScheduledAlarms',
      );
      if (result == null) return {};

      final Map<int, Map<String, dynamic>> alarms = {};
      result.forEach((key, value) {
        if (key is int && value is Map) {
          alarms[key] = Map<String, dynamic>.from(value);
        }
      });
      return alarms;
    } catch (e) {
      print('Error getting scheduled alarms: $e');
      return {};
    }
  }

  static int getPrayerId(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        return fajrId;
      case 'dhuhr':
      case 'যোহর':
        return dhuhrId;
      case 'asr':
      case 'আসর':
        return asrId;
      case 'maghrib':
      case 'মাগরিব':
        return maghribId;
      case 'isha':
      case 'ইশা':
        return ishaId;
      default:
        return -1;
    }
  }

  static Future<bool> updateWidget({
    required String fajr,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
    required String location,
    String nextPrayer = 'ফজর',
    String nextPrayerTime = '--:--',
    String ramadanDay = '',
    bool isRamadan = false,
  }) async {
    if (!isPlatformSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('updateWidget', {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'location': '📍 $location',
        'nextPrayer': nextPrayer,
        'nextPrayerTime': nextPrayerTime,
        'ramadanDay': ramadanDay,
        'isRamadan': isRamadan,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error updating widget: $e');
      return false;
    }
  }
  static Future<bool> requestPinWidget(String type) async {
    if (!isPlatformSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestPinWidget', {
        'type': type,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting home widget pin: $e');
      return false;
    }
  }

}
