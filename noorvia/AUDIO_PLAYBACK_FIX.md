# 🔧 অডিও প্লেব্যাক সমস্যা সমাধান

## 🐛 সমস্যা
```
AudioPlayers Exception: AudioPlayerException(
  UrlSource(url: https://www.islamcan.com/audio/adhan/azan2.mp3, mimeType: null),
  PlatformException(WebAudioError, Failed to set source.
  MediaError: MEDIA_ELEMENT_ERROR: Format error (Code: 4), null)
)
```

## 🔍 কারণ

### ১. CORS (Cross-Origin Resource Sharing) সমস্যা
- ওয়েব ব্রাউজারে অডিও প্লে করতে CORS পারমিশন লাগে
- islamcan.com সার্ভার CORS হেডার পাঠায় না
- তাই ব্রাউজার অডিও লোড করতে দেয় না

### ২. প্ল্যাটফর্ম সমস্যা
- **ওয়েব**: CORS এরর হয়
- **Android/iOS**: সাধারণত কাজ করে
- **Desktop**: কাজ করতে পারে

## ✅ সমাধান

### সমাধান ১: মোবাইল ডিভাইসে টেস্ট করুন
```bash
# Android ডিভাইসে রান করুন
flutter run -d <device-id>

# অথবা APK বিল্ড করুন
flutter build apk
```

**কেন?** মোবাইল ডিভাইসে CORS সমস্যা হয় না।

### সমাধান ২: Chrome CORS Disable করুন (শুধু টেস্টিং এর জন্য)
```bash
# Windows
chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security

# Mac
open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security

# Linux
google-chrome --user-data-dir="/tmp/chrome_dev_test" --disable-web-security
```

**সতর্কতা**: এটা শুধু টেস্টিং এর জন্য। প্রোডাকশনে ব্যবহার করবেন না।

### সমাধান ৩: লোকাল প্রক্সি সার্ভার ব্যবহার করুন
একটি সিম্পল প্রক্সি সার্ভার তৈরি করুন যা CORS হেডার যোগ করবে।

```javascript
// proxy-server.js (Node.js)
const express = require('express');
const cors = require('cors');
const request = require('request');

const app = express();
app.use(cors());

app.get('/audio/:filename', (req, res) => {
  const url = `https://www.islamcan.com/audio/adhan/${req.params.filename}`;
  request(url).pipe(res);
});

app.listen(3000, () => {
  console.log('Proxy server running on http://localhost:3000');
});
```

তারপর URL পরিবর্তন করুন:
```dart
// Before
'https://www.islamcan.com/audio/adhan/azan1.mp3'

// After
'http://localhost:3000/audio/azan1.mp3'
```

### সমাধান ৪: আযান ফাইল ডাউনলোড করে লোকালে রাখুন (সেরা সমাধান)

#### ধাপ ১: আযান ডাউনলোড করুন
```bash
# একটি স্ক্রিপ্ট দিয়ে সব আযান ডাউনলোড করুন
for i in {1..20}; do
  wget https://www.islamcan.com/audio/adhan/azan$i.mp3 -O assets/audio/azan$i.mp3
done
```

#### ধাপ ২: pubspec.yaml আপডেট করুন
```yaml
flutter:
  assets:
    - assets/audio/azan1.mp3
    - assets/audio/azan2.mp3
    # ... azan20.mp3 পর্যন্ত
```

#### ধাপ ৩: কোড আপডেট করুন
```dart
// lib/core/models/prayer_alarm_settings.dart
class OnlineAzanList {
  static List<Map<String, String>> getAzanList() {
    return List.generate(20, (index) {
      final num = index + 1;
      return {
        'url': 'assets/audio/azan$num.mp3', // লোকাল পাথ
        'name': 'আযান $num',
        'id': 'azan$num',
      };
    });
  }
}
```

## 🎯 বর্তমান কোডে যা করা হয়েছে

### ১. Better Error Handling
```dart
Future<void> playAzan() async {
  try {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setVolume(_settings!.volume);
    
    if (_settings!.isOnlineAzan) {
      final source = UrlSource(
        _settings!.selectedAzanPath,
        mimeType: 'audio/mpeg', // MIME type specify করা
      );
      await _audioPlayer.play(source);
    }
  } catch (e) {
    print('❌ Error playing azan: $e');
    _showAzanError(e.toString());
  }
}
```

### ২. Audio Player Configuration
```dart
Future<void> _configureAudioPlayer() async {
  await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
  
  _audioPlayer.onPlayerStateChanged.listen((state) {
    print('🎵 Audio player state: $state');
  });
}
```

### ৩. Error Messages
```dart
void _showAzanError(String error) {
  if (error.contains('CORS') || error.contains('WebAudioError')) {
    print('⚠️ CORS error detected. Use mobile app.');
  } else if (error.contains('Format error')) {
    print('⚠️ Audio format error.');
  }
}
```

## 📱 প্রস্তাবিত সমাধান

### প্রোডাকশনের জন্য:
1. **সব আযান লোকালে রাখুন** (assets/audio/)
2. অথবা **নিজের সার্ভারে হোস্ট করুন** (CORS enabled)
3. অথবা **Firebase Storage ব্যবহার করুন**

### টেস্টিং এর জন্য:
1. **Android/iOS ডিভাইসে টেস্ট করুন**
2. Chrome CORS disable করে টেস্ট করুন (সাময়িক)

## 🚀 দ্রুত সমাধান

### এখনই টেস্ট করতে চান?

#### অপশন ১: Android ডিভাইসে রান করুন
```bash
flutter run
# তারপর ডিভাইস সিলেক্ট করুন
```

#### অপশন ২: একটি আযান লোকালে রাখুন
1. একটি MP3 ফাইল ডাউনলোড করুন
2. `assets/audio/azan1.mp3` এ রাখুন
3. pubspec.yaml এ যোগ করুন:
```yaml
flutter:
  assets:
    - assets/audio/azan1.mp3
```
4. কোড আপডেট করুন:
```dart
// Default azan লোকাল করুন
PrayerAlarmSettings({
  this.selectedAzanPath = 'assets/audio/azan1.mp3',
  this.selectedAzanName = 'আযান ১',
  this.isOnlineAzan = false, // false করুন
  // ...
})
```

## 📊 প্ল্যাটফর্ম সাপোর্ট

| প্ল্যাটফর্ম | অনলাইন আযান | লোকাল আযান | নোট |
|------------|-------------|------------|------|
| Android    | ✅ কাজ করে  | ✅ কাজ করে | সেরা |
| iOS        | ✅ কাজ করে  | ✅ কাজ করে | সেরা |
| Web        | ❌ CORS এরর | ✅ কাজ করে | লোকাল ব্যবহার করুন |
| Desktop    | ⚠️ হতে পারে | ✅ কাজ করে | টেস্ট করুন |

## 🎉 সারাংশ

**সমস্যা**: ওয়েব ব্রাউজারে CORS এরর  
**কারণ**: islamcan.com CORS সাপোর্ট করে না  
**সমাধান**: মোবাইল ডিভাইসে টেস্ট করুন অথবা আযান লোকালে রাখুন

**প্রোডাকশনের জন্য সেরা**: সব আযান assets/audio/ ফোল্ডারে রাখুন

---

**তৈরি করেছেন**: Kiro AI Assistant  
**তারিখ**: May 3, 2026  
**স্ট্যাটাস**: ✅ সমাধান প্রস্তুত
