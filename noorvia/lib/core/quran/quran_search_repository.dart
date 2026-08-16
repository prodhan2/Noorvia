import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/local/local_store.dart';
import 'quran_models.dart';

class QuranSearchResult {
  const QuranSearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.englishName,
    required this.ayahNumber,
    required this.text,
    required this.edition,
    this.fromOfflineCache = false,
  });

  final int surahNumber;
  final String surahName;
  final String englishName;
  final int ayahNumber;
  final String text;
  final String edition;
  final bool fromOfflineCache;

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'englishName': englishName,
        'ayahNumber': ayahNumber,
        'text': text,
        'edition': edition,
        'fromOfflineCache': fromOfflineCache,
      };

  factory QuranSearchResult.fromJson(Map<String, dynamic> json) =>
      QuranSearchResult(
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
        surahName: json['surahName']?.toString() ?? '',
        englishName: json['englishName']?.toString() ?? '',
        ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        edition: json['edition']?.toString() ?? '',
        fromOfflineCache: json['fromOfflineCache'] == true,
      );
}

class QuranSearchResponse {
  const QuranSearchResponse({
    required this.results,
    required this.edition,
    required this.offlineOnly,
  });

  final List<QuranSearchResult> results;
  final String edition;
  final bool offlineOnly;
}

/// Search that prefers Al Quran Cloud's key-less API and falls back to the
/// Surahs already cached in Noorvia's Isar database.
class QuranSearchRepository {
  QuranSearchRepository._();
  static final QuranSearchRepository instance = QuranSearchRepository._();

  static const _base = 'https://api.alquran.cloud/v1';
  static const _searchCache = 'quran_search_v1';
  static const _surahCache = 'quran_surah_v3';

  Future<QuranSearchResponse> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.length < 2) {
      return const QuranSearchResponse(results: [], edition: '', offlineOnly: false);
    }
    final edition = _editionFor(query);
    final key = '$edition::${query.toLowerCase()}';

    try {
      final uri = Uri.parse(
        '$_base/search/${Uri.encodeComponent(query)}/all/$edition',
      );
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Quran search API ${response.statusCode}');
      }
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final data = root['data'];
      if (root['code'] != 200 || data is! Map) {
        throw Exception('Invalid Quran search response');
      }
      final matches = (data['matches'] as List? ?? const [])
          .whereType<Map>()
          .map((match) {
            final item = Map<String, dynamic>.from(match);
            final surah = item['surah'] is Map
                ? Map<String, dynamic>.from(item['surah'] as Map)
                : <String, dynamic>{};
            return QuranSearchResult(
              surahNumber: (surah['number'] as num?)?.toInt() ?? 0,
              surahName: surah['name']?.toString() ?? '',
              englishName: surah['englishName']?.toString() ?? '',
              ayahNumber: (item['numberInSurah'] as num?)?.toInt() ?? 0,
              text: item['text']?.toString() ?? '',
              edition: edition,
            );
          })
          .where((result) => result.surahNumber > 0 && result.ayahNumber > 0)
          .toList();

      await LocalStore.instance.putJson(_searchCache, key, {
        'edition': edition,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'results': matches.map((e) => e.toJson()).toList(),
      }, syncStatus: 'cached');

      return QuranSearchResponse(
        results: matches,
        edition: edition,
        offlineOnly: false,
      );
    } catch (_) {
      final cached = await LocalStore.instance.getJson(_searchCache, key);
      if (cached != null) {
        final rows = (cached['results'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => QuranSearchResult.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (rows.isNotEmpty) {
          return QuranSearchResponse(
            results: rows,
            edition: cached['edition']?.toString() ?? edition,
            offlineOnly: true,
          );
        }
      }

      final local = await _searchCachedSurahs(query, edition);
      return QuranSearchResponse(
        results: local,
        edition: edition,
        offlineOnly: true,
      );
    }
  }

  Future<List<QuranSearchResult>> _searchCachedSurahs(
    String query,
    String edition,
  ) async {
    final records = await LocalStore.instance.listJson(_surahCache);
    final needle = query.toLowerCase();
    final seen = <String>{};
    final results = <QuranSearchResult>[];

    for (final raw in records.values) {
      final surah = QuranSurahData.fromJson(raw);
      for (final ayah in surah.ayahs) {
        final haystack = switch (edition) {
          'bn.bengali' => ayah.bangla,
          'quran-uthmani' => ayah.arabic,
          _ => ayah.english,
        };
        if (!haystack.toLowerCase().contains(needle)) continue;
        final key = '${surah.number}:${ayah.numberInSurah}';
        if (!seen.add(key)) continue;
        results.add(QuranSearchResult(
          surahNumber: surah.number,
          surahName: surah.arabicName,
          englishName: surah.englishName,
          ayahNumber: ayah.numberInSurah,
          text: haystack,
          edition: edition,
          fromOfflineCache: true,
        ));
      }
    }
    results.sort((a, b) {
      final surahCompare = a.surahNumber.compareTo(b.surahNumber);
      return surahCompare != 0 ? surahCompare : a.ayahNumber.compareTo(b.ayahNumber);
    });
    return results;
  }

  String _editionFor(String query) {
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(query)) return 'bn.bengali';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(query)) return 'quran-uthmani';
    return 'en.sahih';
  }
}
