import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/prayer_provider.dart';
import '../../../widgets/shimmer.dart';

class PrayerCard extends StatelessWidget {
  final bool isDark;
  const PrayerCard({super.key, required this.isDark});

  // ── Bangla number ─────────────────────────────────────────
  String _bn(String s) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  // ── 24h "HH:MM" → Bangla 12h "H:MM" ─────────────────────
  String _toDisplay(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return _bn(t);
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final bh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${_bn(bh.toString())}:${_bn(m)}';
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final pt = prayer.prayerTimes;

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
      child: prayer.isLoading && pt == null
          ? PrayerCardShimmer(isDark: isDark)
          : Column(
              children: [
                // ── Row 1: current time + mosque ─────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sun/Moon icon + current time
                      _timeIcon(prayer),
                      const SizedBox(width: 6),
                      Text(
                        prayer.currentTime.isNotEmpty
                            ? prayer.currentTime.split(':').take(2).join(':')
                            : '--:--',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      // Mosque silhouette
                      SizedBox(
                        width: 110,
                        height: 48,
                        child: CustomPaint(
                          painter: _MosquePainter(isDark: isDark),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Row 2: prev prayer ←→ next prayer ────────
                if (pt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: current prayer
                        Row(
                          children: [
                            Text(
                              prayer.currentPrayer,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _toDisplay(_currentPrayerTime(prayer, pt)),
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13, color: subColor),
                            ),
                            const SizedBox(width: 4),
                            const Text('✅', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        // Right: next prayer
                        Row(
                          children: [
                            Text(
                              prayer.nextPrayer,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              prayer.nextPrayerTime,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13, color: subColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // ── Row 3: sunrise ←→ maghrib ─────────────────
                if (pt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Text('🌅', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 4),
                          Text(_toDisplay(pt.sunrise),
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13, color: subColor)),
                        ]),
                        Row(children: [
                          Text(_toDisplay(pt.maghrib),
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 13, color: subColor)),
                          const SizedBox(width: 4),
                          const Text('🌇', style: TextStyle(fontSize: 15)),
                        ]),
                      ],
                    ),
                  ),

                Divider(
                    height: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[200]),

                // ── Progress section ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    children: [
                      // Prayer name + time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            prayer.currentPrayer.isNotEmpty
                                ? prayer.currentPrayer
                                : '--',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            pt != null
                                ? _toDisplay(
                                    _currentPrayerTime(prayer, pt))
                                : '--:--',
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 14, color: subColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Progress bar
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: prayer.prayerProgress.clamp(0.0, 1.0),
                        backgroundColor: isDark
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                        progressColor: AppColors.primary,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                        animation: false,
                      ),
                      const SizedBox(height: 8),

                      // Status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'চলমান',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            prayer.timeRemaining.isNotEmpty
                                ? prayer.timeRemaining
                                : '--',
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 12, color: subColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Get current prayer time string ────────────────────────
  String _currentPrayerTime(PrayerProvider p, PrayerTimeModel pt) {
    switch (p.currentPrayer) {
      case 'ফজর': return pt.fajr;
      case 'সূর্যোদয়': return pt.sunrise;
      case 'যোহর': return pt.dhuhr;
      case 'আসর': return pt.asr;
      case 'মাগরিব': return pt.maghrib;
      case 'ইশা': return pt.isha;
      case 'তাহাজ্জুদ শেষ': return pt.tahajjud;
      default: return pt.fajr;
    }
  }

  // ── Sun/Moon icon based on time ───────────────────────────
  Widget _timeIcon(PrayerProvider p) {
    final h = DateTime.now().hour;
    String emoji;
    if (h >= 5 && h < 7) {
      emoji = '🌅';
    } else if (h >= 7 && h < 17) {
      emoji = '☀️';
    } else if (h >= 17 && h < 19) {
      emoji = '🌇';
    } else {
      emoji = '🌙';
    }
    return Text(emoji, style: const TextStyle(fontSize: 20));
  }

}

// ─── Mosque silhouette painter ────────────────────────────────
class _MosquePainter extends CustomPainter {
  final bool isDark;
  _MosquePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.grey[700] : Colors.grey[300])!
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Main dome
    final dome = Path()
      ..moveTo(w * 0.28, h * 0.95)
      ..lineTo(w * 0.28, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.72, h * 0.52)
      ..lineTo(w * 0.72, h * 0.95)
      ..close();
    canvas.drawPath(dome, paint);

    // Left minaret
    final leftMin = Path()
      ..moveTo(w * 0.04, h * 0.95)
      ..lineTo(w * 0.04, h * 0.28)
      ..lineTo(w * 0.115, h * 0.14)
      ..lineTo(w * 0.19, h * 0.28)
      ..lineTo(w * 0.19, h * 0.95)
      ..close();
    canvas.drawPath(leftMin, paint);

    // Right minaret
    final rightMin = Path()
      ..moveTo(w * 0.81, h * 0.95)
      ..lineTo(w * 0.81, h * 0.28)
      ..lineTo(w * 0.885, h * 0.14)
      ..lineTo(w * 0.96, h * 0.28)
      ..lineTo(w * 0.96, h * 0.95)
      ..close();
    canvas.drawPath(rightMin, paint);

    // Ground line
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.95, w, h * 0.05),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
