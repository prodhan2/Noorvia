# 🔧 Build এরর ও অডিও সমস্যা সমাধান

## 🐛 সমস্যা ১: Gradle Build Failed

### এরর মেসেজ:
```
Network is unreachable: getsockopt
Failed to notify project evaluation listener
java.lang.NullPointerException
BUILD FAILED in 8s
```

### ✅ সমাধান:

#### ধাপ ১: Gradle Clean করুন
```bash
cd android
./gradlew clean
cd ..
```

#### ধাপ ২: Flutter Clean করুন
```bash
flutter clean
flutter pub get
```

#### ধাপ ৩: Gradle Cache Clear করুন
```bash
# Windows
rmdir /s /q %USERPROFILE%\.gradle\caches

# Mac/Linux
rm -rf ~/.gradle/caches
```

#### ধাপ ৪: আবার Build করুন
```bash
flutter build apk --release
```

### অথবা সহজ উপায়:

#### শুধু Debug Mode এ রান করুন:
```bash
flutter run
# মোবাইল ডিভাইস সিলেক্ট করুন
```

Debug mode এ release build এর দরকার নেই, তাই Gradle এরর এড়ানো যায়।

---

## 🐛 সমস্যা ২: আযান বাজছে না (Web Browser)

### এরর মেসেজ:
```
AudioPlayers Exception: AudioPlayerException
PlatformException(WebAudioError, Failed to set source
MediaError: MEDIA_ELEMENT_ERROR: Format error (Code: 4)
```

### 🤔 কারণ:

**ওয়েব ব্রাউজারে CORS সমস্যা**
- GitHub raw link এও CORS সমস্যা হতে পারে
- ব্রাউজার সিকিউরিটি পলিসি অডিও লোড করতে দেয় না
- এটা একটা সাধারণ সমস্যা

### ✅ সমাধান (৩টি উপায়):

---

## সমাধান ১: মোবাইল ডিভাইসে রান করুন (সবচেয়ে সহজ ✅)

### কেন এটা সেরা?
- ✅ কোনো CORS সমস্যা নেই
- ✅ সব ফিচার কাজ করে
- ✅ নোটিফিকেশন টেস্ট করা যায়
- ✅ রিয়েল ইউজার এক্সপেরিয়েন্স

### কিভাবে করবেন:

#### Android ফোনে:
```bash
# ১. USB Debugging চালু করুন
# Settings > Developer Options > USB Debugging

# ২. USB ক্যাবল দিয়ে কানেক্ট করুন

# ৩. রান করুন
flutter run

# ৪. আপনার ফোন সিলেক্ট করুন
```

#### iOS ফোনে:
```bash
# ১. Mac এ Xcode ইনস্টল করুন
# ২. iPhone কানেক্ট করুন
# ৩. রান করুন
flutter run
```

---

## সমাধান ২: Desktop অ্যাপ হিসেবে রান করুন

### Windows Desktop:
```bash
flutter run -d windows
```

### Mac Desktop:
```bash
flutter run -d macos
```

### Linux Desktop:
```bash
flutter run -d linux
```

Desktop অ্যাপে CORS সমস্যা কম হয়।

---

## সমাধান ৩: আযান ফাইল লোকালে রাখুন (স্থায়ী সমাধান)

### ধাপ ১: আযান ডাউনলোড করুন
```bash
# একটি আযান ডাউনলোড করুন
# https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/AzanSounds/azan1.mp3
```

### ধাপ ২: প্রজেক্টে রাখুন
```
muslim_view/
  └── assets/
      └── audio/
          └── azan1.mp3  ← এখানে রাখুন
```

### ধাপ ৩: pubspec.yaml আপডেট করুন
```yaml
flutter:
  assets:
    - assets/audio/azan1.mp3
```

### ধাপ ৪: কোড আপডেট করুন
`lib/core/models/prayer_alarm_settings.dart`:
```dart
PrayerAlarmSettings({
  this.selectedAzanPath = 'assets/audio/azan1.mp3',  // লোকাল পাথ
  this.selectedAzanName = 'আযান ১',
  this.isOnlineAzan = false,  // false করুন
  // ...
})
```

### ধাপ ৫: রিস্টার্ট করুন
```bash
flutter clean
flutter pub get
flutter run
```

এখন সব প্ল্যাটফর্মে কাজ করবে!

---

## 📊 কোন সমাধান বেছে নেবেন?

| সমাধান | সুবিধা | অসুবিধা | প্রস্তাবিত |
|--------|---------|----------|------------|
| মোবাইল ডিভাইস | সব কাজ করে | ফোন লাগে | ⭐⭐⭐⭐⭐ |
| Desktop অ্যাপ | দ্রুত টেস্ট | কিছু ফিচার নাও কাজ করতে পারে | ⭐⭐⭐⭐ |
| লোকাল আযান | সব জায়গায় কাজ করে | ফাইল ডাউনলোড করতে হয় | ⭐⭐⭐⭐⭐ |
| ওয়েব ব্রাউজার | সহজ | CORS সমস্যা | ⭐⭐ |

---

## 🎯 প্রস্তাবিত ওয়ার্কফ্লো

### ডেভেলপমেন্টের জন্য:
```bash
# মোবাইল ডিভাইসে রান করুন
flutter run
# আপনার Android/iOS ফোন সিলেক্ট করুন
```

### প্রোডাকশনের জন্য:
```bash
# APK বিল্ড করুন
flutter build apk --release

# অথবা App Bundle
flutter build appbundle --release
```

---

## 🆘 এখনও সমস্যা?

### Gradle এরর হলে:
```bash
# সব clean করুন
flutter clean
cd android
./gradlew clean
cd ..

# Cache clear করুন
rm -rf ~/.gradle/caches  # Mac/Linux
rmdir /s /q %USERPROFILE%\.gradle\caches  # Windows

# আবার চেষ্টা করুন
flutter run
```

### অডিও এরর হলে:
1. **মোবাইল ডিভাইসে টেস্ট করুন** (সবচেয়ে ভালো)
2. অথবা **লোকাল আযান ব্যবহার করুন**
3. অথবা **Desktop অ্যাপ হিসেবে রান করুন**

### ইন্টারনেট সমস্যা হলে:
```bash
# VPN চালু করুন
# অথবা মোবাইল হটস্পট ব্যবহার করুন
# অথবা অন্য নেটওয়ার্ক ব্যবহার করুন
```

---

## ✅ সারাংশ

### Gradle Build এরর:
- **সমাধান**: `flutter clean` এবং `flutter run` (debug mode)
- **বিকল্প**: Cache clear করুন

### আযান প্লেব্যাক এরর:
- **সমাধান**: মোবাইল ডিভাইসে রান করুন
- **বিকল্প**: লোকাল আযান ব্যবহার করুন

### সবচেয়ে সহজ:
```bash
flutter run
# মোবাইল ফোন সিলেক্ট করুন
# সব কাজ করবে! 🎉
```

---

**তৈরি করেছেন**: Kiro AI Assistant  
**তারিখ**: ৩ মে, ২০২৬  
**স্ট্যাটাস**: ✅ সমাধান প্রস্তুত
