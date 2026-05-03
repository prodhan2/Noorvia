# Prayer Alarm System - Quick Start Guide

## 🚀 Quick Setup (5 Minutes)

### Step 1: Add Audio Files
1. Download 5 Azan MP3 files (or use any MP3 for testing)
2. Place them in `assets/audio/` folder:
   - `azan_default.mp3`
   - `azan_makkah.mp3`
   - `azan_madinah.mp3`
   - `azan_egypt.mp3`
   - `azan_turkey.mp3`

### Step 2: Update Main App
Add providers to `lib/main.dart`:

```dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/providers/prayer_alarm_provider.dart';

void main() async {
  WidgetsBinding.flutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => PrayerAlarmProvider()),
        // ... your other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

### Step 3: Add Navigation
Add route to prayer times page in your navigation:

```dart
// Example: In your Islamic dashboard or home screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrayerTimesPage(),
      ),
    );
  },
  child: const Text('নামাজের সময়'),
)
```

### Step 4: Run the App
```bash
flutter pub get
flutter run
```

## 📱 User Flow

1. **Open Prayer Times Page** → Shows today's prayer schedule
2. **Tap Alarm Icon** → Opens alarm settings
3. **Toggle Prayer Alarms** → Enable/disable for each prayer
4. **Set Pre-Alarm Time** → Use slider (0-60 minutes)
5. **Select Azan** → Choose from available options
6. **Test Audio** → Preview selected Azan
7. **Done!** → Alarms are scheduled automatically

## 🎯 Key Features

### Individual Prayer Control
- ✅ Each prayer has its own alarm toggle
- ✅ Different pre-alarm times for each prayer
- ✅ Example: 10 min before Fajr, 5 min before Dhuhr

### Smart Scheduling
- ✅ Alarms auto-schedule based on prayer times
- ✅ Updates when location changes
- ✅ Works even when app is closed

### Audio Customization
- ✅ 5 pre-loaded Azan options
- ✅ Volume control (0-100%)
- ✅ Test playback before saving
- ✅ Vibration toggle

## 🔧 Testing

### Test Alarm Immediately:
1. Go to alarm settings
2. Enable Fajr alarm
3. Set pre-alarm to 1 minute
4. Wait 1 minute before next Fajr time
5. Notification should appear

### Test Audio:
1. Go to alarm settings
2. Scroll to "Azan Selection"
3. Tap "Test" button
4. Audio should play
5. Tap "Stop" to stop

## 📋 Checklist

Before releasing:
- [ ] Audio files added to `assets/audio/`
- [ ] Providers added to main.dart
- [ ] Timezone initialized
- [ ] Navigation route added
- [ ] Tested on physical device
- [ ] Permissions granted (location, notifications)
- [ ] Battery optimization disabled
- [ ] Alarms trigger correctly
- [ ] Audio plays correctly

## 🐛 Common Issues

### Issue: Alarms not triggering
**Solution:** 
- Check notification permission
- Disable battery optimization
- Ensure exact alarm permission (Android 12+)

### Issue: Audio not playing
**Solution:**
- Verify MP3 files exist in assets/audio/
- Check pubspec.yaml includes assets/audio/
- Run `flutter clean` and rebuild

### Issue: Location not detected
**Solution:**
- Grant location permission
- Enable GPS
- Use manual city selection as fallback

## 📞 Need Help?

1. Check `PRAYER_ALARM_IMPLEMENTATION.md` for detailed docs
2. Review code comments in source files
3. Test with debug logging enabled

## 🎉 You're Done!

Your prayer alarm system is now ready to use. Users can:
- View prayer times for their location
- Set custom alarms for each prayer
- Choose their favorite Azan
- Get notified before prayer time

---

**Next Steps:**
- Customize Azan audio files
- Add more cities to location picker
- Integrate with Namaz Tracker
- Add home screen widget (future enhancement)
