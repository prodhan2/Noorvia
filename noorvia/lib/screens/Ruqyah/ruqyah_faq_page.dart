import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        question: json['question']?.toString() ?? '',
        answer: json['answer']?.toString() ?? '',
      );
}

class FaqSection {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<FaqItem> faqs;

  const FaqSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.faqs,
  });

  factory FaqSection.fromJson(Map<String, dynamic> json) {
    final rawFaqs = json['faqs'];
    final faqs = (rawFaqs is List)
        ? rawFaqs
            .whereType<Map<String, dynamic>>()
            .map((f) => FaqItem.fromJson(f))
            .where((f) => f.question.isNotEmpty)
            .toList()
        : <FaqItem>[];

    return FaqSection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'book',
      faqs: faqs,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FAQ Page
// ═══════════════════════════════════════════════════════════════

class RuqyahFaqPage extends StatefulWidget {
  const RuqyahFaqPage({super.key});

  @override
  State<RuqyahFaqPage> createState() => _RuqyahFaqPageState();
}

class _RuqyahFaqPageState extends State<RuqyahFaqPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/faq.json';
  static const _cacheKey = 'ruqyah_faq_cache';

  List<FaqSection> _sections = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;

  // Track which FAQ items are expanded
  final Set<String> _expanded = {};

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      _parseAndSet(cached, fromCache: true);
    }

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        await prefs.setString(_cacheKey, raw);
        _parseAndSet(raw, fromCache: false);
        return;
      }
    } catch (_) {}

    if (mounted) {
      if (_sections.isNotEmpty) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'ডেটা লোড করা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        });
      }
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final List<dynamic> jsonList = json.decode(raw);
      final sections = jsonList
          .whereType<Map<String, dynamic>>()
          .map((s) => FaqSection.fromJson(s))
          .where((s) => s.title.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _sections = sections;
          _loading = false;
          _offline = fromCache;
        });
      }
    } catch (_) {
      if (mounted && !fromCache) {
        setState(() => _loading = false);
      }
    }
  }

  // Filter sections/faqs by search query
  List<FaqSection> get _filteredSections {
    if (_searchQuery.isEmpty) return _sections;
    return _sections
        .map((section) {
          final matchedFaqs = section.faqs
              .where((faq) =>
                  faq.question.toLowerCase().contains(_searchQuery) ||
                  faq.answer.toLowerCase().contains(_searchQuery))
              .toList();
          if (matchedFaqs.isEmpty &&
              !section.title.toLowerCase().contains(_searchQuery)) {
            return null;
          }
          return FaqSection(
            id: section.id,
            title: section.title,
            subtitle: section.subtitle,
            icon: section.icon,
            faqs: matchedFaqs.isNotEmpty ? matchedFaqs : section.faqs,
          );
        })
        .whereType<FaqSection>()
        .toList();
  }

  IconData _sectionIcon(String icon) {
    switch (icon) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // Section accent colors cycling
  static const _sectionColors = [
    Color(0xFF6C3CE1),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
  ];

  Color _sectionColor(int index) =>
      _sectionColors[index % _sectionColors.length];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  // ── Sliver AppBar ────────────────────────────────────────────
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_offline)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.wifi_off_rounded,
                color: Colors.white70, size: 18),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 20),
          onPressed: _fetchData,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: AppColors.gradient),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Center(
                        child: Text('❓', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'প্রশ্ন ও উত্তর',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'রুকইয়াহ বিষয়ক সাধারণ জিজ্ঞাসা',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'প্রশ্ন ও উত্তর',
          style: GoogleFonts.hindSiliguri(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────
  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😔', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: Text('আবার চেষ্টা করুন',
                    style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline banner
        if (_offline) _buildOfflineBanner(),

        // Search bar
        _buildSearchBar(isDark),

        // Stats row
        if (_searchQuery.isEmpty) _buildStatsRow(isDark),

        // No results
        if (filtered.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(
                    'কোনো ফলাফল পাওয়া যায়নি',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          // Sections
          ...filtered.asMap().entries.map(
                (e) => _buildSection(e.value, e.key, isDark),
              ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Offline banner ───────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'অফলাইন মোড — সংরক্ষিত ডেটা দেখাচ্ছে',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 12, color: Colors.orange),
            ),
          ),
          GestureDetector(
            onTap: _fetchData,
            child: Text(
              'রিফ্রেশ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
              color: AppColors.primary.withOpacity(0.12)),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.hindSiliguri(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'প্রশ্ন খুঁজুন...',
            hintStyle:
                GoogleFonts.hindSiliguri(color: subColor, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: subColor, size: 18),
                    onPressed: _searchCtrl.clear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDark) {
    final totalFaqs =
        _sections.fold<int>(0, (sum, s) => sum + s.faqs.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _statChip(
            icon: Icons.category_rounded,
            label: '${_sections.length} সেকশন',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _statChip(
            icon: Icons.quiz_rounded,
            label: '$totalFaqs প্রশ্ন',
            color: const Color(0xFF0891B2),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ─────────────────────────────────────────────
  Widget _buildSection(FaqSection section, int sectionIndex, bool isDark) {
    final color = _sectionColor(sectionIndex);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(isDark ? 0.25 : 0.1),
                  color.withOpacity(isDark ? 0.1 : 0.04),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withOpacity(0.3), width: 1.5),
                  ),
                  child: Icon(_sectionIcon(section.icon),
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.3,
                        ),
                      ),
                      if (section.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          section.subtitle,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: subColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${section.faqs.length}টি',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FAQ items
          ...section.faqs.asMap().entries.map(
                (e) => _buildFaqItem(
                  faq: e.value,
                  index: e.key,
                  sectionId: section.id,
                  color: color,
                  isLast: e.key == section.faqs.length - 1,
                  isDark: isDark,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ),
        ],
      ),
    );
  }

  // ── FAQ item (expandable) ────────────────────────────────────
  Widget _buildFaqItem({
    required FaqItem faq,
    required int index,
    required String sectionId,
    required Color color,
    required bool isLast,
    required bool isDark,
    required Color textColor,
    required Color subColor,
  }) {
    final key = '$sectionId-$index';
    final isExpanded = _expanded.contains(key);

    return Column(
      children: [
        // Divider between items
        if (index > 0)
          Divider(
            height: 1,
            color: color.withOpacity(0.1),
            indent: 16,
            endIndent: 16,
          ),

        // Question row
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expanded.remove(key);
              } else {
                _expanded.add(key);
              }
            });
          },
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Q badge
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Q',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    faq.question,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Answer (animated expand)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    faq.answer,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkText.withOpacity(0.85)
                          : AppColors.lightText.withOpacity(0.8),
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
