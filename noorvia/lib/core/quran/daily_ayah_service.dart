import 'quran_models.dart';
import 'quran_repository.dart';

class DailyAyah {
  const DailyAyah({
    required this.surahNumber,
    required this.surahName,
    required this.englishName,
    required this.ayah,
  });

  final int surahNumber;
  final String surahName;
  final String englishName;
  final QuranAyahData ayah;
}

/// A calm, deterministic daily Quran selection.
///
/// The references intentionally favour shorter Surahs/selected well-known
/// passages so the first fetch is light; QuranRepository then keeps the Surah
/// in Isar for offline reuse. The content itself always comes from the verified
/// Quran repository rather than being copied into application source code.
class DailyAyahService {
  DailyAyahService._();
  static final DailyAyahService instance = DailyAyahService._();

  static const List<(int, int)> _references = [
    (1, 1), (1, 5), (1, 6), (2, 152), (2, 186), (2, 255), (2, 286),
    (3, 8), (3, 139), (8, 46), (9, 51), (13, 28), (14, 7), (16, 97),
    (17, 23), (18, 10), (20, 46), (21, 87), (25, 63), (29, 69),
    (33, 41), (39, 53), (40, 60), (49, 13), (50, 16), (51, 56),
    (57, 4), (59, 18), (65, 2), (67, 2), (73, 20), (87, 14),
    (89, 27), (91, 9), (93, 5), (94, 5), (94, 6), (95, 4),
    (103, 3), (112, 1), (113, 1), (114, 1),
  ];

  Future<DailyAyah> today() async {
    final now = DateTime.now();
    final first = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(first).inDays;
    final index = (now.year * 397 + dayOfYear) % _references.length;
    final ref = _references[index];
    final surah = await QuranRepository.instance.getSurah(ref.$1);
    final ayah = surah.ayahs.firstWhere(
      (item) => item.numberInSurah == ref.$2,
      orElse: () => surah.ayahs.first,
    );
    return DailyAyah(
      surahNumber: surah.number,
      surahName: surah.arabicName,
      englishName: surah.englishName,
      ayah: ayah,
    );
  }
}
