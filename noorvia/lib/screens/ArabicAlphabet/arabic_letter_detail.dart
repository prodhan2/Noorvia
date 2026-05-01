import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'arabic_letter_model.dart';
import 'arabic_progress_provider.dart';

class ArabicLetterDetail extends StatefulWidget {
  final ArabicLetter letter;
  final List<ArabicLetter> allLetters;
  final int index;

  const ArabicLetterDetail({
    super.key,
    required this.letter,
    required this.allLetters,
    required this.index,
  });

  @override
  State<ArabicLetterDetail> createState() => _ArabicLetterDetailState();
}

class _ArabicLetterDetailState extends State<ArabicLetterDetail>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _audioLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _audioLoading = false;
        });
      }
    });

    // Mark as learned when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ArabicProgressProvider>()
          .markLearned(widget.allLetters[_currentIndex].letter);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  ArabicLetter get _current => widget.allLetters[_currentIndex];

  void _navigate(int delta) {
    final next = _currentIndex + delta;
    if (next < 0 || next >= widget.allLetters.length) return;
    _animCtrl.reset();
    setState(() => _currentIndex = next);
    _animCtrl.forward();
    _player.stop();
    context.read<ArabicProgressProvider>().markLearned(_current.letter);
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _player.stop();
      return;
    }
    if (_current.audioLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('অডিও পাওয়া যায়নি',
              style: GoogleFonts.hindSiliguri()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _audioLoading = true);
    try {
      await _player.play(UrlSource(_current.audioLink));
    } catch (e) {
      if (mounted) {
        setState(() => _audioLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অডিও চালানো যায়নি',
                style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final prog = context.watch<ArabicProgressProvider>();
    final isFav = prog.isFavorite(_current.letter);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
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
        title: Text(
          '${_currentIndex + 1} / ${widget.allLetters.length}',
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.grey,
            ),
            onPressed: () => prog.toggleFavorite(_current.letter),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Main letter card ──────────────────────────
              _buildMainCard(isDark),
              const SizedBox(height: 16),
              // ── Forms card ────────────────────────────────
              _buildFormsCard(isDark),
              const SizedBox(height: 16),
              // ── Audio button ──────────────────────────────
              _buildAudioButton(isDark),
              const SizedBox(height: 24),
              // ── Navigation ───────────────────────────────
              _buildNavigation(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3), Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          Text(
            _current.letter,
            style: const TextStyle(
              fontSize: 96,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _current.bangla,
            style: GoogleFonts.hindSiliguri(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'উচ্চারণ: ${_current.pronunciation}',
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _current.name,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsCard(bool isDark) {
    final forms = [
      ('আলাদা রূপ', _current.forms.isolated, '🔵'),
      ('শুরুর রূপ', _current.forms.initial, '🟢'),
      ('মাঝের রূপ', _current.forms.medial, '🟡'),
      ('শেষের রূপ', _current.forms.finalForm, '🔴'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'অক্ষরের রূপ',
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: forms
                .map((f) => _FormTile(
                      label: f.$1,
                      form: f.$2,
                      dot: f.$3,
                      isDark: isDark,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton(bool isDark) {
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isPlaying
                ? [const Color(0xFFE74C3C), const Color(0xFFE74C3C)]
                : [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isPlaying
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFF2ECC71))
                  .withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_audioLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            else
              Icon(
                _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 24,
              ),
            const SizedBox(width: 10),
            Text(
              _isPlaying ? 'থামান' : 'উচ্চারণ শুনুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _NavButton(
            label: 'আগের অক্ষর',
            icon: Icons.arrow_back_ios_rounded,
            enabled: _currentIndex > 0,
            isDark: isDark,
            onTap: () => _navigate(-1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NavButton(
            label: 'পরের অক্ষর',
            icon: Icons.arrow_forward_ios_rounded,
            enabled: _currentIndex < widget.allLetters.length - 1,
            isDark: isDark,
            onTap: () => _navigate(1),
            isForward: true,
          ),
        ),
      ],
    );
  }
}

// ─── Form Tile ────────────────────────────────────────────────────────────────

class _FormTile extends StatelessWidget {
  final String label;
  final String form;
  final String dot;
  final bool isDark;

  const _FormTile({
    required this.label,
    required this.form,
    required this.dot,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Text(dot, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkText.withValues(alpha: 0.6)
                        : Colors.grey[600],
                  ),
                ),
                Text(
                  form,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;
  final bool isForward;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
    this.isForward = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary
              : (isDark
                  ? AppColors.darkCard
                  : Colors.grey.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isForward) ...[
              Icon(icon,
                  color: enabled ? Colors.white : Colors.grey, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : Colors.grey,
              ),
            ),
            if (isForward) ...[
              const SizedBox(width: 6),
              Icon(icon,
                  color: enabled ? Colors.white : Colors.grey, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
