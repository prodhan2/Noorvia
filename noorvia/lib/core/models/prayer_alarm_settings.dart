// ============================================================
//  prayer_alarm_settings.dart
//  Model for prayer alarm settings with pre-alarm customization
//  Now supports online Azan loading from islamcan.com
// ============================================================

class PrayerAlarmSettings {
  // Individual prayer alarm enabled/disabled
  bool fajrEnabled;
  bool dhuhrEnabled;
  bool asrEnabled;
  bool maghribEnabled;
  bool ishaEnabled;

  // Pre-alarm minutes for each prayer
  int fajrPreAlarm;
  int dhuhrPreAlarm;
  int asrPreAlarm;
  int maghribPreAlarm;
  int ishaPreAlarm;

  // Selected Azan audio (now supports online URLs)
  String selectedAzanPath;
  String selectedAzanName;
  bool isOnlineAzan; // true if URL, false if local asset

  // Volume settings
  double volume;

  // Vibration enabled
  bool vibrationEnabled;

  PrayerAlarmSettings({
    this.fajrEnabled = true,
    this.dhuhrEnabled = true,
    this.asrEnabled = true,
    this.maghribEnabled = true,
    this.ishaEnabled = true,
    this.fajrPreAlarm = 10,
    this.dhuhrPreAlarm = 10,
    this.asrPreAlarm = 10,
    this.maghribPreAlarm = 10,
    this.ishaPreAlarm = 10,
    this.selectedAzanPath = 'https://www.islamcan.com/audio/adhan/azan1.mp3',
    this.selectedAzanName = 'আযান ১',
    this.isOnlineAzan = true,
    this.volume = 0.8,
    this.vibrationEnabled = true,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'fajrEnabled': fajrEnabled,
        'dhuhrEnabled': dhuhrEnabled,
        'asrEnabled': asrEnabled,
        'maghribEnabled': maghribEnabled,
        'ishaEnabled': ishaEnabled,
        'fajrPreAlarm': fajrPreAlarm,
        'dhuhrPreAlarm': dhuhrPreAlarm,
        'asrPreAlarm': asrPreAlarm,
        'maghribPreAlarm': maghribPreAlarm,
        'ishaPreAlarm': ishaPreAlarm,
        'selectedAzanPath': selectedAzanPath,
        'selectedAzanName': selectedAzanName,
        'isOnlineAzan': isOnlineAzan,
        'volume': volume,
        'vibrationEnabled': vibrationEnabled,
      };

  // Create from JSON
  factory PrayerAlarmSettings.fromJson(Map<String, dynamic> json) {
    return PrayerAlarmSettings(
      fajrEnabled: json['fajrEnabled'] ?? true,
      dhuhrEnabled: json['dhuhrEnabled'] ?? true,
      asrEnabled: json['asrEnabled'] ?? true,
      maghribEnabled: json['maghribEnabled'] ?? true,
      ishaEnabled: json['ishaEnabled'] ?? true,
      fajrPreAlarm: json['fajrPreAlarm'] ?? 10,
      dhuhrPreAlarm: json['dhuhrPreAlarm'] ?? 10,
      asrPreAlarm: json['asrPreAlarm'] ?? 10,
      maghribPreAlarm: json['maghribPreAlarm'] ?? 10,
      ishaPreAlarm: json['ishaPreAlarm'] ?? 10,
      selectedAzanPath: json['selectedAzanPath'] ?? 'https://www.islamcan.com/audio/adhan/azan1.mp3',
      selectedAzanName: json['selectedAzanName'] ?? 'আযান ১',
      isOnlineAzan: json['isOnlineAzan'] ?? true,
      volume: json['volume'] ?? 0.8,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  // Get pre-alarm minutes for a specific prayer
  int getPreAlarmMinutes(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        return fajrPreAlarm;
      case 'dhuhr':
      case 'যোহর':
        return dhuhrPreAlarm;
      case 'asr':
      case 'আসর':
        return asrPreAlarm;
      case 'maghrib':
      case 'মাগরিব':
        return maghribPreAlarm;
      case 'isha':
      case 'ইশা':
        return ishaPreAlarm;
      default:
        return 10;
    }
  }

  // Check if alarm is enabled for a specific prayer
  bool isAlarmEnabled(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        return fajrEnabled;
      case 'dhuhr':
      case 'যোহর':
        return dhuhrEnabled;
      case 'asr':
      case 'আসর':
        return asrEnabled;
      case 'maghrib':
      case 'মাগরিব':
        return maghribEnabled;
      case 'isha':
      case 'ইশা':
        return ishaEnabled;
      default:
        return false;
    }
  }

  // Set alarm enabled for a specific prayer
  void setAlarmEnabled(String prayerName, bool enabled) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        fajrEnabled = enabled;
        break;
      case 'dhuhr':
      case 'যোহর':
        dhuhrEnabled = enabled;
        break;
      case 'asr':
      case 'আসর':
        asrEnabled = enabled;
        break;
      case 'maghrib':
      case 'মাগরিব':
        maghribEnabled = enabled;
        break;
      case 'isha':
      case 'ইশা':
        ishaEnabled = enabled;
        break;
    }
  }

  // Set pre-alarm minutes for a specific prayer
  void setPreAlarmMinutes(String prayerName, int minutes) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'ফজর':
        fajrPreAlarm = minutes;
        break;
      case 'dhuhr':
      case 'যোহর':
        dhuhrPreAlarm = minutes;
        break;
      case 'asr':
      case 'আসর':
        asrPreAlarm = minutes;
        break;
      case 'maghrib':
      case 'মাগরিব':
        maghribPreAlarm = minutes;
        break;
      case 'isha':
      case 'ইশা':
        ishaPreAlarm = minutes;
        break;
    }
  }
}

// ============================================================
// Online Azan List - 20 Azans from islamcan.com
// ============================================================
class OnlineAzanList {
  static const String baseUrl = 'https://www.islamcan.com/audio/adhan/';
  
  static List<Map<String, String>> getAzanList() {
    return List.generate(20, (index) {
      final num = index + 1;
      return {
        'url': '${baseUrl}azan$num.mp3',
        'name': 'আযান $num',
        'id': 'azan$num',
      };
    });
  }
  
  static String getAzanUrl(int number) {
    if (number < 1 || number > 20) return '${baseUrl}azan1.mp3';
    return '${baseUrl}azan$number.mp3';
  }
  
  static String getAzanName(int number) {
    if (number < 1 || number > 20) return 'আযান ১';
    return 'আযান $number';
  }
}

