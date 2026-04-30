import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../widgets/shimmer.dart';

const _kPrimary = Color(0xFF1B6B3A);
const _kPrimaryDark = Color(0xFF0F4D2A);
const _kPrimaryLight = Color(0xFF2E8B57);
const _kGold = Color(0xFFFFB300);

// ═══════════════════════════════════════════════════════════════
// SurahDetailPage — uses global AudioProvider
// ═══════════════════════════════════════════════════════════════
class SurahDetailPage extends StatefulWidget {
  final Map surahInfo;
  const SurahDetailPage({super.key, required this.surahInfo});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? surahData;
  Set<String> favVerseKeys = {};
  final ScrollController _scroll = ScrollController();

  int get _surahId => (widget.surahInfo['id'] as num).toInt();
  String get _surahName =>
      widget.surahInfo['translation'] ?? widget.surahInfo['name'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = context.read<AudioProvider>();

      audio.onAutoPlayNext = (nextVerseId) {
        if (!mounted) return;
        if (surahData == null) return;
        final verses = surahData!['verses'] as List;

        if (nextVerseId <= verses.length) {
          final verse = verses[nextVerseId - 1];
          audio.playVerse(
            surahId: _surahId,
            verseId: nextVerseId,
            surahNameStr: _surahName,
            verseTextStr: verse['text'] ?? '',
          );
          _scrollTo(nextVerseId);
        } else {
          _goToNextSurah();
        }
      };
    });
  }

  Future<void> _goToNextSurah() async {
    if (!mounted) return;
    final nextId = _surahId + 1;
    if (nextId > 114) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cachedSurahs');
      if (cached == null || !mounted) return;

      final list = jsonDecode(cached) as List;
      final nextSurah = list.firstWhere(
        (s) => (s['id'] as num).toInt() == nextId,
        orElse: () => null,
      );
      if (nextSurah == null || !mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SurahDetailPage(surahInfo: nextSurah),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _scroll.dispose();
    final audio = context.read<AudioProvider>();
    if (audio.onAutoPlayNext != null) audio.onAutoPlayNext = null;
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadDetail(), _loadFavVerses()]);
  }

  Future<void> _loadDetail() async {
    final cached = await _getCached();
    if (cached != null && mounted) {
      setState(() {
        surahData = cached;
        isLoading = false;
      });
      _autoPlayFirst();
    }
    try {
      final link = widget.surahInfo['link'] as String;
      final res = await http.get(Uri.parse(link));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        await _setCached(data);
        if (mounted) {
          setState(() {
            surahData = data;
            isLoading = false;
          });
          if (cached == null) _autoPlayFirst();
        }
      } else if (mounted && surahData == null) {
        setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted && surahData == null) setState(() => isLoading = false);
    }
  }

  void _autoPlayFirst() {
    if (surahData == null) return;
    final verses = surahData!['verses'] as List;
    if (verses.isEmpty) return;
    final first = verses[0];
    final audio = context.read<AudioProvider>();
    if (!audio.isPlaying) {
      audio.playVerse(
        surahId: _surahId,
        verseId: first['id'] as int,
        surahNameStr: _surahName,
        verseTextStr: first['text'] ?? '',
      );
    }
  }

  Future<void> _setCached(Map<String, dynamic> data) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('surah_$_surahId', json.encode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final d = prefs.getString('surah_$_surahId');
      if (d != null) return json.decode(d) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<void> _loadFavVerses() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        favVerseKeys = (prefs.getStringList('favVerses') ?? []).toSet();
      });
    }
  }

  Future<void> _toggleFav(int verseId) async {
    final key = '$_surahId-$verseId';
    final prefs = await SharedPreferences.getInstance();
    if (favVerseKeys.contains(key)) {
      favVerseKeys.remove(key);
    } else {
      favVerseKeys.add(key);
    }
    await prefs.setStringList('favVerses', favVerseKeys.toList());
    if (mounted) setState(() {});
  }

  void _scrollTo(int verseId) {
    if (surahData == null || !_scroll.hasClients) return;
    final verses = surahData!['verses'] as List;
    final idx = verses.indexWhere((v) => v['id'] == verseId);
    if (idx != -1) {
      _scroll.animateTo(
        (idx * 200.0).clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.hindSiliguri()),
      backgroundColor: _kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  void _showSettings(AudioProvider audio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: audio,
        child: _SettingsSheet(
          onSave: () {
            audio.saveSettings();
            Navigator.pop(context);
            _snack('সেটিংস সেভ হয়েছে ✓');
          },
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final name = widget.surahInfo['translation'] ?? widget.surahInfo['name'];
    final translit = widget.surahInfo['transliteration'] ?? '';
    final totalVerses = widget.surahInfo['total_verses'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: NestedScrollView(
        headerSliverBuilder: (_, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 0,
            collapsedHeight: kToolbarHeight,
            toolbarHeight: kToolbarHeight,
            pinned: true,
            snap: false,
            floating: false,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: _kPrimary,
            automaticallyImplyLeading: false,

            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),

            title: _CollapsedTitle(
              arabic: widget.surahInfo['name'] ?? '',
              bangla: name,
              translit: translit,
              totalVerses: '$totalVerses',
            ),
            centerTitle: false,
            titleSpacing: 4,

            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 20),
                onPressed: () => _showSettings(audio),
              ),
            ],
          ),
        ],
        body: isLoading
            ? VerseCardShimmer(isDark: false)
            : surahData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('ডেটা লোড হয়নি',
                            style: GoogleFonts.hindSiliguri(
                                color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isLoading = true);
                            _loadDetail();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary),
                          child: Text('আবার চেষ্টা করুন',
                              style: GoogleFonts.hindSiliguri(
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _PinchFontScaler(
                    audio: audio,
                    child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: (surahData!['verses'] as List).length,
                    itemBuilder: (ctx, i) {
                      final verse = (surahData!['verses'] as List)[i];
                      final vid = verse['id'] as int;
                      final key = '$_surahId-$vid';
                      final isFav = favVerseKeys.contains(key);
                      final isActive = audio.isThisVerseActive(_surahId, vid);
                      final isPlaying = audio.isThisVersePlaying(_surahId, vid);

                      return _VerseCard(
                        verse: verse,
                        verseId: vid,
                        isFav: isFav,
                        isActive: isActive,
                        isPlaying: isPlaying,
                        arabicSize: audio.arabicSize,
                        showTranslit: audio.showTranslit,
                        showTranslation: audio.showTranslation,
                        duration: isActive ? audio.duration : null,
                        position: isActive ? audio.position : null,
                        onPlay: () => audio.playVerse(
                          surahId: _surahId,
                          verseId: vid,
                          surahNameStr: _surahName,
                          verseTextStr: verse['text'] ?? '',
                        ),
                        onFav: () => _toggleFav(vid),
                        onSeek: (v) =>
                            audio.seek(Duration(milliseconds: v.toInt())),
                        formatDuration: _fmt,
                      );
                    },
                  ),
                ),
      ),
    );
  }
}

