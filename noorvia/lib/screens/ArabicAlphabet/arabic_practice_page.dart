import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'arabic_letter_model.dart';
import 'arabic_progress_provider.dart';

class ArabicPracticePage extends StatefulWidget {
  final List<ArabicLetter> letters;

  const ArabicPracticePage({super.key, required this.letters});

  @override
  State<ArabicPracticePage> createState() => _ArabicPracticePageState();
}

class _ArabicPracticePageState extends State<ArabicPracticePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _showDetails = false;

  final AudioPlayer _player = AudioPlayer();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  ArabicLetter get _current => widget.letters[_currentIndex];

  Future<void> _playAudio() async {
    if (_current.audioLink.isEmpty) return;
    try {
      await _player.stop();
      await _player.play(UrlSource(_current.audioLink));
    } catch (_) {}
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.letters.length) return;
    _animCtrl.reset();
    setState(() {
      _currentIndex = index;
      _showDetails = false;
    });
    _animCtrl.forward();
  }

  void _next() => _goTo(_currentIndex + 1);
  void _prev() => _goTo(_currentIndex - 1);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return ChangeNotifierProvider(
      create: (_) => ArabicProgressProvider()..load(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: _buildAppBar(isDark),
        body: Column(
          children: [
            // Progress bar
            _buildProgressBar(isDark),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Main letter card
                      _buildLetterCard(isDark),
                      const SizedBox(height: 16),
                      // Audio button
                      _buildAudioButton(isDark),
                      const SizedBox(height: 16),
                      // Show details toggle
                      _buildDetailsToggle(isDark),
                      if (_showDetails) ...[
                        const SizedBox(height: 16),
                        _buildFormsCard(isDark),
                      ],
                      const SizedBox(height: 16),
                      // Mark learned button
                      _buildMarkLearnedButton(isDark),
                    ],
                  ),
                ),
              ),
            ),
            // Navigation
            _buildNavigation(isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? AppColors.darkText : AppColors.lightText,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'অনুশীলন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          Text(
            'Arabic Practice',
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkText.withValues(alpha: 0.6)
                  : AppColors.lightText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.letters.length}',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = (_currentIndex + 1) / widget.letters.length;
    return ClipRRect(
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 4,
      ),
    );
  }

  Widget _buildLetterCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE1).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Arabic letter
          Text(
            _current.letter,
            style: const TextStyle(
              fontSize: 100,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // Bangla name
          Text(
            _current.bangla,
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // English name
          Text(
            _current.name,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          // Pronunciation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'উচ্চারণ: ${_current.pronunciation}',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton(bool isDark) {
    return GestureDetector(
      onTap: _current.audioLink.isNotEmpty ? _playAudio : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isPlaying
              ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
              : isDark
                  ? AppColors.darkCard
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPlaying
                ? const Color(0xFF2ECC71)
                : _current.audioLink.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPlaying ? Icons.volume_up_rounded : Icons.play_circle_outline_rounded,
              color: _isPlaying
                  ? const Color(0xFF2ECC71)
                  : _current.audioLink.isNotEmpty
                      ? AppColors.primary
                      : Colors.grey,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              _isPlaying
                  ? 'বাজছে...'
                  : _current.audioLink.isNotEmpty
                      ? 'উচ্চারণ শুনুন'
                      : 'অডিও নেই',
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _isPlaying
                    ? const Color(0xFF2ECC71)
                    : _current.audioLink.isNotEmpty
                        ? AppColors.primary
                        : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsToggle(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = !_showDetails),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'অক্ষরের রূপ দেখুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const Spacer(),
            Icon(
              _showDetails
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormsCard(bool isDark) {
    final forms = _current.forms;
    final formList = [
      {'label': 'বিচ্ছিন্ন', 'value': forms.isolated},
      {'label': 'শুরুতে', 'value': forms.initial},
      {'label': 'মাঝে', 'value': forms.medial},
      {'label': 'শেষে', 'value': forms.finalForm},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'বিভিন্ন অবস্থানে রূপ',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkText.withValues(alpha: 0.6)
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: formList.map((f) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      f['value']!.isNotEmpty ? f['value']! : '—',
                      style: TextStyle(
                        fontSize: 28,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f['label']!,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkText.withValues(alpha: 0.6)
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkLearnedButton(bool isDark) {
    return Consumer<ArabicProgressProvider>(
      builder: (_, prog, __) {
        final isLearned = prog.isLearned(_current.letter);
        return GestureDetector(
          onTap: isLearned ? null : () => prog.markLearned(_current.letter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: isLearned
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF2ECC71).withValues(alpha: 0.8),
                        const Color(0xFF27AE60).withValues(alpha: 0.8),
                      ],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isLearned
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFF6C3CE1))
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLearned ? Icons.check_circle_rounded : Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isLearned ? '✓ শেখা হয়েছে' : 'শেখা হয়েছে চিহ্নিত করুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigation(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: GestureDetector(
              onTap: _currentIndex > 0 ? _prev : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _currentIndex > 0
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16,
                      color: _currentIndex > 0 ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'আগের',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _currentIndex > 0 ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Next
          Expanded(
            child: GestureDetector(
              onTap: _currentIndex < widget.letters.length - 1 ? _next : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _currentIndex < widget.letters.length - 1
                      ? const LinearGradient(
                          colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
                        )
                      : null,
                  color: _currentIndex < widget.letters.length - 1
                      ? null
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _currentIndex < widget.letters.length - 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C3CE1).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentIndex < widget.letters.length - 1
                          ? 'পরের'
                          : 'শেষ',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _currentIndex < widget.letters.length - 1
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    if (_currentIndex < widget.letters.length - 1) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
