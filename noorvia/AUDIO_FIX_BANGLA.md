# 🔧 আযান বাজছে না? সমাধান এখানে!

## 🐛 সমস্যা কি?

আপনি যখন "আযান টেস্ট করুন" বাটনে ক্লিক করেন, তখন এই এরর দেখাচ্ছে:
```
AudioPlayers Exception: WebAudioError
MEDIA_ELEMENT_ERROR: Format error
```

## 🤔 কেন হচ্ছে?

আপনি **ওয়েব ব্রাউজারে** (Chrome/Edge) অ্যাপ চালাচ্ছেন। ওয়েব ব্রাউজারে একটা সিকিউরিটি ফিচার আছে যার নাম **CORS**। এটা বাইরের ওয়েবসাইট থেকে অডিও লোড করতে দেয় না।

### সহজ ভাষায়:
- 🌐 **ওয়েব ব্রাউজারে**: আযান বাজবে না (CORS সমস্যা)
- 📱 **মোবাইল ফোনে**: আযান ঠিকই বাজবে
- 💻 **Desktop অ্যাপে**: আযান বাজতে পারে

## ✅ সমাধান

### সমাধান ১: মোবাইল ফোনে টেস্ট করুন (সবচেয়ে সহজ)

#### ধাপ ১: ফোন কম্পিউটারে কানেক্ট করুন
1. USB ক্যাবল দিয়ে ফোন কানেক্ট করুন
2. ফোনে "USB Debugging" চালু করুন
   - Settings > Developer Options > USB Debugging

#### ধাপ ২: অ্যাপ রান করুন
```bash
flutter run
```

#### ধাপ ৩: ডিভাইস সিলেক্ট করুন
যখন জিজ্ঞেস করবে, আপনার ফোন সিলেক্ট করুন (যেমন: Samsung Galaxy, Xiaomi, etc.)

#### ধাপ ৪: টেস্ট করুন
এখন "আযান টেস্ট করুন" বাটনে ক্লিক করুন। আযান বাজবে! 🎉

---

### সমাধান ২: আযান ফাইল ডাউনলোড করে রাখুন (স্থায়ী সমাধান)

এটা করলে ইন্টারনেট ছাড়াই আযান বাজবে!

#### ধাপ ১: আযান ডাউনলোড করুন
1. এই লিংকে যান: https://www.islamcan.com/audio/adhan/azan1.mp3
2. ফাইল ডাউনলোড করুন (Right click > Save as)
3. নাম দিন: `azan1.mp3`

#### ধাপ ২: ফাইল প্রজেক্টে রাখুন
1. আপনার প্রজেক্টে `assets/audio/` ফোল্ডার তৈরি করুন
2. `azan1.mp3` ফাইল সেখানে কপি করুন

```
noorvia/
  ├── assets/
  │   └── audio/
  │       └── azan1.mp3  ← এখানে রাখুন
  ├── lib/
  └── pubspec.yaml
```

#### ধাপ ৩: pubspec.yaml আপডেট করুন
`pubspec.yaml` ফাইল খুলুন এবং এই লাইন যোগ করুন:

```yaml
flutter:
  assets:
    - assets/audio/azan1.mp3
```

#### ধাপ ৪: কোড আপডেট করুন
`lib/core/models/prayer_alarm_settings.dart` ফাইল খুলুন এবং এই অংশ পরিবর্তন করুন:

**আগে:**
```dart
PrayerAlarmSettings({
  this.selectedAzanPath = 'https://www.islamcan.com/audio/adhan/azan1.mp3',
  this.selectedAzanName = 'আযান ১',
  this.isOnlineAzan = true,  // ← এটা true ছিল
  // ...
})
```

**পরে:**
```dart
PrayerAlarmSettings({
  this.selectedAzanPath = 'assets/audio/azan1.mp3',  // ← লোকাল পাথ
  this.selectedAzanName = 'আযান ১',
  this.isOnlineAzan = false,  // ← এটা false করুন
  // ...
})
```

