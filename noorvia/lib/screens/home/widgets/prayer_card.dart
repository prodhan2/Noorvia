import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';

class PrayerCard extends StatelessWidget {
  final bool isDark;

  const PrayerCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top: current time + mosque silhouette
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('☀️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '১১:৫১',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Mosque silhouette
                _buildMosqueSilhouette(isDark),
              ],
            ),
          ),

          // Prayer times row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _prayerTimeItem('তাহাজ্জুদ শেষ', '৪:০০ মি.', '✅', textColor, subColor),
                _prayerTimeItem('ফজর', '৪:০৫ মি.', '', textColor, subColor, isRight: true),
              ],
            ),
          ),

          // Sunrise/Sunset row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Text('🌅', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('৫:২৬', style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor)),
                ]),
                Row(children: [
                  Text('৬:২৬', style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor)),
                  const SizedBox(width: 4),
                  const Text('🌇', style: TextStyle(fontSize: 14)),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // Progress section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'তাহাজ্জুদ শেষ',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '০৪:০০',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  lineHeight: 8,
                  percent: 0.65,
                  backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  progressColor: AppColors.primary,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
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
                      '৩ ঘণ্টা ৫৭ মিনিট বাকি',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: subColor,
                      ),
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

  Widget _prayerTimeItem(String name, String time, String icon, Color textColor,
      Color subColor, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '$name $time $icon',
          style: GoogleFonts.hindSiliguri(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMosqueSilhouette(bool isDark) {
    return SizedBox(
      width: 120,
      height: 50,
      child: CustomPaint(
        painter: MosquePainter(isDark: isDark),
      ),
    );
  }
}

class MosquePainter extends CustomPainter {
  final bool isDark;
  MosquePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.grey[700] : Colors.grey[300])!
      ..style = PaintingStyle.fill;

    final path = Path();
    // Simple mosque silhouette
    final w = size.width;
    final h = size.height;

    // Main dome
    path.moveTo(w * 0.3, h * 0.9);
    path.lineTo(w * 0.3, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.7, h * 0.5);
    path.lineTo(w * 0.7, h * 0.9);
    path.close();

    // Left minaret
    path.moveTo(w * 0.05, h * 0.9);
    path.lineTo(w * 0.05, h * 0.3);
    path.lineTo(w * 0.12, h * 0.2);
    path.lineTo(w * 0.19, h * 0.3);
    path.lineTo(w * 0.19, h * 0.9);
    path.close();

    // Right minaret
    path.moveTo(w * 0.81, h * 0.9);
    path.lineTo(w * 0.81, h * 0.3);
    path.lineTo(w * 0.88, h * 0.2);
    path.lineTo(w * 0.95, h * 0.3);
    path.lineTo(w * 0.95, h * 0.9);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
