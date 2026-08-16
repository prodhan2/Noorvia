import 'package:flutter/material.dart';

/// Renders the bracket markup used by Al Quran Cloud's `quran-tajweed`
/// edition as a Flutter RichText tree.
///
/// The upstream format marks a styled fragment as e.g. `[q[ق]` or
/// `[h:1[ٱ]`. Unknown markers are rendered with the base style so Quran text
/// remains readable even if the upstream vocabulary expands.
class TajweedText extends StatelessWidget {
  const TajweedText(
    this.markup, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
  });

  final String markup;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;

  static final RegExp _token = RegExp(r'\[([a-z])(?::\d+)?\[([^\]]*)\]');

  @override
  Widget build(BuildContext context) {
    if (markup.isEmpty || !markup.contains('[')) {
      return Text(
        markup,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
      );
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _token.allMatches(markup)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: markup.substring(cursor, match.start), style: style));
      }
      final code = match.group(1) ?? '';
      final text = match.group(2) ?? '';
      spans.add(TextSpan(text: text, style: _styleFor(code)));
      cursor = match.end;
    }
    if (cursor < markup.length) {
      spans.add(TextSpan(text: markup.substring(cursor), style: style));
    }

    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      text: TextSpan(style: style, children: spans),
    );
  }

  TextStyle _styleFor(String code) {
    final color = switch (code) {
      // hamzat al-wasl / silent / lam shamsiyyah
      'h' || 's' || 'l' => const Color(0xFF8A8F94),
      // madd families
      'n' => const Color(0xFF4B79FF),
      'p' => const Color(0xFF4050FF),
      'm' => const Color(0xFF001EBD),
      'o' => const Color(0xFF2144C1),
      // qalqalah
      'q' => const Color(0xFFD91C2B),
      // ikhfa / ikhfa shafawi
      'f' => const Color(0xFF8A16A3),
      'c' => const Color(0xFFC718A8),
      // iqlab
      'i' => const Color(0xFF009DCC),
      // idgham families
      'a' || 'u' || 'w' => const Color(0xFF168A2B),
      'd' || 'b' => const Color(0xFF6D7A78),
      // ghunnah
      'g' => const Color(0xFFF07818),
      _ => style.color,
    };
    return style.copyWith(color: color, fontWeight: FontWeight.w600);
  }
}
