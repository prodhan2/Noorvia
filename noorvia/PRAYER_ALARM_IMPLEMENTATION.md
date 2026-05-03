# Prayer Alarm System - Complete Implementation Guide

## Overview

This document describes the complete implementation of the Prayer Alarm System for the Noorvia Islamic app. The system allows users to set customizable alarms for each prayer time with pre-alarm notifications and custom Azan audio.

## Features Implemented

### 1. ✅ Prayer Time Tracking
- Real-time prayer times based on user location
- Support for all 5 daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha)
- Automatic location detection with manual city selection fallback
- Hijri date display
- Next prayer countdown with progress indicator

### 2. ✅ Individual Prayer Alarm Settings
- Enable/disable alarm for each prayer independently
- Customizable pre-alarm time (0-60 minutes before prayer)
- Visual slider interface for easy adjustment
- Real-time preview of alarm time

### 3. ✅ Azan Selection System
- Multiple pre-loaded Azan options:
  - Default Azan
  - Makkah Azan
  - Madinah Azan
  - Egyptian Azan
  - Turkish Azan
- Test playback functionality
- Stop button for audio control
- Easy selection through bottom sheet picker

### 4. ✅ Audio Playback
- Uses `audioplayers` package for reliable audio playback
- Volume control (0-100%)
- Plays from local assets
- Support for device ringtones (optional)

### 5. ✅ Notification System
- Uses `flutter_local_notifications` for alarm notifications
- Full-screen intent for alarm display
- Vibration support (can be toggled)
- Works even when app is closed
- Exact alarm scheduling (Android 12+)

### 6. ✅ Local Storage
- All settings saved using `shared_preferences`
- Persistent across app restarts
- Prayer times cached for offline access

### 7. ✅ Modern UI
- Clean, Islamic-themed design
- Dark mode support
- Gradient headers
- Card-based layout
- Smooth animations
- Bangla language support

## File Structure

```
lib/
├── core/
│   ├── models/
│   │   └── prayer_alarm_settings.dart      # Alarm settings model
│   ├── providers/
│   │   ├── prayer_provider.dart            # Prayer times state management
│   │   └── prayer_alarm_provider.dart      # Alarm state management
│   └── services/
│       └── prayer_alarm_service.dart       # Alarm scheduling service
├── screens/
│   └── IslamicFeatures/
│       ├── prayer_times_page.dart          # Main prayer times display
│       ├── prayer_alarm_settings_page.dart # Alarm configuration UI
│       └── namaz_tracker_page.dart         # Prayer tracking (existing)
└── main.dart

assets/
└── audio/
    ├── azan_default.mp3
    ├── azan_makkah.mp3
    ├── azan_madinah.mp3
    ├── azan_egypt.mp3
    ├── azan_turkey.mp3
    └── README.md
```

## Dependencies

All required dependencies are already in `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^18.0.1  # Alarm notifications
  audioplayers: ^6.1.0                  # Audio playback
  shared_preferences: ^2.3.2            # Local storage
  timezone: ^0.9.4                      # Timezone support
  provider: ^6.1.2                      # State management
  geolocator: ^13.0.2                   # Location services
  geocoding: ^3.0.0                     # Reverse geocoding
  http: ^1.2.2                          # API calls
  intl: ^0.19.0                         # Date formatting
```

## Setup Instructions

### 1. Add Audio Files

Place Azan MP3 files in `assets/audio/` directory:
- `azan_default.mp3`
- `azan_makkah.mp3`
- `azan_madinah.mp3`
- `azan_egypt.mp3`
- `azan_turkey.mp3`

You can download Azan audio from:
- Islamic audio websites
- YouTube (convert to MP3)
- Open-source Islamic apps

### 2. Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 3. iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
</array>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show accurate prayer times</string>
```

### 4. Initialize Providers

Update `main.dart` to include the new providers:

```dart
void main() async {
  WidgetsBinding.flutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => PrayerAlarmProvider()),
        // ... other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

## Usage Guide

### For Users

#### Setting Up Prayer Alarms:

1. **Open Prayer Times Page**
   - Navigate to Islamic Features → Prayer Times

2. **Access Alarm Settings**
   - Tap the alarm icon in the top right corner

3. **Configure Each Prayer**
   - Toggle the switch to enable/disable alarm
   - Use the slider to set pre-alarm time (0-60 minutes)
   - Each prayer can have different settings

4. **Select Azan Audio**
   - Tap on the Azan selection card
   - Choose from available Azan options
   - Use "Test" button to preview
   - Use "Stop" button to stop playback

5. **Adjust Volume**
   - Use the volume slider (0-100%)
   - Changes apply to all alarms

6. **Toggle Vibration**
   - Enable/disable vibration for alarms

#### How Alarms Work:

