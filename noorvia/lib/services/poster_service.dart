import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poster_model.dart';

class PosterService {
  static const String apiUrl =
      'https://opensheet.elk.sh/16SrsQMW8ETVOzz8J7Ty6HOfWqDU6lAx_ya5bGDxlA5o/2';
  static const String cacheKey = 'cached_posters';
  static const String cacheTimeKey = 'cached_posters_time';
  static const Duration cacheExpiry = Duration(hours: 24);

  /// Fetch posters with cache support
  /// Returns cached data immediately if available, then updates from API
  Future<List<PosterModel>> fetchPosters({bool forceRefresh = false}) async {
    try {
      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedPosters = await _getCachedPosters();
        if (cachedPosters != null && cachedPosters.isNotEmpty) {
          // Return cached data immediately
          // Then fetch fresh data in background
          _fetchAndCachePosters();
          return cachedPosters;
        }
      }

      // No cache or force refresh - fetch from API
      return await _fetchAndCachePosters();
    } catch (e) {
      // If API fails, try to return cached data as fallback
      final cachedPosters = await _getCachedPosters();
      if (cachedPosters != null && cachedPosters.isNotEmpty) {
        return cachedPosters;
      }
      throw Exception('Error fetching posters: $e');
    }
  }

  /// Fetch from API and save to cache
  Future<List<PosterModel>> _fetchAndCachePosters() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final posters = jsonData.map((json) => PosterModel.fromJson(json)).toList();
      
      // Save to cache
      await _saveToCache(posters);
      
      return posters;
    } else {
      throw Exception('Failed to load posters: ${response.statusCode}');
    }
  }

  /// Get cached posters from SharedPreferences
  Future<List<PosterModel>?> _getCachedPosters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);

      if (cachedData == null || cachedTime == null) {
        return null;
      }

      // Check if cache is expired
      final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cachedTime);
      final now = DateTime.now();
      if (now.difference(cacheDateTime) > cacheExpiry) {
        // Cache expired
        return null;
      }

      // Parse cached data
      final List<dynamic> jsonData = json.decode(cachedData);
      return jsonData.map((json) => PosterModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Save posters to cache
  Future<void> _saveToCache(List<PosterModel> posters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = posters.map((poster) => poster.toJson()).toList();
      await prefs.setString(cacheKey, json.encode(jsonData));
      await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Ignore cache save errors
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(cacheTimeKey);
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  /// Check if cache exists and is valid
  Future<bool> hasCachedData() async {
    final cachedPosters = await _getCachedPosters();
    return cachedPosters != null && cachedPosters.isNotEmpty;
  }
}
