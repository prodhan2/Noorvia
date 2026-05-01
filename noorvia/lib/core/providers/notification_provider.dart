// ============================================================
//  notification_provider.dart
//  Manages Islamic notification data with offline-first cache.
//  - Loads from cache immediately on startup
//  - Fetches fresh data when internet is available
//  - Random notification always comes from local cache only
// ============================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/notification_model.dart';
import '../services/notification_cache_service.dart';
import '../services/local_notification_service.dart';

enum NotifSyncState {
  idle,         // nothing happening
  firstSync,    // very first load — no cache yet, fetching
  refreshing,   // has cache, fetching fresh data in background
  offline,      // no internet, loaded from cache
  error,        // fetch failed and no cache
  loaded,       // data ready
}

class NotificationProvider extends ChangeNotifier {
  List<IslamicNotification> _notifications = [];
  NotifSyncState _state = NotifSyncState.idle;
  String _errorMessage = '';
  DateTime? _lastUpdated;
  bool _isOnline = false;

  List<IslamicNotification> get notifications => _notifications;
  NotifSyncState get state => _state;
  String get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isOnline => _isOnline;
  bool get hasData => _notifications.isNotEmpty;

  NotificationProvider() {
    _init();
  }

  // ── Initialise: load cache then try network ───────────────
  Future<void> _init() async {
    // 1. Try loading from cache first (instant)
    final cached = await NotificationCacheService.loadFromCache();
    _lastUpdated = await NotificationCacheService.getCacheTimestamp();

    if (cached != null && cached.isNotEmpty) {
      _notifications = cached;
      _state = NotifSyncState.loaded;
      notifyListeners();
      // Then try to refresh in background
      _refreshIfOnline(background: true);
    } else {
      // No cache — load fallback immediately so UI is never empty
      _notifications = NotificationCacheService.loadFallback();
      _state = NotifSyncState.firstSync;
      notifyListeners();
      // Then try to fetch real data
      await _fetchFromNetwork();
    }
  }

  // ── Check connectivity and refresh ───────────────────────
  Future<void> _refreshIfOnline({bool background = false}) async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.any((r) => r != ConnectivityResult.none);

    if (!_isOnline) {
      if (_notifications.isEmpty) {
        // Load fallback instead of showing error
        _notifications = NotificationCacheService.loadFallback();
        _state = _notifications.isNotEmpty ? NotifSyncState.offline : NotifSyncState.error;
        _errorMessage = 'ইন্টারনেট সংযোগ নেই এবং কোনো ক্যাশ নেই।';
      } else {
        _state = NotifSyncState.offline;
      }
      notifyListeners();
      return;
    }

    if (!background) {
      _state = NotifSyncState.refreshing;
      notifyListeners();
    }

    await _fetchFromNetwork();
  }

  // ── Fetch from network ────────────────────────────────────
  Future<void> _fetchFromNetwork() async {
    try {
      final fresh = await NotificationCacheService.fetchAndCache();
      _notifications = fresh;
      _lastUpdated = DateTime.now();
      _isOnline = true;
      _state = NotifSyncState.loaded;
      _errorMessage = '';
    } catch (e) {
      if (_notifications.isNotEmpty) {
        // Has data (cache or fallback) — show offline mode, not error
        _state = NotifSyncState.offline;
      } else {
        // Last resort: load built-in fallback
        _notifications = NotificationCacheService.loadFallback();
        if (_notifications.isNotEmpty) {
          _state = NotifSyncState.offline;
        } else {
          _state = NotifSyncState.error;
          _errorMessage = 'ডেটা লোড করতে ব্যর্থ হয়েছে।\nইন্টারনেট সংযোগ চেক করুন।';
        }
      }
    }
    notifyListeners();
  }

  // ── Manual refresh (called by "Update Data" button) ───────
  Future<void> refresh() async {
    _state = NotifSyncState.refreshing;
    notifyListeners();
    await _refreshIfOnline(background: false);
  }

  // ── Get a random notification from LOCAL CACHE ONLY ───────
  IslamicNotification? getRandomNotification() {
    if (_notifications.isEmpty) return null;
    final rng = Random();
    return _notifications[rng.nextInt(_notifications.length)];
  }

  // ── Get notifications filtered by type ───────────────────
  List<IslamicNotification> getByType(String type) =>
      _notifications.where((n) => n.type == type).toList();

  // ── Show a random local notification immediately ──────────
  Future<bool> showRandomLocalNotification() async {
    final notif = getRandomNotification();
    if (notif == null) return false;
    await LocalNotificationService.showNotification(notif);
    return true;
  }

  // ── Formatted last-updated string (Bangla) ───────────────
  String get lastUpdatedText {
    if (_lastUpdated == null) return 'কখনো আপডেট হয়নি';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inMinutes < 1) return 'এইমাত্র আপডেট হয়েছে';
    if (diff.inHours < 1) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inDays < 1) return '${diff.inHours} ঘণ্টা আগে';
    return '${diff.inDays} দিন আগে';
  }
}
