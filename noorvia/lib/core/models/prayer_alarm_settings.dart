// ============================================================
//  prayer_alarm_settings.dart
//  Model for prayer alarm settings with pre-alarm customization
//  Uses local azan.mp3 asset only
// ============================================================

// Local azan asset path
const String kLocalAzanPath = 'audio/azan.mp3';
const String kLocalAzanName = 'Noorvia আযান';

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

  // Selected Azan audio (local asset only)
  String selectedAzanPath;
  String selectedAzanName;

  // Volume settings
  double volume;

  // Vibration enabled
  bool vibrationEnabled;

  PrayerAlarmSettings({
    this.fajrEnabled = false, // default OFF — user must enable
    this.dhuhrEnabled = false,
    this.asrEnabled = false,
    this.maghribEnabled = false,
    this.ishaEnabled = false,
    this.fajrPreAlarm = 0,
    this.dhuhrPreAlarm = 0,
    this.asrPreAlarm = 0,
    this.maghribPreAlarm = 0,
    this.ishaPreAlarm = 0,
    this.selectedAzanPath = kLocalAzanPath,
    this.selectedAzanName = kLocalAzanName,
    this.volume = 1.0,
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
    'volume': volume,
    'vibrationEnabled': vibrationEnabled,
  };

  // Create from JSON
  factory PrayerAlarmSettings.fromJson(Map<String, dynamic> json) {
    return PrayerAlarmSettings(
      fajrEnabled: json['fajrEnabled'] ?? false,
      dhuhrEnabled: json['dhuhrEnabled'] ?? false,
      asrEnabled: json['asrEnabled'] ?? false,
      maghribEnabled: json['maghribEnabled'] ?? false,
      ishaEnabled: json['ishaEnabled'] ?? false,
      fajrPreAlarm: json['fajrPreAlarm'] ?? 0,
      dhuhrPreAlarm: json['dhuhrPreAlarm'] ?? 0,
      asrPreAlarm: json['asrPreAlarm'] ?? 0,
      maghribPreAlarm: json['maghribPreAlarm'] ?? 0,
      ishaPreAlarm: json['ishaPreAlarm'] ?? 0,
      selectedAzanPath: kLocalAzanPath, // always local
      selectedAzanName: kLocalAzanName,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
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
// Online Azan List - removed (using local asset only)
// ============================================================
