# Implementation Plan: Gradient Theme

## Overview

Replace the app's emerald-green palette with a premium purple-to-blue gradient (`#6A11CB` → `#2575FC`). All tasks are reset to not-started because the previous implementation used incorrect colors and must be redone. Work proceeds from the token layer outward to widgets and screens.

## Tasks

- [ ] 1. Update AppColors with new gradient tokens
  - Update `gradientStart` to `Color(0xFF6A11CB)` and `gradientEnd` to `Color(0xFF2575FC)` in `lib/core/theme/app_theme.dart`
  - Add `appBackground` (`Color(0xFFF5F7FA)`), `cardBackground` (`Colors.white`), `textPrimary` (`Color(0xFF1A1A1A)`), `textSecondary` (`Color(0xFF6B7280)`), and `activePrayerAccent` (`Color(0xFFFF6B35)`) constants
  - Update `gradient` static getter to use new `gradientStart`/`gradientEnd` values
  - Update `gradientDark` static getter to use new colors at 0.85 opacity
  - Update `primary` to `Color(0xFF6A11CB)` and `primaryLight` to `Color(0xFF2575FC)`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10_

- [ ] 2. Update GradientHelper utility class
  - Open `lib/core/theme/gradient_helper.dart` and verify all methods read from `AppColors.gradient` / `AppColors.gradientDark` — update any hardcoded color values to use the new tokens
  - Confirm `boxDecoration()`, `darkBoxDecoration()`, `gradientText()`, `gradientIcon()`, and `gradientPaint()` all produce the purple-to-blue gradient after the `AppColors` update
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 3. Update AppTheme configuration
  - [ ] 3.1 Set `scaffoldBackgroundColor` to `AppColors.appBackground` in the light `ThemeData`; set `Color(0xFF121212)` in the dark `ThemeData`
    - _Requirements: 3.1, 3.2, 3.3_
  - [ ] 3.2 Configure `cardTheme` with `CardTheme(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))` in light theme; `Color(0xFF1E1E1E)` card color in dark theme
    - _Requirements: 5.1, 5.2, 5.3, 5.5_
  - [ ] 3.3 Configure `textTheme` with `bodyLarge`/`bodyMedium` using `AppColors.textPrimary` and `bodySmall` using `AppColors.textSecondary`
    - _Requirements: 6.1, 6.2, 6.4_
  - [ ] 3.4 Configure `bottomNavigationBarTheme` with `backgroundColor: Colors.white`, `selectedItemColor: AppColors.gradientStart`, `unselectedItemColor: AppColors.textSecondary`; dark mode uses `Color(0xFF1E1E1E)` background
    - _Requirements: 11.1, 11.3, 11.4, 11.5, 11.7_

- [ ] 4. Update home widgets
  - [ ] 4.1 Update `prayer_card.dart` — hero top section
    - Replace solid `AppColors.primary` background on `_buildTopCard` with `GradientHelper.boxDecoration(borderRadius: ...)`
    - Update `_CircularTimerPainter` arc paint to `GradientHelper.gradientPaint(bounds)`
    - Update pulsing dot color to `AppColors.gradientStart`
    - _Requirements: 7.1, 7.4, 7.5_
  - [ ] 4.2 Update `prayer_card.dart` — prayer list rows
    - Inactive prayer rows: white `CardBackground` with `CardShadow` (`BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))`) and `CardRadius`
    - Active prayer row: use `AppColors.activePrayerAccent` (`Color(0xFFFF6B35)`) OR `GradientHelper.boxDecoration()` — must be visually distinct
    - Inactive row prayer name text: `AppColors.textPrimary`; prayer time text: `AppColors.textSecondary`
    - _Requirements: 7.2, 7.3, 7.10, 19.3_
  - [ ] 4.3 Update `prayer_card.dart` — RamadanMiniCard
    - Set `RamadanMiniCard` background to `GradientHelper.boxDecoration(borderRadius: ...)`
    - Update alarm text color, loading spinner, and SnackBar background to `AppColors.gradientStart`
    - _Requirements: 7.6, 7.7, 7.8, 7.9_
  - [ ] 4.4 Update `banner_card.dart`
    - Replace `LinearGradient([0xFF0F4D2A, 0xFF1B6B3A, 0xFF2E8B57])` with `AppColors.gradient`
    - Ensure all text on gradient background is `Colors.white`
    - _Requirements: 8.1, 8.2, 8.3_
  - [ ] 4.5 Update `donation_card.dart`
    - Replace `LinearGradient([0xFF0F4D2A, 0xFF1B6B3A])` with `AppColors.gradient`
    - Donate button: wrap with `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(30))`, set button `backgroundColor: Colors.transparent`
    - _Requirements: 9.1, 9.2, 9.3_
  - [ ] 4.6 Update `section_header.dart`
    - Accent bar: replace solid `color` with `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(3))`
    - Search circle: replace `AppColors.primary` with `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(19))`
    - Title text: use `AppColors.textPrimary`
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  - [ ] 4.7 Update `feature_grid_item.dart`
    - SnackBar `backgroundColor: AppColors.primary` → `AppColors.gradientStart`
    - _Requirements: 17.4_

