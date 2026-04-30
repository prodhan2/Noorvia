# Design Document — Gradient Theme

## Overview

Replace the Noorvia app's emerald-green palette with a premium purple-to-blue gradient (`#6A11CB` → `#2575FC`) applied selectively to key surfaces — AppBars, hero sections, active prayer highlights, and important banners — while keeping the overall background light and minimal. Content cards remain white with soft shadows and rounded corners, creating a calm, spiritual, and modern Islamic app aesthetic.

The implementation is split into three layers:

1. **Token layer** — `AppColors` + `GradientHelper` utility
2. **Theme layer** — `AppTheme` configuration (scaffold, card, typography, bottom nav)
3. **Widget layer** — update each widget/screen to consume the new tokens

---

## Architecture

```
lib/
├── core/
│   └── theme/
│       ├── app_theme.dart          ← update AppColors tokens + AppTheme config
│       └── gradient_helper.dart    ← GradientHelper utility class (already exists)
└── screens/
    ├── home/widgets/
    │   ├── prayer_card.dart        ← gradient hero top section, white card rows, accent active row
    │   ├── banner_card.dart        ← gradient replaces green gradient
    │   ├── donation_card.dart      ← gradient replaces green gradient + button
    │   ├── section_header.dart     ← gradient accent bar + search circle, TextPrimary title
    │   └── feature_grid_item.dart  ← gradient SnackBar
    └── IslamicFeatures/
        ├── calendar.dart           ← gradient AppBar, filter bar, day card headers
        ├── ramadancalender.dart    ← gradient AppBar, column header, year banners
        └── qibla_direction_page.dart ← gradient compass ring, needle, hub, info
```

---

## Component Design

### 1. AppColors (app_theme.dart)

Update the existing `AppColors` class with new gradient tokens:

