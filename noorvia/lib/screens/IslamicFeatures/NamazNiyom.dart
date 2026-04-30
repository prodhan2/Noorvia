import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme colors ──────────────────────────────────────────────
const _kPrimary      = Color(0xFF1B6B3A);
const _kPrimaryDark  = Color(0xFF0F4D2A);
const _kPrimaryLight = Color(0xFF2E8B57);
const _kGold         = Color(0xFFFFB300);
const _kBg           = Color(0xFFF4F6F4);

const _kApiUrl =
    'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/namaz_shikkha.json';

// ═══════════════════════════════════════════════════════════════
// Model
// ═══════════════════════════════════════════════════════════════
class NamazItem {
  final String title;
  final String arabic;
  final String pronunciation;
  final String translation;

  const NamazItem({
    required this.title,
    required this.arabic,
    required this.pronunciation,
    required this.translation,
  });

  factory NamazItem.fromJson(Map<String, dynamic> j) => NamazItem(
        title: j['title'] ?? '',
        arabic: j['arabic'] ?? '',
        pronunciation: j['pronunciation'] ?? '',
        translation: j['translation'] ?? '',
      );
}

// ═══════════════════════════════════════════════════════════════
// ChapterListPage  (নামাজ শিক্ষা)
// ═══════════════════════════════════════════════════════════════
class ChapterListPage extends StatefulWidget {
  const ChapterListPage({super.key});

  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  List<NamazItem> _all = [];
  List<NamazItem> _filtered = [];
  bool _loading = true;
  bool _offline = false;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch + cache ─────────────────────────────────────────
  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = prefs.getString('namaz_shikkha_cache');
      if (cached != null) {
        _parse(cached);
        setState(() => _loading = false);
      }
    }

    try {
      final res = await http
          .get(Uri.parse(_kApiUrl))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        await prefs.setString('namaz_shikkha_cache', res.body);
        _parse(res.body);
        setState(() {
          _loading = false;
          _offline = false;
        });
      } else {
        _fallback(prefs);
      }
    } catch (_) {
      _fallback(prefs);
    }
  }

  void _parse(String raw) {
    final list = (json.decode(raw) as List)
        .map((e) => NamazItem.fromJson(e as Map<String, dynamic>))
        .where((e) => e.title.isNotEmpty)
        .skip(1) // skip copyright entry
        .toList();
    _all = list;
    _applyFilter();
  }

  void _fallback(SharedPreferences prefs) {
    final cached = prefs.getString('namaz_shikkha_cache');
    if (cached != null) {
      _parse(cached);
      setState(() {
        _loading = false;
        _offline = true;
      });
    } else {
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all
              .where((e) =>
                  e.title.toLowerCase().contains(q) ||
                  e.pronunciation.toLowerCase().contains(q) ||
                  e.translation.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _kBg;

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar(isDark)],
        body: Column(
          children: [
            // Offline banner
            if (_offline)
              _OfflineBanner(),

            // Search bar
            _SearchBar(
              controller: _searchCtrl,
              isDark: isDark,
              onChanged: (v) {
                _query = v;
                _applyFilter();
              },
              onClear: () {
                _searchCtrl.clear();
                _query = '';
                _applyFilter();
              },
            ),

            // Count chip
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filtered.length}টি বিষয়',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: _kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : _filtered.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          color: _kPrimary,
                          onRefresh: () => _load(forceRefresh: true),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _NamazCard(
                              item: _filtered[i],
                              index: _all.indexOf(_filtered[i]),
                              isDark: isDark,
                              onTap: () => _openDetail(ctx, _filtered[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext ctx, NamazItem item) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => NamazDetailPage(item: item),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: _kPrimary,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _load(forceRefresh: true),
          tooltip: 'রিফ্রেশ',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
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
                const SizedBox(height: 36),
                const Text('🕌', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  'নামাজ শিক্ষা',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'নিয়ত, দু\'আ ও সূরা সমূহ',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NamazDetailPage
// ═══════════════════════════════════════════════════════════════
class NamazDetailPage extends StatefulWidget {
  final NamazItem item;
  const NamazDetailPage({super.key, required this.item});

  @override
  State<NamazDetailPage> createState() => _NamazDetailPageState();
}

class _NamazDetailPageState extends State<NamazDetailPage> {
  bool _showPronunciation = true;
  bool _showTranslation = true;
  bool _copied = false;

  void _copy() {
    final text =
        '${widget.item.title}\n\n${widget.item.arabic}\n\n${widget.item.pronunciation}\n\n${widget.item.translation}';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _copied = false) : null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _kBg;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.item.title,
              style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _copied ? Icons.check_circle : Icons.copy_outlined,
                  color: _copied ? _kGold : Colors.white,
                  size: 20,
                ),
                onPressed: _copy,
                tooltip: 'কপি করুন',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title chip
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimaryDark, _kPrimaryLight],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.item.title,
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Arabic card
                  _DetailCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    label: 'আরবি',
                    labelIcon: Icons.auto_stories_outlined,
                    labelColor: _kGold,
                    child: SelectableText(
                      widget.item.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 26,
                        height: 2.2,
                        color: textColor,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Toggle row
                  Row(
                    children: [
                      _ToggleChip(
                        label: 'উচ্চারণ',
                        active: _showPronunciation,
                        onTap: () => setState(
                            () => _showPronunciation = !_showPronunciation),
                      ),
                      const SizedBox(width: 8),
                      _ToggleChip(
                        label: 'অনুবাদ',
                        active: _showTranslation,
                        onTap: () => setState(
                            () => _showTranslation = !_showTranslation),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pronunciation card
                  if (_showPronunciation && widget.item.pronunciation.isNotEmpty)
                    _DetailCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      label: 'উচ্চারণ',
                      labelIcon: Icons.record_voice_over_outlined,
                      labelColor: _kPrimaryLight,
                      child: SelectableText(
                        widget.item.pronunciation,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          height: 1.8,
                          color: _kPrimary,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  if (_showPronunciation && widget.item.pronunciation.isNotEmpty)
                    const SizedBox(height: 12),

                  // Translation card
                  if (_showTranslation && widget.item.translation.isNotEmpty)
                    _DetailCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      label: 'বাংলা অনুবাদ',
                      labelIcon: Icons.translate_outlined,
                      labelColor: Colors.blue,
                      child: SelectableText(
                        widget.item.translation,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          height: 1.9,
                          color: subColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Copy button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copy,
                      icon: Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 18,
                      ),
                      label: Text(
                        _copied ? 'কপি হয়েছে!' : 'সম্পূর্ণ কপি করুন',
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _copied ? Colors.green : _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _NamazCard — list tile
// ═══════════════════════════════════════════════════════════════
class _NamazCard extends StatelessWidget {
  final NamazItem item;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _NamazCard({
    required this.item,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kPrimaryDark, _kPrimaryLight],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Arabic preview
                    if (item.arabic.isNotEmpty)
                      Text(
                        item.arabic.length > 60
                            ? '${item.arabic.substring(0, 60)}...'
                            : item.arabic,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 15,
                          color: _kPrimary,
                          fontFamily: 'serif',
                          height: 1.8,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Translation preview
                    if (item.translation.isNotEmpty)
                      Text(
                        item.translation.length > 80
                            ? '${item.translation.substring(0, 80)}...'
                            : item.translation,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: subColor,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _kPrimary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Small reusable widgets
// ═══════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.hindSiliguri(
              color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: 'নিয়ত বা দু\'আ খুঁজুন...',
            hintStyle: GoogleFonts.hindSiliguri(
                color: Colors.grey, fontSize: 13),
            prefixIcon:
                const Icon(Icons.search, color: _kPrimary, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.grey, size: 18),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final String label;
  final IconData labelIcon;
  final Color labelColor;
  final Widget child;

  const _DetailCard({
    required this.isDark,
    required this.cardBg,
    required this.label,
    required this.labelIcon,
    required this.labelColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(labelIcon, color: labelColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? _kPrimary
              : _kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? _kPrimary
                : _kPrimary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
              size: 14,
              color: active ? Colors.white : _kPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'অফলাইন মোড — ক্যাশ ডেটা ব্যবহার হচ্ছে',
            style: GoogleFonts.hindSiliguri(
                fontSize: 12, color: Colors.orange.shade800),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'কোনো বিষয় পাওয়া যায়নি',
            style: GoogleFonts.hindSiliguri(
                color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
