import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// NShimmer — reusable shimmer animation widget
// Usage:
//   NShimmer(width: 200, height: 16)           // simple box
//   NShimmer(width: 40, height: 40, radius: 20) // circle
//   NShimmer.custom(child: myWidget)            // any shape
// ═══════════════════════════════════════════════════════════════
class NShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  final Widget? child;
  final bool isDark;

  const NShimmer({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.child,
    this.isDark = false,
  });

  /// Wrap any widget with shimmer overlay
  const NShimmer.custom({
    super.key,
    required this.child,
    this.isDark = false,
  })  : width = null,
        height = null,
        radius = 8;

  @override
  State<NShimmer> createState() => _NShimmerState();
}

class _NShimmerState extends State<NShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE8E8E8);
    final highlight = widget.isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(_anim.value),
            ).createShader(bounds);
          },
          child: widget.child ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
              ),
        );
      },
    );
  }
}

/// Slides the gradient horizontally
class _SlideGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlideGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * slidePercent, 0, 0);
  }
}

// ═══════════════════════════════════════════════════════════════
// Pre-built shimmer skeletons for each card type
// ═══════════════════════════════════════════════════════════════

/// Prayer card skeleton
class PrayerCardShimmer extends StatelessWidget {
  final bool isDark;
  const PrayerCardShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: time + mosque
          Row(
            children: [
              NShimmer(width: 28, height: 28, radius: 14, isDark: isDark),
              const SizedBox(width: 8),
              NShimmer(width: 90, height: 22, isDark: isDark),
              const Spacer(),
              NShimmer(width: 110, height: 48, isDark: isDark),
            ],
          ),
          const SizedBox(height: 14),
          // Row 2: prayer names
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NShimmer(width: 130, height: 14, isDark: isDark),
              NShimmer(width: 100, height: 14, isDark: isDark),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: sunrise/sunset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NShimmer(width: 70, height: 13, isDark: isDark),
              NShimmer(width: 70, height: 13, isDark: isDark),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 14),
          // Progress label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NShimmer(width: 100, height: 14, isDark: isDark),
              NShimmer(width: 60, height: 14, isDark: isDark),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          NShimmer(
              width: double.infinity, height: 8, radius: 4, isDark: isDark),
          const SizedBox(height: 10),
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NShimmer(width: 70, height: 12, isDark: isDark),
              NShimmer(width: 120, height: 12, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

/// Date card skeleton
class DateCardShimmer extends StatelessWidget {
  final bool isDark;
  const DateCardShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          NShimmer(width: 220, height: 20, isDark: isDark),
          const SizedBox(height: 8),
          NShimmer(width: 280, height: 13, isDark: isDark),
        ],
      ),
    );
  }
}

/// Generic list tile skeleton
class ListTileShimmer extends StatelessWidget {
  final bool isDark;
  const ListTileShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          NShimmer(width: 44, height: 44, radius: 22, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NShimmer(width: double.infinity, height: 14, isDark: isDark),
                const SizedBox(height: 6),
                NShimmer(width: 140, height: 12, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid item skeleton
class GridItemShimmer extends StatelessWidget {
  final bool isDark;
  const GridItemShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NShimmer(width: 32, height: 32, radius: 8, isDark: isDark),
          const SizedBox(height: 8),
          NShimmer(width: 48, height: 11, isDark: isDark),
        ],
      ),
    );
  }
}

/// Surah list skeleton
class SurahListShimmer extends StatelessWidget {
  final bool isDark;
  final int count;
  const SurahListShimmer({super.key, required this.isDark, this.count = 8});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            NShimmer(width: 44, height: 44, radius: 22, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NShimmer(width: 120, height: 15, isDark: isDark),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      NShimmer(width: 44, height: 11, radius: 4, isDark: isDark),
                      const SizedBox(width: 8),
                      NShimmer(width: 60, height: 11, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            NShimmer(width: 40, height: 22, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

/// Verse card skeleton
class VerseCardShimmer extends StatelessWidget {
  final bool isDark;
  final int count;
  const VerseCardShimmer({super.key, required this.isDark, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  NShimmer(width: 32, height: 32, radius: 16, isDark: isDark),
                  const SizedBox(width: 8),
                  NShimmer(width: 32, height: 32, radius: 16, isDark: isDark),
                  const Spacer(),
                  NShimmer(width: 20, height: 20, radius: 4, isDark: isDark),
                ],
              ),
            ),
            // Arabic text placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  NShimmer(width: double.infinity, height: 22, isDark: isDark),
                  const SizedBox(height: 8),
                  NShimmer(width: 200, height: 22, isDark: isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[200]),
            ),
            // Translation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NShimmer(width: double.infinity, height: 13, isDark: isDark),
                  const SizedBox(height: 6),
                  NShimmer(width: 240, height: 13, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
