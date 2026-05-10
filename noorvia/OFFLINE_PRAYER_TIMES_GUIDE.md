# 🕌 Offline Prayer Times - Complete Guide

## ✅ 100% Offline Solution

এই implementation **কোনো API ব্যবহার করে না**। সব calculation device এ locally হয়। ইন্টারনেট ছাড়াই কাজ করবে!

---

## 📦 Packages Used

```yaml
dependencies:
  adhan_dart: 1.2.0  # Offline prayer time calculation
  hijri: ^3.0.0      # Hijri calendar conversion
```

---

## 🚀 Features

### Prayer Times Calculation ✅
- ✅ **100% Offline** - No internet required
- ✅ **Accurate** - Uses astronomical calculations
- ✅ **Multiple Methods** - 12+ calculation methods
- ✅ **Location-based** - Uses GPS coordinates
- ✅ **Real-time** - Updates automatically

### Hijri Calendar ✅
- ✅ **Current Hijri date**
- ✅ **Bengali format**
- ✅ **Islamic events detection**
- ✅ **Ramadan countdown**

### Additional Features ✅
- ✅ **Next prayer countdown**
- ✅ **Current prayer indicator**
- ✅ **Qibla direction**
- ✅ **Monthly prayer times**
- ✅ **Islamic events**

---

## 📱 Usage

### Basic Usage:

```dart
import 'package:muslim_view/widgets/offline_prayer_times_widget.dart';

// In your widget:
OfflinePrayerTimesWidget(
  latitude: 23.8103,  // Dhaka latitude
  longitude: 90.4125, // Dhaka longitude
  isDark: false,
)
```

### Get Prayer Times Programmatically:

```dart
import 'package:muslim_view/services/adhan_service.dart';

// Get prayer times in Bengali
final prayerTimes = AdhanService.getPrayerTimesBengali(
  latitude: 23.8103,
  longitude: 90.4125,
);

print(prayerTimes['ফজর']);    // "04:16 AM"
print(prayerTimes['যোহর']);   // "12:08 PM"
print(prayerTimes['আসর']);    // "03:28 PM"
print(prayerTimes['মাগরিব']); // "06:28 PM"
print(prayerTimes['এশা']);    // "08:16 PM"
```

### Get Next Prayer:

```dart
final nextPrayer = AdhanService.getNextPrayer(
  latitude: 23.8103,
  longitude: 90.4125,
);

print(nextPrayer['name']);     // "যোহর"
print(nextPrayer['time']);     // "12:08 PM"
print(nextPrayer['dateTime']); // DateTime object
```

### Get Time Remaining:

```dart
final timeRemaining = AdhanService.getFormattedTimeRemainingBengali(
  latitude: 23.8103,
  longitude: 90.4125,
);

print(timeRemaining); // "2 ঘন্টা 30 মিনিট"
```

### Get Hijri Date:

```dart
// Current Hijri date in Bengali
final hijriDate = AdhanService.getHijriDateBengali();
print(hijriDate); // "১৫ রমজান ১৪৪৬"

// Full Hijri date with weekday
final fullDate = AdhanService.getFullHijriDateBengali();
print(fullDate); // "শুক্রবার, ১৫ রমজান ১৪৪৬"
```

### Check Islamic Events:

```dart
final events = AdhanService.getIslamicEvents();
if (events.isNotEmpty) {
  print(events); // ["শবে কদর (সম্ভাব্য)"]
}
```

### Get Qibla Direction:

```dart
final qiblaDirection = AdhanService.getQiblaDirection(
  latitude: 23.8103,
  longitude: 90.4125,
);

print(qiblaDirection); // 291.5 degrees from North
```

### Get Monthly Prayer Times:

```dart
final monthlyTimes = AdhanService.getMonthlyPrayerTimes(
  latitude: 23.8103,
  longitude: 90.4125,
  year: 2026,
  month: 5,
);

for (var day in monthlyTimes) {
  print('${day['day']}: Fajr ${day['fajr']}, Dhuhr ${day['dhuhr']}');
}
```

---

## 🎯 Calculation Methods

Available calculation methods (12 methods):

```dart
final methods = AdhanService.getCalculationMethods();

// Use specific method:
final times = AdhanService.calculatePrayerTimes(
  latitude: 23.8103,
  longitude: 90.4125,
  calculationMethod: CalculationMethod.karachi(), // Default for Bangladesh
);
```

