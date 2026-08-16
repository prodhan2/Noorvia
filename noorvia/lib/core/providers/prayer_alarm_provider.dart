// ============================================================
//  prayer_alarm_provider.dart
//  Provider for managing prayer alarm state
//  Supports both native (Kotlin/AlarmManager) and flutter implementations
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/prayer_alarm_settings.dart';
import '../services/integrated_prayer_alarm_service.dart';

class PrayerAlarmProvider extends ChangeNotifier {
  final IntegratedPrayerAlarmService _alarmService = IntegratedPrayerAlarmService();

  PrayerAlarmSettings? _settings;
  bool _isLoading = true;

  PrayerAlarmSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get useNativeImplementation => IntegratedPrayerAlarmService.useNative;

  PrayerAlarmProvider() {
    _initialize();
  }

  // ── Initialize ────────────────────────────────────────────
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _alarmService.initialize();
    _settings = await _alarmService.getSettings();

    _isLoading = false;
    notifyListeners();
  }

  // ── Toggle prayer alarm ───────────────────────────────────
  Future<void> togglePrayerAlarm(String prayerName, bool enabled) async {
    if (_settings == null) return;

    _settings!.setAlarmEnabled(prayerName, enabled);
    await _alarmService.updateSettings(_settings!);

    if (!enabled) {
      await _alarmService.cancelPrayerAlarm(prayerName);
    }

    notifyListeners();
  }

  // ── Update pre-alarm minutes ──────────────────────────────
  Future<void> updatePreAlarmMinutes(String prayerName, int minutes) async {
    if (_settings == null) return;

    _settings!.setPreAlarmMinutes(prayerName, minutes);
    await _alarmService.updateSettings(_settings!);
    notifyListeners();
  }

  // ── Select Azan (always local) ────────────────────────────
  Future<void> selectAzan(String azanPath, String azanName) async {
    if (_settings == null) return;

    _settings!.selectedAzanPath = azanPath;
    _settings!.selectedAzanName = azanName;
    await _alarmService.updateSettings(_settings!);
    notifyListeners();
  }

  // ── Update volume ─────────────────────────────────────────
  Future<void> updateVolume(double volume) async {
    if (_settings == null) return;

    _settings!.volume = volume;
    await _alarmService.updateSettings(_settings!);
    notifyListeners();
  }

  // ── Toggle vibration ──────────────────────────────────────
  Future<void> toggleVibration(bool enabled) async {
    if (_settings == null) return;

    _settings!.vibrationEnabled = enabled;
    await _alarmService.updateSettings(_settings!);
    notifyListeners();
  }

  // ── Schedule alarms with prayer times ─────────────────────
  Future<void> scheduleAlarms(Map<String, String> prayerTimes) async {
    await _alarmService.scheduleAllAlarms(prayerTimes);
  }

  // ── Play test azan ────────────────────────────────────────
  Future<void> playTestAzan() async {
    try {
      await _alarmService.playAzan();
    } catch (e) {
      debugPrint('❌ Error playing test azan: $e');
    }
  }

  // ── Stop azan ─────────────────────────────────────────────
  Future<void> stopAzan() async {
    try {
      await _alarmService.stopAzan();
    } catch (e) {
      debugPrint('❌ Error stopping azan: $e');
    }
  }

  // ── Get pending alarms count ──────────────────────────────
  Future<int> getPendingAlarmsCount() async {
    final pending = await _alarmService.getPendingAlarms();
    return pending.length;
  }

  // ── Switch implementation (for testing/debugging) ─────────
  void setImplementation(AlarmImplementation impl) {
    IntegratedPrayerAlarmService.setImplementation(impl);
    notifyListeners();
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }
}
