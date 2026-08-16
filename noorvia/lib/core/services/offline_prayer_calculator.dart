import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';

class OfflinePrayerResult {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final HijriCalendar hijri;

  const OfflinePrayerResult({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.hijri,
  });
}

/// Network-free fallback that mirrors the app's existing Aladhan method=2
/// calculation preset as closely as possible.
class OfflinePrayerCalculator {
  static OfflinePrayerResult calculate({
    required double latitude,
    required double longitude,
    DateTime? date,
    Duration? utcOffset,
  }) {
    final target = date ?? DateTime.now();
    final coordinates = Coordinates(latitude, longitude);
    // Aladhan method=2 is ISNA/North America. Keep the local fallback on
    // the same preset and default juristic school so online/offline times do
    // not jump when connectivity changes.
    final params = CalculationMethodParameters.northAmerica();
    final times = PrayerTimes(
      coordinates: coordinates,
      date: target,
      calculationParameters: params,
    );

    // adhan_dart exposes UTC-based prayer instants. Prefer an explicit
    // location offset when known (Bangladesh is UTC+6); otherwise use the
    // phone timezone for normal GPS-based usage.
    String hm(DateTime value) {
      final local = utcOffset == null
          ? value.toLocal()
          : value.toUtc().add(utcOffset);
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    return OfflinePrayerResult(
      fajr: hm(times.fajr),
      sunrise: hm(times.sunrise),
      dhuhr: hm(times.dhuhr),
      asr: hm(times.asr),
      maghrib: hm(times.maghrib),
      isha: hm(times.isha),
      hijri: HijriCalendar.fromDate(target),
    );
  }
}
