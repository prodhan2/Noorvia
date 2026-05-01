import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'islamic_name_detail_page.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class IslamicName {
  final String arabic;
  final String pronunciation;
  final String meaning;
  final String whyGood;
  final String firstLetter;

  const IslamicName({
    required this.arabic,
    required this.pronunciation,
    required this.meaning,
    required this.whyGood,
    required this.firstLetter,
  });

  factory IslamicName.fromJson(Map<String, dynamic> json) {
    return IslamicName(
      arabic: json['arabic']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      whyGood: json['why_good']?.toString() ?? '',
      firstLetter: json['first_letter']?.toString() ?? '',
    );
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class IslamicNamesPage extends StatefulWidget {
  const IslamicNamesPage({super.key});

  @override
  State<IslamicNamesPage> createState() => _IslamicNamesPageState();
}

class _IslamicNamesPageState extends State<IslamicNamesPage>
    with SingleTickerProviderStateMixin {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamic_names.json';

  List<IslamicName> _boys = [];
  List<IslamicName> _girls = [];
  List<IslamicName> _filteredBoys = [];
  List<IslamicName> _filteredGirls = [];

  bool _loading = true;
  String? _error;
  String _selectedLetter = 'সব';

  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  // All unique first letters across both lists
  List<String> _boysLetters = [];
  List<String> _girlsLetters = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedLetter = 'সব';
          _searchCtrl.clear();
          _applyFilters();
        });
      }
    });
    _searchCtrl.addListener(_applyFilters);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap =
            json.decode(utf8.decode(response.bodyBytes));

        final boys = _parseList(jsonMap['boys']);
        final girls = _parseList(jsonMap['girls']);

        final boysLetters = ['সব', ...{...boys.map((n) => n.firstLetter)}
            .where((l) => l.isNotEmpty)
            .toList()..sort()];
        final girlsLetters = ['সব', ...{...girls.map((n) => n.firstLetter)}
            .where((l) => l.isNotEmpty)
            .toList()..sort()];

        setState(() {
          _boys = boys;
          _girls = girls;
          _filteredBoys = boys;
          _filteredGirls = girls;
          _boysLetters = boysLetters;
          _girlsLetters = girlsLetters;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'সার্ভার থেকে ডেটা আনা যায়নি (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        _loading = false;
      });
    }
  }

  List<IslamicName> _parseList(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => IslamicName.fromJson(item))
        .where((n) => n.pronunciation.isNotEmpty)
        .toList();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final isBoys = _tabController.index == 0;
    final source = isBoys ? _boys : _girls;

    List<IslamicName> result = source;

    // Letter filter
    if (_selectedLetter != 'সব') {
      result = result.where((n) => n.firstLetter == _selectedLetter).toList();
    }

    // Search filter
    if (q.isNotEmpty) {
      result = result.where((n) {
        return n.pronunciation.toLowerCase().contains(q) ||
            n.meaning.toLowerCase().contains(q) ||
            n.arabic.contains(q) ||
            n.whyGood.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      if (isBoys) {
        _filteredBoys = result;
      } else {
        _filteredGirls = result;
      }
    });
  }

  void _onLetterTap(String letter) {
    setState(() {
      _selectedLetter = letter;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.gradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text('👶', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ইসলামিক নাম',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                Text(
                  'সুন্দর ইসলামিক নাম ও অর্থ',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10,
                    color: Colors.white70,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _fetchData,
            tooltip: 'রিফ্রেশ',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.hindSiliguri(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.hindSiliguri(fontSize: 12),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👦', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'ছেলেদের নাম',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (_boys.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_boys.length}',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'মেয়েদের নাম',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (_girls.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_girls.length}',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    // ── Search bar ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.hindSiliguri(
                              color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'নাম, অর্থ বা আরবি দিয়ে খুঁজুন...',
                            hintStyle: GoogleFonts.hindSiliguri(
                                color: subColor, fontSize: 13),
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.primary, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: subColor, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _applyFilters();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // ── Alphabet filter ─────────────────────────
                    _buildLetterFilter(isDark, cardColor, subColor),

                    // ── Tab content ─────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNameList(
                            _filteredBoys,
                            cardColor,
                            textColor,
                            subColor,
                            isDark,
                            emptyMsg: 'কোনো ছেলের নাম পাওয়া যায়নি',
                          ),
                          _buildNameList(
                            _filteredGirls,
                            cardColor,
                            textColor,
                            subColor,
                            isDark,
                            emptyMsg: 'কোনো মেয়ের নাম পাওয়া যায়নি',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLetterFilter(bool isDark, Color cardColor, Color subColor) {
    final letters = _tabController.index == 0 ? _boysLetters : _girlsLetters;
    if (letters.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: letters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final letter = letters[index];
          final isSelected = _selectedLetter == letter;
          return GestureDetector(
            onTap: () => _onLetterTap(letter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.gradient : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? AppColors.darkCard
                        : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                letter,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : subColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'নাম লোড হচ্ছে...',
            style: GoogleFonts.hindSiliguri(
                color: AppColors.primary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: Text(
                'আবার চেষ্টা করুন',
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameList(
    List<IslamicName> names,
    Color cardColor,
    Color textColor,
    Color subColor,
    bool isDark, {
    required String emptyMsg,
  }) {
    if (names.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: GoogleFonts.hindSiliguri(
                    color: subColor, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: names.length,
        itemBuilder: (context, index) {
          return _NameCard(
            name: names[index],
            index: index,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IslamicNameDetailPage(
                  name: names[index],
                  allNames: names,
                  currentIndex: index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

// ─── Name Card ────────────────────────────────────────────────────────────────

class _NameCard extends StatelessWidget {
  final IslamicName name;
  final int index;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _NameCard({
    required this.name,
    required this.index,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: AppColors.primary
                .withValues(alpha: isDark ? 0.15 : 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Left: number badge ──────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Middle: name info ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name.pronunciation,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name.arabic,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'অর্থ: ${name.meaning}',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: subColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name.whyGood,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right: arrow ────────────────────────────
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
