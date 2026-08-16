import 'package:hijri/hijri_calendar.dart';

/// Adhan Service - Hijri Date Utilities
/// Uses the 'hijri' package for Hijri date conversion
class AdhanService {
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
    if (hijri.hMonth == 9 &&
        hijri.hDay >= 21 &&
        hijri.hDay <= 29 &&
        hijri.hDay % 2 == 1) {
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
