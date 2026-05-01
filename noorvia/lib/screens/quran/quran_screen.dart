import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'surah_detail_page.dart';

// ─── Surah data ───────────────────────────────────────────────────────────────

class SurahInfo {
  final int number;
  final String name;
  final String arabic;
  final String transliteration;
  final String meaning;
  final int ayatCount;
  final String type;

  const SurahInfo({
    required this.number,
    required this.name,
    required this.arabic,
    this.transliteration = '',
    this.meaning = '',
    required this.ayatCount,
    required this.type,
  });
}

const List<SurahInfo> _surahs = [
  SurahInfo(number: 1,   name: 'আল-ফাতিহা',   arabic: 'الفاتحة',    transliteration: 'Al-Fatihah',  meaning: 'সূচনা',                  ayatCount: 7,   type: 'মাক্কী'),
  SurahInfo(number: 2,   name: 'আল-বাকারা',   arabic: 'البقرة',     transliteration: 'Al-Baqarah',  meaning: 'বকনা-বাছুর',             ayatCount: 286, type: 'মাদানী'),
  SurahInfo(number: 3,   name: 'আলে-ইমরান',   arabic: 'آل عمران',   transliteration: "Ali 'Imran",  meaning: 'ইমরানের পরিবার',         ayatCount: 200, type: 'মাদানী'),
  SurahInfo(number: 4,   name: 'আন-নিসা',     arabic: 'النساء',     transliteration: 'An-Nisa',     meaning: 'নারী',                   ayatCount: 176, type: 'মাদানী'),
  SurahInfo(number: 5,   name: 'আল-মায়িদা',  arabic: 'المائدة',    transliteration: "Al-Ma'idah",  meaning: 'খাদ্য পরিবেশিত টেবিল',  ayatCount: 120, type: 'মাদানী'),
  SurahInfo(number: 6,   name: 'আল-আনআম',     arabic: 'الأنعام',    transliteration: "Al-An'am",    meaning: 'গৃহপালিত পশু',           ayatCount: 165, type: 'মাক্কী'),
  SurahInfo(number: 7,   name: 'আল-আরাফ',     arabic: 'الأعراف',    transliteration: 'Al-Araf',     meaning: 'উচ্চস্থান',              ayatCount: 206, type: 'মাক্কী'),
  SurahInfo(number: 8,   name: 'আল-আনফাল',    arabic: 'الأنفال',    transliteration: 'Al-Anfal',    meaning: 'যুদ্ধলব্ধ সম্পদ',       ayatCount: 75,  type: 'মাদানী'),
  SurahInfo(number: 9,   name: 'আত-তাওবা',    arabic: 'التوبة',     transliteration: 'At-Tawbah',   meaning: 'অনুশোচনা',               ayatCount: 129, type: 'মাদানী'),
  SurahInfo(number: 10,  name: 'ইউনুস',        arabic: 'يونس',       transliteration: 'Yunus',       meaning: 'ইউনুস',                  ayatCount: 109, type: 'মাক্কী'),
  SurahInfo(number: 11,  name: 'হুদ',          arabic: 'هود',        transliteration: 'Hud',         meaning: 'হুদ',                    ayatCount: 123, type: 'মাক্কী'),
  SurahInfo(number: 12,  name: 'ইউসুফ',        arabic: 'يوسف',       transliteration: 'Yusuf',       meaning: 'ইউসুফ',                  ayatCount: 111, type: 'মাক্কী'),
  SurahInfo(number: 13,  name: 'আর-রাদ',       arabic: 'الرعد',      transliteration: 'Ar-Rad',      meaning: 'বজ্রপাত',                ayatCount: 43,  type: 'মাদানী'),
  SurahInfo(number: 14,  name: 'ইবরাহীম',      arabic: 'إبراهيم',    transliteration: 'Ibrahim',     meaning: 'ইবরাহীম',                ayatCount: 52,  type: 'মাক্কী'),
  SurahInfo(number: 15,  name: 'আল-হিজর',      arabic: 'الحجر',      transliteration: 'Al-Hijr',     meaning: 'পাথুরে ভূমি',            ayatCount: 99,  type: 'মাক্কী'),
  SurahInfo(number: 36,  name: 'ইয়া-সীন',     arabic: 'يس',         transliteration: 'Ya-Sin',      meaning: 'ইয়া-সীন',               ayatCount: 83,  type: 'মাক্কী'),
  SurahInfo(number: 55,  name: 'আর-রাহমান',    arabic: 'الرحمن',     transliteration: 'Ar-Rahman',   meaning: 'পরম দয়ালু',             ayatCount: 78,  type: 'মাদানী'),
  SurahInfo(number: 67,  name: 'আল-মুলক',      arabic: 'الملك',      transliteration: 'Al-Mulk',     meaning: 'রাজত্ব',                 ayatCount: 30,  type: 'মাক্কী'),
  SurahInfo(number: 112, name: 'আল-ইখলাস',    arabic: 'الإخلاص',    transliteration: 'Al-Ikhlas',   meaning: 'একনিষ্ঠতা',             ayatCount: 4,   type: 'মাক্কী'),
  SurahInfo(number: 113, name: 'আল-ফালাক',    arabic: 'الفلق',      transliteration: 'Al-Falaq',    meaning: 'ভোরের আলো',             ayatCount: 5,   type: 'মাক্কী'),
  SurahInfo(number: 114, name: 'আন-নাস',       arabic: 'الناس',      transliteration: 'An-Nas',      meaning: 'মানবজাতি',               ayatCount: 6,   type: 'মাক্কী'),
];

