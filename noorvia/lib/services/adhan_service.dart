import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Adhan Service - Offline Prayer Time Calculation
/// Uses the 'adhan_dart' package for accurate prayer time calculations
/// Uses the 'hijri' package for Hijri date conversion
/// ✅ No API calls needed - works 100% offline!
class AdhanService {
  /// Calculate prayer times for a given location and date
  /// 
  /// Parameters:
  /// - latitude: Location latitude
  /// - longitude: Location longitude
  /// - date: Date for which to calculate prayer times (defaults to today)
  /// - calculationMethod: Calculation method (defaults to Karachi - used in Bangladesh)
  /// 
  /// Returns: Map of prayer times
  static Map<String, DateTime> calculatePrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
    CalculationParameters? calculationMethod,
  }) {
    // Use provided date or today
    final targetDate = date ?? DateTime.now();
    
    // Create coordinates
    final coordinates = Coordinates(latitude, longitude);
    
    // Set calculation parameters
    // Using Karachi method (method 2 in Aladhan API) which is used in Bangladesh
    final params = calculationMethod ?? CalculationMethod.karachi();
    
    // Calculate prayer times
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      calculationParameters: params,
      dateTime: targetDate,
      precision: true,
    );
    
    // Return prayer times
    return {
      'Fajr': prayerTimes.fajr!,
      'Sunrise': prayerTimes.sunrise!,
      'Dhuhr': prayerTimes.dhuhr!,
      'Asr': prayerTimes.asr!,
      'Maghrib': prayerTimes.maghrib!,
      'Isha': prayerTimes.isha!,
    };
  }
  
  /// Get prayer times with Bengali names and formatted time
  static Map<String, String> getPrayerTimesBengali({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final times = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
    );
    
    final formatter = DateFormat('hh:mm a');
    
    return {
      'ফজর': formatter.format(times['Fajr']!),
      'সূর্যোদয়': formatter.format(times['Sunrise']!),
      'যোহর': formatter.format(times['Dhuhr']!),
      'আসর': formatter.format(times['Asr']!),
      'মাগরিব': formatter.format(times['Maghrib']!),
      'এশা': formatter.format(times['Isha']!),
    };
  }
  
  /// Get prayer times with English names and formatted time
  static Map<String, String> getPrayerTimesEnglish({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final times = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
    );
    
    final formatter = DateFormat('hh:mm a');
    
    return {
      'Fajr': formatter.format(times['Fajr']!),
      'Sunrise': formatter.format(times['Sunrise']!),
      'Dhuhr': formatter.format(times['Dhuhr']!),
      'Asr': formatter.format(times['Asr']!),
      'Maghrib': formatter.format(times['Maghrib']!),
      'Isha': formatter.format(times['Isha']!),
    };
  }
  
  /// Get current prayer name in Bengali
  static String getCurrentPrayerBengali({
    required double latitude,
    required double longitude,
  }) {
    final times = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );
    
    final now = DateTime.now();
    
    if (now.isBefore(times['Fajr']!)) {
      return 'এশা';
    } else if (now.isBefore(times['Sunrise']!)) {
      return 'ফজর';
    } else if (now.isBefore(times['Dhuhr']!)) {
      return 'সূর্যোদয়';
    } else if (now.isBefore(times['Asr']!)) {
      return 'যোহর';
    } else if (now.isBefore(times['Maghrib']!)) {
      return 'আসর';
    } else if (now.isBefore(times['Isha']!)) {
      return 'মাগরিব';
    } else {
      return 'এশা';
    }
  }
  
  /// Get next prayer name and time
  static Map<String, dynamic> getNextPrayer({
    required double latitude,
    required double longitude,
  }) {
    final times = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );
    
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a');
    
    if (now.isBefore(times['Fajr']!)) {
      return {
        'name': 'ফজর',
        'nameEn': 'Fajr',
        'time': formatter.format(times['Fajr']!),
        'dateTime': times['Fajr'],
      };
    } else if (now.isBefore(times['Sunrise']!)) {
      return {
        'name': 'সূর্যোদয়',
        'nameEn': 'Sunrise',
        'time': formatter.format(times['Sunrise']!),
        'dateTime': times['Sunrise'],
      };
    } else if (now.isBefore(times['Dhuhr']!)) {
      return {
        'name': 'যোহর',
        'nameEn': 'Dhuhr',
        'time': formatter.format(times['Dhuhr']!),
        'dateTime': times['Dhuhr'],
      };
    } else if (now.isBefore(times['Asr']!)) {
      return {
        'name': 'আসর',
        'nameEn': 'Asr',
        'time': formatter.format(times['Asr']!),
        'dateTime': times['Asr'],
      };
    } else if (now.isBefore(times['Maghrib']!)) {
      return {
        'name': 'মাগরিব',
        'nameEn': 'Maghrib',
        'time': formatter.format(times['Maghrib']!),
        'dateTime': times['Maghrib'],
      };
    } else if (now.isBefore(times['Isha']!)) {
      return {
        'name': 'এশা',
        'nameEn': 'Isha',
        'time': formatter.format(times['Isha']!),
        'dateTime': times['Isha'],
      };
    } else {
      // Next prayer is Fajr of next day
      final tomorrowTimes = calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: now.add(const Duration(days: 1)),
      );
      return {
        'name': 'ফজর',
        'nameEn': 'Fajr',
        'time': formatter.format(tomorrowTimes['Fajr']!),
        'dateTime': tomorrowTimes['Fajr'],
      };
    }
  }
  
  /// Get time remaining until next prayer
  static Duration getTimeUntilNextPrayer({
    required double latitude,
    required double longitude,
  }) {
    final nextPrayer = getNextPrayer(
      latitude: latitude,
      longitude: longitude,
    );
    
    final nextPrayerTime = nextPrayer['dateTime'] as DateTime;
    final now = DateTime.now();
    
    return nextPrayerTime.difference(now);
  }
  
  /// Get formatted time remaining (e.g., "2 ঘন্টা 30 মিনিট")
  static String getFormattedTimeRemainingBengali({
    required double latitude,
    required double longitude,
  }) {
    final duration = getTimeUntilNextPrayer(
      latitude: latitude,
      longitude: longitude,
    );
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours ঘন্টা $minutes মিনিট';
    } else {
      return '$minutes মিনিট';
    }
  }
  
  /// Get Qibla direction (degrees from North)
  static double getQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final qibla = Qibla(coordinates);
    return qibla.direction;
  }
  
  /// Get prayer times for entire month
  static List<Map<String, dynamic>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
  }) {
    final List<Map<String, dynamic>> monthlyTimes = [];
    
    // Get number of days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final times = calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
      );
      
      final formatter = DateFormat('hh:mm a');
      
      monthlyTimes.add({
        'date': date,
        'day': day,
        'fajr': formatter.format(times['Fajr']!),
        'sunrise': formatter.format(times['Sunrise']!),
        'dhuhr': formatter.format(times['Dhuhr']!),
        'asr': formatter.format(times['Asr']!),
        'maghrib': formatter.format(times['Maghrib']!),
        'isha': formatter.format(times['Isha']!),
      });
    }
    
    return monthlyTimes;
  }
  
  /// Available calculation methods
  static Map<String, CalculationParameters> getCalculationMethods() {
    return {
      'মুসলিম ওয়ার্ল্ড লীগ': CalculationMethod.muslimWorldLeague(),
      'ইসলামিক সোসাইটি অফ নর্থ আমেরিকা': CalculationMethod.northAmerica(),
      'মিশরীয় জেনারেল অথরিটি': CalculationMethod.egyptian(),
      'উম্মুল কুরা ইউনিভার্সিটি': CalculationMethod.ummAlQura(),
      'ইউনিভার্সিটি অফ ইসলামিক সায়েন্সেস, করাচি': CalculationMethod.karachi(),
      'ইনস্টিটিউট অফ জিওফিজিক্স, তেহরান': CalculationMethod.tehran(),
      'কুয়েত': CalculationMethod.kuwait(),
      'কাতার': CalculationMethod.qatar(),
      'সিঙ্গাপুর': CalculationMethod.singapore(),
      'দুবাই': CalculationMethod.dubai(),
      'মুন সাইটিং কমিটি': CalculationMethod.moonsightingCommittee(),
      'তুরস্ক': CalculationMethod.turkey(),
    };
  }
  
  // ═══════════════════════════════════════════════════════════════
  // HIJRI DATE FUNCTIONS
  // ═══════════════════════════════════════════════════════════════
  
  /// Get current Hijri date
  static HijriCalendar getCurrentHijriDate() {
    return HijriCalendar.now();
  }
  
  /// Convert Gregorian date to Hijri
  static HijriCalendar gregorianToHijri(DateTime date) {
    return HijriCalendar.fromDate(date);
  }
  
  /// Get Hijri date in Bengali format
  static String getHijriDateBengali({DateTime? date}) {
    final hijri = date != null 
        ? HijriCalendar.fromDate(date) 
        : HijriCalendar.now();
    
    // Bengali month names
    final monthNames = {
      1: 'মহররম',
      2: 'সফর',
      3: 'রবিউল আউয়াল',
      4: 'রবিউস সানি',
      5: 'জমাদিউল আউয়াল',
      6: 'জমাদিউস সানি',
      7: 'রজব',
      8: 'শাবান',
      9: 'রমজান',
      10: 'শাওয়াল',
      11: 'জিলকদ',
      12: 'জিলহজ্জ',
    };
    
    final bengaliNumbers = _convertToBengaliNumber(hijri.hDay);
    final monthName = monthNames[hijri.hMonth] ?? '';
    final year = _convertToBengaliNumber(hijri.hYear);
    
    return '$bengaliNumbers $monthName $year';
  }
  
  /// Get Hijri date in English format
  static String getHijriDateEnglish({DateTime? date}) {
    final hijri = date != null 
        ? HijriCalendar.fromDate(date) 
        : HijriCalendar.now();
    
    return hijri.toFormat("dd MMMM yyyy");
  }
  
  /// Get full Hijri date with weekday in Bengali
  static String getFullHijriDateBengali({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final hijri = HijriCalendar.fromDate(targetDate);
    
    // Bengali weekday names
    final weekdayNames = {
      1: 'সোমবার',
      2: 'মঙ্গলবার',
      3: 'বুধবার',
      4: 'বৃহস্পতিবার',
      5: 'শুক্রবার',
      6: 'শনিবার',
      7: 'রবিবার',
    };
    
    final weekday = weekdayNames[targetDate.weekday] ?? '';
    final hijriDate = getHijriDateBengali(date: targetDate);
    
    return '$weekday, $hijriDate';
  }
  
  /// Check if current month is Ramadan
  static bool isRamadan({DateTime? date}) {
    final hijri = date != null 
        ? HijriCalendar.fromDate(date) 
        : HijriCalendar.now();
    
    return hijri.hMonth == 9;
  }
  
  /// Get days remaining until Ramadan
  static int getDaysUntilRamadan({DateTime? date}) {
    final currentDate = date ?? DateTime.now();
    final hijri = HijriCalendar.fromDate(currentDate);
    
    if (hijri.hMonth == 9) {
      return 0; // Already in Ramadan
    }
    
    // Calculate next Ramadan
    int targetYear = hijri.hYear;
    if (hijri.hMonth > 9) {
      targetYear++; // Next year's Ramadan
    }
    
    // Create Hijri date for 1st Ramadan
    final ramadanHijri = HijriCalendar()
      ..hYear = targetYear
      ..hMonth = 9
      ..hDay = 1;
    
    // Convert to Gregorian and calculate difference
    final ramadanGregorian = ramadanHijri.hijriToGregorian(
      ramadanHijri.hYear,
      ramadanHijri.hMonth,
      ramadanHijri.hDay,
    );
    
    return ramadanGregorian.difference(currentDate).inDays;
  }
  
  /// Get Islamic events for current date
  static List<String> getIslamicEvents({DateTime? date}) {
    final hijri = date != null 
        ? HijriCalendar.fromDate(date) 
        : HijriCalendar.now();
    
    final events = <String>[];
    
    // Check for special Islamic dates
    if (hijri.hMonth == 1 && hijri.hDay == 1) {
      events.add('ইসলামিক নববর্ষ');
    }
    if (hijri.hMonth == 1 && hijri.hDay == 10) {
      events.add('আশুরা');
    }
    if (hijri.hMonth == 3 && hijri.hDay == 12) {
      events.add('ঈদে মিলাদুন্নবী');
    }
    if (hijri.hMonth == 7 && hijri.hDay == 27) {
      events.add('শবে মেরাজ');
    }
    if (hijri.hMonth == 8 && hijri.hDay == 15) {
      events.add('শবে বরাত');
    }
    if (hijri.hMonth == 9 && hijri.hDay == 1) {
      events.add('রমজান শুরু');
    }
    if (hijri.hMonth == 9 && hijri.hDay >= 21 && hijri.hDay <= 29 && hijri.hDay % 2 == 1) {
      events.add('শবে কদর (সম্ভাব্য)');
    }
    if (hijri.hMonth == 10 && hijri.hDay == 1) {
      events.add('ঈদুল ফিতর');
    }
    if (hijri.hMonth == 12 && hijri.hDay == 10) {
      events.add('ঈদুল আযহা');
    }
    
    return events;
  }
  
  /// Convert number to Bengali numerals
  static String _convertToBengaliNumber(int number) {
    final bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((digit) {
      final index = int.tryParse(digit);
      return index != null ? bengaliDigits[index] : digit;
    }).join();
  }
  
  /// Get Hijri month name in Bengali
  static String getHijriMonthNameBengali(int month) {
    final monthNames = {
      1: 'মহররম',
      2: 'সফর',
      3: 'রবিউল আউয়াল',
      4: 'রবিউস সানি',
      5: 'জমাদিউল আউয়াল',
      6: 'জমাদিউস সানি',
      7: 'রজব',
      8: 'শাবান',
      9: 'রমজান',
      10: 'শাওয়াল',
      11: 'জিলকদ',
      12: 'জিলহজ্জ',
    };
    
    return monthNames[month] ?? '';
  }
}
