import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ArabicQuizResultPage extends StatefulWidget {
  final int score;
  final int total;
  final VoidCallback onRetry;

  const ArabicQuizResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.onRetry,
  });

  @override
  State<ArabicQuizResultPage> createState() => _ArabicQuizResultPageState();
}

class _ArabicQuizResultPageState extends State<ArabicQuizResultPage>
    with TickerProviderStateMixin {
  // ── Confetti particles ──────────────────────────────────
  late AnimationController _confettiCtrl;

  // ── Score counter animation ─────────────────────────────
  late AnimationController _scoreCtrl;
  late Animation<int> _scoreAnim;

  // ── Card scale-in ───────────────────────────────────────
  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;

  // ── Emoji bounce ────────────────────────────────────────
  late AnimationController _emojiCtrl;
  late Animation<double> _emojiBounce;

  final List<_Particle> _particles = [];
  final _rng = Random();

  int get pct => (widget.score / widget.total * 100).round();
  bool get isGreat => pct >= 80;
  bool get isOk => pct >= 50;

  @override
  void initState() {
    super.initState();

    // Generate confetti particles
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle.random(_rng));
    }

    // Confetti falls for 3 seconds, repeats once
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    // Score counts up
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut),
    );

    // Card slides + fades in
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut),
    );
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);

    // Emoji bounces
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _emojiBounce = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _emojiCtrl, curve: Curves.elasticOut),
    );

    // Start sequence
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _cardCtrl.forward();
        _emojiCtrl.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scoreCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _scoreCtrl.dispose();
    _cardCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // ── Confetti layer ─────────────────────────────
          if (isGreat || isOk)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                ),
              ),
            ),

          // ── Main content ───────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: _buildCard(isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Emoji ──────────────────────────────────────
          ScaleTransition(
            scale: _emojiBounce,
            child: Text(
              isGreat ? '🎉' : isOk ? '👍' : '😔',
              style: const TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──────────────────────────────────────
          Text(
            isGreat
                ? 'অভিনন্দন!'
                : isOk
                    ? 'ভালো করেছেন!'
                    : 'আরও চেষ্টা করুন!',
            style: GoogleFonts.hindSiliguri(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            isGreat
                ? 'আপনি দারুণ পারফর্ম করেছেন!'
                : isOk
                    ? 'আরও অনুশীলন করলে আরও ভালো হবে।'
                    : 'হাল ছাড়বেন না, আবার চেষ্টা করুন।',
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkText.withValues(alpha: 0.65)
                  : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── Score circle ───────────────────────────────
          _buildScoreCircle(isDark),
          const SizedBox(height: 28),

          // ── Stats row ──────────────────────────────────
          _buildStatsRow(isDark),
          const SizedBox(height: 28),

          // ── Buttons ────────────────────────────────────
          _buildButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(bool isDark) {
    final color = isGreat
        ? const Color(0xFF2ECC71)
        : isOk
            ? const Color(0xFFF39C12)
            : const Color(0xFFE74C3C);

    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CircularProgressIndicator(
                value: widget.total > 0 ? _scoreAnim.value / widget.total : 0,
                strokeWidth: 10,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_scoreAnim.value}/${widget.total}',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkText.withValues(alpha: 0.6)
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final wrong = widget.total - widget.score;
    return Row(
      children: [
        _StatBox(
          label: 'সঠিক',
          value: '${widget.score}',
          color: const Color(0xFF2ECC71),
          icon: Icons.check_circle_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'ভুল',
          value: '$wrong',
          color: const Color(0xFFE74C3C),
          icon: Icons.cancel_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'মোট',
          value: '${widget.total}',
          color: AppColors.primary,
          icon: Icons.quiz_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildButtons(bool isDark) {
    return Column(
      children: [
        // Retry
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            widget.onRetry();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C3CE1).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '🔄  আবার খেলুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Exit
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // result page
            Navigator.pop(context); // quiz page
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBg
                  : AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'বের হন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stat Box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkText.withValues(alpha: 0.6)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confetti Particle ────────────────────────────────────────────────────────

class _Particle {
  final double x;       // 0..1 horizontal start
  final double speed;   // fall speed multiplier
  final double size;
  final Color color;
  final double wobble;  // horizontal wobble frequency
  final double wobbleAmp;
  final double rotation;

  _Particle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.wobble,
    required this.wobbleAmp,
    required this.rotation,
  });

  factory _Particle.random(Random rng) {
    const colors = [
      Color(0xFF6C3CE1),
      Color(0xFF4A6FE3),
      Color(0xFF2ECC71),
      Color(0xFFF39C12),
      Color(0xFFE74C3C),
      Color(0xFF9B59B6),
      Color(0xFF3498DB),
      Color(0xFFFF6B9D),
    ];
    return _Particle(
      x: rng.nextDouble(),
      speed: 0.4 + rng.nextDouble() * 0.6,
      size: 5 + rng.nextDouble() * 7,
      color: colors[rng.nextInt(colors.length)],
      wobble: 1 + rng.nextDouble() * 3,
      wobbleAmp: 0.02 + rng.nextDouble() * 0.04,
      rotation: rng.nextDouble() * 2 * pi,
    );
  }
}

// ─── Confetti Painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = progress * p.speed * size.height * 1.3;
      if (y > size.height + 20) continue;

      final x = p.x * size.width +
          sin(progress * p.wobble * 2 * pi) * p.wobbleAmp * size.width;

      final paint = Paint()..color = p.color.withValues(alpha: 1 - progress * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * 4);

      // Draw small rectangle (confetti piece)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
