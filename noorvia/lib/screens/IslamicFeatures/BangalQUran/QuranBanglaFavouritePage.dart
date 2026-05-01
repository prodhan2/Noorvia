import 'dart:convert';
import 'BanglaQuran.dart';
import 'BanglaQuranSurahDetails.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';

const _kPrimary      = AppColors.primary;
const _kPrimaryDark  = AppColors.primaryDark;
const _kPrimaryLight = AppColors.primaryLight;

// ═══════════════════════════════════════════════════════════════
// FavoritesPage
// ═══════════════════════════════════════════════════════════════
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  Set<String> favSurahIds = {};
  Set<String> favVerseKeys = {};
  bool loading = true;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadFavs();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    favSurahIds = (prefs.getStringList('favSurahs') ?? []).toSet();
    favVerseKeys = (prefs.getStringList('favVerses') ?? []).toSet();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _removeSurah(String id) async {
    final prefs = await SharedPreferences.getInstance();
    favSurahIds.remove(id);
    await prefs.setStringList('favSurahs', favSurahIds.toList());
    setState(() {});
  }

  Future<void> _removeVerse(String key) async {
    final prefs = await SharedPreferences.getInstance();
    favVerseKeys.remove(key);
    await prefs.setStringList('favVerses', favVerseKeys.toList());
    setState(() {});
  }

  Future<Map<String, dynamic>?> _fetchSurahById(String id) async {
    const url =
        'https://cdn.jsdelivr.net/npm/quran-cloud@1.0.0/dist/chapters/bn/index.json';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List;
      for (final item in list) {
        if ((item['id'] ?? '').toString() == id) {
          return item as Map<String, dynamic>;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchVerseByKey(String key) async {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final sId = parts[0];
    final vId = int.tryParse(parts[1]);
    if (vId == null) return null;
    final surahInfo = await _fetchSurahById(sId);
    if (surahInfo == null) return null;
    final res = await http.get(Uri.parse(surahInfo['link'] as String));
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    for (final v in (data['verses'] as List)) {
      if ((v['id'] ?? 0) == vId) {
        return {
          'surahId': sId,
          'surahName': surahInfo['translation'] ?? surahInfo['name'],
          'verseId': vId,
          'text': v['text'],
          'translation': v['translation'],
          'transliteration': v['transliteration'],
          'surahInfo': surahInfo,
        };
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchAllFavSurahs() async {
    const url =
        'https://cdn.jsdelivr.net/npm/quran-cloud@1.0.0/dist/chapters/bn/index.json';
    final res = await http.get(Uri.parse(url));
    final results = <Map<String, dynamic>>[];
    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List;
      for (final id in favSurahIds) {
        for (final item in list) {
          if ((item['id'] ?? '').toString() == id) {
            results.add(item as Map<String, dynamic>);
            break;
          }
        }
      }
    }
    return results;
  }

  String _bn(dynamic n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF2F2F2);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kPrimaryDark, _kPrimaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text('❤️', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text('পছন্দের তালিকা',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: _kPrimary,
                child: TabBar(
                  controller: _tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'পছন্দের সূরা'),
                    Tab(text: 'পছন্দের আয়াত'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: loading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : TabBarView(
                controller: _tab,
                children: [
                  _buildSurahTab(),
                  _buildVerseTab(),
                ],
              ),
      ),
    );
  }

  // ── Surah tab ─────────────────────────────────────────────
  Widget _buildSurahTab() {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF1A1A1A);
    if (favSurahIds.isEmpty) {
      return _emptyState('কোনো সূরা পছন্দ করা হয়নি', '📖', isDark);
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllFavSurahs(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _kPrimary));
        }
        if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
          return _emptyState('সূরা লোড হয়নি', '⚠️', isDark);
        }
        final list = snap.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final s = list[i];
            final sid = (s['id'] ?? '').toString();
            return _FavSurahTile(
              surah: s,
              bnNumber: _bn(s['id']),
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => SurahDetailPage(surahInfo: s)),
              ).then((_) => _loadFavs()),
              onRemove: () => _removeSurah(sid),
            );
          },
        );
      },
    );
  }

  // ── Verse tab ─────────────────────────────────────────────
  Widget _buildVerseTab() {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF1A1A1A);
    if (favVerseKeys.isEmpty) {
      return _emptyState('কোনো আয়াত পছন্দ করা হয়নি', '🤲', isDark);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: favVerseKeys.length,
      itemBuilder: (ctx, i) {
        final key = favVerseKeys.elementAt(i);
        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchVerseByKey(key),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 80,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                    child: LinearProgressIndicator(color: _kPrimary)),
              );
            }
            if (snap.data == null) {
              return _FavVerseTile(
                title: 'আয়াত $key',
                subtitle: 'লোড হয়নি',
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                onRemove: () => _removeVerse(key),
                onTap: null,
              );
            }
            final v = snap.data!;
            return _FavVerseTile(
              title: '${v['surahName']} — আয়াত ${_bn(v['verseId'])}',
              subtitle: v['translation'] ?? '',
              arabic: v['text'] ?? '',
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              onRemove: () => _removeVerse(key),
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) =>
                        SurahDetailPage(surahInfo: v['surahInfo'])),
              ).then((_) => _loadFavs()),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String msg, String emoji, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(msg,
              style: GoogleFonts.hindSiliguri(
                  color: isDark ? AppColors.darkSubText : Colors.grey,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── Fav surah tile ───────────────────────────────────────────
class _FavSurahTile extends StatelessWidget {
  final Map surah;
  final String bnNumber;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavSurahTile({
    required this.surah,
    required this.bnNumber,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(bnNumber,
                    style: GoogleFonts.hindSiliguri(
                        color: _kPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah['translation'] ?? surah['name'] ?? '',
                    style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textColor),
                  ),
                  Text(
                    surah['transliteration'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubText : Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            Text(
              surah['name'] ?? '',
              style: const TextStyle(
                  fontSize: 20,
                  color: _kPrimary,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fav verse tile ───────────────────────────────────────────
class _FavVerseTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? arabic;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  const _FavVerseTile({
    required this.title,
    required this.subtitle,
    this.arabic,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textColor)),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                ),
              ],
            ),
            if (arabic != null && arabic!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                arabic!,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontSize: 18,
                    color: _kPrimary,
                    fontFamily: 'serif',
                    height: 1.8),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: isDark ? AppColors.darkSubText : Colors.grey[700],
                    height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
