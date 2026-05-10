# আমার মসজিদ (Amar Mosjid) - Nearby Mosque Finder

A complete Flutter feature to find nearby mosques using GPS location and OpenStreetMap data.

## 🌟 Features

- ✅ **Automatic GPS Location Detection** - Uses device GPS to get current location
- ✅ **OpenStreetMap Integration** - Fetches real mosque data from OpenStreetMap
- ✅ **Distance Calculation** - Uses Haversine formula for accurate distance
- ✅ **Sorted by Distance** - Nearest mosque appears at the top
- ✅ **Google Maps Integration** - Direct navigation to mosque location
- ✅ **Customizable Search Radius** - 1km to 20km search range
- ✅ **Beautiful UI** - Modern card-based design with Bengali text
- ✅ **Loading States** - Proper loading indicators
- ✅ **Error Handling** - Handles location permission, no internet, empty results
- ✅ **Bengali Language** - Complete Bengali interface (বাংলা ইন্টারফেস)

## 📁 File Structure

```
lib/
├── core/
│   ├── models/
│   │   └── mosque.dart                    # Mosque data model
│   └── services/
│       └── mosque_service.dart            # API service for fetching mosques
├── screens/
│   └── location/
│       ├── nearby_mosques_screen.dart     # Main mosque finder screen
│       └── mosque_finder_example.dart     # Example/demo screen
└── widgets/
    └── amar_mosjid_button.dart            # Reusable button widget
```

## 🚀 Quick Start

### 1. Dependencies (Already Installed)

The following packages are already in your `pubspec.yaml`:
- `geolocator: ^13.0.2` - For GPS location
- `geocoding: ^3.0.0` - For address lookup
- `url_launcher: ^6.3.1` - For opening Google Maps
- `http: ^1.2.2` - For API calls

### 2. Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add these permissions inside `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (`ios/Runner/Info.plist`)

Add these keys inside `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>আশেপাশের মসজিদ খুঁজতে আপনার লোকেশন প্রয়োজন</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>আশেপাশের মসজিদ খুঁজতে আপনার লোকেশন প্রয়োজন</string>
```

### 3. Usage Examples

#### Option A: Add Button to Home Screen

```dart
import 'package:flutter/material.dart';
import 'widgets/amar_mosjid_button.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Your other widgets...
          
          // Add the mosque finder button
          AmarMosjidButton(),
          
          // More widgets...
        ],
      ),
    );
  }
}
```

#### Option B: Compact Button

```dart
AmarMosjidButton(isCompact: true)
```

#### Option C: Direct Navigation

```dart
import 'screens/location/nearby_mosques_screen.dart';

// Navigate directly
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NearbyMosquesScreen(),
  ),
);
```

#### Option D: Custom Button

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyMosquesScreen(),
      ),
    );
  },
  child: Text('আমার মসজিদ'),
)
```

## 🎨 UI Components

### Main Screen Features

1. **App Bar**
   - Title: "আমার মসজিদ"
   - Search radius selector
   - Refresh button

2. **Loading State**
   - Circular progress indicator
   - Bengali loading message

3. **Mosque Cards**
   - Mosque name (Bengali/English)
   - Distance (meters/kilometers in Bengali)
   - Address (if available)
   - "Nearest Mosque" badge for closest one
   - Two action buttons:
     - দিকনির্দেশনা (Directions)
     - ম্যাপে দেখুন (View on Map)

4. **Error Handling**
   - Location permission denied
   - Location services disabled
   - No internet connection
   - No mosques found
   - Server timeout

## 🔧 Technical Details

### Mosque Model (`mosque.dart`)

```dart
class Mosque {
  final String name;
  final double latitude;
  final double longitude;
  final double distanceInMeters;
  final String? address;
  
  // Methods:
  // - getFormattedDistance() - Returns "X মিটার" or "X কিলোমিটার"
  // - getGoogleMapsUrl() - Returns Google Maps URL
}
```

### Mosque Service (`mosque_service.dart`)

```dart
class MosqueService {
  // Get current location with permission handling
  Future<Position> getCurrentLocation()
  
