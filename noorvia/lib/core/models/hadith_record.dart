class HadithRecord {
  final int number;
  final String text;
  final String bookKey;
  final String bookName;
  final int? sectionNumber;
  final String? sectionName;
  final List<String> grades;
  final String? arabic;

  const HadithRecord({
    required this.number,
    required this.text,
    required this.bookKey,
    required this.bookName,
    this.sectionNumber,
    this.sectionName,
    this.grades = const [],
    this.arabic,
  });

  HadithRecord copyWith({String? arabic}) => HadithRecord(
        number: number,
        text: text,
        bookKey: bookKey,
        bookName: bookName,
        sectionNumber: sectionNumber,
        sectionName: sectionName,
        grades: grades,
        arabic: arabic ?? this.arabic,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'text': text,
        'bookKey': bookKey,
        'bookName': bookName,
        'sectionNumber': sectionNumber,
        'sectionName': sectionName,
        'grades': grades,
        'arabic': arabic,
      };

  factory HadithRecord.fromJson(Map<String, dynamic> json) => HadithRecord(
        number: (json['number'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        bookKey: json['bookKey']?.toString() ?? '',
        bookName: json['bookName']?.toString() ?? '',
        sectionNumber: (json['sectionNumber'] as num?)?.toInt(),
        sectionName: json['sectionName']?.toString(),
        grades: (json['grades'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        arabic: json['arabic']?.toString(),
      );
}
