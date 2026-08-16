import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../core/data/local/local_store.dart';
import '../models/poster_model.dart';

/// Admin-controlled banner/poster source.
///
/// Primary source: Firestore `banners` collection.
/// Legacy Google Sheet/OpenSheet remains a fallback so the UI still has
/// content before Firestore is populated or when Firebase is unavailable.
class PosterService {
  static const String apiUrl =
      'https://opensheet.elk.sh/16SrsQMW8ETVOzz8J7Ty6HOfWqDU6lAx_ya5bGDxlA5o/2';
  static const String _cacheNamespace = 'banner_cache';
  static const String cacheKey = 'active_posters';
  static const Duration cacheExpiry = Duration(days: 7);

  CollectionReference<Map<String, dynamic>> get _banners =>
      FirebaseFirestore.instance.collection('banners');

  Future<List<PosterModel>> fetchPosters({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getCachedPosters();
      if (cached != null && cached.isNotEmpty) {
        // Refresh asynchronously; user sees cached banners instantly.
        unawaited(_fetchPrimaryAndCache());
        return cached;
      }
    }

    try {
      return await _fetchPrimaryAndCache();
    } catch (_) {
      final cached = await _getCachedPosters(ignoreExpiry: true);
      if (cached != null && cached.isNotEmpty) return cached;
      return _fetchLegacyAndCache();
    }
  }

  /// Realtime stream so an admin banner change can appear without a new app
  /// release. Firestore's local cache also helps when the device is offline.
  Stream<List<PosterModel>> watchPosters() async* {
    final cached = await _getCachedPosters(ignoreExpiry: true);
    if (cached != null && cached.isNotEmpty) yield cached;

    try {
      await for (final snapshot in _banners
          .where('active', isEqualTo: true)
          .snapshots()) {
        final posters = snapshot.docs
            .map((doc) => PosterModel.fromJson(doc.data(), id: doc.id))
            .where((p) => p.imglink.isNotEmpty)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        // Empty is meaningful: the admin may intentionally disable every
        // banner. Yield it so the carousel disappears instead of showing an
        // old cached/legacy poster.
        await _saveToCache(posters);
        yield posters;
      }
    } catch (_) {
      // The initial project may not yet contain the Firestore index/data.
      // In that case, keep the legacy source as a graceful fallback.
      try {
        final legacy = await _fetchLegacyAndCache();
        if (legacy.isNotEmpty) yield legacy;
      } catch (_) {}
    }
  }

  Future<List<PosterModel>> _fetchPrimaryAndCache() async {
    try {
      final snapshot = await _banners
          .where('active', isEqualTo: true)
          .get(const GetOptions(source: Source.serverAndCache));
      final posters = snapshot.docs
          .map((doc) => PosterModel.fromJson(doc.data(), id: doc.id))
          .where((p) => p.imglink.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      await _saveToCache(posters);
      return posters;
    } catch (_) {
      // Only fall back to the legacy sheet when Firestore itself is
      // unavailable/misconfigured. A successful empty query means the admin
      // deliberately has no active banners.
      return _fetchLegacyAndCache();
    }
  }

  Future<List<PosterModel>> _fetchLegacyAndCache() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load posters: ${response.statusCode}');
    }

    final List<dynamic> jsonData = json.decode(response.body);
    final posters = jsonData
        .map((item) => PosterModel.fromJson(Map<String, dynamic>.from(item)))
        .where((p) => p.imglink.isNotEmpty)
        .toList();
    await _saveToCache(posters);
    return posters;
  }

  Future<List<PosterModel>?> _getCachedPosters({bool ignoreExpiry = false}) async {
    try {
      final cached = await LocalStore.instance.getJson(_cacheNamespace, cacheKey);
      if (cached == null) return null;
      final savedAt = DateTime.tryParse(cached['cachedAt']?.toString() ?? '');
      final items = cached['items'];
      if (savedAt == null || items is! List) return null;

      if (!ignoreExpiry && DateTime.now().difference(savedAt) > cacheExpiry) {
        return null;
      }

      return items
          .whereType<Map>()
          .map((item) => PosterModel.fromJson(Map<String, dynamic>.from(item)))
          .where((p) => p.active && p.imglink.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(List<PosterModel> posters) async {
    try {
      await LocalStore.instance.putJson(
        _cacheNamespace,
        cacheKey,
        <String, dynamic>{
          'cachedAt': DateTime.now().toUtc().toIso8601String(),
          'items': posters.map((poster) => poster.toJson()).toList(),
        },
        syncStatus: 'cached',
      );
    } catch (_) {}
  }

  Future<void> clearCache() =>
      LocalStore.instance.delete(_cacheNamespace, cacheKey);

  Future<bool> hasCachedData() async {
    final cached = await _getCachedPosters(ignoreExpiry: true);
    return cached != null && cached.isNotEmpty;
  }
}
