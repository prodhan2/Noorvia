import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'ruqyah_list_page.dart';
import 'ruqyah_detail_page.dart';
import 'ruqyah_faq_page.dart';
import 'ruqyah_dua_page.dart';
import 'ruqyah_diagnosis_page.dart';

// ═══════════════════════════════════════════════════════════════
// Ruqyah Home Page
// ═══════════════════════════════════════════════════════════════

class RuqyahHomePage extends StatefulWidget {
  const RuqyahHomePage({super.key});

  @override
  State<RuqyahHomePage> createState() => _RuqyahHomePageState();
}

class _RuqyahHomePageState extends State<RuqyahHomePage>
    with SingleTickerProviderStateMixin {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/rukaiya.json';

  List<RuqyahChapter> _notes = [];
  List<RuqyahChapter> _ayat = [];
  bool _loading = true;
  bool _offline = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('ruqyah_cache');
    if (cached != null) _parseAndSet(cached, fromCache: true);
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        await prefs.setString('ruqyah_cache', raw);
        _parseAndSet(raw, fromCache: false);
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _loading = false;
        _offline = _notes.isNotEmpty || _ayat.isNotEmpty;
      });
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(raw);
      final notes = _parseList(jsonMap['notes']);
      final ayat = _parseList(jsonMap['ayat']);
      if (mounted) {
        setState(() {
          _notes = notes;
          _ayat = ayat;
          _loading = false;
          _offline = fromCache;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RuqyahChapter> _parseList(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw.map<RuqyahChapter>((item) {
      if (item is String) {
        try {
          return RuqyahChapter.fromJson(json.decode(item) as Map<String, dynamic>);
        } catch (_) {
          return const RuqyahChapter(id: '', title: '', body: '');
        }
      } else if (item is Map<String, dynamic>) {
        return RuqyahChapter.fromJson(item);
      }
      return const RuqyahChapter(id: '', title: '', body: '');
    }).where((c) => c.title.isNotEmpty).toList();
  }

  // ── Menu items data ──────────────────────────────────────────
  static const List<Map<String, dynamic>> _menuItems = [
    {'icon': '📖', 'title': 'রুকইয়াহ নোটস',    'color': Color(0xFF6C3CE1)},
    {'icon': '📿', 'title': 'রুকইয়াহ আয়াত',    'color': Color(0xFF0891B2)},
    {'icon': '❓', 'title': 'প্রশ্ন ও উত্তর',    'color': Color(0xFF059669)},
    {'icon': '🤲', 'title': 'রুকইয়াহ দোয়া',    'color': Color(0xFFD97706)},
    {'icon': '🔍', 'title': 'সেলফ ডায়াগনোসিস', 'color': Color(0xFFDC2626)},
  ];

  void _navigateFromMenu(int index) {
    Navigator.pop(context); // close drawer
    switch (index) {
      case 0: _openPage(isNotes: true); break;
      case 1: _openPage(isNotes: false); break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RuqyahFaqPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RuqyahDuaPage()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RuqyahDiagnosisPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: _buildDrawer(isDark),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: _loading
                ? _buildLoading()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildContent(isDark),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Drawer ───────────────────────────────────────────────────
  Widget _buildDrawer(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor  = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Drawer(
      backgroundColor: cardColor,
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.gradient),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 20, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: const Center(child: Text('🌿', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(height: 12),
            Text('রুকইয়াহ',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('কোরআন সুন্নাহ ভিত্তিক চিকিৎসা',
                style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 14),
            Row(children: [
              _drawerBadge('📖 নোটস', _notes.length),
              const SizedBox(width: 8),
              _drawerBadge('📿 আয়াত', _ayat.length),
            ]),
          ]),
        ),

        // Menu items
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _menuItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.07),
              indent: 16, endIndent: 16,
            ),
            itemBuilder: (context, i) {
              final item = _menuItems[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(item['icon'] as String,
                      style: const TextStyle(fontSize: 20))),
                ),
                title: Text(item['title'] as String,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: subColor.withValues(alpha: 0.5)),
                onTap: () => _navigateFromMenu(i),
              );
            },
          ),
        ),

        // Close button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text('বন্ধ করুন',
                  style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: subColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _drawerBadge(String label, int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('$label ($count)',
        style: GoogleFonts.hindSiliguri(
            fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
  );

  // ── Sliver AppBar with background image ─────────────────────
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_offline)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 18),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          onPressed: _fetchData,
        ),
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        title: Text('রুকইয়াহ',
            style: GoogleFonts.hindSiliguri(
                fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image — halka (low opacity)
            Image.network(
              'https://i.postimg.cc/GpTws3cT/image.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.45),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: AppColors.gradient),
              ),
            ),
            // Gradient overlay so text stays readable
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gradientStart.withValues(alpha: 0.55),
                    AppColors.gradientEnd.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
            // Centre content
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35), width: 2),
                    ),
                    child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(height: 10),
                  Text('রুকইয়াহ',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('কোরআন সুন্নাহ ভিত্তিক চিকিৎসা',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() => const SizedBox(
    height: 300,
    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );

  Widget _buildContent(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor  = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_offline) _buildOfflineBanner(),

          _buildSectionTitle('বিষয়সমূহ', isDark),
          const SizedBox(height: 14),

          // ── White-style feature cards ──────────────────────
          _buildWhiteCard(
            isDark: isDark, cardColor: cardColor, textColor: textColor, subColor: subColor,
            icon: '📖', accentColor: const Color(0xFF6C3CE1),
            title: 'রুকইয়াহ নোটস',
            subtitle: 'রুকইয়াহ সম্পর্কিত গুরুত্বপূর্ণ নোট ও গাইডলাইন',
            badge: _notes.isNotEmpty ? '${_notes.length} টি নোট' : null,
            onTap: () => _openPage(isNotes: true),
          ),
          const SizedBox(height: 12),

          _buildWhiteCard(
            isDark: isDark, cardColor: cardColor, textColor: textColor, subColor: subColor,
            icon: '📿', accentColor: const Color(0xFF0891B2),
            title: 'রুকইয়াহ আয়াত',
            subtitle: 'জিন, যাদু ও বদনজর থেকে মুক্তির কোরআনিক আয়াত',
            badge: _ayat.isNotEmpty ? '${_ayat.length} টি আয়াত' : null,
            onTap: () => _openPage(isNotes: false),
          ),
          const SizedBox(height: 12),

          _buildWhiteCard(
            isDark: isDark, cardColor: cardColor, textColor: textColor, subColor: subColor,
            icon: '❓', accentColor: const Color(0xFF059669),
            title: 'প্রশ্ন ও উত্তর',
            subtitle: 'রুকইয়াহ বিষয়ক সাধারণ জিজ্ঞাসা ও বিস্তারিত জবাব',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RuqyahFaqPage())),
          ),
          const SizedBox(height: 12),

          _buildWhiteCard(
            isDark: isDark, cardColor: cardColor, textColor: textColor, subColor: subColor,
            icon: '🤲', accentColor: const Color(0xFFD97706),
            title: 'রুকইয়াহ দোয়া',
            subtitle: 'সকাল-সন্ধ্যা ও হিফাজতের দোয়াসমূহ',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RuqyahDuaPage())),
          ),
          const SizedBox(height: 12),

          _buildWhiteCard(
            isDark: isDark, cardColor: cardColor, textColor: textColor, subColor: subColor,
            icon: '🔍', accentColor: const Color(0xFFDC2626),
            title: 'সেলফ ডায়াগনোসিস',
            subtitle: 'প্রশ্নের উত্তর দিয়ে নিজেই জানুন আপনার সমস্যার ধরন ও সমাধান',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RuqyahDiagnosisPage())),
          ),

          const SizedBox(height: 28),

          // ── Quick preview — Notes ──────────────────────────
          if (_notes.isNotEmpty) ...[
            _buildSectionHeader(
              icon: '📖', title: 'সাম্প্রতিক নোটস',
              onSeeAll: () => _openPage(isNotes: true), isDark: isDark,
            ),
            const SizedBox(height: 12),
            ..._notes.take(3).toList().asMap().entries.map((e) =>
                _buildPreviewTile(
                    chapter: e.value, index: e.key,
                    isDark: isDark, allChapters: _notes)),
            const SizedBox(height: 24),
          ],

          // ── Quick preview — Ayat ───────────────────────────
          if (_ayat.isNotEmpty) ...[
            _buildSectionHeader(
              icon: '📿', title: 'সাম্প্রতিক আয়াত',
              onSeeAll: () => _openPage(isNotes: false), isDark: isDark,
            ),
            const SizedBox(height: 12),
            ..._ayat.take(3).toList().asMap().entries.map((e) =>
                _buildPreviewTile(
                    chapter: e.value, index: e.key,
                    isDark: isDark, allChapters: _ayat)),
          ],
        ],
      ),
    );
  }

  // ── White card (new style) ───────────────────────────────────
  Widget _buildWhiteCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required String icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.12 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            // Accent icon box
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12, color: subColor, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (badge != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: accentColor)),
                  ),
                ],
              ],
            )),
            const SizedBox(width: 8),
            // Arrow
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: accentColor, size: 14),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Offline banner ───────────────────────────────────────────
  Widget _buildOfflineBanner() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange),
      const SizedBox(width: 8),
      Expanded(child: Text('অফলাইন মোড — সংরক্ষিত ডেটা দেখাচ্ছে',
          style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.orange))),
      GestureDetector(
        onTap: _fetchData,
        child: Text('রিফ্রেশ',
            style: GoogleFonts.hindSiliguri(
                fontSize: 12, color: Colors.orange,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline)),
      ),
    ]),
  );

  Widget _buildSectionTitle(String title, bool isDark) => Text(title,
      style: GoogleFonts.hindSiliguri(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkText : AppColors.lightText));

  Widget _buildSectionHeader({
    required String icon, required String title,
    required VoidCallback onSeeAll, required bool isDark,
  }) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 8),
    Text(title,
        style: GoogleFonts.hindSiliguri(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
    const Spacer(),
    GestureDetector(
      onTap: onSeeAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(20)),
        child: Text('সব দেখুন',
            style: GoogleFonts.hindSiliguri(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ),
  ]);

  Widget _buildPreviewTile({
    required RuqyahChapter chapter, required int index,
    required bool isDark, required List<RuqyahChapter> allChapters,
  }) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor  = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => RuqyahDetailPage(
            chapter: chapter, allChapters: allChapters, currentIndex: index),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8, offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('${index + 1}',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chapter.title,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(chapter.preview,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 11, color: subColor, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: AppColors.primary.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  void _openPage({required bool isNotes}) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => RuqyahListPage(initialTab: isNotes ? 0 : 1)));
}
