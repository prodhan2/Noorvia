import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/local/local_store.dart';

class IslamicPlaceArticle {
  final int pageId;
  final String title;
  final String? extract;
  final String? thumbnail;
  final double? lat;
  final double? lon;
  const IslamicPlaceArticle({required this.pageId, required this.title, this.extract, this.thumbnail, this.lat, this.lon});
  Map<String, dynamic> toJson() => {'pageId': pageId, 'title': title, 'extract': extract, 'thumbnail': thumbnail, 'lat': lat, 'lon': lon};
  factory IslamicPlaceArticle.fromJson(Map<String, dynamic> j) => IslamicPlaceArticle(
    pageId: (j['pageId'] as num?)?.toInt() ?? 0,
    title: j['title']?.toString() ?? '',
    extract: j['extract']?.toString(),
    thumbnail: j['thumbnail']?.toString(),
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
  );
}

class IslamicPlacesService {
  static const _ns = 'wikimedia_islamic_places';
  static const _keywords = [
    'mosque', 'masjid', 'islam', 'islamic', 'madrasa', 'madrasah', 'muslim',
    'মসজিদ', 'মাদ্রাসা', 'ইসলাম', 'মুসলিম', 'مسجد', 'جامع'
  ];

  Future<List<IslamicPlaceArticle>> nearby({required double lat, required double lon, bool english = true}) async {
    final lang = english ? 'en' : 'bn';
    final key = '$lang:${lat.toStringAsFixed(2)}:${lon.toStringAsFixed(2)}';
    final cached = await LocalStore.instance.getJson(_ns, key);
    if (cached != null) {
      final at = DateTime.tryParse(cached['cachedAt']?.toString() ?? '');
      final items = cached['items'];
      if (at != null && DateTime.now().difference(at) < const Duration(days: 2) && items is List) {
        return items.whereType<Map>().map((e) => IslamicPlaceArticle.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    }

    final uri = Uri.https('$lang.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'generator': 'geosearch',
      'ggscoord': '$lat|$lon',
      'ggsradius': '10000',
      'ggslimit': '50',
      'prop': 'coordinates|pageimages|extracts',
      'piprop': 'thumbnail',
      'pithumbsize': '480',
      'exintro': '1',
      'explaintext': '1',
      'exsentences': '3',
      'redirects': '1',
      'origin': '*',
    });
    final response = await http.get(uri, headers: const {'User-Agent': 'Noorvia/1.0 Islamic places explorer'}).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Wikimedia unavailable');
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final pages = data is Map && data['query'] is Map ? (data['query'] as Map)['pages'] : null;
    if (pages is! Map) return const [];
    final results = <IslamicPlaceArticle>[];
    for (final value in pages.values.whereType<Map>()) {
      final p = Map<String, dynamic>.from(value);
      final title = p['title']?.toString() ?? '';
      final extract = p['extract']?.toString() ?? '';
      final haystack = '$title $extract'.toLowerCase();
      if (!_keywords.any(haystack.contains)) continue;
      double? plat, plon;
      final coords = p['coordinates'];
      if (coords is List && coords.isNotEmpty && coords.first is Map) {
        plat = ((coords.first as Map)['lat'] as num?)?.toDouble();
        plon = ((coords.first as Map)['lon'] as num?)?.toDouble();
      }
      results.add(IslamicPlaceArticle(
        pageId: (p['pageid'] as num?)?.toInt() ?? 0,
        title: title,
        extract: extract,
        thumbnail: p['thumbnail'] is Map ? (p['thumbnail'] as Map)['source']?.toString() : null,
        lat: plat,
        lon: plon,
      ));
    }
    await LocalStore.instance.putJson(
      _ns,
      key,
      {
        'cachedAt': DateTime.now().toIso8601String(),
        'items': results.map((e) => e.toJson()).toList(),
      },
    );
    // Bangla Wikipedia has fewer geotagged articles in many regions. Fall back
    // to English instead of showing an empty explorer.
    if (results.isEmpty && !english) {
      return nearby(lat: lat, lon: lon, english: true);
    }
    return results;
  }
}
