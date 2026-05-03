// ============================================================
//  prayer_alarm_provider.dart
//  Provider for managing prayer alarm state
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/prayer_alarm_settings.dart';
import '../services/prayer_alarm_service.dart';
import 'dart:async';

class PrayerAlarmProvider extends ChangeNotifier {
  final PrayerAlarmService _alarmService = PrayerAlarmService();
  
  PrayerAlarmSettings? _settings;
  bool _isLoading = true;
  List<String> _availableAzans = [];
  Map<String, bool> _azanLoadingStatus = {}; // Track which azans are loading
  Map<String, bool> _azanCachedStatus = {}; // Track which azans are cached

  PrayerAlarmSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  List<String> get availableAzans => _availableAzans;
  Map<String, bool> get azanLoadingStatus => _azanLoadingStatus;
  Map<String, bool> get azanCachedStatus => _azanCachedStatus;

  PrayerAlarmProvider() {
    _initialize();
  }

  // ── Initialize ────────────────────────────────────────────
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _alarmService.initialize();
    _settings = await _alarmService.getSettings();
    
    // Load 20 online azans from islamcan.com
    _availableAzans = OnlineAzanList.getAzanList()
        .map((azan) => azan['url']!)
        .toList();

    // Initialize loading status for all azans
    for (var url in _availableAzans) {
      _azanLoadingStatus[url] = false;
      _azanCachedStatus[url] = false;
    }

    // Start background preloading
    _preloadAzansInBackground();

    _isLoading = false;
    notifyListeners();
  }

  // ── Preload azans in background ───────────────────────────
  Future<void> _preloadAzansInBackground() async {
    // Preload azans one by one in background
    for (var url in _availableAzans) {
      try {
        _azanLoadingStatus[url] = true;
        notifyListeners();
        
        // Simulate preloading (in real app, you'd cache the audio file)
        await Future.delayed(const Duration(milliseconds: 500));
        
        _azanLoadingStatus[url] = false;
        _azanCachedStatus[url] = true;
        notifyListeners();
      } catch (e) {
        _azanLoadingStatus[url] = false;
        _azanCachedStatus[url] = false;
        notifyListeners();
      }
    }
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

  // ── Select Azan ───────────────────────────────────────────
  Future<void> selectAzan(String azanPath, String azanName) async {
    if (_settings == null) return;

    _settings!.selectedAzanPath = azanPath;
    _settings!.selectedAzanName = azanName;
    // Check if it's an online azan (from islamcan.com)
    _settings!.isOnlineAzan = azanPath.startsWith('http');
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
      print('❌ Error playing test azan: $e');
      // Notify listeners about the error
      notifyListeners();
    }
  }

  // ── Stop azan ─────────────────────────────────────────────
  Future<void> stopAzan() async {
    try {
      await _alarmService.stopAzan();
    } catch (e) {
      print('❌ Error stopping azan: $e');
    }
  }

  // ── Get pending alarms ────────────────────────────────────
  Future<int> getPendingAlarmsCount() async {
    final pending = await _alarmService.getPendingAlarms();
    return pending.length;
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }
}
