// ============================================================
//  data_sync_service.dart
//  Background JSON sync service
//  - App start হলেই সব JSON silently fetch করে cache করে
//  - connectivity_plus দিয়ে net আসলেই auto-refresh করে
//  - User কে কিছু দেখাতে হয় না
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─── API endpoints ────────────────────────────────────────────────────────────

class _ApiEndpoint {
  final String cacheKey;
  final String url;
  const _ApiEndpoint({required this.cacheKey, required this.url});
}

const List<_ApiEndpoint> _endpoints = [
  _ApiEndpoint(
    cacheKey: 'dua_cache',
    url: 'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/dua.json',
  ),
  _ApiEndpoint(
    cacheKey: 'radio_cache',
    url: 'https://data-rosy.vercel.app/radio.json',
  ),
  _ApiEndpoint(
    cacheKey: 'islamic_names_cache',
    url: 'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamic_names.json',
  ),
  _ApiEndpoint(
    cacheKey: 'ruqyah_cache',
    url: 'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/rukaiya.json',
  ),
  _ApiEndpoint(
    cacheKey: 'asmaul_husna_cache',
    url: 'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/asmaul-husna.json',
  ),
];

// ─── DataSyncService ──────────────────────────────────────────────────────────

class DataSyncService {
  DataSyncService._();
  static final DataSyncService instance = DataSyncService._();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  bool _wasOffline = false;

  // ── Initialize: call once from main() ──────────────────────────────────────
  Future<void> init() async {
    // ১. App start এ একবার sync করো
    await _syncAll();

    // ২. Connectivity change হলে auto-sync
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  // ── Connectivity change handler ────────────────────────────────────────────
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    if (isOnline && _wasOffline) {
      // Net ফিরে এসেছে — silently sync করো
      _syncAll();
    }
    _wasOffline = !isOnline;
  }

  // ── Sync all endpoints ─────────────────────────────────────────────────────
  Future<void> _syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // সব endpoint parallel এ fetch করো
      await Future.wait(
        _endpoints.map((e) => _fetchAndCache(e)),
        eagerError: false,
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ── Fetch one endpoint and cache it ───────────────────────────────────────
  Future<void> _fetchAndCache(_ApiEndpoint endpoint) async {
    try {
      final response = await http
          .get(Uri.parse(endpoint.url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        // Validate JSON before caching
        final raw = utf8.decode(response.bodyBytes);
        jsonDecode(raw); // throws if invalid

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(endpoint.cacheKey, raw);

        debugPrint('[DataSync] ✅ ${endpoint.cacheKey} updated');
      }
    } catch (e) {
      // Silent fail — cache থেকে পুরনো data দেখাবে
      debugPrint('[DataSync] ⚠️ ${endpoint.cacheKey} failed: $e');
    }
  }

  // ── Manual refresh (optional, for pull-to-refresh) ────────────────────────
  Future<void> refreshAll() => _syncAll();

  /// Refresh a single endpoint by cache key
  Future<void> refreshOne(String cacheKey) async {
    final endpoint = _endpoints.firstWhere(
      (e) => e.cacheKey == cacheKey,
      orElse: () => throw ArgumentError('Unknown cacheKey: $cacheKey'),
    );
    await _fetchAndCache(endpoint);
  }
}
