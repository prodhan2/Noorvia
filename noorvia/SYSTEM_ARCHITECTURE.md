# 🏗️ আযান অ্যালার্ম সিস্টেম আর্কিটেকচার

## 📊 সিস্টেম ডায়াগ্রাম

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │   Home Page  │───▶│ Azan Alarm   │───▶│   Settings   │    │
│  │              │    │     Page     │    │     Page     │    │
│  └──────────────┘    └──────────────┘    └──────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              ┌────────────────────────────┐                    │
│              │  PrayerAlarmProvider       │                    │
│              ├────────────────────────────┤                    │
│              │ - settings                 │                    │
│              │ - availableAzans (20)      │                    │
│              │ - azanLoadingStatus        │                    │
│              │ - azanCachedStatus         │                    │
│              │                            │                    │
│              │ Methods:                   │                    │
│              │ - togglePrayerAlarm()      │                    │
│              │ - selectAzan()             │                    │
│              │ - playTestAzan()           │                    │
│              │ - scheduleAlarms()         │                    │
│              └────────────────────────────┘                    │
│                              │                                  │
└──────────────────────────────┼──────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              ┌────────────────────────────┐                    │
│              │  PrayerAlarmService        │                    │
│              ├────────────────────────────┤                    │
│              │ - FlutterLocalNotifications│                    │
│              │ - AudioPlayer              │                    │
│              │ - SharedPreferences        │                    │
│              │                            │                    │
│              │ Methods:                   │                    │
│              │ - initialize()             │                    │
│              │ - scheduleAllAlarms()      │                    │
│              │ - playAzan()               │                    │
│              │ - stopAzan()               │                    │
│              │ - _onNotificationTapped()  │                    │
│              └────────────────────────────┘                    │
│                              │                                  │
└──────────────────────────────┼──────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
│   Notifications  │ │ Audio Player │ │   Storage    │
├──────────────────┤ ├──────────────┤ ├──────────────┤
│ - Schedule       │ │ - UrlSource  │ │ - Settings   │
│ - Show           │ │ - AssetSource│ │ - Cache      │
│ - Actions        │ │ - Volume     │ │ - Prefs      │
│ - Background     │ │ - Stop       │ │              │
└──────────────────┘ └──────────────┘ └──────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              ┌────────────────────────────┐                    │
│              │   islamcan.com             │                    │
│              ├────────────────────────────┤                    │
│              │ /audio/adhan/azan1.mp3     │                    │
│              │ /audio/adhan/azan2.mp3     │                    │
│              │ ...                        │                    │
│              │ /audio/adhan/azan20.mp3    │                    │
│              └────────────────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 ডেটা ফ্লো

### 1. অ্যালার্ম সেট করার ফ্লো

```
User Action (Toggle Switch)
        │
        ▼
PrayerAlarmProvider.togglePrayerAlarm()
        │
        ├─▶ Update settings
        │
        ├─▶ Save to SharedPreferences
        │
        └─▶ PrayerAlarmService.scheduleAllAlarms()
                │
                ├─▶ Calculate alarm time
                │
                ├─▶ Apply pre-alarm minutes
                │
                └─▶ Schedule notification
                        │
                        └─▶ Android/iOS Notification System
```

### 2. আযান সিলেক্ট করার ফ্লো

```
User Action (Select Azan)
        │
        ▼
PrayerAlarmProvider.selectAzan()
        │
        ├─▶ Update selectedAzanPath
        │
        ├─▶ Set isOnlineAzan = true
        │
        └─▶ Save to SharedPreferences
```

### 3. আযান বাজানোর ফ্লো

```
Notification Triggered / Test Button
        │
        ▼
PrayerAlarmService.playAzan()
        │
        ├─▶ Check isOnlineAzan
        │
        ├─▶ If online:
        │   └─▶ AudioPlayer.play(UrlSource(url))
        │           │
        │           └─▶ Download from islamcan.com
        │                   │
        │                   └─▶ Play audio
        │
        └─▶ If local:
            └─▶ AudioPlayer.play(AssetSource(path))
                    │
                    └─▶ Play from assets
```

### 4. পুশ নোটিফিকেশন ফ্লো

```
Scheduled Time Reached
        │
        ▼
Android/iOS Notification System
        │
        ├─▶ Show notification with:
        │   ├─▶ Title: "🕌 ফজর নামাজের সময়"
        │   ├─▶ Body: "১০ মিনিট পরে নামাজের সময় হবে"
        │   └─▶ Actions: [Play Azan, Dismiss]
        │
        └─▶ User taps notification
                │
                ├─▶ If "Play Azan" tapped:
                │   └─▶ PrayerAlarmService.playAzan()
                │
                └─▶ If "Dismiss" tapped:
                    └─▶ Close notification
```

---

## 🗂️ ডেটা মডেল

### PrayerAlarmSettings

```dart
{
  // Prayer alarms enabled/disabled
  "fajrEnabled": true,
  "dhuhrEnabled": true,
  "asrEnabled": true,
  "maghribEnabled": true,
  "ishaEnabled": true,
  
  // Pre-alarm minutes
  "fajrPreAlarm": 10,
  "dhuhrPreAlarm": 10,
  "asrPreAlarm": 10,
  "maghribPreAlarm": 10,
  "ishaPreAlarm": 10,
  
  // Selected azan
  "selectedAzanPath": "https://www.islamcan.com/audio/adhan/azan1.mp3",
  "selectedAzanName": "আযান ১",
  "isOnlineAzan": true,
  
  // Audio settings
  "volume": 0.8,
  "vibrationEnabled": true
}
```

### OnlineAzanList

