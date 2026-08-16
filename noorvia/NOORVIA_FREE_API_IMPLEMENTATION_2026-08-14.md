# Noorvia Free API Expansion — Implementation Handoff

Date: 2026-08-14
Canonical Android package: `com.butterflydevs.noorvia`
Base snapshot: `Noorvia_Max_Global_Pro_2026-08-12.zip`

## Implemented in this round

### 1. Global Mosque + Musalla discovery
- Existing Overpass/OpenStreetMap query now discovers both Muslim places of worship and explicit `place_of_worship=musalla` objects.
- Supports node/way/relation responses with center coordinates.
- Deduplicates OSM elements and sorts by distance.
- Displays mosque vs musalla/prayer-room type, distance, approximate walking minutes, address, opening hours, service/Jamaat tags when available, level, wheelchair hint and Wudu/ablution hints.
- Search radius can be changed from the UI.
- Musallas/prayer rooms can be hidden independently.
- Google Maps walking navigation remains available without a routing API key.

### 2. Walking-route abstraction
- Added `MosqueRouteService`.
- Default behavior is fully keyless/offline: straight-line distance with a conservative walking detour factor and walking-speed estimate.
- Optional openrouteservice routed ETA is supported using `ORS_API_KEY` supplied at build time.
- Route results are cached in Isar for 6 hours.
- IMPORTANT: API keys compiled into a mobile app can be extracted. For a public production build, prefer a controlled backend/proxy or a provider-specific restricted client credential rather than treating a Dart define as a true secret.

Optional development build:

```bash
flutter run --dart-define=ORS_API_KEY=YOUR_DEVELOPMENT_KEY
```

Without the key Noorvia still provides an offline ETA and opens walking navigation externally.

### 3. Multi-language Hadith Library
- Added a Hadith repository/service backed by the open `fawazahmed0/hadith-api` corpus delivered through jsDelivr.
- Bangla and English collections are selectable automatically from Noorvia's language.
- Implemented Bukhari, Muslim, Nawawi, Abu Dawud, Tirmidhi, Nasai and Ibn Majah shortcuts.
- Full-book data is cached in Isar after first successful load.
- Search works locally by Hadith number, text and section.
- Local bookmarks are stored in Isar.
- Arabic source text is fetched on demand and cached.
- `.min.json` -> `.json` fallback is implemented.
- Religious-data transparency notice was added: important grading/reference questions should be checked against trusted editions/scholarly sources.

### 4. Daily Hadith in Noorvia Today
- Noorvia Today now includes a deterministic Daily Hadith card.
- Uses an individual Nawawi Hadith endpoint rather than downloading a full large collection on the dashboard.
- Bangla/English follows the app language.
- Individual Hadith responses are cached in Isar for offline reuse.
- Tapping the card opens the Nawawi Hadith library.

### 5. Halal Ingredient Assistant
- Added camera barcode scanning with `mobile_scanner`.
- Added Open Food Facts product lookup and Isar product cache.
- Supports manual barcode entry when camera scanning is unavailable.
- Displays product image/name/brand, ingredient text, allergens and Nutri-Score when provided by the source.
- Adds cautious keyword flags for alcohol/ethanol, gelatin, pork/porcine/lard, carmine/E120 and source-sensitive emulsifier/stearate terms.
- The screen explicitly DOES NOT make a Halal/Haram ruling. It only flags possible concerns for verification.
- Camera permission added for Android, iOS and macOS.
- Android minSdk is set to 23 for the scanner/modern ML Kit baseline.

### 6. Islamic Places Explorer
- Added a nearby Islamic-history/place explorer using the MediaWiki Action API.
- Uses geosearch around the user's coordinates, page images, coordinates and short extracts.
- Filters nearby pages for Islamic/mosque/madrasa/Muslim concepts.
- Uses Bangla Wikipedia in Bangla mode; if no Bangla geotagged result is available, it falls back to English rather than showing an empty result.
- Results are cached in Isar for 2 days.
- Tapping an item opens the source Wikipedia page.

### 7. Offline/data-source controls
Settings > Data Sources & Offline now documents:
- Al Quran Cloud
- AlAdhan
- OpenStreetMap/Overpass
- Open-Meteo
- Radio Browser
- Hadith API/jsDelivr
- Open Food Facts
- Wikimedia/Wikipedia
- openrouteservice
- Firebase/Firestore
- Isar

Safe transient cache clearing now also covers:
- `prayer_cache_v3`
- `ramadan_calendar_v3`
- `mosque_cache`
- `mosque_routes`
- `weather_cache_v1`
- `radio_cache_v2`
- `quran_search_v1`
- `hadith_api_v1`
- `open_food_facts`
- `wikimedia_islamic_places`

It does not intentionally remove Namaz history, Quran bookmarks/last-read/goals, settings or Hadith bookmarks.

## New dependency

```yaml
mobile_scanner: ^7.4.0
```

Run `flutter pub get` on a real Flutter environment so `pubspec.lock` and plugin registrants are updated by Flutter.

## New/major source files
- `lib/core/models/hadith_record.dart`
- `lib/core/services/hadith_service.dart`
- `lib/core/services/open_food_facts_service.dart`
- `lib/core/services/mosque_route_service.dart`
- `lib/core/services/islamic_places_service.dart`
- `lib/screens/services/halal_ingredient_page.dart`
- `lib/screens/location/islamic_places_page.dart`

Major modified integrations:
- `lib/screens/IslamicFeatures/hidithdemo.dart`
- `lib/core/models/mosque.dart`
- `lib/core/services/mosque_service.dart`
- `lib/screens/location/nearby_mosques_screen.dart`
- `lib/screens/companion/daily_companion_page.dart`
- `lib/screens/tools/tools_screen.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/settings/data_sources_page.dart`
- `lib/core/localization/app_i18n.dart`
- Android/iOS/macOS camera configuration

## Isar namespaces introduced/used
- `hadith_api_v1` — downloaded Hadith data + individual Arabic/text cache
- `hadith_user` — local Hadith bookmarks (user data; not part of safe transient clearing)
- `open_food_facts` — product cache
- `wikimedia_islamic_places` — nearby article cache
- `mosque_routes` — routed walking ETA cache

## Important production limitations
1. OpenStreetMap completeness varies by country/community; missing a mosque does not mean the mosque does not exist.
2. Open Food Facts is community-maintained and cannot be used as a religious Halal certification authority.
3. Hadith API is an open corpus; preserve collection/reference metadata and provide source transparency. Do not silently rewrite Hadith religious text with the generic UI translator.
4. Wikimedia results are an educational/history layer, not a comprehensive Islamic-place directory.
5. Direct ORS API keys inside a mobile binary are not true secrets. Use a secure proxy/restricted credential strategy for a large public deployment.
6. This execution environment does not include Flutter/Dart/Android SDKs, so a real compile/analyze/device test is still mandatory.

## Recommended release commands

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Then run the device checklist in `NOORVIA_FREE_API_TEST_CHECKLIST_2026-08-14.md`.
