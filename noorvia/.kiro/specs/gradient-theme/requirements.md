# Requirements Document

## Introduction

Noorvia is a Flutter-based Islamic app with a Bengali UI, offering features such as prayer times, Ramadan calendar, Quran reading, Qibla direction, Asmaul Husna, Tasbih counter, and more. The app currently uses an emerald-green color palette (`AppColors.primary`, `_kEmerald`, `_kGreen1`, `_QColors.teal`, etc.) defined across multiple files.

This feature replaces the entire app's color theme with a premium purple-to-blue gradient (`#6A11CB` → `#2575FC`) applied selectively to key surfaces — top headers, hero sections, active prayer highlights, and important banners — while keeping the overall background light and minimal. Content cards remain white with soft shadows and rounded corners, creating a calm, spiritual, and modern Islamic app aesthetic.

---

## Glossary

- **GradientTheme**: The app-wide visual theme using a two-stop linear gradient from `#6A11CB` (deep purple) to `#2575FC` (vivid blue).
- **GradientStart**: The first gradient color, `Color(0xFF6A11CB)` (deep purple).
- **GradientEnd**: The second gradient color, `Color(0xFF2575FC)` (vivid blue).
- **GradientDirection**: The consistent gradient direction — top-left (`Alignment.topLeft`) to bottom-right (`Alignment.bottomRight`).
- **AppBackground**: The app-wide page background color — `Color(0xFFF5F7FA)` (off-white) in light mode, `Color(0xFF121212)` in dark mode.
- **CardBackground**: The surface color for content cards — `Colors.white` in light mode, `Color(0xFF1E1E1E)` in dark mode.
- **TextPrimary**: The main body text color — `Color(0xFF1A1A1A)` in light mode, `Colors.white` in dark mode.
- **TextSecondary**: The supporting/label text color — `Color(0xFF6B7280)` in light mode, `Color(0xFF9CA3AF)` in dark mode.
- **ActivePrayerAccent**: The highlight color for the currently active prayer row — a soft orange `Color(0xFFFF6B35)` or the `GradientTheme` gradient, used exclusively on the active prayer row.
- **CardShadow**: The standard soft shadow applied to all content cards — `BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))`.
- **CardRadius**: The standard border radius for content cards — `BorderRadius.circular(16)` to `BorderRadius.circular(20)`.
- **AppTheme**: The central theme configuration in `lib/core/theme/app_theme.dart`, including `AppColors` and `AppTheme` classes.
- **GradientHelper**: A utility class providing reusable gradient decorations, gradient-filled containers, and gradient-text/icon helpers.
- **PrimaryColor**: The single representative solid color used where Flutter's `ThemeData` requires a single `Color` — set to `GradientStart` (`Color(0xFF6A11CB)`).
- **DarkModeGradient**: A slightly reduced-opacity version of the `GradientTheme` used in dark mode AppBar surfaces — same hue, `0.85` opacity.
- **AppBar**: Flutter `AppBar` widget used at the top of each screen.
- **FAB**: Floating Action Button (`FloatingActionButton`).
- **SectionHeader**: The `SectionHeader` widget in `lib/screens/home/widgets/section_header.dart`.
- **FeatureGridItem**: The `FeatureGridItem` widget in `lib/screens/home/widgets/feature_grid_item.dart`.
- **PrayerCard**: The `PrayerCard` widget in `lib/screens/home/widgets/prayer_card.dart`.
- **RamadanMiniCard**: The `RamadanMiniCard` widget inside `prayer_card.dart` showing Sehri/Iftar countdown.
- **BannerCard**: The `BannerCard` widget in `lib/screens/home/widgets/banner_card.dart`.
- **DonationCard**: The `DonationCard` widget in `lib/screens/home/widgets/donation_card.dart`.
- **CalendarPage**: `PrayerTimesCalendarPage` in `lib/screens/IslamicFeatures/calendar.dart`.
- **RamadanCalendarPage**: `RamadanCalendarPage` in `lib/screens/IslamicFeatures/ramadancalender.dart`.
- **QiblaPage**: `QiblaDirectionPage` in `lib/screens/IslamicFeatures/qibla_direction_page.dart`.
- **BottomNavigation**: The app's bottom navigation bar widget.
- **Neumorphic Shadow**: A soft, dual-shadow depth technique using a light shadow above-left and a slightly darker shadow below-right to create subtle elevation without heavy borders.

