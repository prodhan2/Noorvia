// ============================================================
//  notification_cache_service.dart
//  Fetch Islamic notifications from API and cache locally.
//  Offline-first: always loads from cache, refreshes when online.
//  Fallback: built-in data used when no cache and no internet.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationCacheService {
  // Raw GitHub URL
  static const String _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamic_notifications.json';

  // ── Built-in fallback data (used when no cache & no internet) ──
  static const String _fallbackJson = '''
{
  "islamic_notifications": [
    {"id":1,"title":"কুরআনের বানী","message":"নিশ্চয়ই নামাজ বেহায়া ও মন্দ কাজ থেকে বিরত রাখে।","type":"quran","reference":"সূরা আল-আনকাবুত (২৯), আয়াত: ৪৫","schedule":"daily"},
    {"id":2,"title":"হাদিসের আলো","message":"তোমাদের মধ্যে যার ঈমান সবচেয়ে পূর্ণ, সে হলো সেই যার চরিত্র সবচেয়ে উত্তম।","type":"hadith","reference":"সহীহ মুসলিম, হাদিস নং: ২৩২২","schedule":"daily"},
    {"id":3,"title":"ফজরের নামাজের সময়","message":"ফজরের নামাজের সময় শুরু হয়েছে। আল্লাহ তায়ালা আমাদের নামাজ কবুল করুন।","type":"prayer","reference":"সূরা আল-বাকারা (২), আয়াত: ২৩৮","schedule":"fajr"},
    {"id":4,"title":"সকালের দোয়া","message":"আল্লাহুম্মা বিকা আসবাহনা, ওয়া বিকা আমসায়না, ওয়া বিকা নাহইয়া, ওয়া বিকা নামুতু।","type":"dua","reference":"সুনানু তিরমিযি, হাদিস নং: ৩৩৯১","schedule":"morning"},
    {"id":5,"title":"আল্লাহর স্মরণ","message":"জেনে রেখো, আল্লাহর স্মরণেই হৃদয় প্রশান্তি লাভ করে।","type":"reminder","reference":"সূরা আর-রা'দ (১৩), আয়াত: ২৮","schedule":"daily"},
    {"id":6,"title":"কুরআনের বানী","message":"আর ধৈর্য ধরো, নিশ্চয়ই আল্লাহ ধৈর্যশীলদের সাথে আছেন।","type":"quran","reference":"সূরা আল-বাকারা (২), আয়াত: ১৫৩","schedule":"daily"},
    {"id":7,"title":"হাদিসের আলো","message":"জ্ঞান অর্জন করা প্রত্যেক মুসলমানের উপর ফরজ।","type":"hadith","reference":"সুনানু ইবনে মাজাহ, হাদিস নং: ২২৪","schedule":"daily"},
    {"id":8,"title":"কুরআনের বানী","message":"আর তোমরা আল্লাহর রহমত থেকে নিরাশ হয়ো না, নিশ্চয়ই আল্লাহ ছাড়া কেউ নিরাশ হয় না।","type":"quran","reference":"সূরা ইউসুফ (১২), আয়াত: ৮৭","schedule":"daily"},
    {"id":9,"title":"দান-সদকার ফজিলত","message":"দান করো, আল্লাহ তোমাদের উপর দয়া করবেন। দান ধ্বংস করে না, বরং বৃদ্ধি করে।","type":"reminder","reference":"সহীহ মুসলিম, হাদিস নং: ২৫৮৮","schedule":"daily"},
    {"id":10,"title":"রাতের দোয়া","message":"আল্লাহুম্মা ইন্নী আ'উযু বিকা মিন শাররি মা খালাকত।","type":"dua","reference":"সহীহ মুসলিম, হাদিস নং: ২৭২৩","schedule":"night"}
  ]
}
''';

  static const String _cacheKey = 'islamic_notifications_cache';
  static const String _cacheTimestampKey = 'islamic_notifications_cache_ts';

  // ── Load from local cache ─────────────────────────────────
  static Future<List<IslamicNotification>?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      final List<dynamic> list = decoded['islamic_notifications'] as List? ?? [];
      return list
          .map((e) => IslamicNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Save to local cache ───────────────────────────────────
  static Future<void> saveToCache(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, rawJson);
    await prefs.setInt(
        _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Get cache timestamp ───────────────────────────────────
  static Future<DateTime?> getCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTimestampKey);
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  // ── Fetch from network and cache ──────────────────────────
  static Future<List<IslamicNotification>> fetchAndCache() async {
    final response = await http
        .get(Uri.parse(_apiUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final rawJson = response.body;
      await saveToCache(rawJson);

      final decoded = jsonDecode(rawJson);
      final List<dynamic> list =
          decoded['islamic_notifications'] as List? ?? [];
      return list
          .map((e) => IslamicNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  // ── Check if cache exists ─────────────────────────────────
  static Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    return raw != null && raw.isNotEmpty;
  }

  // ── Clear cache ───────────────────────────────────────────
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  // ── Load built-in fallback data ───────────────────────────
  static List<IslamicNotification> loadFallback() {
    try {
      final decoded = jsonDecode(_fallbackJson);
      final List<dynamic> list = decoded['islamic_notifications'] as List? ?? [];
      return list
          .map((e) => IslamicNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
