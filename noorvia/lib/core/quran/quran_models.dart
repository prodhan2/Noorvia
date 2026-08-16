class QuranAyahData {
  const QuranAyahData({
    required this.numberInSurah,
    required this.globalNumber,
    required this.arabic,
    required this.tajweed,
    required this.bangla,
    required this.english,
    required this.transliteration,
    required this.audioUrl,
    required this.page,
    required this.juz,
  });

  final int numberInSurah;
  final int globalNumber;
  final String arabic;
  final String tajweed;
  final String bangla;
  final String english;
  final String transliteration;
  final String audioUrl;
  final int page;
  final int juz;

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'globalNumber': globalNumber,
        'arabic': arabic,
        'tajweed': tajweed,
        'bangla': bangla,
        'english': english,
        'transliteration': transliteration,
        'audioUrl': audioUrl,
        'page': page,
        'juz': juz,
      };

  factory QuranAyahData.fromJson(Map<String, dynamic> json) => QuranAyahData(
        numberInSurah: (json['numberInSurah'] as num?)?.toInt() ?? 0,
        globalNumber: (json['globalNumber'] as num?)?.toInt() ?? 0,
        arabic: json['arabic']?.toString() ?? '',
        tajweed: json['tajweed']?.toString() ?? '',
        bangla: json['bangla']?.toString() ?? '',
        english: json['english']?.toString() ?? '',
        transliteration: json['transliteration']?.toString() ?? '',
        audioUrl: json['audioUrl']?.toString() ?? '',
        page: (json['page'] as num?)?.toInt() ?? 0,
        juz: (json['juz'] as num?)?.toInt() ?? 0,
      );
}

class QuranSurahData {
  const QuranSurahData({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishMeaning,
    required this.revelationType,
    required this.ayahs,
    required this.reciter,
  });

  final int number;
  final String arabicName;
  final String englishName;
  final String englishMeaning;
  final String revelationType;
  final List<QuranAyahData> ayahs;
  final String reciter;

  Map<String, dynamic> toJson() => {
        'number': number,
        'arabicName': arabicName,
        'englishName': englishName,
        'englishMeaning': englishMeaning,
        'revelationType': revelationType,
        'reciter': reciter,
        'ayahs': ayahs.map((e) => e.toJson()).toList(),
      };

  factory QuranSurahData.fromJson(Map<String, dynamic> json) => QuranSurahData(
        number: (json['number'] as num?)?.toInt() ?? 0,
        arabicName: json['arabicName']?.toString() ?? '',
        englishName: json['englishName']?.toString() ?? '',
        englishMeaning: json['englishMeaning']?.toString() ?? '',
        revelationType: json['revelationType']?.toString() ?? '',
        reciter: json['reciter']?.toString() ?? 'ar.alafasy',
        ayahs: ((json['ayahs'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => QuranAyahData.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
