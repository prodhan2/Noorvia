class PrayerTime {
  final String name;
  final String time;
  final String icon;

  PrayerTime({required this.name, required this.time, required this.icon});
}

class PrayerTimesHelper {
  static List<PrayerTime> getDhakaPrayerTimes() {
    return [
      PrayerTime(name: 'ফজর', time: '৪:০৫', icon: '🌅'),
      PrayerTime(name: 'সূর্যোদয়', time: '৫:২৬', icon: '☀️'),
      PrayerTime(name: 'যোহর', time: '১১:৫১', icon: '🌤️'),
      PrayerTime(name: 'আসর', time: '৩:১৫', icon: '🌇'),
      PrayerTime(name: 'মাগরিব', time: '৬:২৬', icon: '🌆'),
      PrayerTime(name: 'ইশা', time: '৭:৪৫', icon: '🌙'),
      PrayerTime(name: 'তাহাজ্জুদ শেষ', time: '৪:০০', icon: '⭐'),
    ];
  }

  static String getCurrentPrayer() => 'তাহাজ্জুদ শেষ';
  static String getNextPrayer() => 'ফজর';
  static String getTimeRemaining() => '৩ ঘণ্টা ৫৭ মিনিট বাকি';
  static double getProgress() => 0.65;

  static String toBanglaNumber(String s) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < en.length; i++) {
      s = s.replaceAll(en[i], bn[i]);
    }
    return s;
  }

  static String getBanglaDate() {
    final now = DateTime.now();
    final months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final days = ['রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার'];
    return '${days[now.weekday % 7]}, ${toBanglaNumber(now.day.toString())} ${months[now.month - 1]}';
  }

  static String getHijriDate() => '১১ জিলকদ ১৪৪৭ হিজরি 🌙';
  static String getBanglaCalDate() => 'বৃহস্পতিবার, ১৭ বৈশাখ ১৪৩৩ বঙ্গাব্দ, গ্রীষ্মকাল';
}
