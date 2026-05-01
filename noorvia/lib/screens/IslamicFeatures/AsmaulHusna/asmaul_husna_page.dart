import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';

// ─── Theme-aware colour helper ────────────────────────────────────────────────
class _TC {
  final bool isDark;
  const _TC(this.isDark);

  // backgrounds
  Color get bg     => isDark ? AppColors.darkBg   : AppColors.lightBg;
  Color get card   => isDark ? AppColors.darkCard  : AppColors.lightCard;
  Color get card2  => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8);

  // text
  Color get text   => isDark ? AppColors.darkText    : AppColors.lightText;
  Color get sub    => isDark ? AppColors.darkSubText  : AppColors.lightSubText;

  // accents (same in both modes)
  Color get gold      => const Color(0xFFD4AF37);
  Color get goldLight => const Color(0xFFF0D060);
  Color get teal      => const Color(0xFF00BFA5);
  Color get tealDark  => const Color(0xFF00897B);
  Color get primary   => AppColors.primary;

  // divider
  Color get divider => isDark ? const Color(0xFF2A3F58) : const Color(0xFFE0E0E0);

  // header gradient
  List<Color> get headerGrad => isDark
      ? [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C), const Color(0xFF0D2B3E)]
      : [AppColors.primaryDark, AppColors.primary, AppColors.gradientMid];

  // card shadow
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.06),
      blurRadius: 8, offset: const Offset(0, 2)),
  ];
}

// ─── Language model ───────────────────────────────────────────────────────────
enum _Lang { english, bangla, urdu, indonesian }

extension _LangExt on _Lang {
  String get label {
    switch (this) {
      case _Lang.english:    return 'EN';
      case _Lang.bangla:     return 'বাং';
      case _Lang.urdu:       return 'اردو';
      case _Lang.indonesian: return 'ID';
    }
  }
  String get key {
    switch (this) {
      case _Lang.english:    return 'english';
      case _Lang.bangla:     return 'bangla';
      case _Lang.urdu:       return 'urdu';
      case _Lang.indonesian: return 'indonesian';
    }
  }
}

// ─── Main page ────────────────────────────────────────────────────────────────
class AsmaulHusnaPage extends StatefulWidget {
  const AsmaulHusnaPage({super.key});
  @override
  State<AsmaulHusnaPage> createState() => _AsmaulHusnaPageState();
}