---

## Requirements

### Requirement 1: Central Color Token Definition

**User Story:** As a developer, I want all theme colors defined in one place, so that changing the theme requires editing only a single file.

#### Acceptance Criteria

1. THE `AppColors` class SHALL define `gradientStart` as `Color(0xFF6A11CB)` and `gradientEnd` as `Color(0xFF2575FC)`.
2. THE `AppColors` class SHALL define a `gradient` static getter returning a `LinearGradient` from `GradientStart` to `GradientEnd` with `begin: Alignment.topLeft` and `end: Alignment.bottomRight`.
3. THE `AppColors` class SHALL define a `gradientDark` static getter returning a `LinearGradient` identical to `gradient` but with both colors at `0.85` opacity, for use in dark mode AppBar surfaces.
4. THE `AppColors` class SHALL define `appBackground` as `Color(0xFFF5F7FA)` for the light mode page background.
5. THE `AppColors` class SHALL define `cardBackground` as `Colors.white` for light mode content card surfaces.
6. THE `AppColors` class SHALL define `textPrimary` as `Color(0xFF1A1A1A)` and `textSecondary` as `Color(0xFF6B7280)`.
7. THE `AppColors` class SHALL define `activePrayerAccent` as `Color(0xFFFF6B35)` (soft orange) for the active prayer row highlight.
8. THE `AppColors` class SHALL replace the existing `primary` constant with `GradientStart` (`Color(0xFF6A11CB)`), so that all existing `AppColors.primary` references automatically adopt the new theme.
9. THE `AppColors` class SHALL replace the existing `primaryLight` constant with `GradientEnd` (`Color(0xFF2575FC)`).
10. WHEN the `AppColors.gradient` getter is called, THE `AppColors` class SHALL return a `LinearGradient` with exactly two color stops: index 0 = `GradientStart`, index 1 = `GradientEnd`.

---

### Requirement 2: GradientHelper Utility

**User Story:** As a developer, I want a reusable helper that provides gradient-filled `BoxDecoration`, gradient `ShaderMask` text/icons, and gradient `Paint` for custom painters, so that gradient logic is not duplicated across files.

#### Acceptance Criteria

1. THE `GradientHelper` class SHALL provide a static method `boxDecoration({BorderRadius? borderRadius, List<BoxShadow>? boxShadow})` returning a `BoxDecoration` with `AppColors.gradient` applied.
2. THE `GradientHelper` class SHALL provide a static method `darkBoxDecoration({BorderRadius? borderRadius, List<BoxShadow>? boxShadow})` returning a `BoxDecoration` with `AppColors.gradientDark` applied.
3. THE `GradientHelper` class SHALL provide a static method `gradientText(String text, TextStyle style)` returning a `ShaderMask`-wrapped `Text` widget that renders the text with the gradient shader.
4. THE `GradientHelper` class SHALL provide a static method `gradientIcon(IconData icon, double size)` returning a `ShaderMask`-wrapped `Icon` widget with the gradient shader.
5. THE `GradientHelper` class SHALL provide a static method `gradientPaint(Rect bounds)` returning a `Paint` object with `shader` set to `AppColors.gradient.createShader(bounds)`, for use in `CustomPainter` subclasses.
6. WHEN `GradientHelper.boxDecoration()` is called without arguments, THE `GradientHelper` SHALL return a `BoxDecoration` with no border radius and no box shadow.

---

### Requirement 3: App Background and Page Scaffold