```dart
// Gradient theme tokens
static const Color gradientStart = Color(0xFF6A11CB);  // deep purple
static const Color gradientEnd   = Color(0xFF2575FC);  // vivid blue

// App background and card surfaces
static const Color appBackground  = Color(0xFFF5F7FA); // off-white page background
static const Color cardBackground = Colors.white;       // content card surface

// Typography
static const Color textPrimary   = Color(0xFF1A1A1A);  // main body text
static const Color textSecondary = Color(0xFF6B7280);  // supporting/label text

// Active prayer accent
static const Color activePrayerAccent = Color(0xFFFF6B35); // soft orange

static LinearGradient get gradient => const LinearGradient(
  colors: [gradientStart, gradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

static LinearGradient get gradientDark => LinearGradient(
  colors: [
    gradientStart.withValues(alpha: 0.85),
    gradientEnd.withValues(alpha: 0.85),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

Also update:
- `primary` → `Color(0xFF6A11CB)` (was `Color(0xFF1B6B3A)`)
- `primaryLight` → `Color(0xFF2575FC)` (was `Color(0xFF2E8B57)`)

### 2. GradientHelper (gradient_helper.dart)

Existing utility class — update all methods to use the new gradient colors. The interface remains the same:

```dart
class GradientHelper {
  static BoxDecoration boxDecoration({BorderRadius? borderRadius, List<BoxShadow>? boxShadow})
  static BoxDecoration darkBoxDecoration({BorderRadius? borderRadius, List<BoxShadow>? boxShadow})
  static Widget gradientText(String text, TextStyle style)
  static Widget gradientIcon(IconData icon, double size)
  static Paint gradientPaint(Rect bounds)
}
```

Since `GradientHelper` reads from `AppColors.gradient` and `AppColors.gradientDark`, updating `AppColors` is sufficient — no changes to `GradientHelper` logic are needed unless it hardcodes colors.

### 3. AppTheme Configuration (app_theme.dart)

Update the `AppTheme` light theme to include:

```dart
ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.appBackground,

  cardColor: Colors.white,
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    shadowColor: const Color(0x14000000),
    // Standard CardShadow applied via BoxDecoration on individual cards
  ),

  textTheme: const TextTheme(
    bodyLarge:  TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textPrimary),
    bodySmall:  TextStyle(color: AppColors.textSecondary),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.gradientStart,
    unselectedItemColor: AppColors.textSecondary,
    elevation: 8,
  ),
);
```

Dark mode equivalents:
- `scaffoldBackgroundColor: Color(0xFF121212)`
- `cardColor: Color(0xFF1E1E1E)`
- `bottomNavigationBarTheme.backgroundColor: Color(0xFF1E1E1E)`
- AppBar `flexibleSpace` uses `AppColors.gradientDark`

### 4. Card Design System

**CardShadow** — standard soft shadow for all content cards:
```dart
const BoxShadow cardShadow = BoxShadow(
  color: Color(0x14000000),
  blurRadius: 12,
  offset: Offset(0, 4),
);
```

**CardRadius** — standard border radius:
- Default: `BorderRadius.circular(16)`
- Hero/featured cards: `BorderRadius.circular(20)`

**CardBackground** — `Colors.white` in light mode, `Color(0xFF1E1E1E)` in dark mode.

Cards use shadow and spacing for separation — no heavy borders.

### 5. Typography System

| Token | Light Mode | Dark Mode |
|---|---|---|
| `textPrimary` | `Color(0xFF1A1A1A)` | `Colors.white` |
| `textSecondary` | `Color(0xFF6B7280)` | `Color(0xFF9CA3AF)` |

- Text on gradient backgrounds (AppBar, hero sections, active prayer card): `Colors.white`
- Body text on white/light cards: `textPrimary`
- Label/supporting text: `textSecondary`

### 6. Bottom Navigation Design

```dart
BottomNavigationBarThemeData(
  backgroundColor: Colors.white,           // light mode
  selectedItemColor: AppColors.gradientStart,
  unselectedItemColor: AppColors.textSecondary,
  elevation: 8,
)
```

- Active icon: `GradientHelper.gradientIcon()` for full gradient shader, OR `AppColors.gradientStart` solid color
- Inactive icons: `AppColors.textSecondary`
- Active label: `AppColors.gradientStart`
- Inactive label: `AppColors.textSecondary`
- Top border or soft shadow separates nav bar from page content

### 7. PrayerCard

- `_buildTopCard`: `BoxDecoration.color: AppColors.primary` → `GradientHelper.boxDecoration(borderRadius: ...)`
- Prayer list rows: white `CardBackground` with `CardShadow` and `CardRadius` for each inactive row
- `_buildPrayerRow` active bg: `AppColors.primary` → `AppColors.activePrayerAccent` (`Color(0xFFFF6B35)`) OR `GradientHelper.boxDecoration()` — must be visually distinct from inactive rows
- Inactive row prayer name text: `AppColors.textPrimary`
- Inactive row prayer time text: `AppColors.textSecondary`
- `_CircularTimerPainter` arc paint: `AppColors.primary` → `GradientHelper.gradientPaint(bounds)`
- Pulsing dot: `AppColors.primary` → `AppColors.gradientStart`
- `RamadanMiniCard` background: `GradientHelper.boxDecoration(borderRadius: ...)`
- `RamadanMiniCard` alarm text color: `AppColors.primary` → `AppColors.gradientStart`
- `RamadanMiniCard` loading spinner: `AppColors.primary` → `AppColors.gradientStart`
- `RamadanMiniCard` SnackBar bg: `AppColors.primary` → `AppColors.gradientStart`

### 8. BannerCard

- Replace `LinearGradient([0xFF0F4D2A, 0xFF1B6B3A, 0xFF2E8B57])` with `AppColors.gradient`
- All text on gradient background: `Colors.white`
- Maintain existing `CardRadius` and `CardShadow`

### 9. DonationCard

- Replace `LinearGradient([0xFF0F4D2A, 0xFF1B6B3A])` with `AppColors.gradient`
- Donate button: `color: Color(0xFF2E8B57)` → `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(30))` with `backgroundColor: Colors.transparent`
- All text on gradient background: `Colors.white`

### 10. SectionHeader

- Accent bar: `color: color` → `decoration: GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(3))`
- Search circle: `color: AppColors.primary` → `decoration: GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(19))`
- Title text: `AppColors.textPrimary` (`Color(0xFF1A1A1A)`)
- The `color` argument is ignored for bar fill — gradient is always applied

### 11. FeatureGridItem

- SnackBar `backgroundColor: AppColors.primary` → `AppColors.gradientStart`

### 12. CalendarPage (calendar.dart)

- AppBar: `backgroundColor: _kGreen1` → gradient `flexibleSpace` pattern (`backgroundColor: Colors.transparent`, `elevation: 0`)
- Page background: `AppColors.appBackground`
- Filter bar: `color: _kGreen2` → `GradientHelper.darkBoxDecoration()`
- `_DayCard` base: white `CardBackground` with `CardShadow` and `CardRadius`
- `_DayCard` header: `color: _kGreen1` → `GradientHelper.boxDecoration(borderRadius: ...)`
- "আজ" badge: `_kGreenAccent` → `AppColors.gradientStart`
- "জুমা" badge: `_kFridayBorder` → `AppColors.gradientEnd`
- Month picker dialog: `backgroundColor: _kGreen1` → gradient via `Container` wrapper
- Selected month chip: `_kGreenAccent` → `AppColors.gradientStart`
- Retry button: `backgroundColor: _kGreen2` → `AppColors.gradientStart`
- Loading spinner: `color: _kGreen2` → `AppColors.gradientStart`
- Dropdown `dropdownColor: _kGreen2` → `AppColors.gradientStart`

### 13. RamadanCalendarPage (ramadancalender.dart)

- AppBar `flexibleSpace`: `[_kEmerald, _kEmeraldLight]` → `AppColors.gradient`
- Column header: `[_kEmerald, _kEmeraldLight]` → `AppColors.gradient`
- Current-year banner: `[_kEmerald, _kEmeraldLight]` → `AppColors.gradient`
- Today row bg: `Color(0xFF0D5C3A)` → `AppColors.gradientStart`
- FAB `backgroundColor: _kGold` → `AppColors.gradientStart`
- Hijri year badge bg: `_kGold.withValues(alpha:0.25)` → `AppColors.gradientStart.withValues(alpha:0.25)`
- Hijri year badge border: `_kGoldLight.withValues(alpha:0.5)` → `AppColors.gradientEnd.withValues(alpha:0.5)`
- Hijri year badge text color: `_kGoldLight` → `AppColors.gradientEnd`
- Loading spinner: `Color(0xFF0D5C3A)` → `AppColors.gradientStart`
- Retry TextButton color: `_kEmerald` → `AppColors.gradientStart`
- Dropdown `dropdownColor: _kEmerald` → `AppColors.gradientStart`
- Current-year dot: `_kGoldLight` → `AppColors.gradientEnd`

### 14. QiblaDirectionPage (qibla_direction_page.dart)

- AppBar: transparent → gradient `flexibleSpace`, back icon/title use `Colors.white`
- Refresh button bg: `_QColors.teal.withValues(alpha:0.12)` → `AppColors.gradientStart.withValues(alpha:0.12)`
- Refresh button icon: `_QColors.teal` → `AppColors.gradientStart`
- Compass ring border: `_QColors.teal.withValues(alpha:0.35)` → `AppColors.gradientStart.withValues(alpha:0.35)`
- Compass ring shadow: `_QColors.teal` → `AppColors.gradientStart`
- `_CompassRingPainter` primaryColor: `_QColors.teal` → `AppColors.gradientStart`
- `_CompassRingPainter` secondaryColor: `_QColors.teal.withValues(alpha:0.3)` → `AppColors.gradientStart.withValues(alpha:0.3)`
- Center hub: `color: _QColors.teal` → `AppColors.gradientStart`
- Center hub shadow: `_QColors.teal.withValues(alpha:0.5)` → `AppColors.gradientStart.withValues(alpha:0.5)`
- Needle shaft gradient top color: `_QColors.teal` → `AppColors.gradientStart`
- Kaaba icon circle (not aligned): `_QColors.teal` → `AppColors.gradientStart`
- Loading spinner border/icon: `_QColors.teal` → `AppColors.gradientStart`
- Loading text: `_QColors.teal` → `AppColors.gradientStart`
- Error retry button: `_QColors.teal` → `AppColors.gradientStart`
- Error settings TextButton: `_QColors.teal` → `AppColors.gradientStart`
- Info section location icon: `_QColors.teal` → `AppColors.gradientStart`
- Qibla degree text: `_QColors.teal` → `AppColors.gradientStart`
- Alignment chip border/icon/text: `_QColors.teal` → `AppColors.gradientStart`
- Hint card border/icon: `_QColors.teal` → `AppColors.gradientStart`
- Cardinal 'উ.' label color: `_QColors.teal` → `AppColors.gradientStart`

---

## Correctness Properties

1. **P1 — Token Consistency**: Every gradient surface uses `AppColors.gradient`, `AppColors.gradientStart`, or `AppColors.gradientEnd` — no hardcoded green hex values remain in updated files.
2. **P2 — White Text Contrast**: All text rendered on gradient backgrounds is `Colors.white` or `Colors.white.withValues(alpha: ≥ 0.7)`.
3. **P3 — Dark Mode Safety**: In dark mode, `gradientDark` (0.85 opacity) is used for AppBar surfaces; card body backgrounds remain `Color(0xFF1E1E1E)`.
4. **P4 — No Regression**: All existing functionality (navigation, API calls, timers, compass) is unaffected — only color/decoration values change.
5. **P5 — Single Source of Truth**: `AppColors.primary` equals `AppColors.gradientStart` after the update, so all existing `AppColors.primary` references automatically use the new color.
6. **P6 — Gradient-Only on Key Surfaces**: The gradient is applied exclusively to AppBars, hero sections, active prayer highlights, important banners, and bottom navigation active icons — never to page backgrounds, regular card bodies, inactive prayer rows, body text, or decorative dividers.
7. **P7 — Card Design System Consistency**: All content cards use `Colors.white` background, `CardShadow` (`BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))`), and `CardRadius` (16–20px) — no heavy borders.
8. **P8 — Typography Hierarchy**: Primary body text uses `AppColors.textPrimary` (`Color(0xFF1A1A1A)`); supporting text uses `AppColors.textSecondary` (`Color(0xFF6B7280)`); text on gradient surfaces uses `Colors.white`.
9. **P9 — Bottom Navigation Consistency**: Active nav icon/label uses `AppColors.gradientStart`; inactive uses `AppColors.textSecondary`; background is `Colors.white` in light mode.
