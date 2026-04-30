import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class AsmaulHusnaItem {
  final int number;
  final String arabic;
  final String transliteration;
  final String banglaName;
  final String banglaMeaning;
  final String banglaDetails;
  final String englishName;
  final String englishMeaning;
  final String audioUrl;

  const AsmaulHusnaItem({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.banglaName,
    required this.banglaMeaning,
    required this.banglaDetails,
    required this.englishName,
    required this.englishMeaning,
    required this.audioUrl,
  });

  factory AsmaulHusnaItem.fromJson(Map<String, dynamic> j) {
    final bangla = j['translations']?['bangla'] ?? {};
    final english = j['translations']?['english'] ?? {};
    return AsmaulHusnaItem(
      number: j['number'] ?? 0,
      arabic: j['name']?['arabic'] ?? '',
      transliteration: j['name']?['transliteration'] ?? '',
      banglaName: bangla['name'] ?? '',
      banglaMeaning: bangla['meaning'] ?? '',
      banglaDetails: bangla['details'] ?? '',
      englishName: english['name'] ?? '',
      englishMeaning: english['meaning'] ?? '',
      audioUrl: j['audio_url'] ?? '',
    );
  }
}

// ─── Color palette for cards (cycles through 99 names) ───────────────────────
const List<Color> _kCardColors = [
  Color(0xFF1B6B3A), Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFFE65100),
  Color(0xFF00838F), Color(0xFFAD1457), Color(0xFF2E7D32), Color(0xFF4527A0),
  Color(0xFF00695C), Color(0xFF558B2F), Color(0xFF4E342E), Color(0xFF37474F),
];

Color _colorFor(int index) => _kCardColors[index % _kCardColors.length];

// ─── Main Page ────────────────────────────────────────────────────────────────
class AsmaulHusnaPage extends StatefulWidget {
  const AsmaulHusnaPage({super.key});

  @override
  State<AsmaulHusnaPage> createState() => _AsmaulHusnaPageState();
}

