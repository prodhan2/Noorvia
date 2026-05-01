import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'arabic_letter_model.dart';

class ArabicAlphabetService {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/arabic_letters.json';
  static const _cacheKey = 'arabic_letters_cache';

  /// Returns letters from cache first, then fetches fresh data.
  /// [onData] is called whenever data is available (cache or network).
  static Future<List<ArabicLetter>> fetchLetters() async {
    final prefs = await SharedPreferences.getInstance();

    // Try cache first
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final list = _parse(cached);
        if (list.isNotEmpty) return list;
        // Cache is corrupt/empty — clear it and fetch fresh
        await prefs.remove(_cacheKey);
      } catch (_) {
        await prefs.remove(_cacheKey);
      }
    }

    // Fetch from network
    final response = await http
        .get(Uri.parse(_apiUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      await prefs.setString(_cacheKey, response.body);
      return _parse(response.body);
    }

    throw Exception('Failed to load Arabic letters (${response.statusCode})');
  }

  static List<ArabicLetter> _parse(String body) {
    final decoded = json.decode(body);
    final List<dynamic> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map) {
      // Try known root keys in order
      raw = (decoded['arabic_alphabets'] ??
              decoded['letters'] ??
              decoded['data'] ??
              []) as List<dynamic>;
    } else {
      raw = [];
    }
    return raw
        .map((e) => ArabicLetter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey);
  }
}
