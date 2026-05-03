# Prayer Alarm System - Integration Guide

## 🎯 How to Add to Your Existing App

This guide shows you how to integrate the Prayer Alarm System into your existing Islamic dashboard or home screen.

## Option 1: Add to Islamic Dashboard (Recommended)

### Step 1: Import Navigation Helper

```dart
import 'screens/IslamicFeatures/prayer_times_navigation.dart';
```

### Step 2: Add Cards to Dashboard

In your `islamicdashboard.dart` or similar file:

```dart
// Inside your GridView or Column
PrayerTimesCard(),
PrayerAlarmCard(),
```

**Full Example:**

```dart
class IslamicDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ইসলামিক ড্যাশবোর্ড')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // Existing cards...
          PrayerTimesCard(),
          PrayerAlarmCard(),
          // More cards...
        ],
      ),
    );
  }
}
```

## Option 2: Add to Navigation Drawer

```dart
import 'screens/IslamicFeatures/prayer_times_navigation.dart';

Drawer(
  child: ListView(
    children: [
      // Existing items...
      PrayerTimesListTile(),
      PrayerAlarmListTile(),
      // More items...
    ],
  ),
)
```

## Option 3: Add to App Bar

```dart
import 'screens/IslamicFeatures/prayer_times_navigation.dart';

AppBar(
  title: Text('নূরভিয়া'),
  actions: [
    PrayerTimesIconButton(),
    PrayerAlarmIconButton(),
  ],
)
```

## Option 4: Custom Button

```dart
import 'screens/IslamicFeatures/prayer_times_navigation.dart';

ElevatedButton(
  onPressed: () => navigateToPrayerTimes(context),
  child: Text('নামাজের সময়'),
)

// Or for alarm settings
ElevatedButton(
  onPressed: () => navigateToPrayerAlarmSettings(context),
  child: Text('আযান সেটিংস'),
)
```

## Option 5: Replace Existing Prayer Time Screen

If you already have a prayer time screen (like `namaztime.dart`), you can replace it:

### In your navigation code:

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => MonthlyPrayerTimesScreen()),
);
```

**After:**
```dart
import 'screens/IslamicFeatures/prayer_times_navigation.dart';

navigateToPrayerTimes(context);
```

## Complete Integration Example

Here's a complete example showing how to add to your Islamic Features page:

```dart
// lib/screens/IslamicFeatures/islamicdashboard.dart

import 'package:flutter/material.dart';
import 'prayer_times_navigation.dart';

class IslamicDashboard extends StatelessWidget {
  const IslamicDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইসলামিক ফিচার'),
        actions: [
          PrayerTimesIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Prayer Times Card
            PrayerTimesCard(),
            const SizedBox(height: 16),
            
            // Prayer Alarm Card
            PrayerAlarmCard(),
            const SizedBox(height: 16),
            
            // Your existing features...
            _buildFeatureCard(
              context,
              'কুরআন',
              Icons.book_rounded,
              () {/* Navigate to Quran */},
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              context,
              'হাদিস',
              Icons.menu_book_rounded,
              () {/* Navigate to Hadith */},
            ),
            // More features...
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Testing Your Integration

After integration, test the following:

1. **Navigation Works**
   - Tap on Prayer Times card → Opens Prayer Times page
   - Tap on Alarm Settings card → Opens Alarm Settings page

2. **Back Navigation**
   - Press back button → Returns to previous screen
   - Navigation stack is correct

3. **State Persistence**
   - Change alarm settings
   - Navigate away and back
   - Settings should be saved

4. **Providers Available**
   - Prayer times load correctly
   - Alarm settings load correctly
   - No provider errors in console

## Troubleshooting

### Issue: "Could not find provider"

**Solution:** Make sure providers are added in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PrayerProvider()),
    ChangeNotifierProvider(create: (_) => PrayerAlarmProvider()),
    // ... other providers
  ],
  child: MaterialApp(...),
)
```

### Issue: Navigation not working

**Solution:** Check import statement:

```dart
import 'screens/IslamicFeatures/prayer_times_navigation.dart';
```

### Issue: Cards not displaying correctly

**Solution:** Wrap in proper parent widget:

```dart
// Good
Column(
  children: [
    PrayerTimesCard(),
  ],
)

// Also good
GridView(
  children: [
    PrayerTimesCard(),
  ],
)
```

## Customization

### Change Card Colors

Edit `prayer_times_navigation.dart`:

```dart
gradient: LinearGradient(
  colors: [
    Colors.blue,  // Change this
    Colors.blue.withOpacity(0.7),  // And this
  ],
  // ...
),
```

### Change Card Text

Edit the text in `prayer_times_navigation.dart`:

```dart
const Text(
  'Your Custom Title',  // Change this
  style: TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
```

### Add Custom Icons

```dart
const Icon(
  Icons.your_icon_here,  // Change this
  color: Colors.white,
  size: 24,
),
```

## Best Practices

1. **Use Navigation Helper**
   - Always use `navigateToPrayerTimes()` and `navigateToPrayerAlarmSettings()`
   - Don't create MaterialPageRoute manually

2. **Use Pre-built Widgets**
   - Use `PrayerTimesCard`, `PrayerAlarmCard`, etc.
   - Consistent design across app

3. **Test on Device**
   - Always test navigation on physical device
   - Check back button behavior
   - Verify state persistence

4. **Handle Permissions**
   - Ensure location permission is granted
   - Check notification permission
   - Handle permission denials gracefully

## Quick Reference

### Available Widgets

| Widget | Use Case | Example |
|--------|----------|---------|
| `PrayerTimesCard` | Dashboard grid/list | `PrayerTimesCard()` |
| `PrayerAlarmCard` | Dashboard grid/list | `PrayerAlarmCard()` |
| `PrayerTimesListTile` | Drawer/Settings | `PrayerTimesListTile()` |
| `PrayerAlarmListTile` | Drawer/Settings | `PrayerAlarmListTile()` |
| `PrayerTimesIconButton` | App bar | `PrayerTimesIconButton()` |
| `PrayerAlarmIconButton` | App bar | `PrayerAlarmIconButton()` |

### Available Functions

| Function | Purpose |
|----------|---------|
| `navigateToPrayerTimes(context)` | Navigate to prayer times page |
| `navigateToPrayerAlarmSettings(context)` | Navigate to alarm settings page |

## Next Steps

After integration:

1. ✅ Test navigation
2. ✅ Add audio files
3. ✅ Test alarms
4. ✅ Configure permissions
5. ✅ Test on device
6. ✅ Deploy to users

## Support

If you encounter issues:
1. Check `PRAYER_ALARM_IMPLEMENTATION.md` for detailed docs
2. Review `PRAYER_ALARM_QUICK_START.md` for setup
3. Check code comments in source files
4. Test with debug logging

---

**Happy Coding! 🎉**