**User Story:** As a user, I want the app's page backgrounds to be light and minimal, so that the content feels clean and uncluttered.

#### Acceptance Criteria

1. THE `Scaffold` background color for all screens SHALL use `AppColors.appBackground` (`Color(0xFFF5F7FA)`) in light mode.
2. THE `AppTheme` light theme SHALL set `scaffoldBackgroundColor` to `AppColors.appBackground`.
3. WHILE the app is in dark mode, THE `Scaffold` background SHALL use `Color(0xFF121212)` instead of `AppColors.appBackground`.
4. THE app SHALL NOT apply the gradient to full-page backgrounds — gradient usage SHALL be restricted to AppBars, hero sections, active prayer highlights, and important banners.

---

### Requirement 4: AppBar Gradient

**User Story:** As a user, I want every screen's AppBar to display the purple-to-blue gradient, so that the app feels visually unified and premium.

#### Acceptance Criteria

1. WHEN any screen's `AppBar` is rendered, THE `AppBar` SHALL display the `GradientTheme` gradient as its background via a `flexibleSpace` `Container` with `AppColors.gradient`.
2. THE `AppBar` SHALL set `backgroundColor: Colors.transparent` and `elevation: 0` when using the gradient `flexibleSpace`.
3. THE `AppBar` SHALL render all icons and title text in `Colors.white` to ensure contrast against the gradient background.
4. WHERE a screen uses a custom `PreferredSizeWidget` AppBar (e.g., `QiblaPage`), THE `AppBar` SHALL apply the same gradient `flexibleSpace` pattern.
5. IF a screen's AppBar currently uses a solid `_kEmerald`, `_kGreen1`, `_kGreen2`, or `AppColors.primary` background, THEN THE `AppBar` SHALL replace that solid color with the gradient `flexibleSpace`.

---

### Requirement 5: Card Design System

**User Story:** As a user, I want all content cards to be white with soft shadows and rounded corners, so that the app feels clean, elevated, and modern.

#### Acceptance Criteria

1. THE `CardBackground` for all content cards SHALL be `Colors.white` in light mode and `Color(0xFF1E1E1E)` in dark mode.
2. THE border radius for all content cards SHALL be between `16px` and `20px` (`BorderRadius.circular(16)` to `BorderRadius.circular(20)`).
3. THE `CardShadow` applied to all content cards SHALL use `BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))` as the standard elevation shadow.
4. THE app SHALL NOT apply heavy borders to content cards — card separation SHALL be achieved through shadow and spacing alone.
5. THE `AppTheme` light theme SHALL set `cardColor` to `Colors.white` and `cardTheme` with the standard `CardShadow` and `CardRadius`.
6. WHEN a card requires additional depth (e.g., featured or hero cards), THE card SHALL use a Neumorphic Shadow with a light shadow at `Offset(-4, -4)` and a slightly darker shadow at `Offset(4, 4)` in addition to the standard `CardShadow`.

---

### Requirement 6: Typography System

**User Story:** As a user, I want all text to be highly readable with a consistent hierarchy, so that I can quickly scan and understand the app's content.

#### Acceptance Criteria

1. THE primary body text color SHALL be `TextPrimary` (`Color(0xFF1A1A1A)`) in light mode.
2. THE secondary/label text color SHALL be `TextSecondary` (`Color(0xFF6B7280)`) in light mode.
3. WHILE the app is in dark mode, THE primary text color SHALL be `Colors.white` and the secondary text color SHALL be `Color(0xFF9CA3AF)`.
4. THE `AppTheme` SHALL define a `TextTheme` with `bodyLarge` using `TextPrimary`, `bodyMedium` using `TextPrimary`, and `bodySmall` using `TextSecondary`.
5. THE app SHALL NOT use vague or decorative fonts for body text — the font SHALL prioritize legibility at small sizes.
6. WHEN text is rendered on a gradient background (AppBar, hero section, active prayer card), THE text color SHALL be `Colors.white` to maintain contrast.