- [ ] 5. Update CalendarPage (calendar.dart)
  - [ ] 5.1 AppBar and page background
    - Replace solid `_kGreen1` AppBar background with gradient `flexibleSpace` (`backgroundColor: Colors.transparent`, `elevation: 0`)
    - Set page/scaffold background to `AppColors.appBackground`
    - _Requirements: 13.1, 13.2, 4.1, 4.2, 4.3_
  - [ ] 5.2 Filter bar and `_DayCard` styling
    - Filter bar: replace `_kGreen2` with `GradientHelper.darkBoxDecoration()`
    - `_DayCard` base: white `CardBackground` with `CardShadow` and `CardRadius`
    - `_DayCard` header: replace `_kGreen1` with `GradientHelper.boxDecoration(borderRadius: ...)`
    - "আজ" badge: `_kGreenAccent` → `AppColors.gradientStart`
    - "জুমা" badge: `_kFridayBorder` → `AppColors.gradientEnd`
    - _Requirements: 13.3, 13.4, 13.5, 13.6, 13.7_
  - [ ] 5.3 Month picker dialog, loading, and interactive elements
    - Month picker dialog: replace `_kGreen1` background with gradient via `Container` wrapper
    - Selected month chip: `_kGreenAccent` → `AppColors.gradientStart`
    - Loading spinner, retry button, dropdown `dropdownColor`: all → `AppColors.gradientStart`
    - _Requirements: 13.8, 13.9, 13.10, 17.1, 17.3, 17.5, 18.1, 18.3_

- [ ] 6. Update RamadanCalendarPage (ramadancalender.dart)
  - [ ] 6.1 AppBar, column header, and year banner
    - AppBar `flexibleSpace`: replace `[_kEmerald, _kEmeraldLight]` with `AppColors.gradient`
    - Column header row: replace `[_kEmerald, _kEmeraldLight]` with `AppColors.gradient`
    - Current-year separator banner: replace `[_kEmerald, _kEmeraldLight]` with `AppColors.gradient`
    - _Requirements: 14.1, 14.2, 14.3_
  - [ ] 6.2 Today row, FAB, Hijri badge, and interactive elements
    - Today row background: `Color(0xFF0D5C3A)` → `AppColors.gradientStart`
    - FAB `backgroundColor: _kGold` → `AppColors.gradientStart`
    - Hijri year badge: background → `AppColors.gradientStart.withValues(alpha: 0.25)`, border → `AppColors.gradientEnd.withValues(alpha: 0.5)`, text → `AppColors.gradientEnd`
    - Current-year dot: `_kGoldLight` → `AppColors.gradientEnd`
    - Loading spinner, retry TextButton, dropdown `dropdownColor`: all → `AppColors.gradientStart`
    - _Requirements: 14.4, 14.5, 14.6, 14.7, 14.8, 14.9, 14.10, 14.11, 14.12, 17.2, 17.3, 17.5, 18.1, 18.4, 18.5_

- [ ] 7. Update QiblaDirectionPage (qibla_direction_page.dart)
  - [ ] 7.1 AppBar gradient
    - Replace transparent AppBar with gradient `flexibleSpace` pattern (`backgroundColor: Colors.transparent`, `elevation: 0`)
    - Back icon and title text: `Colors.white`
    - _Requirements: 15.1, 4.1, 4.2, 4.3, 4.4_
  - [ ] 7.2 Compass ring and painter
    - Compass ring border: `_QColors.teal.withValues(alpha:0.35)` → `AppColors.gradientStart.withValues(alpha:0.35)`
    - Compass ring outer glow shadow: `_QColors.teal` → `AppColors.gradientStart`
    - `_CompassRingPainter` `primaryColor`: `_QColors.teal` → `AppColors.gradientStart`
    - `_CompassRingPainter` `secondaryColor`: `_QColors.teal.withValues(alpha:0.3)` → `AppColors.gradientStart.withValues(alpha:0.3)`
    - _Requirements: 15.2, 15.3, 15.4_
  - [ ] 7.3 Center hub, needle, and Kaaba icon
    - Center hub color and shadow: `_QColors.teal` → `AppColors.gradientStart`
    - Needle shaft gradient top color: `_QColors.teal` → `AppColors.gradientStart`
    - Kaaba icon circle (not aligned): `_QColors.teal` → `AppColors.gradientStart`
    - _Requirements: 15.5, 15.6, 15.7_
  - [ ] 7.4 Info section, loading, error, and interactive elements
    - Location refresh button bg/icon, info section location icon, Qibla degree text, alignment chip border/icon/text, hint card border/icon, cardinal label color: all `_QColors.teal` → `AppColors.gradientStart`
    - Loading spinner, error retry button, error settings TextButton: `_QColors.teal` → `AppColors.gradientStart`
    - _Requirements: 15.8, 15.9, 15.10, 15.11, 17.3, 18.1_

- [ ] 8. Update Bottom Navigation bar
  - Find the bottom navigation bar widget file in the project
  - Set background to `Colors.white` (light mode) / `Color(0xFF1E1E1E)` (dark mode)
  - Active icon: use `GradientHelper.gradientIcon()` OR set active icon color to `AppColors.gradientStart`
  - Inactive icons: `AppColors.textSecondary`
  - Active label: `AppColors.gradientStart`; inactive label: `AppColors.textSecondary`
  - Add top border or soft shadow to separate nav bar from page content
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

- [ ] 9. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
  - Verify no hardcoded green hex values (`0xFF1B6B3A`, `0xFF2E8B57`, `0xFF0F4D2A`, `0xFF0D5C3A`) remain in any updated file
  - Verify gradient is applied only to key surfaces (AppBars, hero sections, active prayer row, banners, bottom nav active icon) — not to page backgrounds or regular card bodies
  - _Requirements: 19.1, 19.2, 19.4_

## Notes

- All tasks are reset to `[ ]` — the previous implementation used incorrect magenta/cyan colors and must be redone with the new purple-to-blue palette
- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- The gradient direction is always `Alignment.topLeft` → `Alignment.bottomRight`
- `AppColors.primary` = `AppColors.gradientStart` after the update — all existing `AppColors.primary` references automatically adopt the new color
