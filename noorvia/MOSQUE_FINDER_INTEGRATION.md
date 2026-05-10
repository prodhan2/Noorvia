# How to Integrate "আমার মসজিদ" Feature into Your App

## ✅ What's Already Done

All the necessary files have been created:

1. ✅ **Model**: `lib/core/models/mosque.dart`
2. ✅ **Service**: `lib/core/services/mosque_service.dart`
3. ✅ **Screen**: `lib/screens/location/nearby_mosques_screen.dart`
4. ✅ **Widget**: `lib/widgets/amar_mosjid_button.dart`
5. ✅ **Example**: `lib/screens/location/mosque_finder_example.dart`
6. ✅ **Dependencies**: Already in pubspec.yaml (geolocator, http, url_launcher)
7. ✅ **Permissions**: Already configured in AndroidManifest.xml

## 🚀 Quick Integration (3 Steps)

### Step 1: Import the Button Widget

In any screen where you want to add the mosque finder button, add this import:

```dart
import 'package:muslim_view/widgets/amar_mosjid_button.dart';
```

### Step 2: Add the Button

Add the button widget anywhere in your UI:

```dart
// Full-width card button (recommended for home screen)
AmarMosjidButton()

// OR compact button
AmarMosjidButton(isCompact: true)
```

### Step 3: Run the App

That's it! The button is ready to use.

---

## 📍 Integration Examples

### Example 1: Add to Home Screen

If you have a home screen with a list of features:

```dart
// In lib/screens/home/home_screen.dart or similar

import 'package:flutter/material.dart';
import '../../widgets/amar_mosjid_button.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('হোম')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your existing widgets...
            
            // Add mosque finder button
            AmarMosjidButton(),
            
            // More widgets...
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Add to Islamic Features Screen

```dart
// In lib/screens/IslamicFeatures/islamic_features_screen.dart

import '../../widgets/amar_mosjid_button.dart';

// Inside your build method:
GridView.count(
  crossAxisCount: 2,
  children: [
    // Your existing feature cards...
    
    // Add as a grid item
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NearbyMosquesScreen(),
          ),
        );
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mosque, size: 48),
            SizedBox(height: 8),
            Text('আমার মসজিদ', style: TextStyle(fontFamily: 'Kalpurush')),
          ],
        ),
      ),
    ),
  ],
)
```

### Example 3: Add to Navigation Drawer

```dart
// In your drawer widget

import '../screens/location/nearby_mosques_screen.dart';

Drawer(
  child: ListView(
    children: [
      // Your existing drawer items...
      
      ListTile(
        leading: Icon(Icons.mosque),
        title: Text('আমার মসজিদ', style: TextStyle(fontFamily: 'Kalpurush')),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NearbyMosquesScreen(),
            ),
          );
        },
      ),
    ],
  ),
)
```

### Example 4: Add to Bottom Navigation

```dart
// If you have bottom navigation

BottomNavigationBar(
  items: [
    // Your existing items...
    BottomNavigationBarItem(
      icon: Icon(Icons.mosque),
      label: 'মসজিদ',
    ),
  ],
  onTap: (index) {
    if (index == yourMosqueIndex) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyMosquesScreen(),
        ),
      );
    }
  },
)
```

### Example 5: Add as Floating Action Button

```dart
Scaffold(
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NearbyMosquesScreen(),
        ),
      );
    },
    icon: Icon(Icons.mosque),
    label: Text('আমার মসজিদ', style: TextStyle(fontFamily: 'Kalpurush')),
  ),
)
```

---

## 🎨 Customization Options

### Change Button Colors

```dart
// Modify lib/widgets/amar_mosjid_button.dart

// Change gradient colors
gradient: LinearGradient(
  colors: [
    Colors.green,        // Your primary color
    Colors.green[700]!,  // Your secondary color
  ],
)
```

### Change Button Text

```dart
// In amar_mosjid_button.dart, change:
Text('আমার মসজিদ')  // to your preferred text
Text('আশেপাশের মসজিদ খুঁজুন')  // to your preferred subtitle
```

### Change Default Search Radius

```dart
// In lib/screens/location/nearby_mosques_screen.dart

// Change this line:
int _searchRadius = 5000; // Change to 3000, 10000, etc.
```

### Change App Bar Title

```dart
// In nearby_mosques_screen.dart