class _AsmaulHusnaPageState extends State<AsmaulHusnaPage>
    with SingleTickerProviderStateMixin {
  static const _apiUrl =
      'https://raw.githubusercontent.com/eiaserbd/asmaul-husna-api/main/data/asmaul-husna.json';

  List<AsmaulHusnaItem> _all = [];
  List<AsmaulHusnaItem> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  Set<int> _favorites = {};

  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final AudioPlayer _audio = AudioPlayer();
  int? _playingIndex;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadFavorites();
    _fetchData();
    _audio.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _audio.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playingIndex = null; _isPlaying = false; });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────
  Future<void> _fetchData() async {
    try {
      final res = await http.get(Uri.parse(_apiUrl));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = (json['asmaul_husna'] as List)
            .map((e) => AsmaulHusnaItem.fromJson(e))
            .toList();
        setState(() { _all = list; _filtered = list; _loading = false; });
      } else {
        setState(() { _error = 'ডেটা লোড ব্যর্থ (${res.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'ইন্টারনেট সংযোগ নেই'; _loading = false; });
    }
  }

  void _search(String q) {
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((item) =>
          item.arabic.contains(q) ||
          item.transliteration.toLowerCase().contains(q.toLowerCase()) ||
          item.banglaName.contains(q) ||
          item.englishName.toLowerCase().contains(q.toLowerCase()) ||
          item.number.toString() == q,
        ).toList();
      }
    });
  }

  // ── Favorites ─────────────────────────────────────────────
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('asmaul_husna_favs') ?? [];
    setState(() => _favorites = list.map(int.parse).toSet());
  }

  Future<void> _toggleFavorite(int number) async {
    setState(() {
      if (_favorites.contains(number)) {
        _favorites.remove(number);
      } else {
        _favorites.add(number);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('asmaul_husna_favs', _favorites.map((e) => e.toString()).toList());
  }

  // ── Audio ─────────────────────────────────────────────────
  Future<void> _toggleAudio(int index, String url) async {
    try {
      // Same track — pause/resume
      if (_playingIndex == index) {
        if (_isPlaying) {
          await _audio.pause();
          if (mounted) setState(() => _isPlaying = false);
        } else {
          await _audio.resume();
          if (mounted) setState(() => _isPlaying = true);
        }
        return;
      }

      // New track — stop previous, play new
      await _audio.stop();
      if (mounted) setState(() { _playingIndex = index; _isPlaying = false; });

      await _audio.play(UrlSource(url));
      if (mounted) setState(() => _isPlaying = true);

    } catch (e) {
      if (mounted) {
        setState(() { _playingIndex = null; _isPlaying = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অডিও চালাতে সমস্যা হয়েছে', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'أَسْمَاءُ اللّٰهِ الْحُسْنَى',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          height: 1.6,
                          fontWeight: FontWeight.w300,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'আল্লাহর ৯৯টি সুন্দর নাম',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                'আসমাউল হুসনা',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'সকল নাম'),
                Tab(text: 'প্রিয় নাম'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                style: GoogleFonts.hindSiliguri(color: textColor),
                decoration: InputDecoration(
                  hintText: 'নাম, অর্থ বা নম্বর দিয়ে খুঁজুন...',
                  hintStyle: GoogleFonts.hindSiliguri(
                    color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                    color: isDark ? AppColors.darkSubText : AppColors.lightSubText),
                  suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchCtrl.clear(); _search(''); },
                      )
                    : null,
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: _loading
                ? _buildLoading()
                : _error != null
                  ? _buildError()
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildGrid(_filtered, isDark),
                        _buildGrid(
                          _all.where((e) => _favorites.contains(e.number)).toList(),
                          isDark,
                          emptyMsg: 'কোনো প্রিয় নাম নেই\nকার্ডে ❤️ চাপুন',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (_, i) => _ShimmerCard(color: _colorFor(i)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.hindSiliguri(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () { setState(() { _loading = true; _error = null; }); _fetchData(); },
            icon: const Icon(Icons.refresh_rounded),
            label: Text('আবার চেষ্টা করুন', style: GoogleFonts.hindSiliguri()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<AsmaulHusnaItem> items, bool isDark, {String? emptyMsg}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              emptyMsg ?? 'কোনো ফলাফল পাওয়া যায়নি',
              style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = _colorFor(item.number - 1);
        final isFav = _favorites.contains(item.number);
        final isPlaying = _playingIndex == item.number && _isPlaying;

        return _NameCard(
          item: item,
          color: color,
          isFav: isFav,
          isPlaying: isPlaying,
          onTap: () => _openDetail(item, color, isDark),
          onFav: () => _toggleFavorite(item.number),
          onAudio: () => _toggleAudio(item.number, item.audioUrl),
        );
      },
    );
  }

  void _openDetail(AsmaulHusnaItem item, Color color, bool isDark) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: _DetailPage(
            item: item,
            color: color,
            isFav: _favorites.contains(item.number),
            onFav: () => _toggleFavorite(item.number),
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// ─── Name Card ────────────────────────────────────────────────────────────────
class _NameCard extends StatelessWidget {
  final AsmaulHusnaItem item;
  final Color color;
  final bool isFav;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFav;
  final VoidCallback onAudio;

  const _NameCard({
    required this.item,
    required this.color,
    required this.isFav,
    required this.isPlaying,
    required this.onTap,
    required this.onFav,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Number badge
            Positioned(
              top: 8, left: 8,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${item.number}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // Fav button
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: onFav,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red[300] : Colors.white.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 32, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        item.arabic,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    item.banglaName,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.transliteration,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Audio button
                  if (item.audioUrl.isNotEmpty)
                    GestureDetector(
                      onTap: onAudio,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isPlaying ? 'বিরতি' : 'শুনুন',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Page ──────────────────────────────────────────────────────────────
class _DetailPage extends StatefulWidget {
  final AsmaulHusnaItem item;
  final Color color;
  final bool isFav;
  final VoidCallback onFav;

  const _DetailPage({
    required this.item,
    required this.color,
    required this.isFav,
    required this.onFav,
  });

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> {
  bool _isFav = false;
  final AudioPlayer _audio = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFav;
    _audio.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() {
          _isPlaying = s == PlayerState.playing;
          _isLoading = false;
        });
      }
    });
    _audio.onPlayerComplete.listen((_) {
      if (mounted) { setState(() { _isPlaying = false; _isLoading = false; }); }
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = widget.item.audioUrl;
    if (url.isEmpty) return;
    try {
      if (_isPlaying) {
        await _audio.pause();
      } else if (!_isPlaying && _isLoading == false) {
        setState(() => _isLoading = true);
        await _audio.stop();
        await _audio.play(UrlSource(url));
      } else {
        await _audio.resume();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isPlaying = false; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অডিও চালাতে সমস্যা হয়েছে', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final color = widget.color;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFav ? Colors.red[300] : Colors.white,
                ),
                onPressed: () {
                  setState(() => _isFav = !_isFav);
                  widget.onFav();
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '${widget.item.arabic}\n${widget.item.transliteration}\n${widget.item.banglaName}: ${widget.item.banglaMeaning}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('কপি হয়েছে', style: GoogleFonts.hindSiliguri()),
                      backgroundColor: color,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.9),
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Number circle
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.item.number}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Arabic name
                      Text(
                        widget.item.arabic,
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.transliteration,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.banglaName,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio player card
                  if (widget.item.audioUrl.isNotEmpty)
                    _AudioCard(
                      color: color,
                      isPlaying: _isPlaying,
                      isLoading: _isLoading,
                      onTap: _toggleAudio,
                      isDark: isDark,
                    ),

                  const SizedBox(height: 20),

                  // Bangla meaning
                  _SectionCard(
                    title: 'অর্থ',
                    icon: Icons.translate_rounded,
                    color: color,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    child: Text(
                      widget.item.banglaMeaning,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 15,
                        color: textColor,
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // English meaning
                  _SectionCard(
                    title: 'English Meaning',
                    icon: Icons.language_rounded,
                    color: color,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    child: Text(
                      '${widget.item.englishName} — ${widget.item.englishMeaning}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Details with markdown
                  if (widget.item.banglaDetails.isNotEmpty)
                    _SectionCard(
                      title: 'বিস্তারিত ও ফজিলত',
                      icon: Icons.auto_stories_rounded,
                      color: color,
                      cardBg: cardBg,
                      textColor: textColor,
                      subColor: subColor,
                      child: MarkdownBody(
                        data: widget.item.banglaDetails,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: textColor,
                            height: 1.7,
                          ),
                          strong: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Audio Card ───────────────────────────────────────────────────────────────
class _AudioCard extends StatelessWidget {
  final Color color;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isDark;

  const _AudioCard({
    required this.color,
    required this.isPlaying,
    this.isLoading = false,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'লোড হচ্ছে...' : isPlaying ? 'চলছে...' : 'উচ্চারণ শুনুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    'IslamCity Audio',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.volume_up_rounded,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final Color color;
  const _ShimmerCard({required this.color});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.3 + 0.2 * _anim.value),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
     