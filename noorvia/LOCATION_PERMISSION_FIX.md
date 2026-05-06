# Location Permission Fix - একবার Permission দিলে সব জায়গায় কাজ করবে

## সমস্যা
- মোবাইলে মসজিদ ডেটা দেখা যাচ্ছিল না
- প্রতিবার location permission চাইছিল
- বিভিন্ন স্ক্রিনে permission handling inconsistent ছিল

## সমাধান
একটি **Global Location Permission Service** তৈরি করা হয়েছে যা:

### ✅ কী করে
1. **একবার permission দিলে সেটা মনে রাখে** - Singleton pattern ব্যবহার করে
2. **App startup এ একবার permission চায়** - `main.dart` এ initialize করা হয়
3. **সব জায়গায় একই permission ব্যবহার করে** - Global service থেকে
4. **Permission verify করে** - প্রতিবার ব্যবহারের সময় check করে যে permission valid আছে কিনা

## ফাইল পরিবর্তন

### 1. নতুন ফাইল: `lib/core/services/location_permission_service.dart`
```dart
LocationPermissionService() // Singleton
- initializePermissions()    // App startup এ একবার কল হয়
- getCachedPermission()      // Cached permission পায়
- isPermissionGranted()      // Permission আছে কিনা check করে
- verifyPermission()         // Permission verify করে
- openAppSettings()          // Settings খুলে
```

### 2. আপডেট: `lib/main.dart`
```dart
// App startup এ permission initialize করা হয়
unawaited(LocationPermissionService().initializePermissions());
```

### 3. আপডেট: `lib/core/services/mosque_service.dart`
```dart
// Global permission service ব্যবহার করে
getCurrentLocation() {
  final permissionService = LocationPermissionService();
  final isGranted = await permissionService.verifyPermission();
  // ...
}
```

### 4. আপডেট: `lib/screens/home/home_screen.dart`
```dart
// _findMosque() ফাংশন আপডেট করা হয়েছে
// Global permission service ব্যবহার করে
```

### 5. আপডেট: `lib/screens/location/nearby_mosques_screen.dart`
```dart
// Error handling উন্নত করা হয়েছে
// Permission denied forever এর জন্য Settings button দেখায়
```

## কীভাবে কাজ করে

### প্রথমবার App খোলা হলে:
1. `main()` এ `LocationPermissionService().initializePermissions()` কল হয়
2. Permission dialog দেখা যায়
3. User permission দেয় বা reject করে
4. Permission status cache হয়ে যায়

### পরবর্তীতে যখন মসজিদ ডেটা চাওয়া হয়:
1. `NearbyMosquesScreen` খোলা হয়
2. `_loadNearbyMosques()` কল হয়
3. `MosqueService.getCurrentLocation()` কল হয়
4. `LocationPermissionService.verifyPermission()` check করে
5. যদি permission valid থাকে, location পায় এবং মসজিদ দেখায়
6. যদি permission invalid থাকে, error দেখায়

## ব্যবহারকারীর অভিজ্ঞতা

### ✅ ভালো অভিজ্ঞতা
- App খোলার সময় একবার permission চায়
- পরবর্তীতে বারবার চায় না
- সব জায়গায় (মসজিদ খুঁজি, আমার মসজিদ) একই permission ব্যবহার করে
- Permission denied হলে Settings খুলার option দেয়

### ❌ পুরানো অভিজ্ঞতা
- প্রতিবার permission চাইত
- বিভিন্ন জায়গায় inconsistent behavior ছিল
- Web এ কাজ করত কিন্তু mobile এ না

## Testing

### Test করার জন্য:
1. App আনইনস্টল করুন
2. App ইনস্টল করুন
3. App খুলুন - permission dialog দেখবেন
4. Permission দিন
5. "আমার মসজিদ" এ যান - মসজিদ দেখবেন
6. "মসজিদ খুঁজি" এ যান - Google Maps খুলবে
7. App বন্ধ করুন এবং আবার খুলুন - permission dialog আর দেখবেন না

## Notes
- Web এ location permission কাজ করে না (geolocator web support নেই)
- Android এ location services চালু থাকতে হবে
- iOS এ location permission settings এ দিতে হবে
