# Noorvia Max Global Pro — Implementation Snapshot

Date: 2026-08-12
Canonical Android applicationId / namespace: `com.butterflydevs.noorvia`
Internal Dart package: `muslim_view`

## What this snapshot adds on top of Noorvia Ultra

### Quran Pro+
- Al Quran Cloud-backed Uthmani Arabic + `quran-tajweed` + Bangla + Saheeh International + transliteration + selectable reciter audio.
- Tajweed color renderer for the upstream bracket markup, with a user setting to enable/disable colors.
- Global Quran Search for Bangla, English and Arabic.
- Search uses online API first, then exact cached search, then scans Surahs already cached in Isar.
- Khatam planner based on the 604-page Mushaf with 7/15/30/60/90-day presets.
- Hifz progress counter and daily Hifz target foundation.
- Quran goal/Hifz progress is local-first in Isar and backed up privately to Firestore when Firebase auth is available.
- Noorvia Today has a deterministic Daily Ayah. The actual Quran text/verified translation is fetched through the Quran repository and cached; it is not hard-coded into the app.
- Existing Ayah-level recitation highlighting, auto-scroll, offline audio, repeat modes, reading themes and Mushaf/Study modes remain intact.

### Noorvia Today
- One daily companion page combining next Salah, remaining time, current prayer progress, Hijri date, today's Namaz completion, Khatam progress, weather context, Daily Ayah and quick Quran actions.
- Current weather uses Open-Meteo through a dedicated service and Isar cache with a 30-minute freshness window.
- If weather/network is unavailable, a cached value is used when possible.

### Global Islamic Radio resilience
- Noorvia's curated radio JSON remains primary.
- Radio Browser is a global Quran/Islamic fallback when the primary feed fails.
- Searches Quran and Islamic tags, excludes broken stations and prefers higher-voted stations.
- Sends a descriptive Noorvia User-Agent and registers Radio Browser station clicks.
- Normalized station catalogue is cached in Isar; legacy SharedPreferences radio cache is migrated/read as fallback.

### Data transparency and offline controls
- New Settings page: Data Sources & Offline.
- Explains Quran, prayer/Hijri, mosque/map, weather, radio, Firebase and local Isar roles.
- Safe cache cleanup clears transient prayer/Ramadan/mosque/banner/weather/radio/search cache only.
- Namaz history, Quran goals/bookmarks/last read and user settings are deliberately preserved.

### Localization
- Added natural English mappings for the new Quran Search, Quran Goals/Hifz, Noorvia Today, Tajweed and Data Sources experiences.
- Verified Quran Arabic and verified Quran translations continue to bypass the generic UI translation engine.
- Dynamic Bangla phrase replacement remains Bangla-boundary aware.

## Data architecture

UI -> repository/service -> Isar first -> network refresh/cloud sync.

Local-first / offline:
- Prayer and Ramadan cache
- Mosque and banner cache
- Namaz history
- Quran Surah/search/audio/settings/bookmarks/last-read/goals
- Language and Smart Salah settings
- Weather and Radio catalogue cache

Cloud:
- Firestore private user data and cross-device recovery
- Admin-controlled banners/config
- Namaz and Quran-goal backup

## Important API/legal notes

- Al Quran Cloud is the main keyless Quran source. Cache aggressively and preserve text/translation attribution. Quran/translation/recitation rights and commercial use need to follow the provider's current terms and the relevant translator/reciter rights.
- Open-Meteo's public free endpoint is suitable for non-commercial free-tier use. If Noorvia becomes a commercial/paid/high-volume product, move weather to an appropriate commercial plan or a compliant self-hosted/provider abstraction.
- Radio Browser is free/open, but public nodes can change; the integration should continue to be treated as a fallback and cached.
- Quran Foundation APIs that require client credentials must only be integrated through a secure backend proxy. Never place a client secret in the Flutter APK/AAB.
- OpenStreetMap/Overpass/Nominatim public services require responsible caching and usage-policy compliance.

## Build/release requirements

This execution environment did not include Flutter/Dart/Android SDK, so a real build was not run here. Before release run:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Then test on a real Android device:
- exact Azan alarms when app is killed
- reboot/timezone/date changes
- Smart Salah vibrate/silent/DND restore
- background mosque geofence
- all home widgets
- Bangla/English switching including native notifications/widgets
- offline Quran/search/goals/audio
- Firestore Namaz/Quran goal recovery
- radio fallback and playback
- airplane-mode/offline weather/cache behavior

## Firebase production requirement

Register the exact package `com.butterflydevs.noorvia` in the intended Firebase project, use the genuine generated `google-services.json`, deploy reviewed Firestore rules, configure App Check as appropriate, and use a real release signing key. Do not ship debug signing or placeholder Firebase configuration.