class _AsmaulHusnaPageState extends State<AsmaulHusnaPage>
    with TickerProviderStateMixin {
  List _all   = [];
  List _shown = [];
  bool _loading = true;
  bool _error   = false;

  final _player     = AudioPlayer();
  String? _playingUrl;
  bool    _isPlaying = false;

  _Lang _lang = _Lang.bangla;
  final _searchCtrl = TextEditingController();
  bool  _searching  = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playingUrl = null; _isPlaying = false; });
    });
    _fetchData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _player.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = false; });
    try {
      final res = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/asmaul-husna.json',
      )).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final d = json.decode(res.body)['asmaul_husna'] as List;
        setState(() { _all = d; _shown = d; _loading = false; });
      } else {
        setState(() { _loading = false; _error = true; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = true; });
    }
  }

  void _onSearch(String q) {
    final lq = q.toLowerCase();
    setState(() {
      _shown = q.isEmpty
          ? _all
          : _all.where((e) {
              final ar = (e['name']['arabic'] ?? '').toLowerCase();
              final tr = (e['name']['transliteration'] ?? '').toLowerCase();
              final nm = (e['translations'][_lang.key]?['name'] ?? '').toLowerCase();
              return ar.contains(lq) || tr.contains(lq) || nm.contains(lq);
            }).toList();
    });
  }

  Future<void> _toggleAudio(String url) async {
    HapticFeedback.lightImpact();
    if (_playingUrl == url && _isPlaying) {
      await _player.pause();
    } else if (_playingUrl == url && !_isPlaying) {
      await _player.resume();
    } else {
      await _player.stop();
      setState(() { _playingUrl = url; _isPlaying = false; });
      await _player.play(UrlSource(url));
    }
  }

  void _openDetail(Map item, _TC tc) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => _DetailPage(
        item: item, lang: _lang,
        player: _player,
        playingUrl: _playingUrl,
        isPlaying: _isPlaying,
        onToggle: _toggleAudio,
      ),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final tc = _TC(isDark);

    return Scaffold(
      backgroundColor: tc.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverAppBar(tc)],
        body: _loading
            ? _buildLoader(tc)
            : _error
                ? _buildError(tc)
                : Column(children: [
                    _buildSearchBar(tc),
                    _buildLangBar(tc),
                    Expanded(child: _buildList(tc)),
                  ]),
      ),
    );
  }

  // ── sliver app bar ─────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(_TC tc) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: tc.headerGrad[0],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('اَلْأَسْمَاءُ الْحُسْنَىٰ',
            style: GoogleFonts.amiri(
              fontSize: 18,
              color: tc.gold,
              fontWeight: FontWeight.bold,
            )),
          const SizedBox(width: 8),
          Container(width: 1.2, height: 16, color: Colors.white30),
          const SizedBox(width: 8),
          Text('আসমাউল হুসনা',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: tc.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tc.gold.withValues(alpha: 0.4), width: 1),
            ),
            child: Text('৯৯',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: tc.gold,
                fontWeight: FontWeight.w700,
              )),
          ),
        ],
      ),
      centerTitle: false,
      titleSpacing: 0,
    );
  }

  // ── search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(_TC tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searching ? tc.gold.withValues(alpha: 0.5) : tc.divider,
            width: 1.2),
          boxShadow: _searching
              ? [BoxShadow(color: tc.gold.withValues(alpha: 0.12), blurRadius: 12)]
              : tc.cardShadow,
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.hindSiliguri(color: tc.text, fontSize: 14),
          onChanged: _onSearch,
          onTap: () => setState(() => _searching = true),
          onSubmitted: (_) => setState(() => _searching = false),
          decoration: InputDecoration(
            hintText: 'নাম বা অর্থ খুঁজুন…',
            hintStyle: GoogleFonts.hindSiliguri(color: tc.sub, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: tc.sub, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: tc.sub, size: 18),
                    onPressed: () {
                      _searchCtrl.clear(); _onSearch('');
                      setState(() => _searching = false);
                    })
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── language bar ───────────────────────────────────────────────────────────
  Widget _buildLangBar(_TC tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        Text('ভাষা:', style: GoogleFonts.hindSiliguri(color: tc.sub, fontSize: 12)),
        const SizedBox(width: 8),
        ..._Lang.values.map((l) => _LangChip(
          label: l.label, selected: _lang == l, tc: tc,
          onTap: () => setState(() { _lang = l; _onSearch(_searchCtrl.text); }),
        )),
        const Spacer(),
        Text('${_shown.length} টি নাম',
          style: GoogleFonts.hindSiliguri(color: tc.sub, fontSize: 12)),
      ]),
    );
  }

  // ── list ───────────────────────────────────────────────────────────────────
  Widget _buildList(_TC tc) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _shown.length,
      itemBuilder: (_, i) {
        final item = _shown[i] as Map;
        final url  = item['audio_url'] as String? ?? '';
        final isThis = _playingUrl == url;
        return _NameCard(
          item: item, lang: _lang, tc: tc,
          isPlaying: isThis && _isPlaying,
          isPaused:  isThis && !_isPlaying && _playingUrl != null,
          pulseCtrl: _pulseCtrl,
          onPlay: () => _toggleAudio(url),
          onTap:  () => _openDetail(item, tc),
        );
      },
    );
  }

  // ── loader / error ─────────────────────────────────────────────────────────
  Widget _buildLoader(_TC tc) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(width: 48, height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(tc.gold))),
      const SizedBox(height: 16),
      Text('লোড হচ্ছে…',
        style: GoogleFonts.hindSiliguri(color: tc.sub, fontSize: 14)),
    ],
  ));

  Widget _buildError(_TC tc) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.wifi_off_rounded, color: tc.sub, size: 56),
      const SizedBox(height: 12),
      Text('ডেটা লোড হয়নি',
        style: GoogleFonts.hindSiliguri(color: tc.text, fontSize: 16,
            fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('ইন্টারনেট সংযোগ চেক করুন',
        style: GoogleFonts.hindSiliguri(color: tc.sub, fontSize: 13)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: tc.teal, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        icon: const Icon(Icons.refresh_rounded),
        label: Text('আবার চেষ্টা করুন',
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
        onPressed: _fetchData,
      ),
    ],
  ));
}

// ─── Language chip ────────────────────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final _TC    tc;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.selected,
      required this.tc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? tc.gold : tc.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tc.gold : tc.divider, width: 1),
        ),
        child: Text(label,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : tc.sub)),
      ),
    );
  }
}

// ─── Name card ────────────────────────────────────────────────────────────────
class _NameCard extends StatelessWidget {
  final Map  item;
  final _Lang lang;
  final _TC   tc;
  final bool  isPlaying;
  final bool  isPaused;
  final AnimationController pulseCtrl;
  final VoidCallback onPlay;
  final VoidCallback onTap;

