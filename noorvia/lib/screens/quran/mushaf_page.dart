import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../core/data/local/local_store.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/web_view_page.dart';
import 'surah_detail_page.dart';

class MushafPage extends StatefulWidget {
  const MushafPage({super.key});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  static const String _lastSurahKey = 'mushafLastSurah';
  static const String _mushafSourceKey = 'selectedMushafSource';
  static const String _madaniSvgSourceId = 'alfurqan_svg';
  static const String _nativeSourceId = 'noorvia_native';
  static const String _prefsNamespace = 'quran_mushaf';

  int _lastSurah = 1;
  _MushafSource _selectedSource = _mushafSources.first;

  @override
  void initState() {
    super.initState();
    _loadLastSurah();
  }

  Future<void> _loadLastSurah() async {
    final data = await LocalStore.instance.getJson(_prefsNamespace, 'reader_state');
    if (!mounted) return;
    final sourceId = data?[_mushafSourceKey]?.toString();
    setState(() {
      _lastSurah = (data?[_lastSurahKey] as num?)?.toInt() ?? 1;
      _selectedSource = _mushafSources.firstWhere(
        (source) => source.id == sourceId,
        orElse: () => _mushafSources.first,
      );
    });
  }

  Future<void> _persistState() => LocalStore.instance.putJson(
        _prefsNamespace,
        'reader_state',
        {
          _lastSurahKey: _lastSurah,
          _mushafSourceKey: _selectedSource.id,
        },
      );

  Future<void> _selectSource(_MushafSource source) async {
    if (!mounted) return;
    setState(() => _selectedSource = source);
    await _persistState();
  }