- Alarms trigger at: **Prayer Time - Pre-alarm Minutes**
- Example: If Fajr is at 5:00 AM and pre-alarm is 10 minutes, alarm rings at 4:50 AM
- Alarms work even when app is closed
- Notification shows prayer name and time remaining
- Tapping notification plays full Azan audio

### For Developers

#### Scheduling Alarms Programmatically:

```dart
// Get providers
final prayerProvider = context.read<PrayerProvider>();
final alarmProvider = context.read<PrayerAlarmProvider>();

// Schedule all alarms
await alarmProvider.scheduleAlarms({
  'fajr': prayerProvider.prayerTimes!.fajr,
  'dhuhr': prayerProvider.prayerTimes!.dhuhr,
  'asr': prayerProvider.prayerTimes!.asr,
  'maghrib': prayerProvider.prayerTimes!.maghrib,
  'isha': prayerProvider.prayerTimes!.isha,
});
```

#### Updating Settings:

```dart
// Toggle prayer alarm
await alarmProvider.togglePrayerAlarm('ফজর', true);

// Update pre-alarm minutes
await alarmProvider.updatePreAlarmMinutes('ফজর', 15);

// Select Azan
await alarmProvider.selectAzan(
  'assets/audio/azan_makkah.mp3',
  'মক্কার আযান',
);

// Update volume
await alarmProvider.updateVolume(0.8);

// Toggle vibration
await alarmProvider.toggleVibration(true);
```

#### Playing Azan:

```dart
// Play test azan
await alarmProvider.playTestAzan();

// Stop azan
await alarmProvider.stopAzan();
```

## API Integration

The system uses the Aladhan API for prayer times:

### Endpoints Used:

1. **Prayer Times by Coordinates**
   ```
   GET https://api.aladhan.com/v1/timings/{date}
   ?latitude={lat}&longitude={lon}&method=2
   ```

2. **Prayer Times by City**
   ```
   GET https://api.aladhan.com/v1/timingsByCity/{date}
   ?city={city}&country={country}&method=2
   ```

3. **Hijri Date Conversion**
   ```
   GET https://api.aladhan.com/v1/gToH/{date}
   ```

### Calculation Method:
- Method 2: Islamic Society of North America (ISNA)
- Can be changed in `PrayerProvider` if needed

## Troubleshooting

### Alarms Not Triggering:

1. **Check Permissions**
   - Ensure notification permission is granted
   - Check exact alarm permission (Android 12+)
   - Verify location permission for prayer times

2. **Battery Optimization**
   - Disable battery optimization for the app
   - Add app to "Don't optimize" list

3. **Verify Settings**
   - Ensure alarm is enabled for the prayer
   - Check that prayer times are loaded correctly
   - Verify pre-alarm time is set

### Audio Not Playing:

1. **Check Audio Files**
   - Ensure MP3 files exist in `assets/audio/`
   - Verify files are listed in `pubspec.yaml`
   - Check file names match exactly

2. **Volume Settings**
   - Ensure volume is not set to 0
   - Check device volume is not muted

3. **Permissions**
   - Verify audio playback permissions

### Location Issues:

1. **Permission Denied**
   - Request location permission again
   - Use manual city selection as fallback

2. **Inaccurate Location**
   - Try manual city selection
   - Check GPS is enabled

## Future Enhancements

Potential features to add:

1. **Custom Azan Upload**
   - Allow users to upload their own Azan audio
   - Support for device ringtone picker

2. **Qibla Direction Integration**
   - Show Qibla direction on prayer times page
   - Compass integration

3. **Prayer Reminders**
   - Multiple reminders per prayer
   - Custom reminder messages

4. **Statistics**
   - Track prayer completion rate
   - Monthly/yearly statistics
   - Integration with Namaz Tracker

5. **Widget Support**
   - Home screen widget showing next prayer
   - Quick alarm toggle from widget

6. **Smart Scheduling**
   - Adjust alarm based on sleep patterns
   - Weekend/weekday different settings

7. **Community Features**
   - Share prayer times with family
   - Mosque prayer time sync

## Testing Checklist

- [ ] Alarms trigger at correct time
- [ ] Pre-alarm calculation is accurate
- [ ] Audio plays correctly
- [ ] Volume control works
- [ ] Vibration works (if enabled)
- [ ] Settings persist after app restart
- [ ] Alarms work when app is closed
- [ ] Notification appears correctly
- [ ] Tapping notification plays Azan
- [ ] Multiple alarms don't conflict
- [ ] Location detection works
- [ ] Manual city selection works
- [ ] Dark mode displays correctly
- [ ] Bangla text displays correctly
- [ ] All prayers can be configured independently

## Support

For issues or questions:
1. Check this documentation
2. Review code comments
3. Test with debug logging enabled
4. Check device logs for errors

## License

This implementation is part of the Noorvia Islamic app.

---

**Last Updated:** May 3, 2026
**Version:** 1.0.0
**Author:** Kiro AI Assistant