// ─── Settings sheet ───────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  final VoidCallback onSave;
  const _SettingsSheet({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();

    final reciters = [
      {'id': 'MaherAlMuaiqly128kbps', 'name': 'মাহের আল-মুয়াইকলি'},
      {'id': 'AbdulSamad_64kbps_QuranExplorer.Com', 'name': 'আব্দুল সামাদ'},
      {'id': 'Abdul_Basit_Mujawwad_128kbps', 'name': 'আব্দুল বাসিত মুজাওয়াদ'},
      {'id': 'Abdul_Basit_Murattal_192kbps', 'name': 'আব্দুল বাসিত মুরাত্তাল'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('সেটিংস',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          _sw('উচ্চারণ দেখান', audio.showTranslit,
              (v) => audio.showTranslit = v, audio),
          _sw('বাংলা অনুবাদ দেখান', audio.showTranslation,
              (v) => audio.showTranslation = v, audio),
          _sw('অটো প্লে (পরের আয়াত)', audio.autoPlay,
              (v) => audio.autoPlay = v, audio),
          if (!kIsWeb)
            _sw('অডিও ক্যাশ করুন', audio.useCached,
                (v) => audio.useCached = v, audio),

          const SizedBox(height: 12),
          // Font size
          Row(
            children: [
              Text('আরবি ফন্ট সাইজ',
                  style: GoogleFonts.hindSiliguri(fontSize: 14)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: _kPrimary),
                onPressed: () {
                  audio.arabicSize = (audio.arabicSize - 2).clamp(18, 40);
                  audio.notifyListeners();
                },
              ),
              Text('${audio.arabicSize.toInt()}',
                  style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _kPrimary),
                onPressed: () {
                  audio.arabicSize = (audio.arabicSize + 2).clamp(18, 40);
                  audio.notifyListeners();
                },
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text('ক্বারী নির্বাচন করুন',
              style: GoogleFonts.hindSiliguri(fontSize: 14)),
          const SizedBox(height: 4),
          ...reciters.map((r) => RadioListTile<String>(
                value: r['id']!,
                groupValue: audio.reciter,
                activeColor: _kPrimary,
                title: Text(r['name']!,
                    style: GoogleFonts.hindSiliguri(fontSize: 13)),
                onChanged: (v) {
                  if (v != null) {
                    audio.reciter = v;
                    audio.notifyListeners();
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('সেভ করুন',
                  style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sw(String label, bool val, Function(bool) setter,
      AudioProvider audio) {
    return SwitchListTile(
      title: Text(label, style: GoogleFonts.hindSiliguri(fontSize: 14)),
      value: val,
      onChanged: (v) {
        setter(v);
        audio.notifyListeners();
      },
      activeColor: _kPrimary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ─── Verse card ───────────────────────────────────────────────
class _VerseCard extends StatelessWidget {
  final dynamic verse;
  final int verseId;
  final bool isFav, isActive, isPlaying;
  final double arabicSize;
  final bool showTranslit, showTranslation;
  final Duration? duration, position;
  final VoidCallback onPlay, onFav;
  final ValueChanged<double> onSeek;
  final String Function(Duration) formatDuration;

  const _VerseCard({
    required this.verse,
    required this.verseId,
    required this.isFav,
    required this.isActive,
    required this.isPlaying,
    required this.arabicSize,
    required this.showTranslit,
    required this.showTranslation,
    required this.duration,
    required this.position,
    required this.onPlay,
    required this.onFav,
    required this.onSeek,
    required this.formatDuration,
  });

  String _bn(int n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: _kPrimary, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: _kPrimary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(_bn(verseId),
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive && isPlaying
                          ? _kPrimary
                          : _kPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive && isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isActive && isPlaying ? Colors.white : _kPrimary,
                      size: 18,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onFav,
                  child: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? _kGold : Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Arabic
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              verse['text'] ?? '',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontSize: arabicSize,
                  height: 2.0,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'serif'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: _kPrimary.withValues(alpha: 0.12), height: 1),
          ),

          if (showTranslit && (verse['transliteration'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                verse['transliteration'] ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _kPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.6),
              ),
            ),

          if (showTranslation && (verse['translation'] ?? '').isNotEmpty)
            Padding(
              padding:
                  EdgeInsets.fromLTRB(16, showTranslit ? 4 : 10, 16, 14),
              child: Text(
                verse['translation'] ?? '',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 14, color: Colors.grey[700], height: 1.7),
              ),
            ),

          // Audio progress
          if (isActive && duration != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _kPrimary,
                      inactiveTrackColor: _kPrimary.withValues(alpha: 0.2),
                      thumbColor: _kPrimary,
                      overlayColor: _kPrimary.withValues(alpha: 0.1),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: (position ?? Duration.zero)
                          .inMilliseconds
                          .toDouble()
                          .clamp(0, duration!.inMilliseconds.toDouble()),
                      max: duration!.inMilliseconds.toDouble(),
                      onChanged: onSeek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position ?? Duration.zero),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey)),
                        Text(formatDuration(duration!),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (!showTranslit && !showTranslation && !isActive)
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Pinch-to-zoom font scaler ───────────────────────────────
class _PinchFontScaler extends StatefulWidget {
  final AudioProvider audio;
  final Widget child;
  const _PinchFontScaler({required this.audio, required this.child});

  @override
  State<_PinchFontScaler> createState() => _PinchFontScalerState();
}

class _PinchFontScalerState extends State<_PinchFontScaler> {
  double _baseSize = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (_) => _baseSize = widget.audio.arabicSize,
      onScaleUpdate: (details) {
        if (details.pointerCount < 2) return;
        final newSize = (_baseSize * details.scale).clamp(18.0, 40.0);
        widget.audio.arabicSize = newSize;
        widget.audio.notifyListeners();
      },
      child: widget.child,
    );
  }
}

// ─── Collapsed app-bar title ──────────────────────────────────
// ✅ সব টেক্সট এক লাইনে, স্মুথ ট্রানজিশন
class _CollapsedTitle extends StatelessWidget {
  final String arabic;
  final String bangla;
  final String translit;
  final String totalVerses;

  const _CollapsedTitle({
    required this.arabic,
    required this.bangla,
    required this.translit,
    required this.totalVerses,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Arabic name
        Text(
          arabic,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 5),

        // Divider
        Container(width: 1, height: 14, color: Colors.white38),
        const SizedBox(width: 5),

        // Bangla name
        Flexible(
          child: Text(
            bangla,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (translit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Container(width: 1, height: 14, color: Colors.white38),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              translit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        const SizedBox(width: 6),

        // Verse count pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$totalVerses আয়াত',
            style: GoogleFonts.hindSiliguri(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}