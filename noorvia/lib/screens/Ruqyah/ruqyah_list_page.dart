import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'ruqyah_detail_page.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

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

// ─── List Page ────────────────────────────────────────────────────────────────

class RuqyahListPage extends StatefulWidget {
  const RuqyahListPage({super.key});

  @override
  State<RuqyahListPage> createState() => _RuqyahListPageState();
}

class _RuqyahListPageState extends State<RuqyahListPage>
    with SingleTickerProviderStateMixin {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/rukaiya.json';

  List<RuqyahChapter> _notes = [];
  List<RuqyahChapter> _ayat = [];
  List<RuqyahChapter> _filteredNotes = [];
  List<RuqyahChapter> _filteredAyat = [];

  bool _loading = true;
  String? _error;
  bool _offline = false;

  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final cached = prefs.getString('ruqyah_cache');
    if (cached != null) {
      _parseAndSet(cached, fromCache: true);
    }

    // ── ২. Network থেকে fresh data আনো ───────────────────────
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        await prefs.setString('ruqyah_cache', raw);
        _parseAndSet(raw, fromCache: false);
      } else {
        if (_notes.isEmpty && _ayat.isEmpty) {
          setState(() {
            _error = 'সার্ভার থেকে ডেটা আনা যায়নি (${response.statusCode})';
            _loading = false;
          });
        } else {
          setState(() { _loading = false; _offline = true; });
        }
      }
    } catch (e) {
      if (_notes.isEmpty && _ayat.isEmpty) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _offline = true; });
      }
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(raw);
      final notes = _parseList(jsonMap['notes']);
      final ayat = _parseList(jsonMap['ayat']);
      setState(() {
        _notes = notes;
        _ayat = ayat;
        _filteredNotes = notes;
        _filteredAyat = ayat;
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) setState(() { _loading = false; });
    }
  }

  List<RuqyahChapter> _parseList(dynamic raw) {
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
      _filteredAyat = q.isEmpty
          ? _ayat
          : _ayat
              .where((c) =>
                  c.title.toLowerCase().contains(q) ||
                  c.body.toLowerCase().contains(q))
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
            const Text('🌿', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'রুকইয়াহ',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                Text(
                  'কোরআন সুন্নাহ ভিত্তিক চিকিৎসা',
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
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'মেনু',
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.hindSiliguri(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.hindSiliguri(fontSize: 12),
          tabs: [
            Tab(text: '📖 নোটস (${_notes.length})'),
            Tab(text: '📿 আয়াত (${_ayat.length})'),
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
                    // Offline banner
                    if (_offline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        color: Colors.orange.withValues(alpha: 0.15),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              'অফলাইন মোড — সংরক্ষিত ডেটা দেখাচ্ছে',
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 11, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
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
                          _buildList(
                            _filteredNotes,
                            cardColor,
                            textColor,
                            subColor,
                            isDark,
                            emptyMsg: 'কোনো নোট পাওয়া যায়নি',
                          ),
                          _buildList(
                            _filteredAyat,
                            cardColor,
                            textColor,
                            subColor,
                            isDark,
                            emptyMsg: 'কোনো আয়াত পাওয়া যায়নি',
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
                    _drawerBadge('📿 আয়াত', _ayat.length),
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
                        _drawerList(_notes, textColor, subColor, 0),
                        _drawerList(_ayat, textColor, subColor, 1),
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

  Widget _drawerList(
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
            Navigator.pop(context); // close drawer
            // switch to correct tab
            _tabController.animateTo(tabIndex);
            // navigate to detail
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

  Widget _buildList(
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
