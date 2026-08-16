import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/local/local_store.dart';
import '../models/hadith_record.dart';

class HadithBook {
  final String key;
  final String bnName;
  final String enName;
  const HadithBook(this.key, this.bnName, this.enName);
}

class HadithService {
  static const _base = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1';
  static const _ns = 'hadith_api_v1';
  static const books = <HadithBook>[
    HadithBook('bukhari', 'সহীহ বুখারী', 'Sahih al-Bukhari'),
    HadithBook('muslim', 'সহীহ মুসলিম', 'Sahih Muslim'),
    HadithBook('nawawi', 'ইমাম নববীর ৪০ হাদিস', 'Forty Hadith of an-Nawawi'),
    HadithBook('abudawud', 'সুনান আবু দাউদ', 'Sunan Abu Dawud'),
    HadithBook('tirmidhi', 'জামে আত-তিরমিযী', 'Jami at-Tirmidhi'),
    HadithBook('nasai', 'সুনান আন-নাসাঈ', 'Sunan an-Nasai'),
    HadithBook('ibnmajah', 'সুনান ইবনে মাজাহ', 'Sunan Ibn Majah'),
  ];

  Future<List<HadithRecord>> loadBook({
    required String bookKey,
    required bool english,
    bool forceRefresh = false,
  }) async {
    final language = english ? 'eng' : 'ben';
    final cacheKey = '$language-$bookKey';
    if (!forceRefresh) {
      final cached = await LocalStore.instance.getJson(_ns, cacheKey);
      final rows = cached?['hadiths'];
      if (rows is List && rows.isNotEmpty) {
        return rows.whereType<Map>().map((e) => HadithRecord.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    }

    final edition = '$language-$bookKey';
    final data = await _getJsonWithFallback('editions/$edition');
    final metadata = data['metadata'] is Map ? Map<String, dynamic>.from(data['metadata']) : <String, dynamic>{};
    final bookName = metadata['name']?.toString() ?? bookKey;
    final sectionsRaw = metadata['section'];
    final sections = sectionsRaw is Map ? Map<String, dynamic>.from(sectionsRaw) : <String, dynamic>{};
    final hadiths = data['hadiths'];
    if (hadiths is! List) throw Exception('Hadith data unavailable');

    final rows = <HadithRecord>[];
    for (final item in hadiths.whereType<Map>()) {
      final m = Map<String, dynamic>.from(item);
      final ref = m['reference'] is Map ? Map<String, dynamic>.from(m['reference']) : const <String, dynamic>{};
      final sectionNo = (ref['book'] as num?)?.toInt();
      final grades = <String>[];
      if (m['grades'] is List) {
        for (final g in (m['grades'] as List).whereType<Map>()) {
          final gm = Map<String, dynamic>.from(g);
          final grade = gm['grade']?.toString();
          if (grade != null && grade.isNotEmpty) grades.add(grade);
        }
      }
      final text = m['text']?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      rows.add(HadithRecord(
        number: (m['hadithnumber'] as num?)?.toInt() ?? 0,
        text: text,
        bookKey: bookKey,
        bookName: bookName,
        sectionNumber: sectionNo,
        sectionName: sectionNo == null ? null : sections['$sectionNo']?.toString(),
        grades: grades,
      ));
    }

    await LocalStore.instance.putJson(_ns, cacheKey, {
      'cachedAt': DateTime.now().toIso8601String(),
      'hadiths': rows.map((e) => e.toJson()).toList(),
    });
    return rows;
  }

  Future<HadithRecord> loadOne({
    required String bookKey,
    required int number,
    required bool english,
  }) async {
    final language = english ? 'eng' : 'ben';
    final cacheKey = '$language-$bookKey-$number';
    final cached = await LocalStore.instance.getJson(_ns, cacheKey);
    if (cached != null && cached['record'] is Map) {
      return HadithRecord.fromJson(
        Map<String, dynamic>.from(cached['record'] as Map),
      );
    }

    final data = await _getJsonWithFallback(
      'editions/$language-$bookKey/$number',
    );
    final hadiths = data['hadiths'];
    if (hadiths is! List || hadiths.isEmpty || hadiths.first is! Map) {
      throw Exception('Hadith not found');
    }
    final item = Map<String, dynamic>.from(hadiths.first as Map);
    final grades = <String>[];
    if (item['grades'] is List) {
      for (final gradeRaw in (item['grades'] as List).whereType<Map>()) {
        final grade = gradeRaw['grade']?.toString().trim();
        if (grade != null && grade.isNotEmpty) grades.add(grade);
      }
    }
    final ref = item['reference'] is Map
        ? Map<String, dynamic>.from(item['reference'] as Map)
        : const <String, dynamic>{};
    final rawBook = ref['book'];
    final sectionNumber = rawBook is num
        ? rawBook.toInt()
        : int.tryParse(rawBook?.toString() ?? '');
    final book = books.firstWhere(
      (b) => b.key == bookKey,
      orElse: () => HadithBook(bookKey, bookKey, bookKey),
    );
    final record = HadithRecord(
      number: (item['hadithnumber'] as num?)?.toInt() ?? number,
      text: item['text']?.toString().trim() ?? '',
      bookKey: bookKey,
      bookName: english ? book.enName : book.bnName,
      sectionNumber: sectionNumber,
      grades: grades,
    );
    if (record.text.isEmpty) throw Exception('Hadith text unavailable');
    await LocalStore.instance.putJson(
      _ns,
      cacheKey,
      {'record': record.toJson(), 'cachedAt': DateTime.now().toIso8601String()},
    );
    return record;
  }

  Future<String?> loadArabic(String bookKey, int number) async {
    final cacheKey = 'ara-$bookKey-$number';
    final cached = await LocalStore.instance.getJson(_ns, cacheKey);
    final cachedText = cached?['text']?.toString();
    if (cachedText != null && cachedText.isNotEmpty) return cachedText;
    try {
      final data = await _getJsonWithFallback('editions/ara-$bookKey/$number');
      final hadiths = data['hadiths'];
      if (hadiths is List && hadiths.isNotEmpty && hadiths.first is Map) {
        final text = (hadiths.first as Map)['text']?.toString();
        if (text != null && text.trim().isNotEmpty) {
          await LocalStore.instance.putJson(_ns, cacheKey, {'text': text.trim()});
          return text.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> _getJsonWithFallback(String endpoint) async {
    Object? last;
    for (final suffix in ['min.json', 'json']) {
      try {
        final response = await http.get(
          Uri.parse('$_base/$endpoint.$suffix'),
          headers: const {'Accept': 'application/json', 'User-Agent': 'Noorvia/1.0'},
        ).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        }
        last = 'HTTP ${response.statusCode}';
      } catch (e) {
        last = e;
      }
    }
    throw Exception('Hadith source unavailable: $last');
  }
}
