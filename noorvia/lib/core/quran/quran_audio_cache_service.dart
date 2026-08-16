import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'quran_models.dart';

/// Dedicated Quran recitation cache.
///
/// Audio that has been played/downloaded remains available offline without
/// mixing with Noorvia's general-purpose network cache.
class QuranAudioCacheService {
  QuranAudioCacheService._();
  static final QuranAudioCacheService instance = QuranAudioCacheService._();

  final CacheManager _cache = CacheManager(
    Config(
      'noorvia_quran_audio_v1',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 7000,
    ),
  );

  Future<File?> getCached(String url) async {
    if (url.isEmpty) return null;
    final info = await _cache.getFileFromCache(url);
    return info?.file;
  }

  Future<File> getOrDownload(String url) async {
    final cached = await getCached(url);
    if (cached != null && await cached.exists()) return cached;
    return _cache.getSingleFile(url);
  }

  Future<void> downloadSurah(
    QuranSurahData surah, {
    void Function(int done, int total)? onProgress,
  }) async {
    var done = 0;
    for (final ayah in surah.ayahs) {
      if (ayah.audioUrl.isNotEmpty) {
        await getOrDownload(ayah.audioUrl);
      }
      done++;
      onProgress?.call(done, surah.ayahs.length);
    }
  }

  Future<void> clear() => _cache.emptyCache();
}
