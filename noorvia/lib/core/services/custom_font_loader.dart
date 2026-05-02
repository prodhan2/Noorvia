import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Custom Bangla Font Loader
/// Fetches font list from GitHub and caches it locally
class CustomFontLoader {
  static const String _cacheKey = 'custom_bangla_fonts_cache';
  static const String _cacheTimeKey = 'custom_bangla_fonts_cache_time';
  static const String _githubApiUrl =
      'https://api.github.com/repos/prodhan2/beautifulDinajpurFrames/contents/font';
  static const String _fontBaseUrl =
      'https://raw.githubusercontent.com/prodhan2/beautifulDinajpurFrames/main/font/';

  // Cache duration: 7 days
  static const Duration _cacheDuration = Duration(days: 7);

  /// Get list of custom Bangla fonts
  /// Returns cached list if available and not expired
  /// Otherwise fetches from GitHub
  static Future<List<CustomBanglaFont>> getCustomFonts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache
      final cachedData = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey);

      if (cachedData != null && cacheTime != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();

        // If cache is still valid, return cached data
        if (now.difference(cacheDate) < _cacheDuration) {
          final List<dynamic> jsonList = json.decode(cachedData);
          return jsonList
              .map((json) => CustomBanglaFont.fromJson(json))
              .toList();
        }
      }

      // Cache expired or doesn't exist, fetch from GitHub
      return await _fetchAndCacheFonts(prefs);
    } catch (e) {
      print('Error loading custom fonts: $e');
      // Return empty list on error
      return [];
    }
  }

  /// Fetch fonts from GitHub API and cache them
  static Future<List<CustomBanglaFont>> _fetchAndCacheFonts(
      SharedPreferences prefs) async {
    try {
      final response = await http.get(Uri.parse(_githubApiUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Filter only TTF/ttf files (exclude .py and other files)
        final fontFiles = data
            .where((item) =>
                item['name'] != null &&
                item['name'].toString().toLowerCase().endsWith('.ttf') &&
                !item['name'].toString().contains('sujan.py'))
            .map((item) => item['name'].toString())
            .toList();

        // Convert to CustomBanglaFont objects
        final fonts = fontFiles.map((file) {
          return CustomBanglaFont(
            fileName: file,
            displayName: _formatDisplayName(file),
            downloadUrl: '$_fontBaseUrl$file',
          );
        }).toList();

        // Cache the data
        final jsonList = fonts.map((font) => font.toJson()).toList();
        await prefs.setString(_cacheKey, json.encode(jsonList));
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);

        return fonts;
      } else {
        print('Failed to fetch fonts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching fonts from GitHub: $e');
      return [];
    }
  }

  /// Format file name to display name
  /// Example: "ANANEB__.TTF" → "Anane"
  static String _formatDisplayName(String fileName) {
    // Remove extension
    String name = fileName.replaceAll(RegExp(r'\.(TTF|ttf)$'), '');

    // Remove underscores and special characters
    name = name.replaceAll(RegExp(r'[_\-]+'), ' ');

    // Capitalize first letter of each word
    final words = name.split(' ');
    name = words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .where((word) => word.isNotEmpty)
        .join(' ');

    return name.trim();
  }

  /// Clear font cache (useful for testing or forcing refresh)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
  }

  /// Load a specific font from URL
  static Future<ByteData?> loadFontFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        return ByteData.view(response.bodyBytes.buffer);
      }
      return null;
    } catch (e) {
      print('Error loading font from URL: $e');
      return null;
    }
  }
}

/// Custom Bangla Font Model
class CustomBanglaFont {
  final String fileName;
  final String displayName;
  final String downloadUrl;

  CustomBanglaFont({
    required this.fileName,
    required this.displayName,
    required this.downloadUrl,
  });

  factory CustomBanglaFont.fromJson(Map<String, dynamic> json) {
    return CustomBanglaFont(
      fileName: json['fileName'] as String,
      displayName: json['displayName'] as String,
      downloadUrl: json['downloadUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'displayName': displayName,
      'downloadUrl': downloadUrl,
    };
  }
}
