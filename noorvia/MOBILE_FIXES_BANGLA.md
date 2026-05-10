# মোবাইল অ্যাপ সমস্যা সমাধান (Mobile App Fixes)

## সমস্যা সমূহ (Issues Identified)

### ১. আমার মসজিদ বাটন - ওয়েবে কাজ করে কিন্তু মোবাইলে করে না
**সমস্যা:** "আশেপাশের আমার মসজিদ" বাটনে ক্লিক করলে ওয়েবে দেখায় কিন্তু মোবাইল অ্যাপে দেখায় না।

**কারণ:**
- মোবাইলে লোকেশন পারমিশন সঠিকভাবে রিকোয়েস্ট করা হচ্ছে না
- ইউজার পারমিশন ডিনাই করলে কোনো সঠিক মেসেজ দেখাচ্ছে না

**সমাধান:**
- ✅ লোকেশন পারমিশন এরর হ্যান্ডলিং উন্নত করা হয়েছে
- ✅ পারমিশন ডিনাই হলে স্ন্যাকবার দেখাবে "সেটিংস" বাটন সহ
- ✅ সেটিংস বাটনে ক্লিক করলে সরাসরি অ্যাপ সেটিংসে যাবে

### ২. আযান অ্যালার্ম বাজে না এবং পুশ নোটিফিকেশন আসে না
**সমস্যা:** আযান অ্যালার্ম সেট করলেও অ্যালার্ম বাজে না এবং কোনো পুশ নোটিফিকেশন আসে না।

**কারণ:**
- Android 12+ এ exact alarm পারমিশন প্রয়োজন
- ডিভাইস স্লিপ মোডে থাকলে অ্যালার্ম কাজ করছে না
- Wake lock পারমিশন ছিল না
- Foreground service পারমিশন ছিল না
- Notification visibility সেট করা ছিল না

**সমাধান:**
- ✅ `WAKE_LOCK` পারমিশন যোগ করা হয়েছে
- ✅ `FOREGROUND_SERVICE` পারমিশন যোগ করা হয়েছে
- ✅ `FOREGROUND_SERVICE_MEDIA_PLAYBACK` পারমিশন যোগ করা হয়েছে
- ✅ Notification visibility `public` সেট করা হয়েছে (লক স্ক্রিনে দেখাবে)
- ✅ iOS এর জন্য `interruptionLevel: timeSensitive` যোগ করা হয়েছে
- ✅ Alarm scheduling উন্নত করা হয়েছে (daily recurring)
- ✅ Permission check method যোগ করা হয়েছে

## পরিবর্তিত ফাইল সমূহ (Modified Files)

### 1. `android/app/src/main/AndroidManifest.xml`
```xml
<!-- নতুন পারমিশন যোগ করা হয়েছে -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

### 2. `lib/core/services/prayer_alarm_service.dart`
**পরিবর্তন:**
- ✅ Notification visibility `public` সেট করা হয়েছে
- ✅ iOS interruption level `timeSensitive` যোগ করা হয়েছে
- ✅ Permission checking method `arePermissionsGranted()` যোগ করা হয়েছে
- ✅ Better error handling for permission requests
- ✅ TZDateTime constructor ব্যবহার করে daily recurring alarm সঠিকভাবে সেট করা হয়েছে

### 3. `lib/screens/location/nearby_mosques_screen.dart`
**পরিবর্তন:**
- ✅ Better exception handling
- ✅ Permission error এর জন্য snackbar দেখাবে
- ✅ "সেটিংস" বাটন যোগ করা হয়েছে যা সরাসরি app settings খুলবে
- ✅ Geolocator import যোগ করা হয়েছে

## ইউজারদের জন্য নির্দেশনা (User Instructions)

### আমার মসজিদ ফিচার ব্যবহার করতে:

1. **প্রথমবার ব্যবহার:**
   - "আমার মসজিদ" বাটনে ক্লিক করুন
   - লোকেশন পারমিশন রিকোয়েস্ট আসলে "Allow" দিন
   - যদি "Deny" করে থাকেন, তাহলে:
     - এরর মেসেজে "সেটিংস" বাটনে ক্লিক করুন
     - অথবা: Settings > Apps > Muslim View > Permissions > Location > Allow

2. **লোকেশন সার্ভিস চালু করুন:**
   - Settings > Location > Turn ON

### আযান অ্যালার্ম সেটআপ করতে:

1. **নোটিফিকেশন পারমিশন:**
   - প্রথমবার অ্যাপ খুললে notification permission দিন
   - Settings > Apps > Muslim View > Notifications > Allow all

2. **Exact Alarm পারমিশন (Android 12+):**
   - Settings > Apps > Muslim View > Alarms & reminders > Allow
   - এটি না দিলে অ্যালার্ম সঠিক সময়ে বাজবে না

3. **Battery Optimization বন্ধ করুন:**
   - Settings > Apps > Muslim View > Battery > Unrestricted
   - অথবা: Settings > Battery > Battery optimization > Muslim View > Don't optimize
   - এটি না করলে ব্যাকগ্রাউন্ডে অ্যালার্ম বন্ধ হয়ে যেতে পারে

4. **আযান অ্যালার্ম সেট করুন:**
   - হোম স্ক্রিন > "আযান অ্যালার্ম" বাটনে ক্লিক করুন
   - যে নামাজের জন্য অ্যালার্ম চান সেটি enable করুন
   - Pre-alarm সময় সেট করুন (0-30 মিনিট)
   - আযান সিলেক্ট করুন
   - "Test Azan" বাটনে ক্লিক করে চেক করুন

## ডেভেলপারদের জন্য টেস্টিং (Developer Testing)

### মসজিদ ফাইন্ডার টেস্ট:
```bash
# মোবাইল ডিভাইসে রান করুন
flutter run --release