---

### Requirement 7: PrayerCard Design

**User Story:** As a user, I want the prayer times card to use the gradient for its hero section and a clear accent for the active prayer, so that I can immediately identify the current prayer time.

#### Acceptance Criteria

1. THE `PrayerCard` top hero section (date, location, sunrise/sunset) SHALL use `GradientHelper.boxDecoration(borderRadius: ...)` as its background, replacing the solid `AppColors.primary` background.
2. THE `PrayerCard` prayer list rows SHALL use white `CardBackground` with `CardShadow` and `CardRadius` for each row.
3. THE `PrayerCard` active prayer row SHALL use `ActivePrayerAccent` (`Color(0xFFFF6B35)`) as its highlight background, OR `GradientHelper.boxDecoration()` as an alternative accent — the active row SHALL be visually distinct from inactive rows.
4. THE `_CircularTimerPainter` progress arc SHALL use `GradientHelper.gradientPaint(bounds)` instead of the solid `AppColors.primary` paint color.
5. THE pulsing dot inside the circular timer SHALL use `GradientStart` (`Color(0xFF6A11CB)`) as its color.
6. THE `RamadanMiniCard` SHALL use `GradientHelper.boxDecoration(borderRadius: ...)` as its background, making it a gradient hero/banner card.
7. THE `RamadanMiniCard` "অ্যালার্ম" text links SHALL use `GradientStart` as their color.
8. THE `RamadanMiniCard` loading spinner SHALL use `GradientStart` as its color.
9. THE `RamadanMiniCard` SnackBar background SHALL use `GradientStart` as its `backgroundColor`.
10. WHEN the prayer list is rendered, THE inactive prayer rows SHALL use `TextPrimary` for prayer name text and `TextSecondary` for prayer time text.

---

### Requirement 8: BannerCard Design

**User Story:** As a user, I want important banners (Ramadan, Hajj, notifications) to use the gradient, so that they stand out as key highlights on the home screen.

#### Acceptance Criteria

1. THE `BannerCard` SHALL replace its current green `LinearGradient` with `AppColors.gradient` (purple-to-blue).
2. THE `BannerCard` text content SHALL use `Colors.white` for all text rendered on the gradient background.
3. THE `BannerCard` SHALL maintain its existing `CardRadius` (`BorderRadius.circular(16)` to `BorderRadius.circular(20)`) and `CardShadow`.
4. IF a `BannerCard` is used for a non-critical informational message, THEN THE `BannerCard` MAY use a white `CardBackground` with a `GradientStart`-colored left border accent instead of the full gradient background.

---

### Requirement 9: DonationCard Design

**User Story:** As a user, I want the donation card to use the gradient theme, so that it is visually prominent and consistent with the app's premium feel.

#### Acceptance Criteria

1. THE `DonationCard` SHALL replace its current green `LinearGradient` with `AppColors.gradient`.
2. THE `DonationCard` donate button SHALL use `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(30))` as its visual container, with the button's `backgroundColor` set to `Colors.transparent`.
3. THE `DonationCard` text content SHALL use `Colors.white` for all text rendered on the gradient background.

---

### Requirement 10: SectionHeader Design

**User Story:** As a user, I want the section header accent bars to use the gradient, so that section dividers feel part of the unified theme.

#### Acceptance Criteria

1. THE `SectionHeader` vertical accent bar SHALL use `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(3))` instead of the solid `color` parameter.
2. THE `SectionHeader` search button circle SHALL use `GradientHelper.boxDecoration(borderRadius: BorderRadius.circular(19))` instead of the solid `AppColors.primary` background.
3. WHEN `SectionHeader` is rendered with any `color` argument, THE `SectionHeader` SHALL ignore the `color` argument for the bar fill and always apply the gradient.
4. THE `SectionHeader` title text SHALL use `TextPrimary` (`Color(0xFF1A1A1A)`) for the section label.