**Available Methods:**
1. মুসলিম ওয়ার্ল্ড লীগ (Muslim World League)
2. ইসলামিক সোসাইটি অফ নর্থ আমেরিকা (ISNA)
3. মিশরীয় জেনারেল অথরিটি (Egyptian)
4. উম্মুল কুরা ইউনিভার্সিটি (Umm al-Qura)
5. **ইউনিভার্সিটি অফ ইসলামিক সায়েন্সেস, করাচি** (Karachi) ← **Default for Bangladesh**
6. ইনস্টিটিউট অফ জিওফিজিক্স, তেহরান (Tehran)
7. কুয়েত (Kuwait)
8. কাতার (Qatar)
9. সিঙ্গাপুর (Singapore)
10. দুবাই (Dubai)
11. মুন সাইটিং কমিটি (Moonsighting Committee)
12. তুরস্ক (Turkey)

---

## 🔄 Replace Existing API Code

### Before (Using API):

```dart
// Old code using Aladhan API
final response = await http.get(Uri.parse(
  'https://api.aladhan.com/v1/timingsByCity/$dateStr?city=Dhaka&country=Bangladesh&method=2'
));
final data = json.decode(response.body);
final fajr = data['data']['timings']['Fajr'];
```

### After (Offline):

```dart
// New code - 100% offline
final times = AdhanService.getPrayerTimesBengali(
  latitude: 23.8103,
  longitude: 90.4125,
);
final fajr = times['ফজর'];
```

---

## 📊 Comparison: API vs Offline

| Feature | API (Aladhan) | Offline (adhan_dart) |
|---------|---------------|----------------------|
| **Internet Required** | ✅ Yes | ❌ No |
| **Speed** | Slow (network) | ⚡ Instant |
| **Accuracy** | High | High |
| **Offline Support** | ❌ No | ✅ Yes |
| **API Limits** | Yes | No |
| **Cost** | Free (but limited) | Free |
| **Privacy** | Sends location | 100% Local |
| **Reliability** | Depends on API | Always works |

---

## 🎨 Widget Customization

```dart
OfflinePrayerTimesWidget(
  latitude: 23.8103,
  longitude: 90.4125,
  isDark: true, // Dark theme
)
```

---

## 🌍 Location Setup

### Option 1: Use Geolocator (Already in your app)

```dart
import 'package:geolocator/geolocator.dart';

// Get current location
final position = await Geolocator.getCurrentPosition();

// Use in widget
OfflinePrayerTimesWidget(
  latitude: position.latitude,
  longitude: position.longitude,
)
```

### Option 2: Hardcode for Specific City

```dart
// Dhaka, Bangladesh
OfflinePrayerTimesWidget(
  latitude: 23.8103,
  longitude: 90.4125,
)

// Chittagong, Bangladesh
OfflinePrayerTimesWidget(
  latitude: 22.3569,
  longitude: 91.7832,
)

// Sylhet, Bangladesh
OfflinePrayerTimesWidget(
  latitude: 24.8949,
  longitude: 91.8687,
)
```

---

## 🔧 Integration Example

### Replace in Home Screen:

```dart
import 'package:flutter/material.dart';
import 'package:muslim_view/widgets/offline_prayer_times_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Poster Carousel
            const PosterCarouselWidget(
              height: 180,
              autoSlide: true,
            ),
            
            const SizedBox(height: 16),
            
            // Offline Prayer Times
            Padding(
              padding: const EdgeInsets.all(16),
              child: OfflinePrayerTimesWidget(
                latitude: 23.8103,  // Dhaka
                longitude: 90.4125,
                isDark: false,
              ),
            ),
            
            // Other content...
          ],
        ),
      ),
    );
  }
}
```

---

## 🐛 Troubleshooting

### Problem: Times are incorrect
**Solution:** Check if you're using the correct calculation method for your region. Bangladesh uses Karachi method.

### Problem: Location not working
**Solution:** Make sure you have location permissions enabled.

### Problem: Hijri date is off by 1 day
**Solution:** This is normal. Hijri calendar depends on moon sighting and can vary by location.

---

## ✨ Benefits of Offline Solution

1. **⚡ Faster** - No network delay
2. **🔒 Privacy** - No data sent to servers
3. **💰 Free** - No API costs or limits
4. **📱 Offline** - Works without internet
5. **🎯 Accurate** - Same accuracy as API
6. **🔋 Battery** - No network usage
7. **🌍 Global** - Works anywhere
8. **🚀 Reliable** - No API downtime

---

## 📝 Summary

✅ **Installed Packages:**
- `adhan_dart: 1.2.0`
- `hijri: ^3.0.0`

✅ **Created Files:**
- `lib/services/adhan_service.dart` - Core service
- `lib/widgets/offline_prayer_times_widget.dart` - UI widget

✅ **Features:**
- Prayer times calculation (offline)
- Hijri calendar
- Next prayer countdown
- Islamic events
- Qibla direction
- Monthly prayer times

✅ **No API Required:**
- 100% offline
- No internet needed
- Instant calculations
- Always reliable

---

## 🎉 Test It!

```bash
flutter run
```

**Your prayer times now work 100% offline!** 🕌✨
