import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'ruqyah_gosol_page.dart';

// ─── Gosol Detail Page ────────────────────────────────────────

class RuqyahGosolDetailPage extends StatefulWidget {
  final RuqyahGosol gosol;
  final List<RuqyahGosol> allGosols;
  final int currentIndex;

  const RuqyahGosolDetailPage({
    super.key,
    required this.gosol,
    required this.allGosols,
    required this.currentIndex,
  });

  @override
  State<RuqyahGosolDetailPage> createState() => _RuqyahGosolDetailPageState();
}

class _RuqyahGosolDetailPageState extends State<RuqyahGosolDetailPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.allGosols.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  RuqyahGosol get _currentGosol => widget.allGosols[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'রুকইয়াহ গোসল',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.allGosols.length}',
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              // Share functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'শেয়ার করা হয়েছে',
                    style: GoogleFonts.hindSiliguri(),
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'গোসল #${_currentIndex + 1}',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    _currentGosol.title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Description section ──────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'বিস্তারিত নির্দেশনা',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentGosol.content,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: textColor,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Tips section ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFF8E1,
                      ).withValues(alpha: isDark ? 0.1 : 1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFC107,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Color(0xFFFFC107),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'গুরুত্বপূর্ণ টিপস',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTipItem(
                          '✓',
                          'নিয়ত করে গোসল করুন - সব বদনজর কেটে যাওয়ার জন্য',
                          textColor,
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem(
                          '✓',
                          'যদি সমস্যা বাড়ে তবে ৩-৫ দিন টানা করুন',
                          textColor,
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem(
                          '✓',
                          'অসুস্থ ব্যক্তি শুধু গোসল করবে, অন্য কেউ পড়বে',
                          textColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Benefits section ────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE8F5E9,
                      ).withValues(alpha: isDark ? 0.1 : 1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4CAF50,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'উপকারিতা',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitItem(
                          '💧',
                          'জিন, যাদু ও বদনজর থেকে সুরক্ষা',
                          textColor,
                        ),
                        const SizedBox(height: 10),
                        _buildBenefitItem(
                          '📿',
                          'কোরআনিক আয়াত দিয়ে শরীর পবিত্র করা',
                          textColor,
                        ),
                        const SizedBox(height: 10),
                        _buildBenefitItem(
                          '✨',
                          'মানসিক ও শারীরিক শান্তি',
                          textColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Navigation buttons ───────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Previous button
              Expanded(
                child: GestureDetector(
                  onTap: _currentIndex > 0 ? _goToPrevious : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentIndex > 0
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 16,
                          color: _currentIndex > 0
                              ? AppColors.primary
                              : Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'আগে',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _currentIndex > 0
                                ? AppColors.primary
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next button
              Expanded(
                child: GestureDetector(
                  onTap: _currentIndex < widget.allGosols.length - 1
                      ? _goToNext
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: _currentIndex < widget.allGosols.length - 1
                          ? AppColors.gradient
                          : null,
                      color: _currentIndex < widget.allGosols.length - 1
                          ? null
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'পরে',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _currentIndex < widget.allGosols.length - 1
                                ? Colors.white
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: _currentIndex < widget.allGosols.length - 1
                              ? Colors.white
                              : Colors.grey.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String icon, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: textColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String emoji, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: textColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