---

### Requirement 11: Bottom Navigation Design

**User Story:** As a user, I want the bottom navigation bar to have a clean white background with gradient-colored active icons, so that navigation is clear and consistent with the premium theme.

#### Acceptance Criteria

1. THE `BottomNavigation` background SHALL be `Colors.white` in light mode and `Color(0xFF1E1E1E)` in dark mode.
2. THE `BottomNavigation` active icon SHALL use `GradientHelper.gradientIcon()` to render the active icon with the gradient shader, OR use `GradientStart` as the active icon color.
3. THE `BottomNavigation` inactive icons SHALL use `TextSecondary` (`Color(0xFF6B7280)`) as their color.
4. THE `BottomNavigation` active label text SHALL use `GradientStart` as its color.
5. THE `BottomNavigation` inactive label text SHALL use `TextSecondary` as its color.
6. THE `BottomNavigation` SHALL have a top border or soft shadow to separate it from the page content — no heavy border SHALL be used.
7. THE `AppTheme` SHALL set `bottomNavigationBarTheme` with `backgroundColor: Colors.white`, `selectedItemColor: AppColors.gradientStart`, and `unselectedItemColor: AppColors.textSecondary`.

---

### Requirement 12: Icon Style Guidelines

**User Story:** As a developer, I want all icons to follow a consistent style, so that the app feels visually cohesive and polished.

#### Acceptance Criteria

1. THE app SHALL use simple, rounded, line-style or soft-filled icons consistently across all screens.
2. THE icon color for interactive icons on white/light backgrounds SHALL be `GradientStart` (`Color(0xFF6A11CB)`) or `TextSecondary` (`Color(0xFF6B7280)`) depending on their prominence.
3. THE icon color for icons rendered on gradient backgrounds (AppBar, hero cards) SHALL be `Colors.white`.
4. THE icon size for navigation icons SHALL be consistent — `24px` for bottom navigation, `22px` for AppBar actions.
5. THE app SHALL NOT mix icon styles (e.g., mixing sharp-edged and rounded icons) within the same screen.

---

### Requirement 13: CalendarPage Design

**User Story:** As a user, I want the prayer times calendar screen to use the new theme, so that it is visually consistent with the rest of the app.

#### Acceptance Criteria

1. THE `CalendarPage` `AppBar` SHALL use the gradient `flexibleSpace` pattern, replacing the solid `_kGreen1` background.
2. THE `CalendarPage` page background SHALL use `AppColors.appBackground` (`Color(0xFFF5F7FA)`).
3. THE `CalendarPage` filter bar SHALL use `GradientHelper.darkBoxDecoration()` instead of the solid `_kGreen2` background.
4. THE `_DayCard` SHALL use white `CardBackground` with `CardShadow` and `CardRadius` as its base style.
5. THE `_DayCard` header container SHALL use `GradientHelper.boxDecoration(borderRadius: ...)` for standard days.
6. THE `_DayCard` "আজ" badge SHALL use `GradientStart` as its background color instead of `_kGreenAccent`.
7. THE `_DayCard` "জুমা" badge SHALL use `GradientEnd` as its background color instead of `_kFridayBorder`.
8. THE month/year picker dialog SHALL use `GradientHelper.boxDecoration()` as the dialog background instead of the solid `_kGreen1` background.
9. THE selected month chip in the picker SHALL use `GradientStart` as its background color instead of `_kGreenAccent`.
10. THE loading spinner, retry button, and dropdown colors SHALL be updated to `AppColors.gradientStart`.

---

### Requirement 14: RamadanCalendarPage Design

**User Story:** As a user, I want the Ramadan calendar screen to use the new theme, so that it is visually consistent.

#### Acceptance Criteria

