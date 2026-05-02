# Custom Bangla Fonts Implementation

## Overview
The app now supports loading custom Bangla fonts from GitHub repository. Users can select from 40+ custom TTF fonts in addition to the 5 built-in Google Fonts.

## Features

### 1. **Font Loading from GitHub**
- Fetches font list from: `https://github.com/prodhan2/beautifulDinajpurFrames/tree/main/font`
- Uses GitHub API to get list of TTF files
- Filters out non-font files (like .py scripts)

### 2. **Caching System**
- **Cache Duration**: 7 days
- **Storage**: SharedPreferences
- **Benefits**: 
  - Reduces network calls
  - Works offline after first load
  - Faster app startup

### 3. **Font Management**
- **Built-in Fonts** (5):
  - Hind Siliguri
  - Baloo 2
  - Noto Sans Bengali
  - Galada
  - Tiro Devanagari

- **Custom Fonts** (40+):
  - Anane, Bely, Bhramari, Chanchal, Jui, Juthi, Jomuna, Padma, Rajani, Rinkiy, Shurma, Siyamrupali, Teeshta, and many more

### 4. **User Interface**
- **Settings Screen** → **কাস্টম বাংলা ফন্ট** section
- Shows loading indicator while fetching fonts
- Dropdown to select custom font
- Live preview of selected font
- Button to return to built-in fonts
- Refresh button if loading fails

## Technical Implementation

### Files Modified

1. **`lib/core/services/custom_font_loader.dart`**
   - Service to fetch and cache fonts from GitHub
   - Uses GitHub API instead of static file list
   - Implements 7-day caching mechanism

2. **`lib/core/providers/settings_provider.dart`**
   - Added custom font state management
   - `List<CustomBanglaFont> customFonts` - available fonts
   - `CustomBanglaFont? selectedCustomFont` - currently selected
   - `bool isLoadingCustomFonts` - loading state
   - `Map<String, String> _loadedCustomFonts` - loaded font cache
   - New methods:
     - `setCustomFont(CustomBanglaFont)` - select custom font
     - `getCurrentFontStyle()` - get style for current font (built-in or custom)
     - `refreshCustomFonts()` - force reload from GitHub

3. **`lib/screens/settings/settings_screen.dart`**
   - Added "কাস্টম বাংলা ফন্ট" section
   - Custom font dropdown widget
   - Loading and error states
   - Font preview
   - Clear custom font button

4. **`lib/core/utils/text_styles.dart`**
   - Updated to use `getCurrentFontStyle()` method
   - Automatically uses custom font when selected
   - Falls back to built-in font when no custom font selected

## How It Works

### Font Loading Flow

```
App Start
    ↓
SettingsProvider._loadCustomFonts()
    ↓
CustomFontLoader.getCustomFonts()
    ↓
Check Cache (7 days)
    ↓
    ├─ Valid Cache → Return cached fonts
    └─ No Cache/Expired → Fetch from GitHub API
           ↓
       Parse TTF files
           ↓
       Cache for 7 days
           ↓
       Return font list
```

### Font Selection Flow

```
User selects custom font
    ↓
SettingsProvider.setCustomFont()
    ↓
Check if font already loaded
    ↓
    ├─ Not loaded → Download TTF from GitHub
    │       ↓
    │   Load with FontLoader
    │       ↓
    │   Cache in memory
    └─ Already loaded → Skip download
           ↓
    Save to SharedPreferences
           ↓
    notifyListeners()
           ↓
    All text updates automatically
```

### Font Application

When text is rendered:
1. Check if custom font is selected
2. If yes → Use custom font family
3. If no → Use built-in Google Font
4. Apply font size, weight, color from settings

## Usage Examples

### In Settings Screen
```dart
// User sees dropdown with all custom fonts
_CustomFontDropdownTile(
  icon: Icons.font_download_rounded,
  label: 'কাস্টম ফন্ট নির্বাচন',
  settings: settings,
)

// Preview shows selected font
Text(
  'আল্লাহু আকবার — সুবহানাল্লাহ',
  style: settings.getCurrentFontStyle(
    fontSize: settings.fontSize,
    fontWeight: settings.fontWeight,
  ),
)
```

### In Any Screen
```dart
// Using context extension (automatically uses custom font if selected)
Text('আসসালামু আলাইকুম', style: context.banglaBody)

// Or directly from settings
final settings = context.watch<SettingsProvider>();
Text(
  'ইসলামিক জ্ঞান',
  style: settings.getCurrentFontStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
)
```

## Data Persistence

### SharedPreferences Keys
- `custom_bangla_fonts_cache` - JSON array of font list
- `custom_bangla_fonts_cache_time` - Timestamp of cache
- `customFontFileName` - Selected font file name
- `customFontDisplayName` - Selected font display name
- `customFontUrl` - Selected font download URL

### Cache Structure
```json
{
  "fonts": [
    {
      "fileName": "ANANEB__.TTF",
      "displayName": "Anane",
      "downloadUrl": "https://raw.githubusercontent.com/.../ANANEB__.TTF"
    },
    ...
  ],
  "cacheTime": 1234567890
}
```

## Error Handling

1. **Network Error**: Shows error message with retry button
2. **Font Load Error**: Falls back to built-in font
3. **Cache Corruption**: Clears cache and refetches
4. **Invalid Font File**: Skips and continues with other fonts

## Performance Considerations

1. **Lazy Loading**: Fonts are only downloaded when selected
2. **Memory Cache**: Loaded fonts stay in memory for instant switching
3. **Network Optimization**: 
   - Single API call for font list
   - Individual font files loaded on-demand
   - 7-day cache reduces network usage

## Future Enhancements

1. **Font Preview in Dropdown**: Show sample text in each font
2. **Font Categories**: Group fonts by style (modern, traditional, etc.)
3. **Font Search**: Search fonts by name
4. **Favorite Fonts**: Mark frequently used fonts
5. **Font Size Per Font**: Different default sizes for different fonts
6. **Download Progress**: Show progress bar when downloading large fonts

## Testing Checklist

- [x] Font list loads from GitHub
- [x] Cache works (7-day expiration)
- [x] Custom font selection persists across app restarts
- [x] Custom font applies globally to all Bangla text
- [x] Switching between built-in and custom fonts works
- [x] Error handling for network failures
- [x] Loading states display correctly
- [x] Font preview shows correct font
- [ ] Test with slow network
- [ ] Test with no network (offline mode)
- [ ] Test cache expiration after 7 days
- [ ] Test with all 40+ fonts

## Known Issues

None currently.

## Dependencies

- `http` - For GitHub API calls
- `shared_preferences` - For caching
- `flutter/services.dart` - For FontLoader
- `google_fonts` - For built-in fonts

---

**Last Updated**: May 2, 2026
**Status**: ✅ Implemented and Ready for Testing
