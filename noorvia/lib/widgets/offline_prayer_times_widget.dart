import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/adhan_service.dart';

/// Offline Prayer Times Widget
/// ✅ Works 100% offline - No API needed!
/// Uses adhan_dart package for accurate calculations
class OfflinePrayerTimesWidget extends StatefulWidget {
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
  State<OfflinePrayerTimesWidget> createState() =>
      _OfflinePrayerTimesWidgetState();
}

class _OfflinePrayerTimesWidgetState extends State<OfflinePrayerTimesWidget> {
  Map<String, String>? _prayerTimes;
  Map<String, dynamic>? _nextPrayer;
  String? _currentPrayer;
  String? _timeRemaining;
  String? _hijriDate;
  List<String>? _islamicEvents;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    // Update every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _loadPrayerTimes();
      }
    });
  }

  void _loadPrayerTimes() {
    setState(() {
      // Get prayer times
      _prayerTimes = AdhanService.getPrayerTimesBengali(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      // Get next prayer
      _nextPrayer = AdhanService.getNextPrayer(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      // Get current prayer
      _currentPrayer = AdhanService.getCurrentPrayerBengali(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      // Get time remaining
      _timeRemaining = AdhanService.getFormattedTimeRemainingBengali(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      // Get Hijri date
      _hijriDate = AdhanService.getHijriDateBengali();

      // Get Islamic events
      _islamicEvents = AdhanService.getIslamicEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_prayerTimes == null || _nextPrayer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Hijri Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'নামাজের সময়',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hijriDate ?? '',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mosque,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Next Prayer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'পরবর্তী নামাজ',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _nextPrayer!['name'],
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _nextPrayer!['time'],
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'আর $_timeRemaining',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // All Prayer Times
          Column(
            children: _prayerTimes!.entries.map((entry) {
              final isCurrentPrayer = entry.key == _currentPrayer;
              final isNextPrayer = entry.key == _nextPrayer!['name'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isNextPrayer
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isNextPrayer
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPrayerIcon(entry.key),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.key,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: isNextPrayer
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      entry.value,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: isNextPrayer
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Islamic Events (if any)
          if (_islamicEvents != null && _islamicEvents!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _islamicEvents!.join(', '),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Offline Indicator
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'অফলাইন মোড - ইন্টারনেট প্রয়োজন নেই',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'ফজর':
        return Icons.wb_twilight;
      case 'সূর্যোদয়':
        return Icons.wb_sunny;
      case 'যোহর':
        return Icons.wb_sunny_outlined;
      case 'আসর':
        return Icons.wb_cloudy;
      case 'মাগরিব':
        return Icons.nights_stay;
      case 'এশা':
        return Icons.nightlight;
      default:
        return Icons.access_time;
    }
  }
}