1. THE `RamadanCalendarPage` `AppBar` `flexibleSpace` SHALL use `AppColors.gradient` instead of the solid `LinearGradient([_kEmerald, _kEmeraldLight])`.
2. THE column header row (রমাযান, তারিখ, বার, সাহরী শেষ, ইফতার) SHALL use `AppColors.gradient` instead of the solid `LinearGradient([_kEmerald, _kEmeraldLight])`.
3. THE current-year separator banner SHALL use `AppColors.gradient` instead of the solid `LinearGradient([_kEmerald, _kEmeraldLight])`.
4. THE today's row background SHALL use `GradientStart` (`Color(0xFF6A11CB)`) instead of the solid `Color(0xFF0D5C3A)`.
5. THE `FloatingActionButton` (scroll-to-today) SHALL use `GradientStart` as its `backgroundColor` instead of `_kGold`.
6. THE Hijri year badge in the AppBar title SHALL use `GradientStart.withValues(alpha: 0.25)` as its background instead of `_kGold.withValues(alpha: 0.25)`.
7. THE Hijri year badge border SHALL use `GradientEnd.withValues(alpha: 0.5)` instead of `_kGoldLight.withValues(alpha: 0.5)`.
8. THE Hijri year badge text color SHALL use `GradientEnd` instead of `_kGoldLight`.
9. THE loading spinner SHALL use `GradientStart` instead of `Color(0xFF0D5C3A)`.
10. THE retry `TextButton` color SHALL use `GradientStart` instead of `_kEmerald`.
11. THE dropdown `dropdownColor` SHALL use `GradientStart` instead of `_kEmerald`.
12. THE current-year dot indicator SHALL use `GradientEnd` instead of `_kGoldLight`.

---

### Requirement 15: QiblaPage Design

**User Story:** As a user, I want the Qibla compass screen to use the new theme, so that it is visually consistent.

#### Acceptance Criteria

1. THE `QiblaPage` `AppBar` SHALL use the gradient `flexibleSpace` pattern, replacing the transparent AppBar with a gradient one.
2. THE compass ring outer glow `BoxShadow` SHALL use `GradientStart` instead of `_QColors.teal`.
3. THE compass ring border SHALL use `GradientStart.withValues(alpha: 0.35)` instead of `_QColors.teal.withValues(alpha: 0.35)`.
4. THE `_CompassRingPainter` tick marks SHALL use `GradientStart` as `primaryColor` and `GradientStart.withValues(alpha: 0.3)` as `secondaryColor`.
5. THE center hub dot SHALL use `GradientStart` as its color instead of `_QColors.teal`.
6. THE Qibla needle shaft gradient SHALL use `GradientStart` as the top color instead of `_QColors.teal`.
7. THE Kaaba icon circle SHALL use `GradientStart` when not aligned and `AppColors.gold` when aligned.
8. THE info card hint border and icon SHALL use `GradientStart` instead of `_QColors.teal`.
9. THE location refresh button container background SHALL use `GradientStart.withValues(alpha: 0.12)` instead of `_QColors.teal.withValues(alpha: 0.12)`.
10. THE alignment status chip border and icon SHALL use `GradientStart` instead of `_QColors.teal`.
11. THE Qibla degree text (large `°` display) SHALL use `GradientStart` instead of `_QColors.teal`.

---

### Requirement 16: Dark Mode Adaptation

**User Story:** As a user who uses dark mode, I want the theme to adapt gracefully for dark backgrounds, so that it remains readable and does not cause eye strain.

#### Acceptance Criteria

