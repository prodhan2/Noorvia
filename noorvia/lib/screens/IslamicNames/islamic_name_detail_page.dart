import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'islamic_names_page.dart';

class IslamicNameDetailPage extends StatelessWidget {
  final IslamicName name;
  final List<IslamicName> allNames;
  final int currentIndex;

  const IslamicNameDetailPage({
    super.key,
    required this.name,
    required this.allNames,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.gradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'নামের বিবরণ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            tooltip: 'কপি করুন',
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text:
                    '${name.pronunciation} (${name.arabic})\nঅর্থ: ${name.meaning}\n${name.whyGood}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'নাম কপি হয়েছে!',
                    style: GoogleFonts.hindSiliguri(fontSize: 13),
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero card ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      // Serial number badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '#${currentIndex + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Arabic
                      Text(
                        name.arabic,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Bengali pronunciation
                      Text(
                        name.pronunciation,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // First letter chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'প্রথম অক্ষর: ${name.firstLetter}',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Detail rows ────────────────────────────────────
            _DetailCard(
              icon: Icons.translate_rounded,
              label: 'অর্থ',
              value: name.meaning,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
            ),
            const SizedBox(height: 12),
            _DetailCard(
              icon: Icons.star_rounded,
              label: 'কেন ভালো নাম',
              value: name.whyGood,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
            ),
            const SizedBox(height: 12),
            _DetailCard(
              icon: Icons.menu_book_rounded,
              label: 'আরবি লিখন',
              value: name.arabic,
              valueRtl: true,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
            ),

            const SizedBox(height: 28),

            // ── Prev / Next navigation ─────────────────────────
            if (allNames.length > 1)
              Row(
                children: [
                  if (currentIndex > 0)
                    Expanded(
                      child: _NavButton(
                        label: allNames[currentIndex - 1].pronunciation,
                        icon: Icons.arrow_back_ios_new_rounded,
                        isNext: false,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IslamicNameDetailPage(
                                name: allNames[currentIndex - 1],
                                allNames: allNames,
                                currentIndex: currentIndex - 1,
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  const SizedBox(width: 12),
                  if (currentIndex < allNames.length - 1)
                    Expanded(
                      child: _NavButton(
                        label: allNames[currentIndex + 1].pronunciation,
                        icon: Icons.arrow_forward_ios_rounded,
                        isNext: true,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IslamicNameDetailPage(
                                name: allNames[currentIndex + 1],
                                allNames: allNames,
                                currentIndex: currentIndex + 1,
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Card ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool valueRtl;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueRtl = false,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueRtl
                      ? TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: 1.6,
                        )
                      : GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.4,
                        ),
                  textDirection:
                      valueRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Prev/Next Nav Button ─────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isNext;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.isNext,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              isNext ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: isNext
              ? [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, size: 14, color: AppColors.primary),
                ]
              : [
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