  const _NameCard({
    required this.item, required this.lang, required this.tc,
    required this.isPlaying, required this.isPaused,
    required this.pulseCtrl, required this.onPlay, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final num     = item['number'] ?? 0;
    final ar      = item['name']?['arabic'] ?? '';
    final tr      = item['name']?['transliteration'] ?? '';
    final trans   = item['translations']?[lang.key];
    final name    = trans?['name'] ?? '';
    final meaning = trans?['meaning'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? tc.gold.withValues(alpha: 0.6) : tc.divider,
            width: isPlaying ? 1.5 : 1),
          boxShadow: isPlaying
              ? [BoxShadow(color: tc.gold.withValues(alpha: 0.18), blurRadius: 16, spreadRadius: 1)]
              : tc.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _NumberBadge(num: num, isPlaying: isPlaying, tc: tc, pulseCtrl: pulseCtrl),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(ar,
                        style: GoogleFonts.amiri(
                          fontSize: 22, color: tc.gold,
                          fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl)),
                    const SizedBox(width: 8),
                    Text(tr,
                      style: GoogleFonts.poppins(
                        fontSize: 10, color: tc.teal,
                        fontStyle: FontStyle.italic)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(name,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14, color: tc.text,
                    fontWeight: FontWeight.w600)),
                if (meaning.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(meaning,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11, color: tc.sub, height: 1.4)),
                ],
              ],
            )),
            const SizedBox(width: 10),
            _PlayButton(
              isPlaying: isPlaying, isPaused: isPaused,
              tc: tc, pulseCtrl: pulseCtrl, onTap: onPlay),
          ]),
        ),
      ),
    );
  }
}

// ─── Number badge ─────────────────────────────────────────────────────────────
class _NumberBadge extends StatelessWidget {
  final int num;
  final bool isPlaying;
  final _TC  tc;
  final AnimationController pulseCtrl;
  const _NumberBadge({required this.num, required this.isPlaying,
      required this.tc, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        final scale = isPlaying ? 1.0 + pulseCtrl.value * 0.08 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isPlaying
                    ? [tc.gold, tc.goldLight]
                    : [tc.card2, tc.divider],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
              boxShadow: isPlaying
                  ? [BoxShadow(color: tc.gold.withValues(alpha: 0.4), blurRadius: 10)]
                  : [],
            ),
            child: Center(child: Text('$num',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: isPlaying ? Colors.white : tc.sub))),
          ),
        );
      },
    );
  }
}

// ─── Play button ──────────────────────────────────────────────────────────────
class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isPaused;
  final _TC  tc;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;
  const _PlayButton({required this.isPlaying, required this.isPaused,
      required this.tc, required this.pulseCtrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) => Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isPlaying
                  ? [tc.teal, tc.tealDark]
                  : [tc.card2, tc.divider]),
            boxShadow: isPlaying
                ? [BoxShadow(color: tc.teal.withValues(alpha: 0.4), blurRadius: 10)]
                : [],
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded
                : isPaused ? Icons.play_arrow_rounded
                : Icons.volume_up_rounded,
            color: isPlaying ? Colors.white : tc.sub,
            size: 20),
        ),
      ),
    );
  }
}

// ─── Detail page ──────────────────────────────────────────────────────────────
class _DetailPage extends StatefulWidget {
  final Map  item;
  final _Lang lang;
  final AudioPlayer player;
  final String? playingUrl;
  final bool    isPlaying;
  final Future<void> Function(String) onToggle;