1. WHILE the app is in dark mode, THE `GradientTheme` SHALL apply `AppColors.gradientDark` (0.85 opacity gradient) to AppBar `flexibleSpace` containers.
2. WHILE the app is in dark mode, THE `PrayerCard` top hero section SHALL use `AppColors.gradientDark` instead of `AppColors.gradient`.
3. WHILE the app is in dark mode, THE `SectionHeader` accent bar SHALL use `AppColors.gradientDark`.
4. WHILE the app is in dark mode, card backgrounds (`CardBackground`) SHALL remain `Color(0xFF1E1E1E)` — the gradient SHALL NOT be applied to card body backgrounds in dark mode.
5. WHILE the app is in dark mode, THE page background SHALL use `Color(0xFF121212)` instead of `AppColors.appBackground`.
6. WHILE the app is in dark mode, THE `BottomNavigation` background SHALL use `Color(0xFF1E1E1E)` instead of `Colors.white`.
7. IF the app is in dark mode AND a gradient surface would render white text at less than 4.5:1 contrast ratio, THEN THE `GradientTheme` SHALL use the full-opacity gradient (not the dark variant) to maintain readability.

---

### Requirement 17: Buttons and Interactive Elements

**User Story:** As a user, I want all primary action buttons and interactive elements to use the gradient, so that calls-to-action are visually prominent and consistent.

#### Acceptance Criteria

1. THE `ElevatedButton` widgets that currently use `AppColors.primary` or `_kGreen*` as `backgroundColor` SHALL use a `GradientHelper`-wrapped `Container` with `GradientHelper.boxDecoration()` as their visual container, with the button's `backgroundColor` set to `Colors.transparent`.
2. THE `FloatingActionButton` widgets that currently use `_kGold` or `AppColors.primary` as `backgroundColor` SHALL use `GradientStart` as their `backgroundColor`.
3. THE `TextButton` and `IconButton` widgets that currently use `AppColors.primary` or `_kEmerald` as their foreground color SHALL use `GradientStart` as their foreground color.
4. THE `SnackBar` widgets that currently use `AppColors.primary` as `backgroundColor` SHALL use `GradientStart` as their `backgroundColor`.
5. WHEN a `DropdownButton` is rendered inside a gradient-background container, THE `DropdownButton` `dropdownColor` SHALL use `GradientStart` instead of `_kGreen1` or `_kEmerald`.

---

### Requirement 18: Progress Indicators and Badges

**User Story:** As a user, I want loading spinners, progress bars, and badge chips to use the gradient accent color, so that they feel part of the unified theme.

#### Acceptance Criteria

1. THE `CircularProgressIndicator` widgets that currently use `_kGreen2` or `AppColors.primary` as their `color` SHALL use `GradientStart` as their `color`.
2. THE `LinearProgressIndicator` widgets (if any) that currently use green colors SHALL use `GradientStart` as their `valueColor`.
3. THE "আজ" (today) badge chip in `CalendarPage` SHALL use `GradientStart` as its background color.
4. THE Hijri year badge in `RamadanCalendarPage` AppBar SHALL use `GradientStart.withValues(alpha: 0.25)` as its background.
5. THE section dot indicators (small circles in year separator banners) SHALL use `GradientEnd` as their color for the current year and `Colors.white54` for other years.

---

### Requirement 19: Gradient Usage Constraints

**User Story:** As a designer, I want gradient usage to be restricted to key surfaces only, so that the app maintains a calm, balanced, and elegant feel without overusing color.

#### Acceptance Criteria

1. THE gradient SHALL be applied ONLY to: AppBar/header surfaces, hero sections (top card of `PrayerCard`), active prayer row highlight, important banners (`BannerCard`, `DonationCard`, `RamadanMiniCard`), and bottom navigation active icon.
2. THE gradient SHALL NOT be applied to: page backgrounds, regular content card bodies, inactive prayer rows, body text, or decorative dividers.
3. THE app SHALL use `ActivePrayerAccent` (soft orange `Color(0xFFFF6B35)`) OR the gradient for the active prayer row — both are acceptable, but the choice SHALL be consistent across all instances of the active prayer row.
4. THE app SHALL maintain a maximum of three distinct accent colors visible on any single screen: `GradientStart`, `GradientEnd`, and `ActivePrayerAccent`.
5. WHEN a new widget or screen is added to the app, THE developer SHALL apply gradient only to surfaces that match the categories in criterion 1 of this requirement.