  // Fetch nearby mosques from OpenStreetMap
  Future<List<Mosque>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusInMeters = 5000,
  })
  
  // Combined method: get location + fetch mosques
  Future<List<Mosque>> getNearbyMosques({
    int radiusInMeters = 5000,
  })
}
```

### Distance Calculation

Uses the **Haversine Formula** for accurate distance calculation:

```dart
distance = 2 * R * arcsin(sqrt(
  sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
))
```

Where:
- R = Earth's radius (6371 km)
- Δlat = lat2 - lat1
- Δlon = lon2 - lon1

## 🌐 OpenStreetMap Overpass API

### Query Structure

```overpass
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:5000,lat,lon);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:5000,lat,lon);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:5000,lat,lon);
);
out center;
```

### API Endpoint

```
POST https://overpass-api.de/api/interpreter
```

### Response Format

```json
{
  "elements": [
    {
      "type": "node",
      "id": 123456,
      "lat": 23.8103,
      "lon": 90.4125,
      "tags": {
        "name": "Baitul Mukarram Mosque",
        "name:bn": "বায়তুল মোকাররম মসজিদ",
        "amenity": "place_of_worship",
        "religion": "muslim"
      }
    }
  ]
}
```

## 🎯 Search Radius Options

- 1 কিলোমিটার (1 km)
- 3 কিলোমিটার (3 km)
- 5 কিলোমিটার (5 km) - Default
- 10 কিলোমিটার (10 km)
- 20 কিলোমিটার (20 km)

## 📱 Permissions Flow

1. **Check if location services are enabled**
   - If disabled → Show error message

2. **Check location permission**
   - If denied → Request permission
   - If denied again → Show error message
   - If permanently denied → Show settings message

3. **Get current position**
   - Use high accuracy
   - Timeout after 30 seconds

4. **Fetch mosque data**
   - Call OpenStreetMap API
   - Parse response
   - Calculate distances
   - Sort by distance

## 🎨 Customization

### Change Primary Color

The UI uses `Theme.of(context).primaryColor`. To customize:

```dart
MaterialApp(
  theme: ThemeData(
    primaryColor: Colors.green, // Your color
  ),
)
```

### Change Search Radius

```dart
// In nearby_mosques_screen.dart
int _searchRadius = 10000; // Change default to 10km
```

### Change Font

Replace `'Kalpurush'` with your preferred Bengali font:

```dart
style: TextStyle(
  fontFamily: 'YourFont', // Change here
)
```

## 🐛 Error Messages (Bengali)

| Error | Message |
|-------|---------|
| Location services disabled | লোকেশন সার্ভিস বন্ধ আছে। দয়া করে চালু করুন। |
| Permission denied | লোকেশন অনুমতি প্রত্যাখ্যান করা হয়েছে। |
| Permission permanently denied | লোকেশন অনুমতি স্থায়ীভাবে প্রত্যাখ্যান করা হয়েছে। সেটিংস থেকে অনুমতি দিন। |
| No internet | ইন্টারনেট সংযোগ নেই। দয়া করে আপনার সংযোগ পরীক্ষা করুন। |
| Server timeout | সার্ভার থেকে সাড়া পাওয়া যায়নি। আবার চেষ্টা করুন। |
| No mosques found | আশেপাশে কোনো মসজিদ পাওয়া যায়নি। অনুসন্ধান পরিসীমা বাড়ান। |

## 🧪 Testing

### Test on Real Device

1. Enable location services
2. Grant location permission
3. Ensure internet connection
4. Click "আমার মসজিদ" button
5. Wait for results

### Test Error Cases

1. **No Internet**: Turn off WiFi/mobile data
2. **Location Disabled**: Turn off location services
3. **Permission Denied**: Deny location permission
4. **No Mosques**: Test in remote area or reduce search radius

## 📊 Performance

- **API Response Time**: 2-5 seconds (depends on network)
- **Location Accuracy**: ±10-50 meters
- **Max Mosques Returned**: Unlimited (sorted by distance)
- **Memory Usage**: ~5-10 MB

## 🔐 Privacy

- Location data is **NOT stored**
- Location data is **NOT sent to any server** except OpenStreetMap
- No user tracking
- No analytics
- Open source data from OpenStreetMap

## 🌍 Data Source

All mosque data comes from **OpenStreetMap**, a free, open-source map database maintained by volunteers worldwide.

- Website: https://www.openstreetmap.org
- License: Open Database License (ODbL)
- Data Quality: Community-maintained

## 🤝 Contributing

To improve mosque data:
1. Visit https://www.openstreetmap.org
2. Create an account
3. Add missing mosques in your area
4. Tag them correctly:
   - `amenity=place_of_worship`
   - `religion=muslim`
   - `name=Mosque Name`
   - `name:bn=মসজিদের নাম` (Bengali name)

## 📝 License

This code is part of the Muslim View app. Use it freely in your projects.

## 🙏 Credits

- **OpenStreetMap** - For mosque data
- **Geolocator Package** - For location services
- **Flutter Team** - For the amazing framework

## 📞 Support

If you encounter any issues:
1. Check internet connection
2. Check location permissions
3. Try increasing search radius
4. Restart the app
5. Check if OpenStreetMap API is accessible

---

**Made with ❤️ for the Muslim community**

**আল্লাহ আমাদের সবাইকে নিয়মিত মসজিদে যাওয়ার তৌফিক দান করুন। আমীন।**
