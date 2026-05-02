# ⚙️ নূরভিয়া — Global Settings System

## 🎯 Overview

নূরভিয়া অ্যাপে **সব settings globally apply হয়** — font, size, color, theme সব কিছু পুরো অ্যাপে একসাথে change হয়।

---

## ✅ What's Included

### 🔤 Font Settings
- **Bangla Font:** 5 options (Hind Siliguri, Baloo 2, Noto Sans Bengali, Galada, Tiro Devanagari)
- **Arabic Font:** 5 options (Amiri, Scheherazade New, Noto Naskh Arabic, Lateef, Reem Kufi)
- **Font Size:** Bangla (10-26), Arabic (14-36)
- **Font Weight:** 5 weights (Light to Bold)
- **Line Height:** 1.0-2.5

### 🎨 Theme Settings
- **Dark Mode:** Manual toggle
- **Auto Theme:** Time-based (6 AM - 6 PM light, 6 PM - 6 AM dark)
- **Accent Color:** 7 colors (Purple, Blue, Green, Orange, Violet, Teal, Red)

### 🖥️ Display Settings
- **Text Scale:** 80%-140%
- **Colored Cards:** Enable/disable
- **Animations:** Enable/disable
- **Compact Mode:** Enable/disable

---

## 📍 Where to Find Settings

Settings accessible from **3 locations**:

1. **Bottom Navigation Bar** → ⚙️ "সেটিংস" (rightmost icon)
2. **App Bar** → ⚙️ Settings button (top right)
3. **Drawer Menu** → ⚙️ "সেটিংস" option

---

## 🔧 How It Works

### Architecture

```
User changes setting in Settings Screen
         ↓
SettingsProvider.notifyListeners()
         ↓
MaterialApp theme rebuilds
         ↓
All screens automatically update
         ↓
Setting saved to SharedPreferences
```

### Key Files

```
lib/
├── core/
│   ├── providers/
│   │   ├── settings_provider.dart      ← All settings logic
│   │   └── theme_provider.dart         ← Dark/light mode
│   ├── theme/
│   │   └── app_theme.dart              ← Theme builder
│   └── utils/
│       ├── text_styles.dart            ← Helper extension
│       └── global_settings_usage_guide.dart  ← Examples
├── screens/
│   └── settings/
│       └── settings_screen.dart        ← Settings UI
└── main.dart                           ← Provider setup
```

---

## 💻 Usage for Developers

### Method 1: Direct Access

```dart
import 'package:provider/provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return Text(
      'আসসালামু আলাইকুম',
      style: settings.banglaFont.style(
        fontSize: settings.fontSize,
        fontWeight: settings.fontWeight,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
    );
  }
}
```

### Method 2: Helper Extension (Recommended)

```dart
import '../core/utils/text_styles.dart';

// Bangla text
Text('আসসালামু আলাইকুম', style: context.banglaBody)
Text('ইসলামিক জ্ঞান', style: context.banglaHeading)
Text('বিস্তারিত', style: context.banglaSubtitle)

// Arabic text
Text('بِسْمِ اللَّهِ', 
  style: context.arabicText, 
  textDirection: TextDirection.rtl)

// Theme colors
Container(color: context.bgColor)
Icon(Icons.star, color: context.accentColor)

// Custom
Text('কাস্টম', style: context.banglaCust(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: Colors.red,
))
```

---

## 📚 Available Styles (via Extension)

### Bangla Styles
- `context.banglaBody` — Default body text
- `context.banglaHeading` — Large heading
- `context.banglaTitle` — Medium title
- `context.banglaSubtitle` — Small subtitle
- `context.banglaCaption` — Tiny caption
- `context.banglaButton` — Button text
- `context.banglaCust(...)` — Custom parameters

### Arabic Styles
- `context.arabicText` — Default Arabic text
- `context.arabicHeading` — Large Arabic heading
- `context.arabicSubtitle` — Small Arabic subtitle
- `context.arabicCust(...)` — Custom parameters

### Theme Helpers
- `context.textColor` — Primary text color
- `context.subTextColor` — Secondary text color
- `context.bgColor` — Background color
- `context.cardColor` — Card background color
- `context.accentColor` — User's accent color
- `context.isDark` — Is dark mode active
- `context.settings` — Full SettingsProvider access

---

## 🎨 Settings Screen Features

### Complete UI Sections

1. **Profile Card** — User info with gradient background
2. **Theme Section** — Dark mode + Auto theme toggles
3. **Accent Color** — 7 color options with visual picker
4. **Bangla Font** — Dropdown + live preview + size/weight sliders
5. **Arabic Font** — Dropdown + live preview + size slider
6. **Display** — Text scale + toggles for cards/animations/compact
7. **About** — App version + links
8. **Reset** — Reset all to defaults with confirmation

---

## 🔄 Persistence

All settings automatically save to **SharedPreferences**:
- Settings survive app restarts
- No manual save needed
- Instant apply + save on change

---

## ✅ Verification

See `GLOBAL_SETTINGS_VERIFICATION.md` for complete verification checklist.

**Status:** ✅ All settings globally applied and verified

---

## 📖 Documentation Files

1. **README_SETTINGS.md** (this file) — Quick overview
2. **GLOBAL_SETTINGS_VERIFICATION.md** — Complete verification
3. **lib/core/utils/global_settings_usage_guide.dart** — Code examples
4. **lib/core/utils/text_styles.dart** — Helper extension

---

## 🚀 Quick Start

### For Users
1. Open app
2. Tap ⚙️ Settings (bottom nav, app bar, or drawer)
3. Change any setting
4. See changes apply instantly throughout app

### For Developers
1. Import helper: `import '../core/utils/text_styles.dart';`
2. Use extension: `Text('টেক্সট', style: context.banglaBody)`
3. Done! Settings automatically apply

---

## 🎯 Summary

✅ **15+ settings** available  
✅ **10 fonts** (5 Bangla + 5 Arabic)  
✅ **7 accent colors**  
✅ **3 access points** to settings  
✅ **Global application** via Provider  
✅ **Persistent storage** via SharedPreferences  
✅ **Helper utilities** for easy usage  
✅ **Zero configuration** needed  

**Everything works globally. Change once, apply everywhere.** 🎉
