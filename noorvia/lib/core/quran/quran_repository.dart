import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/local/local_store.dart';
import 'quran_models.dart';

/// Offline-first Quran repository.
///
/// Primary public source: Al Quran Cloud. The Quran text and translations are
/// cached in Isar so previously opened Surahs remain fully readable offline.
class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  static const _base = 'https://api.alquran.cloud/v1';
  static const _namespace = 'quran_surah_v3';

  Future<QuranSurahData> getSurah(
    int surahNumber, {
    String reciter = 'ar.alafasy',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${surahNumber}_$reciter';
    if (!forceRefresh) {
      final cached = await LocalStore.instance.getJson(_namespace, cacheKey);
      if (cached != null) {
        return QuranSurahData.fromJson(cached);
      }
    }

    try {
      final fresh = await _fetchSurah(surahNumber, reciter);
      await LocalStore.instance.putJson(
        _namespace,
        cacheKey,
        fresh.toJson(),
        syncStatus: 'cached',
      );
      return fresh;
    } catch (e) {
      final cached = await LocalStore.instance.getJson(_namespace, cacheKey);
      if (cached != null) return QuranSurahData.fromJson(cached);
      rethrow;
    }
  }

  Future<QuranSurahData> _fetchSurah(int surahNumber, String reciter) async {
    final safeReciter = reciter.startsWith('ar.') ? reciter : 'ar.alafasy';
    final editions = [
      'quran-uthmani',
      'quran-tajweed',
      'bn.bengali',
      'en.sahih',
      'en.transliteration',
      safeReciter,
    ].join(',');
    final uri = Uri.parse('$_base/surah/$surahNumber/editions/$editions');
    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw Exception('Quran API ${response.statusCode}');
    }

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    if (root['code'] != 200 || root['data'] is! List) {
      throw Exception('Invalid Quran API response');
    }
    final editionsData = (root['data'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    Map<String, dynamic>? byIdentifier(String id) {
      for (final edition in editionsData) {
        final info = edition['edition'];
        if (info is Map && info['identifier']?.toString() == id) return edition;
      }
      return null;
    }

    final arabic = byIdentifier('quran-uthmani') ?? editionsData.first;
    final tajweed = byIdentifier('quran-tajweed');
    final bangla = byIdentifier('bn.bengali');
    final english = byIdentifier('en.sahih');
    final transliteration = byIdentifier('en.transliteration');
    final audio = byIdentifier(safeReciter);

    final arAyahs = ((arabic['ayahs'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final tjAyahs = ((tajweed?['ayahs'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final bnAyahs = ((bangla?['ayahs'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final enAyahs = ((english?['ayahs'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final trAyahs = ((transliteration?['ayahs'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final audioAyahs = ((audio?['ayahs'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    String at(List<Map<String, dynamic>> list, int index, String field) =>
        index < list.length ? list[index][field]?.toString() ?? '' : '';

    final ayahs = <QuranAyahData>[];
    for (var i = 0; i < arAyahs.length; i++) {
      final item = arAyahs[i];
      final global = (item['number'] as num?)?.toInt() ?? 0;
      final audioUrl = at(audioAyahs, i, 'audio');
      ayahs.add(QuranAyahData(
        numberInSurah: (item['numberInSurah'] as num?)?.toInt() ?? i + 1,
        globalNumber: global,
        arabic: item['text']?.toString() ?? '',
        tajweed: at(tjAyahs, i, 'text'),
        bangla: at(bnAyahs, i, 'text'),
        english: at(enAyahs, i, 'text'),
        transliteration: _stripHtml(at(trAyahs, i, 'text')),
        audioUrl: audioUrl.isNotEmpty
            ? audioUrl
            : 'https://cdn.islamic.network/quran/audio/128/$safeReciter/$global.mp3',
        page: (item['page'] as num?)?.toInt() ?? 0,
        juz: (item['juz'] as num?)?.toInt() ?? 0,
      ));
    }

    return QuranSurahData(
      number: (arabic['number'] as num?)?.toInt() ?? surahNumber,
      arabicName: arabic['name']?.toString() ?? '',
      englishName: arabic['englishName']?.toString() ?? '',
      englishMeaning: arabic['englishNameTranslation']?.toString() ?? '',
      revelationType: arabic['revelationType']?.toString() ?? '',
      reciter: safeReciter,
      ayahs: ayahs,
    );
  }

  String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}