  const _DetailPage({
    required this.item, required this.lang, required this.player,
    required this.playingUrl, required this.isPlaying, required this.onToggle,
  });

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> with TickerProviderStateMixin {
  late _Lang _lang;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late AnimationController _pulseCtrl;

  String? _playingUrl;
  bool    _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _lang       = widget.lang;
    _playingUrl = widget.playingUrl;
    _isPlaying  = widget.isPlaying;

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    widget.player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    widget.player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playingUrl = null; _isPlaying = false; });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.item['audio_url'] as String? ?? '';
    setState(() => _playingUrl = url);
    await widget.onToggle(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final tc     = _TC(isDark);

    final item    = widget.item;
    final num     = item['number'] ?? 0;
    final ar      = item['name']?['arabic'] ?? '';
    final tr      = item['name']?['transliteration'] ?? '';
    final url     = item['audio_url'] as String? ?? '';
    final isThis  = _playingUrl == url;
    final trans   = item['translations']?[_lang.key] as Map? ?? {};
    final name    = trans['name']    ?? '';
    final meaning = trans['meaning'] ?? '';
    final details = trans['details'] ?? '';

    return Scaffold(
      backgroundColor: tc.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── hero header ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              backgroundColor: tc.headerGrad[0],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Number badge
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) {
                      final s = isThis && _isPlaying
                          ? 1.0 + _pulseCtrl.value * 0.08 : 1.0;
                      return Transform.scale(
                        scale: s,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [tc.gold, tc.goldLight])),
                          child: Center(child: Text('$num',
                            style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.bold,
                              color: Colors.white)))));
                    }),
                  const SizedBox(width: 8),
                  // Arabic name
                  Text(ar,
                    style: GoogleFonts.amiri(
                      fontSize: 20, color: tc.gold,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(width: 1.2, height: 16, color: Colors.white30),
                  const SizedBox(width: 8),
                  // Transliteration
                  Flexible(
                    child: Text(tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70,
                        fontStyle: FontStyle.italic))),
                ],
              ),
              centerTitle: false,
              titleSpacing: 0,
            ),

            // ── body ─────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDetailLangBar(tc),
                    const SizedBox(height: 14),
                    _buildNameAudioCard(name, url, isThis, tc),
                    const SizedBox(height: 12),
                    if (meaning.isNotEmpty) _buildSection(
                      icon: Icons.auto_awesome_rounded,
                      title: 'অর্থ / Meaning',
                      content: meaning, tc: tc,
                      accentColor: tc.teal),
                    const SizedBox(height: 12),
                    if (details.isNotEmpty) _buildDetailsCard(details, tc),
                    const SizedBox(height: 12),
                    _buildInfoRow('Transliteration', tr, Icons.translate_rounded, tc),
                    const SizedBox(height: 8),
                    _buildInfoRow('Number', '$num / 99', Icons.tag_rounded, tc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailLangBar(_TC tc) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Lang.values.map((l) => _LangChip(
          label: l.label, selected: _lang == l, tc: tc,
          onTap: () => setState(() => _lang = l),
        )).toList(),
      ),
    );
  }

  Widget _buildNameAudioCard(String name, String url, bool isThis, _TC tc) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isThis && _isPlaying
              ? tc.gold.withValues(alpha: 0.5) : tc.divider),
        boxShadow: isThis && _isPlaying
            ? [BoxShadow(color: tc.gold.withValues(alpha: 0.15), blurRadius: 16)]
            : tc.cardShadow,
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('নাম', style: GoogleFonts.hindSiliguri(color: tc.sub, fontSize: 11)),
            const SizedBox(height: 4),
            Text(name, style: GoogleFonts.hindSiliguri(
              color: tc.text, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        )),
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final s = isThis && _isPlaying
                  ? 1.0 + _pulseCtrl.value * 0.1 : 1.0;
              return Transform.scale(
                scale: s,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isThis && _isPlaying
                          ? [tc.teal, tc.tealDark]
                          : [tc.gold, tc.goldLight]),
                    boxShadow: [BoxShadow(
                      color: (isThis && _isPlaying ? tc.teal : tc.gold)
                          .withValues(alpha: 0.4),
                      blurRadius: 14)]),
                  child: Icon(
                    isThis && _isPlaying
                        ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 26)));
            }),
        ),
      ]),
    );
  }

  Widget _buildSection({
    required IconData icon, required String title,
    required String content, required _TC tc, required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.divider),
        boxShadow: tc.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.poppins(
            color: accentColor, fontSize: 12,
            fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        ]),
        const SizedBox(height: 10),
        Text(content, style: GoogleFonts.hindSiliguri(
          color: tc.text, fontSize: 14, height: 1.6)),
      ]),
    );
  }

  Widget _buildDetailsCard(String details, _TC tc) {
    final parts = details.split('\n');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.divider),
        boxShadow: tc.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.menu_book_rounded, color: tc.gold, size: 16),
          const SizedBox(width: 6),
          Text('বিস্তারিত / Details',
            style: GoogleFonts.poppins(
              color: tc.gold, fontSize: 12,
              fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        ]),
        const SizedBox(height: 12),
        ...parts.map((line) {
          if (line.trim().isEmpty) return const SizedBox(height: 6);
          if (line.contains('**')) {
            final clean = line.replaceAll('**', '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tc.gold.withValues(alpha: tc.isDark ? 0.08 : 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tc.gold.withValues(alpha: 0.25))),
                child: Text(clean,
                  style: GoogleFonts.hindSiliguri(
                    color: tc.isDark ? tc.goldLight : const Color(0xFF8B6914),
                    fontSize: 13, fontWeight: FontWeight.w600, height: 1.5))));
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line,
              style: GoogleFonts.hindSiliguri(
                color: tc.text, fontSize: 13, height: 1.65)));
        }),
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, _TC tc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.divider),
        boxShadow: tc.cardShadow,
      ),
      child: Row(children: [
        Icon(icon, color: tc.sub, size: 16),
        const SizedBox(width: 10),
        Text('$label  ', style: GoogleFonts.poppins(color: tc.sub, fontSize: 12)),
        Expanded(child: Text(value,
          style: GoogleFonts.poppins(
            color: tc.text, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
