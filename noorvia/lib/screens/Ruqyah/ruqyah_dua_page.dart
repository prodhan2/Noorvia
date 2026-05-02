import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

String cleanHtml(String raw) {
  return raw
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();
}

// ═══════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════

class DuaItem {
  final int id;
  final String duaName;
  final String arDua;
  final String bnDua;
  final String bnProDua;
  final String duaRef;
  final int duaNumber;
  final String audiopath;

  const DuaItem({
    required this.id,
    required this.duaName,
    required this.arDua,
    required this.bnDua,
    required this.bnProDua,
    required this.duaRef,
    required this.duaNumber,
    required this.audiopath,
  });

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    return DuaItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      duaName: json['dua_name']?.toString() ?? '',
      arDua: json['ar_dua']?.toString() ?? '',
      bnDua: json['bn_dua']?.toString() ?? '',
      bnProDua: json['bn_pro_dua']?.toString() ?? '',
      duaRef: json['dua_ref']?.toString() ?? '',
      duaNumber: (json['dua_number'] as num?)?.toInt() ?? 0,
      audiopath: json['audiopath']?.toString() ?? '',
    );
  }
}

class DuaGroup {
  final int id;
  final String bnTitle;
  final String bnSubtitle;
  final List<DuaItem> duas;

  const DuaGroup({
    required this.id,
    required this.bnTitle,
    required this.bnSubtitle,
    required this.duas,
  });

  factory DuaGroup.fromJson(Map<String, dynamic> json) {
    final rawDuas = json['duas'];
    final duas = (rawDuas is List)
        ? rawDuas
            .whereType<Map<String, dynamic>>()
            .map((d) => DuaItem.fromJson(d))
            .toList()
        : <DuaItem>[];

    return DuaGroup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bnTitle: json['bn_title']?.toString() ?? '',
      bnSubtitle: json['bn_subtitle']?.toString() ?? '',
      duas: duas,
    );
  }
}

class DuaChapter {
  final int id;
  final String bnTitle;
  final List<DuaGroup> groups;

  const DuaChapter({
    required this.id,
    required this.bnTitle,
    required this.groups,
  });

  factory DuaChapter.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    final groups = (rawGroups is List)
        ? rawGroups
            .whereType<Map<String, dynamic>>()
            .map((g) => DuaGroup.fromJson(g))
            .toList()
        : <DuaGroup>[];

    return DuaChapter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bnTitle: json['bn_title']?.toString() ?? '',
      groups: groups,
    );
  }

  int get totalDuas =>
      groups.fold(0, (sum, g) => sum + g.duas.length);
}

// ═══════════════════════════════════════════════════════════════
// Page
// ═══════════════════════════════════════════════════════════════

class RuqyahDuaPage extends StatefulWidget {
  const RuqyahDuaPage({super.key});

  @override
  State<RuqyahDuaPage> createState() => _RuqyahDuaPageState();
}