  Future<void> _openSurah(_MushafSurah surah) async {
    if (!mounted) return;
    setState(() => _lastSurah = surah.number);
    await _persistState();

    if (_selectedSource.id == _nativeSourceId) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurahDetailPage(
            surahName: surah.name,
            arabicName: surah.arabic,
            surahNumber: surah.number,
            ayatCount: surah.ayahs,
            type: '',
          ),
        ),
      );
      return;
    }

    if (_selectedSource.id == _madaniSvgSourceId) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _MadaniSvgSurahReaderPage(surah: surah, source: _selectedSource),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewPage(
          title: '${_selectedSource.label} - ${surah.name}',
          url: _selectedSource.urlFor(surah),
        ),
      ),
    );
  }

  // ignore: unused_element
  String _bn(Object value) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var text = value.toString();
    for (var i = 0; i < en.length; i++) {
      text = text.replaceAll(en[i], bn[i]);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? AppColors.darkSubText : Colors.black54;
    final lastSurah = _surahs[_lastSurah - 1];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'কুরআন মুসহাফ',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openSurah(lastSurah),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'শেষ পড়া সূরা',
                            style: GoogleFonts.hindSiliguri(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lastSurah.name} থেকে চালিয়ে যান',
                            style: GoogleFonts.hindSiliguri(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _mushafSources.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final source = _mushafSources[index];
                final isSelected = source.id == _selectedSource.id;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(source.label),
                  avatar: Icon(
                    source.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  onSelected: (_) => _selectSource(source),
                  selectedColor: AppColors.primary,
                  backgroundColor: cardColor,
                  labelStyle: GoogleFonts.hindSiliguri(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _surahs.length,
              itemBuilder: (context, index) {
                final surah = _surahs[index];
                final isLast = surah.number == _lastSurah;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openSurah(surah),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isLast ? AppColors.primary : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLast
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isLast
                                ? Colors.white.withValues(alpha: 0.16)
                                : AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _bn(surah.number),
                            style: GoogleFonts.hindSiliguri(
                              color: isLast ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surah.name,
                                style: GoogleFonts.hindSiliguri(
                                  color: isLast ? Colors.white : textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_bn(surah.ayahs)} আয়াত',
                                style: GoogleFonts.hindSiliguri(
                                  color: isLast ? Colors.white70 : subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          surah.arabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: isLast
                                ? Colors.white
                                : const Color(0xFFB8860B),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafSurah {
  final int number;
  final String name;
  final String arabic;
  final int ayahs;
  int get startPage => _surahStartPages[number] ?? 1;
  int get endPage {
    if (number >= 114) return 604;
    final nextStartPage = _surahStartPages[number + 1] ?? 605;
    if (nextStartPage <= startPage) return startPage;
    return nextStartPage - 1;
  }

  const _MushafSurah(this.number, this.name, this.arabic, this.ayahs);
}

class _MushafSource {
  final String id;
  final String label;
  final String script;
  final String field;
  final String Function(_MushafSurah surah) urlFor;
  final IconData icon;

  const _MushafSource({
    required this.id,
    required this.label,
    required this.urlFor,
    required this.icon,
    this.script = 'uthmani',
    this.field = 'text_uthmani',
  });
}

typedef _MushafType = _MushafSource;

final List<_MushafSource> _mushafSources = [
  _MushafSource(
    id: 'noorvia_native',
    label: 'নূরভিয়া মুসহাফ',
    urlFor: (surah) => '',
    icon: Icons.auto_stories_rounded,
  ),
  _MushafSource(
    id: 'alquran_cloud',
    label: 'Al Quran Cloud',
    urlFor: (surah) => 'https://alquran.cloud/mushaf/${surah.startPage}',
    icon: Icons.cloud_outlined,
  ),
  _MushafSource(
    id: 'quran_com',
    label: 'Quran.com',
    urlFor: (surah) => 'https://quran.com/${surah.number}',
    icon: Icons.auto_stories_rounded,
    script: 'uthmani',
    field: 'text_uthmani',
  ),
  _MushafSource(
    id: 'alfurqan_svg',
    label: 'মাদানী SVG',
    urlFor: (surah) =>
        'https://alfurqan.online/api/v1/quran-text/page/${surah.startPage}',
    icon: Icons.menu_book_rounded,
  ),
  _MushafSource(
    id: 'noor_page',
    label: 'Noor Page',
    urlFor: (surah) => 'https://www.noorulquraan.com/page/${surah.startPage}',
    icon: Icons.chrome_reader_mode_rounded,
  ),
];

const Map<int, int> _surahStartPages = {
  1: 1,
  2: 2,
  3: 50,
  4: 77,
  5: 106,
  6: 128,
  7: 151,
  8: 177,
  9: 187,
  10: 208,
  11: 221,
  12: 235,
  13: 249,
  14: 255,
  15: 262,
  16: 267,
  17: 282,
  18: 293,
  19: 305,
  20: 312,
  21: 322,
  22: 332,
  23: 342,
  24: 350,
  25: 359,
  26: 367,
  27: 377,
  28: 385,
  29: 396,
  30: 404,
  31: 411,
  32: 415,
  33: 418,
  34: 428,
  35: 434,
  36: 440,
  37: 446,
  38: 453,
  39: 458,
  40: 467,
  41: 477,
  42: 483,
  43: 489,
  44: 496,
  45: 499,
  46: 502,
  47: 507,
  48: 511,
  49: 515,
  50: 518,
  51: 520,
  52: 523,
  53: 526,
  54: 528,
  55: 531,
  56: 534,
  57: 537,
  58: 542,
  59: 545,
  60: 549,
  61: 551,
  62: 553,
  63: 554,
  64: 556,
  65: 558,
  66: 560,
  67: 562,
  68: 564,
  69: 566,
  70: 568,
  71: 570,
  72: 572,
  73: 574,
  74: 575,
  75: 577,
  76: 578,
  77: 580,
  78: 582,
  79: 583,
  80: 585,
  81: 586,
  82: 587,
  83: 587,
  84: 589,
  85: 590,
  86: 591,
  87: 591,
  88: 592,
  89: 593,
  90: 594,
  91: 595,
  92: 595,
  93: 596,
  94: 596,
  95: 597,
  96: 597,
  97: 598,
  98: 598,
  99: 599,
  100: 599,
  101: 600,
  102: 600,
  103: 601,
  104: 601,
  105: 601,
  106: 602,
  107: 602,
  108: 602,
  109: 603,
  110: 603,
  111: 603,
  112: 604,
  113: 604,
  114: 604,
};

class _MadaniSvgSurahReaderPage extends StatefulWidget {
  final _MushafSurah surah;
  final _MushafSource source;

  const _MadaniSvgSurahReaderPage({required this.surah, required this.source});

  @override
  State<_MadaniSvgSurahReaderPage> createState() =>
      _MadaniSvgSurahReaderPageState();
}

class _MadaniSvgSurahReaderPageState extends State<_MadaniSvgSurahReaderPage> {
  late final PageController _pageController;
  late int _currentPage;

  static const int _firstPage = 1;
  static const int _lastPage = 604;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.surah.startPage;
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _pageUrl(int page) {
    return 'https://alfurqan.online/api/v1/quran-text/page/$page';
  }

  // ignore: unused_element
  String _bn(Object value) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var text = value.toString();
    for (var i = 0; i < en.length; i++) {
      text = text.replaceAll(en[i], bn[i]);
    }
    return text;
  }

  Future<void> _goToPage(int page) async {
    if (page < _firstPage || page > _lastPage) return;
    await _pageController.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.surah.name} - ${widget.source.label}',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              reverse: true,
              itemCount: _lastPage,
              onPageChanged: (index) {
                setState(() => _currentPage = index + 1);
              },
              itemBuilder: (context, index) {
                final page = index + 1;
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.network(
                      _pageUrl(page),
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E6E2))),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: _currentPage < _lastPage
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Page $_currentPage / $_lastPage',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hindSiliguri(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: _currentPage > _firstPage
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafSurahReaderPage extends StatefulWidget {
  final _MushafSurah surah;
  final _MushafType mushafType;

  const _MushafSurahReaderPage({required this.surah, required this.mushafType});

  @override
  State<_MushafSurahReaderPage> createState() => _MushafSurahReaderPageState();
}

class _MushafSurahReaderPageState extends State<_MushafSurahReaderPage> {
  late Future<List<_MushafVerse>> _versesFuture;

  @override
  void initState() {
    super.initState();
    _versesFuture = _loadVerses();
  }

  Future<List<_MushafVerse>> _loadVerses() async {
    final uri = Uri.parse(
      'https://api.quran.com/api/v4/quran/verses/'
      '${widget.mushafType.script}?chapter_number=${widget.surah.number}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to load mushaf');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final verses = decoded['verses'] as List<dynamic>;
    return verses.map((item) {
      final verse = item as Map<String, dynamic>;
      final key = verse['verse_key']?.toString() ?? '';
      final ayahNumber = int.tryParse(key.split(':').last) ?? 0;
      final text = _cleanVerseText(verse[widget.mushafType.field]?.toString());
      return _MushafVerse(ayahNumber: ayahNumber, text: text);
    }).toList();
  }

  String _cleanVerseText(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _bn(Object value) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var text = value.toString();
    for (var i = 0; i < en.length; i++) {
      text = text.replaceAll(en[i], bn[i]);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.surah.name} - ${widget.mushafType.label}',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: FutureBuilder<List<_MushafVerse>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'মুসহাফ লোড করা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          final verses = snapshot.data ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _bn(verse.ayahNumber),
                          style: GoogleFonts.hindSiliguri(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      verse.text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: textColor,
                        fontSize: widget.mushafType.script.contains('nastaleeq')
                            ? 28
                            : 25,
                        height: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MushafVerse {
  final int ayahNumber;
  final String text;

  const _MushafVerse({required this.ayahNumber, required this.text});
}

const List<_MushafSurah> _surahs = [
  _MushafSurah(1, 'আল-ফাতিহা', 'الفاتحة', 7),
  _MushafSurah(2, 'আল-বাকারা', 'البقرة', 286),
  _MushafSurah(3, 'আলে-ইমরান', 'آل عمران', 200),
  _MushafSurah(4, 'আন-নিসা', 'النساء', 176),
  _MushafSurah(5, 'আল-মায়িদা', 'المائدة', 120),
  _MushafSurah(6, 'আল-আনআম', 'الأنعام', 165),
  _MushafSurah(7, 'আল-আরাফ', 'الأعراف', 206),
  _MushafSurah(8, 'আল-আনফাল', 'الأنفال', 75),
  _MushafSurah(9, 'আত-তাওবা', 'التوبة', 129),
  _MushafSurah(10, 'ইউনুস', 'يونس', 109),
  _MushafSurah(11, 'হুদ', 'هود', 123),
  _MushafSurah(12, 'ইউসুফ', 'يوسف', 111),
  _MushafSurah(13, 'আর-রাদ', 'الرعد', 43),
  _MushafSurah(14, 'ইবরাহিম', 'إبراهيم', 52),
  _MushafSurah(15, 'আল-হিজর', 'الحجر', 99),
  _MushafSurah(16, 'আন-নাহল', 'النحل', 128),
  _MushafSurah(17, 'আল-ইসরা', 'الإسراء', 111),
  _MushafSurah(18, 'আল-কাহফ', 'الكهف', 110),
  _MushafSurah(19, 'মারইয়াম', 'مريم', 98),
  _MushafSurah(20, 'ত্বা-হা', 'طه', 135),
  _MushafSurah(21, 'আল-আম্বিয়া', 'الأنبياء', 112),
  _MushafSurah(22, 'আল-হাজ্জ', 'الحج', 78),
  _MushafSurah(23, 'আল-মুমিনুন', 'المؤمنون', 118),
  _MushafSurah(24, 'আন-নূর', 'النور', 64),
  _MushafSurah(25, 'আল-ফুরকান', 'الفرقان', 77),
  _MushafSurah(26, 'আশ-শুআরা', 'الشعراء', 227),
  _MushafSurah(27, 'আন-নামল', 'النمل', 93),
  _MushafSurah(28, 'আল-কাসাস', 'القصص', 88),
  _MushafSurah(29, 'আল-আনকাবুত', 'العنكبوت', 69),
  _MushafSurah(30, 'আর-রূম', 'الروم', 60),
  _MushafSurah(31, 'লুকমান', 'لقمان', 34),
  _MushafSurah(32, 'আস-সাজদা', 'السجدة', 30),
  _MushafSurah(33, 'আল-আহযাব', 'الأحزاب', 73),
  _MushafSurah(34, 'সাবা', 'سبأ', 54),
  _MushafSurah(35, 'ফাতির', 'فاطر', 45),
  _MushafSurah(36, 'ইয়া-সীন', 'يس', 83),
  _MushafSurah(37, 'আস-সাফফাত', 'الصافات', 182),
  _MushafSurah(38, 'সাদ', 'ص', 88),
  _MushafSurah(39, 'আয-যুমার', 'الزمر', 75),
  _MushafSurah(40, 'গাফির', 'غافر', 85),
  _MushafSurah(41, 'ফুসসিলাত', 'فصلت', 54),
  _MushafSurah(42, 'আশ-শূরা', 'الشورى', 53),
  _MushafSurah(43, 'আয-যুখরুফ', 'الزخرف', 89),
  _MushafSurah(44, 'আদ-দুখান', 'الدخان', 59),
  _MushafSurah(45, 'আল-জাসিয়া', 'الجاثية', 37),
  _MushafSurah(46, 'আল-আহকাফ', 'الأحقاف', 35),
  _MushafSurah(47, 'মুহাম্মাদ', 'محمد', 38),
  _MushafSurah(48, 'আল-ফাতহ', 'الفتح', 29),
  _MushafSurah(49, 'আল-হুজুরাত', 'الحجرات', 18),
  _MushafSurah(50, 'কাফ', 'ق', 45),
  _MushafSurah(51, 'আয-যারিয়াত', 'الذاريات', 60),
  _MushafSurah(52, 'আত-তূর', 'الطور', 49),
  _MushafSurah(53, 'আন-নাজম', 'النجم', 62),
  _MushafSurah(54, 'আল-কামার', 'القمر', 55),
  _MushafSurah(55, 'আর-রাহমান', 'الرحمن', 78),
  _MushafSurah(56, 'আল-ওয়াকিয়া', 'الواقعة', 96),
  _MushafSurah(57, 'আল-হাদীদ', 'الحديد', 29),
  _MushafSurah(58, 'আল-মুজাদিলা', 'المجادلة', 22),
  _MushafSurah(59, 'আল-হাশর', 'الحشر', 24),
  _MushafSurah(60, 'আল-মুমতাহিনা', 'الممتحنة', 13),
  _MushafSurah(61, 'আস-সাফ', 'الصف', 14),
  _MushafSurah(62, 'আল-জুমুআ', 'الجمعة', 11),
  _MushafSurah(63, 'আল-মুনাফিকুন', 'المنافقون', 11),
  _MushafSurah(64, 'আত-তাগাবুন', 'التغابن', 18),
  _MushafSurah(65, 'আত-তালাক', 'الطلاق', 12),
  _MushafSurah(66, 'আত-তাহরীম', 'التحريم', 12),
  _MushafSurah(67, 'আল-মুলক', 'الملك', 30),
  _MushafSurah(68, 'আল-কালাম', 'القلم', 52),
  _MushafSurah(69, 'আল-হাক্কাহ', 'الحاقة', 52),
  _MushafSurah(70, 'আল-মাআরিজ', 'المعارج', 44),
  _MushafSurah(71, 'নূহ', 'نوح', 28),
  _MushafSurah(72, 'আল-জিন', 'الجن', 28),
  _MushafSurah(73, 'আল-মুযযাম্মিল', 'المزمل', 20),
  _MushafSurah(74, 'আল-মুদ্দাসসির', 'المدثر', 56),
  _MushafSurah(75, 'আল-কিয়ামাহ', 'القيامة', 40),
  _MushafSurah(76, 'আল-ইনসান', 'الإنسان', 31),
  _MushafSurah(77, 'আল-মুরসালাত', 'المرسلات', 50),
  _MushafSurah(78, 'আন-নাবা', 'النبأ', 40),
  _MushafSurah(79, 'আন-নাযিআত', 'النازعات', 46),
  _MushafSurah(80, 'আবাসা', 'عبس', 42),
  _MushafSurah(81, 'আত-তাকভীর', 'التكوير', 29),
  _MushafSurah(82, 'আল-ইনফিতার', 'الإنفطار', 19),
  _MushafSurah(83, 'আল-মুতাফফিফীন', 'المطففين', 36),
  _MushafSurah(84, 'আল-ইনশিকাক', 'الإنشقاق', 25),
  _MushafSurah(85, 'আল-বুরুজ', 'البروج', 22),
  _MushafSurah(86, 'আত-তারিক', 'الطارق', 17),
  _MushafSurah(87, 'আল-আলা', 'الأعلى', 19),
  _MushafSurah(88, 'আল-গাশিয়াহ', 'الغاشية', 26),
  _MushafSurah(89, 'আল-ফাজর', 'الفجر', 30),
  _MushafSurah(90, 'আল-বালাদ', 'البلد', 20),
  _MushafSurah(91, 'আশ-শামস', 'الشمس', 15),
  _MushafSurah(92, 'আল-লাইল', 'الليل', 21),
  _MushafSurah(93, 'আদ-দুহা', 'الضحى', 11),
  _MushafSurah(94, 'আশ-শারহ', 'الشرح', 8),
  _MushafSurah(95, 'আত-তীন', 'التين', 8),
  _MushafSurah(96, 'আল-আলাক', 'العلق', 19),
  _MushafSurah(97, 'আল-কদর', 'القدر', 5),
  _MushafSurah(98, 'আল-বাইয়্যিনাহ', 'البينة', 8),
  _MushafSurah(99, 'আয-যিলযাল', 'الزلزلة', 8),
  _MushafSurah(100, 'আল-আদিয়াত', 'العاديات', 11),
  _MushafSurah(101, 'আল-কারিআহ', 'القارعة', 11),
  _MushafSurah(102, 'আত-তাকাসুর', 'التكاثر', 8),
  _MushafSurah(103, 'আল-আসর', 'العصر', 3),
  _MushafSurah(104, 'আল-হুমাযাহ', 'الهمزة', 9),
  _MushafSurah(105, 'আল-ফীল', 'الفيل', 5),
  _MushafSurah(106, 'কুরাইশ', 'قريش', 4),
  _MushafSurah(107, 'আল-মাউন', 'الماعون', 7),
  _MushafSurah(108, 'আল-কাউসার', 'الكوثر', 3),
  _MushafSurah(109, 'আল-কাফিরুন', 'الكافرون', 6),
  _MushafSurah(110, 'আন-নাসর', 'النصر', 3),
  _MushafSurah(111, 'আল-মাসাদ', 'المسد', 5),
  _MushafSurah(112, 'আল-ইখলাস', 'الإخلاص', 4),
  _MushafSurah(113, 'আল-ফালাক', 'الفلق', 5),
  _MushafSurah(114, 'আন-নাস', 'الناس', 6),
];
