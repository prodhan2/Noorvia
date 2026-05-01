// ─── Arabic Letter Model ──────────────────────────────────────────────────────

class ArabicLetterForms {
  final String isolated;
  final String initial;
  final String medial;
  final String finalForm;

  const ArabicLetterForms({
    required this.isolated,
    required this.initial,
    required this.medial,
    required this.finalForm,
  });

  factory ArabicLetterForms.fromJson(Map<String, dynamic> json) {
    return ArabicLetterForms(
      isolated: json['isolated']?.toString() ?? '',
      initial: json['initial']?.toString() ?? '',
      medial: json['medial']?.toString() ?? '',
      finalForm: json['final']?.toString() ?? '',
    );
  }
}

class ArabicLetter {
  final String letter;
  final String name;
  final String bangla;
  final String pronunciation;
  final String audioLink;
  final ArabicLetterForms forms;

  const ArabicLetter({
    required this.letter,
    required this.name,
    required this.bangla,
    required this.pronunciation,
    required this.audioLink,
    required this.forms,
  });

  factory ArabicLetter.fromJson(Map<String, dynamic> json) {
    return ArabicLetter(
      letter: json['letter']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bangla: json['bangla']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? '',
      audioLink: json['audio_link']?.toString() ?? '',
      forms: json['forms'] != null
          ? ArabicLetterForms.fromJson(json['forms'] as Map<String, dynamic>)
          : ArabicLetterForms(
              isolated: json['letter']?.toString() ?? '',
              initial: '',
              medial: '',
              finalForm: '',
            ),
    );
  }
}
