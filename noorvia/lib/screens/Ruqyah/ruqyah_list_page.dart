import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'ruqyah_detail_page.dart';
import 'ruqyah_ayat_detail_page.dart';

// ─── Notes Model ──────────────────────────────────────────────────────────────

class RuqyahChapter {
  final String id;
  final String title;
  final String body;

  const RuqyahChapter({
    required this.id,
    required this.title,
    required this.body,
  });

  factory RuqyahChapter.fromJson(Map<String, dynamic> json) {
    return RuqyahChapter(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }

  String get preview {
    final plain = body.replaceAll('\\n', ' ').trim();
    return plain.length > 120 ? '${plain.substring(0, 120)}...' : plain;
  }
}

// ─── Ayat Models ──────────────────────────────────────────────────────────────

class RuqyahAyah {
  final int id;
  final int ayahNumber;
  final String ayahArabic;
  final String ayahBangla;
  final String? ayahTitle;
  final String? ayahNote;
  final String? audiopath;
  final int groupId;

  const RuqyahAyah({
    required this.id,
    required this.ayahNumber,
    required this.ayahArabic,
    required this.ayahBangla,
    this.ayahTitle,
    this.ayahNote,
    this.audiopath,
    required this.groupId,
  });

  factory RuqyahAyah.fromJson(Map<String, dynamic> json) {
    return RuqyahAyah(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayah_number'] as num?)?.toInt() ?? 0,
      ayahArabic: json['ayah_arabic']?.toString() ?? '',
      ayahBangla: json['ayah_bangla']?.toString() ?? '',
      ayahTitle: json['ayah_title']?.toString(),
      ayahNote: json['ayah_note']?.toString(),
      audiopath: json['audiopath']?.toString(),
      groupId: (json['group_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class RuqyahAyatGroup {
  final int id;
  final String title;
  final String subtitle;
  final List<RuqyahAyah> ayahs;

  const RuqyahAyatGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ayahs,
  });

  factory RuqyahAyatGroup.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'];
    final ayahs = (rawAyahs is List)
        ? rawAyahs
            .whereType<Map<String, dynamic>>()
            .map((a) => RuqyahAyah.fromJson(a))
            .where((a) => a.ayahArabic.isNotEmpty)
            .toList()
        : <RuqyahAyah>[];
    return RuqyahAyatGroup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      ayahs: ayahs,
    );
  }

  String get preview {
    if (ayahs.isEmpty) return '';
    final first = ayahs.first.ayahBangla.trim();
    return first.length > 100 ? '${first.substring(0, 100)}...' : first;
  }
}

// ─── List Page ────────────────────────────────────────────────────────────────

class RuqyahListPage extends StatefulWidget {
  final int initialTab;

  const RuqyahListPage({super.key, this.initialTab = 0});

