import 'package:flutter/material.dart';
import '../services/adhan_service.dart';

/// Example widget showing how to use AdhanService
/// This replaces API calls with offline calculation
class AdhanPrayerTimesWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const AdhanPrayerTimesWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    // Get prayer times (offline calculation - no API needed!)
    final prayerTimes = AdhanService.getPrayerTimesBengali(
      latitude: latitude,
      longitude: longitude,
    );

    // Get next prayer info
    final nextPrayer = AdhanService.getNextPrayer(
      latitude: latitude,
      longitude: longitude,
    );

    // Get time remaining
    final timeRemaining = AdhanService.getFormattedTimeRemaining(
      latitude: latitude,
      longitude: longitude,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'নামাজের সময়সূচী',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Next Prayer Highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'পরবর্তী নামাজ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          nextPrayer['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nextPrayer['time'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeRemaining,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // All Prayer Times
            ...prayerTimes.entries.map((entry) {
              final isNext = entry.key == nextPrayer['name'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isNext ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getPrayerIcon(entry.key),
                        color: isNext ? Colors.blue : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                          color: isNext ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                        color: isNext ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
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
        return Icons.light_mode;
      case 'আসর':
        return Icons.wb_cloudy;
      case 'মাগরিব':
        return Icons.wb_twilight;
      case 'এশা':
        return Icons.nightlight;
      default:
        return Icons.access_time;
    }
  }
}