class _RuqyahDuaPageState extends State<RuqyahDuaPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/DUA_merged.json';
  static const _cacheKey = 'ruqyah_dua_cache';

  List<DuaChapter> _chapters = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;

  DuaChapter? _selectedChapter;
  double _fontSize = 15.0;

  // Track which dua items are expanded: key = dua id
  final Set<int> _expandedDuas = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    // ── ১. Cache থেকে তাৎক্ষণিক দেখাও ──────────────────────
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final chapters = _parseChapters(cached);
        if (mounted) {
          setState(() {
            _chapters = chapters;
            _loading = false;
            _offline = true;
          });
        }
      } catch (_) {}
    }

    // ── ২. Network থেকে silent refresh ───────────────────────
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        final chapters = _parseChapters(raw);
        await prefs.setString(_cacheKey, raw);
        if (mounted) {
          setState(() {
            _chapters = chapters;
            _loading = false;
            _offline = false;
          });
        }
        return;
      }
    } catch (_) {}

    // ── ৩. Network failed ─────────────────────────────────────
    if (mounted) {
      if (_chapters.isNotEmpty) {
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

  List<DuaChapter> _parseChapters(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((c) => DuaChapter.fromJson(c))
          .toList();
    }
    return [];
  }

  void _goBack() {
    if (_selectedChapter != null) {
      setState(() {
        _selectedChapter = null;
        _expandedDuas.clear();
      });
    } else {
      Navigator.pop(context);
    }
  }

  // ── Card gradient cycling ────────────────────────────────────
  static const List<List<Color>> _cardGradients = [
    [Color(0xFF6C3CE1), Color(0xFF4A90D9)],
    [Color(0xFF0891B2), Color(0xFF34D399)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFF7C3AED), Color(0xFFEC4899)],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: _buildBody(isDark),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar ─────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      title: null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: EdgeInsets.zero,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final collapsed = constraints.maxHeight <= kToolbarHeight + 10;
            if (!collapsed) return const SizedBox.shrink();
            return SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                    onPressed: _goBack,
                  ),
                  Expanded(
                    child: Text(
                      'রুকইয়াহ দোয়া',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  if (_selectedChapter != null) ...[
                    IconButton(
                      icon: const Icon(Icons.text_decrease_rounded,
                          color: Colors.white, size: 20),
                      tooltip: 'ছোট করুন',
                      onPressed: () {
                        setState(() {
                          if (_fontSize > 11) _fontSize -= 1;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_increase_rounded,
                          color: Colors.white, size: 20),
                      tooltip: 'বড় করুন',
                      onPressed: () {
                        setState(() {
                          if (_fontSize < 26) _fontSize += 1;
                        });
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _loadData,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/IslamicAppImages/rukaiyabg.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: AppColors.gradient),
              ),
            ),
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -20, left: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Expanded top-bar row
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                      onPressed: _goBack,
                    ),
                    const Spacer(),
                    if (_selectedChapter != null) ...[
                      IconButton(
                        icon: const Icon(Icons.text_decrease_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'ছোট করুন',
                        onPressed: () {
                          setState(() {
                            if (_fontSize > 11) _fontSize -= 1;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'বড় করুন',
                        onPressed: () {
                          setState(() {
                            if (_fontSize < 26) _fontSize += 1;
                          });
                        },
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                      onPressed: _loadData,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            // Centre content
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'রুকইয়াহ দোয়া',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D1B2A),
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'হিফাজত ও শিফার দোয়াসমূহ',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: const Color(0xFF1A3A5C),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'আবার চেষ্টা করুন',
                    style: GoogleFonts.hindSiliguri(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main content
        _selectedChapter == null
            ? _buildChapterGrid(isDark)
            : _buildChapterDetail(isDark),
      ],
    );
  }

  // ── Chapter Grid ─────────────────────────────────────────────
  Widget _buildChapterGrid(bool isDark) {
    if (_chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'কোনো ডেটা পাওয়া যায়নি',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _chapters.length,
        itemBuilder: (context, index) {
          final chapter = _chapters[index];
          final gradientColors =
              _cardGradients[index % _cardGradients.length];
          return _buildChapterCard(chapter, gradientColors);
        },
      ),
    );
  }

  Widget _buildChapterCard(
      DuaChapter chapter, List<Color> gradientColors) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChapter = chapter;
          _expandedDuas.clear();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤲', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              chapter.bnTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${chapter.totalDuas} টি দোয়া',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Chapter Detail ───────────────────────────────────────────
  Widget _buildChapterDetail(bool isDark) {
    final chapter = _selectedChapter!;

    if (chapter.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'এই অধ্যায়ে কোনো দোয়া নেই',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: chapter.groups
            .map((group) => _buildGroupCard(group, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildGroupCard(DuaGroup group, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.85),
                  AppColors.accent.withOpacity(0.85),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.bnTitle,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (group.bnSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    group.bnSubtitle,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Dua items
          ...group.duas.map((dua) => _buildDuaItem(dua, isDark)),
        ],
      ),
    );
  }

  Widget _buildDuaItem(DuaItem dua, bool isDark) {
    final isExpanded = _expandedDuas.contains(dua.id);
    final arText = cleanHtml(dua.arDua);
    final bnText = cleanHtml(dua.bnDua);
    final proText = cleanHtml(dua.bnProDua);
    final refText = cleanHtml(dua.duaRef);

    return Column(
      children: [
        const Divider(height: 1, thickness: 0.5),
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedDuas.remove(dua.id);
              } else {
                _expandedDuas.add(dua.id);
              }
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Dua number badge
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${dua.duaNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Dua name
                Expanded(
                  child: Text(
                    dua.duaName.isNotEmpty ? dua.duaName : 'দোয়া',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.lightText,
                    ),
                  ),
                ),
                // Expand arrow
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildDuaContent(
              dua, arText, bnText, proText, refText, isDark),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildDuaContent(
    DuaItem dua,
    String arText,
    String bnText,
    String proText,
    String refText,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic text
          if (arText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                arText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: _fontSize + 5,
                  color: AppColors.primary,
                  height: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Bengali translation
          if (bnText.isNotEmpty) ...[
            Text(
              bnText,
              style: GoogleFonts.hindSiliguri(
                fontSize: _fontSize,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Transliteration
          if (proText.isNotEmpty) ...[
            Text(
              proText,
              style: GoogleFonts.hindSiliguri(
                fontSize: _fontSize - 1,
                color: isDark
                    ? AppColors.darkSubText
                    : AppColors.lightSubText,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Reference
          if (refText.isNotEmpty) ...[
            Text(
              refText,
              style: GoogleFonts.hindSiliguri(
                fontSize: _fontSize - 2,
                color: isDark
                    ? AppColors.darkSubText
                    : AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Copy button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                final copyText = [
                  if (arText.isNotEmpty) arText,
                  if (bnText.isNotEmpty) bnText,
                ].join('\n\n');
                Clipboard.setData(ClipboardData(text: copyText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'কপি হয়েছে',
                      style: GoogleFonts.hindSiliguri(),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(
                'কপি করুন',
                style: GoogleFonts.hindSiliguri(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
