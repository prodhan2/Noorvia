import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';

/// Offline Prayer Times Widget (Placeholder)
/// This widget is a placeholder - use the main PrayerProvider instead
class OfflinePrayerTimesWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isDark;

  const OfflinePrayerTimesWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF2C5F7F)]
              : [const Color(0xFF6C3CE1), const Color(0xFF4A6FE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'নামাজের সময়',
              style: GoogleFonts.hindSiliguri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'প্রধান নামাজের সময় ফিচারটি ব্যবহার করুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
