import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'arabic_letter_model.dart';
import 'arabic_alphabet_service.dart';
import 'arabic_letter_detail.dart';
import 'arabic_quiz_page.dart';
import 'arabic_progress_provider.dart';

class ArabicAlphabetHome extends StatefulWidget {
  const ArabicAlphabetHome({super.key});

  @override
  State<ArabicAlphabetHome> createState() => _ArabicAlphabetHomeState();
}

class _ArabicAlphabetHomeState extends State<ArabicAlphabetHome> {
  List<ArabicLetter> _letters = [];
  List<ArabicLetter> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Audio — one shared player for the grid
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingLetter; // which letter is currently playing

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadData();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) setState(() => _playingLetter = null);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final cached = await ArabicAlphabetService.getCached();
    if (cached != null) {
      try {
        final list = await ArabicAlphabetService.fetchLetters();
        if (mounted) {
          setState(() {
            _letters = list;
            _filtered = list;
            _loading = false;
            _offline = false;
          });
        }
        return;
      } catch (_) {}
    }

    try {
      final list = await ArabicAlphabetService.fetchLetters();
      if (mounted) {
        setState(() {
          _letters = list;
          _filtered = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _offline = cached != null;
          if (cached == null) _error = 'ডেটা লোড হয়নি। ইন্টারনেট চেক করুন।';
        });
      }
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _letters;
      } else {
        _filtered = _letters.where((l) {
          return l.letter.contains(q) ||
              l.bangla.toLowerCase().contains(q) ||
              l.name.toLowerCase().contains(q) ||
              l.pronunciation.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _playAudio(ArabicLetter letter) async {
    if (letter.audioLink.isEmpty) return;
    if (_playingLetter == letter.letter) {
      // tap again → stop
      await _audioPlayer.stop();
      setState(() => _playingLetter = null);
      return;
    }
    setState(() => _playingLetter = letter.letter);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(letter.audioLink));
    } catch (_) {
      setState(() => _playingLetter = null);
    }
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return ChangeNotifierProvider(
      create: (_) => ArabicProgressProvider()..load(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(isDark),
        body: Column(
          children: [
            if (_offline)
              Container(
                width: double.infinity,
                color: Colors.orange.withValues(alpha: 0.15),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'অফলাইন মোড — ক্যাশ থেকে দেখানো হচ্ছে',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            _buildSearchBar(isDark),
            Expanded(child: _buildBody(isDark)),
          ],
        ),
      ),
    );
  }

  // ── Gradient AppBar ──────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3), Color(0xFF4A90D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আরবি বর্ণমালা',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Arabic Alphabet Learning',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Streak badge
                Consumer<ArabicProgressProvider>(
                  builder: (_, prog, __) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${prog.streak}',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Quiz icon button
                IconButton(
                  tooltip: 'কুইজ',
                  icon: const Icon(Icons.quiz_rounded,
                      color: Colors.white, size: 24),
                  onPressed: _letters.isEmpty
                      ? null
                      : () => _go(ArabicQuizPage(letters: _letters)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.hindSiliguri(
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          decoration: InputDecoration(
            hintText: 'অক্ষর, বাংলা বা ইংরেজি নাম দিয়ে খুঁজুন...',
            hintStyle: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkText.withValues(alpha: 0.4)
                  : Colors.grey,
            ),
            prefixIcon:
                Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchCtrl.clear(),
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

  Widget _buildBody(bool isDark) {
    if (_loading) return _buildShimmer(isDark);
    if (_error != null) return _buildError(isDark);
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'কোনো ফলাফল পাওয়া যায়নি',
          style: GoogleFonts.hindSiliguri(
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      );
    }

    return Consumer<ArabicProgressProvider>(
      builder: (_, prog, __) => RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,       // ← 4 columns
            childAspectRatio: 0.78,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            final letter = _filtered[index];
            final isLearned = prog.isLearned(letter.letter);
            final isFav = prog.isFavorite(letter.letter);
            final isPlaying = _playingLetter == letter.letter;

            return _LetterCard(
              letter: letter,
              isDark: isDark,
              isLearned: isLearned,
              isFavorite: isFav,
              isPlaying: isPlaying,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: prog,
                      child: ArabicLetterDetail(
                        letter: letter,
                        allLetters: _letters,
                        index: _letters.indexOf(letter),
                      ),
                    ),
                  ),
                );
              },
              onFavToggle: () => prog.toggleFavorite(letter.letter),
              onSound: () => _playAudio(letter),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.78,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 16,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label:
                  Text('আবার চেষ্টা করুন', style: GoogleFonts.hindSiliguri()),
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
}

// ─── Letter Card ──────────────────────────────────────────────────────────────

class _LetterCard extends StatelessWidget {
  final ArabicLetter letter;
  final bool isDark;
  final bool isLearned;
  final bool isFavorite;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFavToggle;
  final VoidCallback onSound;

  const _LetterCard({
    required this.letter,
    required this.isDark,
    required this.isLearned,
    required this.isFavorite,
    required this.isPlaying,
    required this.onTap,
    required this.onFavToggle,
    required this.onSound,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLearned
                ? const Color(0xFF2ECC71).withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.12),
            width: isLearned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Sound icon — top right corner ──────────────
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onSound,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: isPlaying
                        ? const LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
                          ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: (isPlaying
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFF6C3CE1))
                            .withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isPlaying
                      ? const _WaveAnimation()
                      : const Icon(Icons.volume_up_rounded,
                          color: Colors.white, size: 14),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Arabic letter
                Expanded(
                  child: Center(
                    child: Text(
                      letter.letter,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),

                // Bangla name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    letter.bangla,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 4),

                // উচ্চারণ
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    letter.pronunciation,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wave Animation ───────────────────────────────────────────────────────────

class _WaveAnimation extends StatefulWidget {
  const _WaveAnimation();

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (i) {
            // each bar has a phase offset
            final phase = (i / 4) * 2 * pi;
            final height = 4.0 +
                8.0 * (0.5 + 0.5 * sin(_ctrl.value * 2 * pi + phase));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