#### ধাপ ৫: অ্যাপ রিস্টার্ট করুন
```bash
# অ্যাপ বন্ধ করুন (Ctrl+C)
# আবার চালু করুন
flutter run
```

এখন আযান বাজবে! 🎉

---

### সমাধান ৩: সব ২০টি আযান ডাউনলোড করুন (সম্পূর্ণ সমাধান)

#### ধাপ ১: সব আযান ডাউনলোড করুন
প্রতিটি আযান ডাউনলোড করুন:
- https://www.islamcan.com/audio/adhan/azan1.mp3
- https://www.islamcan.com/audio/adhan/azan2.mp3
- ... azan20.mp3 পর্যন্ত

#### ধাপ ২: সব ফাইল `assets/audio/` তে রাখুন
```
assets/audio/
  ├── azan1.mp3
  ├── azan2.mp3
  ├── azan3.mp3
  ├── ...
  └── azan20.mp3
```

#### ধাপ ৩: pubspec.yaml আপডেট করুন
```yaml
flutter:
  assets:
    - assets/audio/
```

#### ধাপ ৪: কোড আপডেট করুন
`lib/core/models/prayer_alarm_settings.dart` এ:

```dart
class OnlineAzanList {
  static List<Map<String, String>> getAzanList() {
    return List.generate(20, (index) {
      final num = index + 1;
      return {
        'url': 'assets/audio/azan$num.mp3',  // ← লোকাল পাথ
        'name': 'আযান $num',
        'id': 'azan$num',
      };
    });
  }
}
```

এবং ডিফল্ট সেটিংস:
```dart
PrayerAlarmSettings({
  this.selectedAzanPath = 'assets/audio/azan1.mp3',
  this.selectedAzanName = 'আযান ১',
  this.isOnlineAzan = false,  // ← false করুন
  // ...
})
```

---

## 🎯 কোন সমাধান বেছে নেবেন?

### দ্রুত টেস্ট করতে চান?
→ **সমাধান ১** ব্যবহার করুন (মোবাইল ফোনে টেস্ট)

### স্থায়ী সমাধান চান?
→ **সমাধান ২** বা **সমাধান ৩** ব্যবহার করুন (আযান ডাউনলোড)

### প্রোডাকশন অ্যাপের জন্য?
→ **সমাধান ৩** সবচেয়ে ভালো (সব আযান লোকালে)

---

## 📊 কোথায় কাজ করবে?

| কোথায় চালাচ্ছেন | অনলাইন আযান | লোকাল আযান |
|------------------|-------------|------------|
| 🌐 Chrome/Edge   | ❌ বাজবে না | ✅ বাজবে   |
| 📱 Android ফোন   | ✅ বাজবে    | ✅ বাজবে   |
| 📱 iPhone        | ✅ বাজবে    | ✅ বাজবে   |
| 💻 Windows অ্যাপ | ⚠️ হতে পারে | ✅ বাজবে   |

---

## 🆘 এখনও সমস্যা?

### আযান বাজছে না?
1. ভলিউম চেক করুন (০% হলে শব্দ হবে না)
2. ফাইল পাথ চেক করুন (`assets/audio/azan1.mp3`)
3. pubspec.yaml এ assets যোগ করেছেন কিনা চেক করুন

### ফাইল খুঁজে পাচ্ছে না?
```bash
# Clean করে আবার build করুন
flutter clean
flutter pub get
flutter run
```

### এখনও কাজ করছে না?
Console এ কি এরর দেখাচ্ছে দেখুন:
```
❌ Error playing azan: ...
```

---

## 🎉 সারাংশ

**সমস্যা**: ওয়েব ব্রাউজারে আযান বাজছে না  
**কারণ**: CORS সিকিউরিটি  
**সমাধান**: মোবাইল ফোনে টেস্ট করুন অথবা আযান লোকালে রাখুন

**সবচেয়ে ভালো**: সব আযান `assets/audio/` ফোল্ডারে রাখুন

---

**সাহায্য করেছেন**: Kiro AI Assistant  
**তারিখ**: ৩ মে, ২০২৬  
**স্ট্যাটাস**: ✅ সমাধান প্রস্তুত
