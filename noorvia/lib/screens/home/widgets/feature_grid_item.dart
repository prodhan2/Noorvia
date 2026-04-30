import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class FeatureItem {
  final String emoji;
  final String label;
  final VoidCallback? onTap;

  const FeatureItem({
    required this.emoji,
    required this.label,
    this.onTap,
  });
}

class FeatureGridItem extends StatelessWidget {
  final FeatureItem item;
  final bool isDark;

  const FeatureGridItem({super.key, required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap ?? () => _showComingSoon(context, item.label),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji in a soft gradient circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.10),
                    AppColors.accent.withValues(alpha: isDark ? 0.20 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label — শীঘ্রই আসছে',
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