  @override
  State<RuqyahListPage> createState() => _RuqyahListPageState();
}

class _RuqyahListPageState extends State<RuqyahListPage>
    with SingleTickerProviderStateMixin {
  static const _notesApiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/rukaiya.json';
  static const _ayatApiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/ruqyah_ayat_merged.json';

  List<RuqyahChapter> _notes = [];
  List<RuqyahAyatGroup> _ayatGroups = [];
  List<RuqyahChapter> _filteredNotes = [];
  List<RuqyahAyatGroup> _filteredAyatGroups = [];

  bool _loading = true;
  String? _error;
  bool _offline = false;

  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
    _searchCtrl.addListener(_onSearch);
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
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();

    // ── ১. Cache থেকে তাৎক্ষণিক দেখাও ───────────────────────
    final cachedNotes = prefs.getString('ruqyah_cache');
    if (cachedNotes != null) {
      _parseNotesAndSet(cachedNotes, fromCache: true);
    }
    final cachedAyat = prefs.getString('ruqyah_ayat_cache');
    if (cachedAyat != null) {
      _parseAyatAndSet(cachedAyat, fromCache: true);
    }

    // ── ২. Network থেকে fresh data আনো ───────────────────────
    bool hasError = false;
    try {
      final notesResponse = await http
          .get(Uri.parse(_notesApiUrl))
          .timeout(const Duration(seconds: 15));
      if (notesResponse.statusCode == 200) {
        final raw = utf8.decode(notesResponse.bodyBytes);
        await prefs.setString('ruqyah_cache', raw);
        _parseNotesAndSet(raw, fromCache: false);
      } else {
        hasError = true;
      }
    } catch (_) {
      hasError = true;
    }

    try {
      final ayatResponse = await http
          .get(Uri.parse(_ayatApiUrl))
          .timeout(const Duration(seconds: 15));
      if (ayatResponse.statusCode == 200) {
        final raw = utf8.decode(ayatResponse.bodyBytes);
        await prefs.setString('ruqyah_ayat_cache', raw);
        _parseAyatAndSet(raw, fromCache: false);
      } else {
        hasError = true;
      }
    } catch (_) {
      hasError = true;
    }

    if (mounted) {
      if (hasError && _notes.isEmpty && _ayatGroups.isEmpty) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _offline = hasError;
        });
      }
    }
  }

  void _parseNotesAndSet(String raw, {required bool fromCache}) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(raw);
      final notes = _parseNotesList(jsonMap['notes']);
      if (mounted) {
        setState(() {
          _notes = notes;
          _filteredNotes = notes;
          _loading = false;
          if (!fromCache) _offline = false;
        });
      }
    } catch (_) {
      if (!fromCache && mounted) setState(() => _loading = false);
    }
  }

  void _parseAyatAndSet(String raw, {required bool fromCache}) {
    try {
      final List<dynamic> jsonList = json.decode(raw);
      final groups = jsonList
          .whereType<Map<String, dynamic>>()
          .map((g) => RuqyahAyatGroup.fromJson(g))
          .where((g) => g.title.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _ayatGroups = groups;
          _filteredAyatGroups = groups;
          _loading = false;
          if (!fromCache) _offline = false;
        });
      }
    } catch (_) {
      if (!fromCache && mounted) setState(() => _loading = false);
    }
  }

  List<RuqyahChapter> _parseNotesList(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw.map<RuqyahChapter>((item) {
      if (item is String) {
        try {
          return RuqyahChapter.fromJson(
              json.decode(item) as Map<String, dynamic>);
        } catch (_) {
          return const RuqyahChapter(id: '', title: '', body: '');
        }
      } else if (item is Map<String, dynamic>) {
        return RuqyahChapter.fromJson(item);
      }
      return const RuqyahChapter(id: '', title: '', body: '');
    }).where((c) => c.title.isNotEmpty).toList();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredNotes = q.isEmpty
          ? _notes
          : _notes
              .where((c) =>
                  c.title.toLowerCase().contains(q) ||
                  c.body.toLowerCase().contains(q))
              .toList();
      _filteredAyatGroups = q.isEmpty
          ? _ayatGroups
          : _ayatGroups
              .where((g) =>
                  g.title.toLowerCase().contains(q) ||
                  g.subtitle.toLowerCase().contains(q) ||
                  g.ayahs.any((a) =>
                      a.ayahBangla.toLowerCase().contains(q) ||
                      (a.ayahTitle?.toLowerCase().contains(q) ?? false)))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      // ── Drawer ──────────────────────────────────────────────
      drawer: _buildDrawer(isDark, cardColor, textColor, subColor),
      // ── Compact AppBar ──────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/IslamicAppImages/rukaiyabg.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: AppColors.gradient),
              ),
            ),
            // Decorative circles
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
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'রুকইয়াহ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            Text(
              'কোরআন সুন্নাহ ভিত্তিক চিকিৎসা',
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.black,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: _fetchData,
            tooltip: 'রিফ্রেশ',
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'মেনু',
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black,
          labelStyle: GoogleFonts.hindSiliguri(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.hindSiliguri(fontSize: 12),
          tabs: [
            Tab(text: '📖 নোটস (${_notes.length})'),
            Tab(text: '📿 আয়াত (${_ayatGroups.length})'),
          ],
        ),
      ),

      // ── Body ────────────────────────────────────────────────
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.hindSiliguri(
                              color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'খুঁজুন...',
                            hintStyle: GoogleFonts.hindSiliguri(
                                color: subColor, fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.primary, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: subColor, size: 18),
                                    onPressed: _searchCtrl.clear,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotesList(
                            _filteredNotes,
                            cardColor,
                            textColor,
                            subColor,
                            isDark,
                            emptyMsg: 'কোনো নোট পাওয়া যায়নি',
                          ),
                          _buildAyatGroupList(
                            _filteredAyatGroups,
                            cardColor,
                            textColor,
                            subColor,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
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
            'ডেটা লোড হচ্ছে...',
            style: GoogleFonts.hindSiliguri(
                color: AppColors.primary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
      bool isDark, Color cardColor, Color textColor, Color subColor) {
    return Drawer(
      backgroundColor: cardColor,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.gradient),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌿', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                Text(
                  'রুকইয়াহ',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'কোরআন সুন্নাহ ভিত্তিক চিকিৎসা',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _drawerBadge('📖 নোটস', _notes.length),
                    const SizedBox(width: 8),
                    _drawerBadge('📿 আয়াত', _ayatGroups.length),
                  ],
                ),
              ],
            ),
          ),

          // Tab selector inside drawer
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: subColor,
                    indicatorColor: AppColors.primary,
                    labelStyle: GoogleFonts.hindSiliguri(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: '📖 নোটস'),
                      Tab(text: '📿 আয়াত'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _drawerNotesList(_notes, textColor, subColor, 0),
                        _drawerAyatList(_ayatGroups, textColor, subColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 16),
                label: Text(
                  'বন্ধ করুন',
                  style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: subColor,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerBadge(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ($count)',
        style: GoogleFonts.hindSiliguri(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _drawerNotesList(
      List<RuqyahChapter> items, Color textColor, Color subColor, int tabIndex) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'কোনো আইটেম নেই',
          style: GoogleFonts.hindSiliguri(color: subColor, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.primary.withValues(alpha: 0.08),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final chapter = items[index];
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          title: Text(
            chapter.title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          onTap: () {
            Navigator.pop(context);
            _tabController.animateTo(tabIndex);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RuqyahDetailPage(
                  chapter: chapter,
                  allChapters: items,
                  currentIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _drawerAyatList(
      List<RuqyahAyatGroup> groups, Color textColor, Color subColor) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'কোনো আয়াত নেই',
          style: GoogleFonts.hindSiliguri(color: subColor, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.primary.withValues(alpha: 0.08),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final group = groups[index];
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          title: Text(
            group.title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${group.ayahs.length} টি আয়াত',
            style: GoogleFonts.hindSiliguri(fontSize: 11, color: subColor),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          onTap: () {
            Navigator.pop(context);
            _tabController.animateTo(1);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RuqyahAyatDetailPage(
                  group: group,
                  allGroups: groups,
                  currentIndex: index,
                ),
              ),
            );
          },
        );
      },
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
                style:
                    GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
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

  Widget _buildNotesList(
    List<RuqyahChapter> items,
    Color cardColor,
    Color textColor,
    Color subColor,
    bool isDark, {
    required String emptyMsg,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style:
                    GoogleFonts.hindSiliguri(color: subColor, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final chapter = items[index];
          return _ChapterCard(
            chapter: chapter,
            index: index,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RuqyahDetailPage(
                  chapter: chapter,
                  allChapters: items,
                  currentIndex: index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAyatGroupList(
    List<RuqyahAyatGroup> groups,
    Color cardColor,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'কোনো আয়াত পাওয়া যায়নি',
              style: GoogleFonts.hindSiliguri(color: subColor, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _AyatGroupCard(
            group: group,
            index: index,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RuqyahAyatDetailPage(
                  group: group,
                  allGroups: groups,
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

// ─── Chapter Card ─────────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  final RuqyahChapter chapter;
  final int index;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _ChapterCard({
    required this.chapter,
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
        margin: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chapter.preview,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: subColor,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ayat Group Card ──────────────────────────────────────────────────────────

class _AyatGroupCard extends StatelessWidget {
  final RuqyahAyatGroup group;
  final int index;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _AyatGroupCard({
    required this.group,
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
        margin: const EdgeInsets.only(bottom: 12),
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
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    if (group.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        group.subtitle,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      group.preview,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: subColor,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${group.ayahs.length} টি আয়াত',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