// ─── QuranScreen ──────────────────────────────────────────────────────────────

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<SurahInfo> _filtered = _surahs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _searchQuery = q;
      _filtered = _surahs
          .where((s) =>
              s.name.contains(q) ||
              s.arabic.contains(q) ||
              s.number.toString().contains(q))
          .toList();
    });
  }

  void _openSurah(BuildContext context, SurahInfo surah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailPage(
          surahName: surah.name,
          arabicName: surah.arabic,
          surahNumber: surah.number,
          ayatCount: surah.ayatCount,
          type: surah.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8),
                ],
              ),
              child: TextField(
                onChanged: _onSearch,
                style: GoogleFonts.hindSiliguri(color: textColor),
                decoration: InputDecoration(
                  hintText: 'সূরার নাম বা নম্বর দিয়ে খুঁজুন...',
                  hintStyle:
                      GoogleFonts.hindSiliguri(color: Colors.grey, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.grey, size: 18),
                          onPressed: () {
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.primary,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle:
                  GoogleFonts.hindSiliguri(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'সূরা'),
                Tab(text: 'পারা'),
                Tab(text: 'পৃষ্ঠা'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurahList(isDark, textColor, cardColor),
                _buildParaList(isDark, textColor, cardColor),
                _buildPageList(isDark, textColor, cardColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Surah list ──────────────────────────────────────────────────────────────

  Widget _buildSurahList(bool isDark, Color textColor, Color cardColor) {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'কোনো সূরা পাওয়া যায়নি',
              style: GoogleFonts.hindSiliguri(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final surah = _filtered[index];
        return _SurahListTile(
          surah: surah,
          isDark: isDark,
          textColor: textColor,
          cardColor: cardColor,
          onTap: () => _openSurah(context, surah),
        );
      },
    );
  }

  // ── Para list ───────────────────────────────────────────────────────────────

  Widget _buildParaList(bool isDark, Color textColor, Color cardColor) {
    final banglaNumbers = [
      '১','২','৩','৪','৫','৬','৭','৮','৯','১০',
      '১১','১২','১৩','১৪','১৫','১৬','১৭','১৮','১৯','২০',
      '২১','২২','২৩','২৪','২৫','২৬','২৭','২৮','২৯','৩০',
    ];
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banglaNumbers[index],
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'পারা',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Page list ───────────────────────────────────────────────────────────────

  Widget _buildPageList(bool isDark, Color textColor, Color cardColor) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: 604,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Surah list tile widget ───────────────────────────────────────────────────

class _SurahListTile extends StatelessWidget {
  final SurahInfo surah;
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final VoidCallback onTap;

  const _SurahListTile({
    required this.surah,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.onTap,
  });

  String _toBangla(String s) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < en.length; i++) {
      s = s.replaceAll(en[i], bn[i]);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _toBangla(surah.number.toString()),
                    style: GoogleFonts.hindSiliguri(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: Transliteration (meaning) — above Arabic ──
                    if (surah.transliteration.isNotEmpty)
                      Text(
                        '${surah.transliteration} (${surah.meaning})',
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    // ── Row 2: Arabic name ──
                    Text(
                      surah.arabic,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFFB8860B), // gold
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ── Row 3: Type badge + ayat count ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: surah.type == 'মাক্কী'
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            surah.type,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: surah.type == 'মাক্কী'
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_toBangla(surah.ayatCount.toString())} আয়াত',
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
