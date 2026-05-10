# 🚀 Quick Start - আমার মসজিদ Feature

## ⚡ 30-Second Integration

### Step 1: Import
```dart
import 'package:muslim_view/widgets/amar_mosjid_button.dart';
```

### Step 2: Add Button
```dart
AmarMosjidButton()
```

### Step 3: Done! ✅

---

## 🎯 Where to Add?

### Home Screen
```dart
// lib/screens/home/home_screen.dart
Column(
  children: [
    AmarMosjidButton(),  // ← Add here
  ],
)
```

### Islamic Features
```dart
// lib/screens/IslamicFeatures/
GridView(
  children: [
    // Your features...
    AmarMosjidButton(isCompact: true),  // ← Add here
  ],
)
```

### Navigation Drawer
```dart
import 'package:muslim_view/screens/location/nearby_mosques_screen.dart';

ListTile(
  leading: Icon(Icons.mosque),
  title: Text('আমার মসজিদ'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NearbyMosquesScreen()),
  ),
)
```

---

## 🧪 Test Immediately

### Run Demo Screen
```dart
import 'package:muslim_view/screens/location/mosque_finder_demo.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => MosqueFinderDemo()),
);
```

---

## 📱 Platform Setup

### Android ✅
Already configured! No action needed.

### iOS ⚠️
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>আশেপাশের মসজিদ খুঁজতে আপনার লোকেশন প্রয়োজন</string>
```

---

## 🎨 Button Styles

### Full Button (Default)
```dart
AmarMosjidButton()
```
![Full width card with gradient]

### Compact Button
```dart
AmarMosjidButton(isCompact: true)
```
![Small button]

### Custom Button
```dart
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NearbyMosquesScreen()),
  ),
  child: Text('আমার মসজিদ'),
)
```

---

## 📚 Full Documentation

- **Complete Guide**: `MOSQUE_FINDER_GUIDE.md`
- **Integration Guide**: `MOSQUE_FINDER_INTEGRATION.md`
- **Summary**: `MOSQUE_FINDER_SUMMARY.md`

---

## ✅ Checklist

- [ ] Import button widget
- [ ] Add button to your screen
- [ ] Test on real device
- [ ] Grant location permission
- [ ] See nearby mosques!

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| No mosques found | Increase search radius |
| Permission denied | Enable in device settings |
| No internet | Check connection |
| Can't import | Check file path |

---

## 🎉 That's It!

You're ready to use the mosque finder feature!

**Total Time**: 2 minutes
**Total Code**: 2 lines
**Total Effort**: Minimal

---

**Need help?** Check the full guides in the documentation files.

**May Allah accept this work. Ameen. 🤲**