# টেস্ট করুন:
1. "আমার মসজিদ" বাটনে ক্লিক করুন
2. Location permission allow করুন
3. মসজিদের লিস্ট দেখা যাচ্ছে কিনা চেক করুন
4. Permission deny করে আবার চেষ্টা করুন - error message দেখা যাচ্ছে কিনা
5. "সেটিংস" বাটনে ক্লিক করে app settings খুলছে কিনা
```

### আযান অ্যালার্ম টেস্ট:
```bash
# মোবাইল ডিভাইসে রান করুন
flutter run --release

# টেস্ট করুন:
1. আযান অ্যালার্ম পেজে যান
2. একটি নামাজের অ্যালার্ম enable করুন
3. Pre-alarm 1 মিনিট সেট করুন
4. বর্তমান সময়ের 2 মিনিট পরের জন্য সেট করুন
5. "Test Azan" বাটনে ক্লিক করে আযান বাজছে কিনা চেক করুন
6. অ্যাপ বন্ধ করে দিন
7. নির্ধারিত সময়ে notification আসছে কিনা চেক করুন
8. Lock screen এ notification দেখা যাচ্ছে কিনা চেক করুন
```

### Pending Alarms চেক করুন:
```dart
// Debug করার জন্য
final service = PrayerAlarmService();
await service.initialize();
final pending = await service.getPendingAlarms();
print('Pending alarms: ${pending.length}');
for (var alarm in pending) {
  print('ID: ${alarm.id}, Title: ${alarm.title}, Body: ${alarm.body}');
}
```

## সাধারণ সমস্যা ও সমাধান (Common Issues & Solutions)

### সমস্যা: অ্যালার্ম এখনও বাজছে না
**সমাধান:**
1. Battery optimization বন্ধ করুন
2. Exact alarm permission দিন
3. Do Not Disturb mode বন্ধ করুন
4. অ্যাপ আনইনস্টল করে আবার ইনস্টল করুন

### সমস্যা: মসজিদ খুঁজে পাচ্ছে না
**সমাধান:**
1. Location services চালু করুন
2. High accuracy mode সিলেক্ট করুন
3. ইন্টারনেট কানেকশন চেক করুন
4. Search radius বাড়ান (5km থেকে 10km বা 20km)

### সমস্যা: Lock screen এ notification দেখা যাচ্ছে না
**সমাধান:**
1. Settings > Apps > Muslim View > Notifications > Lock screen > Show
2. Settings > Lock screen > Notifications > Show all notification content

## পরবর্তী আপডেট (Future Improvements)

- [ ] Foreground service implementation for better alarm reliability
- [ ] Custom alarm sound picker
- [ ] Snooze functionality
- [ ] Alarm history and logs
- [ ] Mosque favorites and saved locations
- [ ] Offline mosque database for faster loading

## সাপোর্ট (Support)

যদি এখনও সমস্যা হয়, তাহলে:
1. অ্যাপ লগ চেক করুন: `flutter logs`
2. Device info শেয়ার করুন (Android version, device model)
3. Screenshot শেয়ার করুন

---

**সর্বশেষ আপডেট:** May 4, 2026
**ভার্সন:** 1.0.0