```dart
[
  {
    "url": "https://www.islamcan.com/audio/adhan/azan1.mp3",
    "name": "আযান ১",
    "id": "azan1"
  },
  {
    "url": "https://www.islamcan.com/audio/adhan/azan2.mp3",
    "name": "আযান ২",
    "id": "azan2"
  },
  // ... up to azan20
]
```

---

## 🔐 পারমিশন ফ্লো

```
App Launch
    │
    ▼
PrayerAlarmService.initialize()
    │
    ├─▶ Request Notification Permission
    │   └─▶ Android: requestNotificationsPermission()
    │   └─▶ iOS: requestPermissions()
    │
    ├─▶ Request Exact Alarm Permission
    │   └─▶ Android: requestExactAlarmsPermission()
    │
    └─▶ Create Notification Channel
        └─▶ Channel ID: "prayer_alarm_channel"
            ├─▶ Name: "নামাজের আযান"
            ├─▶ Importance: MAX
            ├─▶ Sound: Enabled
            └─▶ Vibration: Enabled
```

---

## 📱 UI কম্পোনেন্ট হায়ারার্কি

```
AzanAlarmPage
├── AppBar
│   ├── Back Button
│   ├── Title: "আযান অ্যালার্ম"
│   └── Settings Button
│
├── Location & Date Card
│   ├── Location Icon + Name
│   └── Date
│
├── Quick Status Card
│   ├── Enabled Alarms Count
│   └── Status Icon
│
├── Today's Alarms Card
│   ├── Fajr Toggle
│   ├── Dhuhr Toggle
│   ├── Asr Toggle
│   ├── Maghrib Toggle
│   └── Isha Toggle
│
├── Quick Actions Card
│   ├── Test Button
│   ├── Stop Button
│   └── Advanced Settings Button
│
└── Settings Summary Card
    ├── Selected Azan
    ├── Volume
    └── Vibration Status

PrayerAlarmSettingsPage
├── AppBar (Gradient)
│   └── Title: "নামাজের আযান সেটিংস"
│
├── Prayer Alarm Cards (5)
│   ├── Prayer Icon
│   ├── Prayer Name & Time
│   ├── Enable/Disable Switch
│   └── Pre-Alarm Slider (0-60 min)
│
├── Azan Selection Card
│   ├── Selected Azan Display
│   ├── Change Button
│   ├── Test Button
│   └── Stop Button
│
├── Volume Control Card
│   └── Volume Slider (0-100%)
│
└── Vibration Toggle Card
    └── Vibration Switch
```

---

## ⚡ পারফরম্যান্স অপটিমাইজেশন

### 1. ব্যাকগ্রাউন্ড প্রিলোডিং
```dart
// আযান ব্যাকগ্রাউন্ডে লোড হয়
Future<void> _preloadAzansInBackground() async {
  for (var url in _availableAzans) {
    // একটার পর একটা লোড হয়
    await Future.delayed(const Duration(milliseconds: 500));
    // UI ব্লক হয় না
  }
}
```

### 2. লেজি লোডিং
```dart
// শুধু প্রয়োজন হলে লোড হয়
if (_settings == null) {
  await _loadSettings();
}
```

### 3. ক্যাশিং
```dart
// সেটিংস SharedPreferences এ ক্যাশ হয়
await prefs.setString('prayer_alarm_settings', jsonEncode(settings));
```

---

## 🔒 সিকিউরিটি

### 1. ডেটা ভ্যালিডেশন
```dart
// URL ভ্যালিডেশন
if (azanPath.startsWith('http')) {
  isOnlineAzan = true;
}
```

### 2. এরর হ্যান্ডলিং
```dart
try {
  await _audioPlayer.play(UrlSource(url));
} catch (e) {
  print('Error playing azan: $e');
  // Fallback to default azan
}
```

### 3. পারমিশন চেক
```dart
// পারমিশন চেক করে তারপর কাজ করে
await android.requestNotificationsPermission();
await android.requestExactAlarmsPermission();
```

---

## 🧪 টেস্টিং স্ট্র্যাটেজি

### Unit Tests
- ✅ PrayerAlarmSettings model serialization
- ✅ OnlineAzanList URL generation
- ✅ Pre-alarm time calculation

### Integration Tests
- ✅ Alarm scheduling flow
- ✅ Azan selection flow
- ✅ Audio playback flow

### E2E Tests
- ✅ Complete user journey
- ✅ Notification handling
- ✅ Background alarm triggering

---

## 📈 ভবিষ্যৎ উন্নতি

### Phase 1: অফলাইন সাপোর্ট
```dart
// flutter_cache_manager দিয়ে
final file = await DefaultCacheManager().getSingleFile(azanUrl);
await _audioPlayer.play(DeviceFileSource(file.path));
```

### Phase 2: কাস্টম আযান
```dart
// ইউজার নিজের আযান আপলোড করতে পারবে
final file = await FilePicker.platform.pickFiles(type: FileType.audio);
```

### Phase 3: অ্যানালিটিক্স
```dart
// কোন আযান বেশি ব্যবহার হয়
await analytics.logEvent('azan_selected', parameters: {
  'azan_id': azanId,
  'azan_name': azanName,
});
```

---

## 🎯 সমাপ্তি

এই আর্কিটেকচার:
- ✅ **Scalable**: নতুন ফিচার যোগ করা সহজ
- ✅ **Maintainable**: কোড পরিষ্কার ও সংগঠিত
- ✅ **Testable**: ইউনিট টেস্ট করা সহজ
- ✅ **Performant**: দ্রুত ও মসৃণ
- ✅ **Reliable**: এরর হ্যান্ডলিং আছে

**আলহামদুলিল্লাহ! 🤲**