AppBar(
  title: Text('নিকটবর্তী মসজিদ'), // Your preferred title
)
```

---

## 🧪 Testing Checklist

After integration, test these scenarios:

- [ ] Button appears correctly in your UI
- [ ] Clicking button navigates to mosque screen
- [ ] Location permission is requested
- [ ] Loading indicator appears while fetching
- [ ] Mosque list displays correctly
- [ ] Distance is shown in Bengali
- [ ] Nearest mosque has special badge
- [ ] "View on Map" button opens Google Maps
- [ ] "Directions" button opens Google Maps
- [ ] Search radius can be changed
- [ ] Refresh button works
- [ ] Error messages appear in Bengali
- [ ] Works without internet (shows error)
- [ ] Works when location is disabled (shows error)

---

## 🐛 Troubleshooting

### Issue: Button doesn't appear

**Solution**: Make sure you imported the widget:
```dart
import 'package:muslim_view/widgets/amar_mosjid_button.dart';
```

### Issue: "Cannot find NearbyMosquesScreen"

**Solution**: Import the screen:
```dart
import 'package:muslim_view/screens/location/nearby_mosques_screen.dart';
```

### Issue: Location permission not working

**Solution**: 
1. Check AndroidManifest.xml has location permissions (already done)
2. For iOS, check Info.plist has location usage descriptions
3. Test on real device (emulator may have issues)

### Issue: No mosques found

**Solution**:
1. Increase search radius (click tune icon)
2. Check internet connection
3. Try in a different location
4. OpenStreetMap may not have data for your area

### Issue: Google Maps doesn't open

**Solution**:
1. Make sure Google Maps is installed on device
2. Check url_launcher package is working
3. Check queries section in AndroidManifest.xml (already configured)

### Issue: Bengali text not showing

**Solution**:
1. Make sure Kalpurush font is in your assets
2. Check pubspec.yaml has font configuration
3. Or change fontFamily to your Bengali font

---

## 📱 Platform-Specific Notes

### Android
- ✅ All permissions already configured
- ✅ Internet permission included
- ✅ Location permissions included
- ✅ Google Maps intent configured

### iOS
Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>আশেপাশের মসজিদ খুঁজতে আপনার লোকেশন প্রয়োজন</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>আশেপাশের মসজিদ খুঁজতে আপনার লোকেশন প্রয়োজন</string>
```

### Web
- Location API works in modern browsers
- Requires HTTPS in production
- May need user permission

---

## 🎯 Recommended Placement

Based on your app structure, here are the best places to add the mosque finder:

1. **Home Screen** - Most visible, easy access
2. **Islamic Features Screen** - Logical grouping with other Islamic features
3. **Tools Screen** - If you have a tools/utilities section
4. **Navigation Drawer** - Always accessible from anywhere
5. **Location Screen** - If you have a location-related section

---

## 📊 Expected Behavior

1. **First Time Use**:
   - User clicks "আমার মসজিদ" button
   - App requests location permission
   - User grants permission
   - App gets GPS location (2-5 seconds)
   - App fetches mosques from OpenStreetMap (2-5 seconds)
   - Mosque list appears, sorted by distance

2. **Subsequent Uses**:
   - Permission already granted
   - Faster location detection
   - Immediate mosque list display

3. **Offline**:
   - Shows error: "ইন্টারনেট সংযোগ নেই"
   - Retry button available

4. **No Mosques**:
   - Shows empty state
   - Suggests increasing search radius

---

## 🔄 Future Enhancements (Optional)

You can extend this feature with:

- [ ] Save favorite mosques
- [ ] Show mosque photos
- [ ] Display prayer times for each mosque
- [ ] Add mosque reviews/ratings
- [ ] Show mosque facilities (parking, wudu area, etc.)
- [ ] Filter by mosque type (Jummah, Eid, etc.)
- [ ] Offline caching of mosque data
- [ ] Share mosque location with friends
- [ ] Get notifications for nearby mosques

---

## 📞 Need Help?

If you encounter any issues:

1. Check the main guide: `MOSQUE_FINDER_GUIDE.md`
2. Review the example: `lib/screens/location/mosque_finder_example.dart`
3. Test the example screen first before integrating
4. Check console logs for error messages

---

**Happy Coding! 🚀**

**May Allah accept our efforts. Ameen. 🤲**
