# Noorvia Ultra Implementation — 2026-08-12

## Canonical identity
- Android namespace/applicationId: `com.butterflydevs.noorvia`
- iOS/macOS bundle identifier aligned to `com.butterflydevs.noorvia`
- App display brand: **Noorvia**
- Flutter/Dart package name intentionally remains `muslim_view` to avoid a high-risk internal import migration in this snapshot.

## 1. Offline-first Isar architecture
Noorvia now uses `isar_community` as the primary local document/cache layer on Dart IO platforms through a generic `LocalStore` abstraction. Web has a safe stub.

Current Isar-backed areas:
- Namaz tracker history/cache
- Prayer time/location cache
- Ramadan calendar cache
- Mosque cache
- Admin banner cache
- App language preference
- Smart Salah settings
- Quran text/surah cache
- Quran bookmarks and last-read progress
- Quran reader settings
- Mushaf source/reader state

Cloud remains Firestore for user-owned sync, admin-controlled content and cross-device data.

## 2. Bangla + English app UI
- Settings → Language → বাংলা / English
- Language persists offline in Isar.
- Material locale switches live.
- Android native widgets, prayer notifications and Azan foreground notification also follow the selected language.
- Legacy Bangla-first visible `Text(...)` strings are routed through a centralized localization layer.
- High-visibility UI strings use natural exact English mappings.
- Phrase fallback is Bangla-word-boundary aware so words like `আবার`, `বার্তা`, `দিনাজপুর` are not corrupted by substring replacement.
- If a rich remote/religious content block lacks a verified English version, Noorvia preserves the original content rather than showing a broken mixed-language translation.
- Quran Arabic and verified Quran translations bypass the app UI translation engine.

## 3. Advanced Quran reader
### Native Noorvia Mushaf is now the default
- Mushaf screen defaults to **Noorvia Native Mushaf** instead of opening a website.
- Optional external sources remain available.
- Last Surah/source state is saved offline.

### Real Quran data
The new reader loads real full-Surah data from Al Quran Cloud instead of placeholder ayahs:
- Uthmani Arabic
- Bangla translation (`bn.bengali`)
- Saheeh International English
- English transliteration
- Multiple reciters/audio
- Page/Juz metadata

### Reading modes
1. **Mushaf** — book/paper focused reading
2. **Study** — ayah blocks with translation, actions and audio controls

### Audio-synced reading
- Ayah-by-ayah playback
- Active Ayah visual highlight
- Auto-scroll to the currently playing Ayah
- Previous/next Ayah controls
- Continuous playback
- Repeat current Ayah / repeat Surah
- Playback speed
- Current Ayah progress scrubber
- Cache audio while listening
- Download complete Surah audio for offline listening

> Important accuracy note: this snapshot uses verified **Ayah-level synchronization**. If an Ayah wraps across multiple visual lines, the complete active Ayah block is highlighted. Exact word/printed-line timing is deliberately not approximated. Quran Foundation's exact timing/page-line APIs require a secure credentialed backend/proxy before Noorvia should enable exact word/line sync.

### Quran reader settings
- Mushaf / Study layout
- Bangla / English / both translations
- Show/hide translation
- Show/hide transliteration
- Show/hide Ayah number
- Highlight playing Ayah
- Auto-scroll with audio
- Show Page/Juz markers
- Paper / Clean / Sepia / Night reader theme
- Arabic font: NooreHuda / NooreHera / System
- Arabic font size
- Translation font size
- Arabic line spacing
- Reciter selection
- Playback speed
- Repeat mode
- Continuous playback
- Cache audio while playing

## 4. Smart Salah Mode
Settings → Smart Salah Mode

User controls:
- Enable/disable
- Trigger: Prayer Time Only / Nearby Mosque + Prayer Time
- Per-prayer toggles: Fajr, Dhuhr, Asr, Maghrib, Isha
- Before-prayer activation window
- After-prayer restore window
- Phone mode: Vibrate / Silent / DND
- Mosque radius (100–500m UI; native safety clamp 100–1000m)
- Restore previous phone mode
- DND access status/open system access
- Background-location permission status
- Refresh mosque geofences

Behavior:
- Prayer alarm schedule also schedules the Smart Salah window.
- Mosque-aware mode only applies when Android geofencing says the user is in an active mosque zone.
- ENTER/DWELL/EXIT geofence transitions are used with dwell/responsiveness to reduce drive-by triggers.
- Previous ringer/DND state is restored after the prayer window.
- Raw continuous location is not stored by Smart Salah manager; it keeps geofence membership state.
- DND priority mode respects Android's configured priority/emergency exceptions.

## 5. Prayer/Azan reliability retained and integrated
- Native exact alarm architecture
- User-granted `SCHEDULE_EXACT_ALARM`
- Pre-reminder is separate from actual Azan
- Actual prayer time starts bundled Azan through a foreground media service
- Reboot/app update/time/date/timezone/exact-alarm permission changes restore schedules
- Smart Salah windows are tied to the same authoritative enabled prayer alarms

## 6. Namaz tracking
- Fast local Isar history
- Firestore user/day documents
- Firebase anonymous session when a visible account does not exist
- Existing local history migration waits for a server-backed snapshot before pushing missing dates
- Firestore offline queue remains available in addition to Isar local-first state

## 7. Admin banner + Firestore rules
- `banners` collection remains admin-controlled
- Active banners can be changed without an app release
- Last downloaded banner data can be shown from local cache
- Firestore rules isolate user data by uid
- `app_config` is public-read/admin-write and MUST contain public config only, never secrets

## 8. Android home-screen widgets
- Full Prayer Times
- Next Azan + live countdown
- Ramadan Sehri/Iftar
- Selected language syncs to native widget labels
- Offline/cached prayer and Ramadan state is reused

## Required developer commands before release
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

`local_record.g.dart` is included as a generated-compatible schema so the source snapshot is self-contained, but regenerate it with the command above in the real Flutter environment.

## Firebase actions required
1. Firebase Console: register the Android app `com.butterflydevs.noorvia`.
2. Download the genuine new `google-services.json` and replace `android/app/google-services.json`.
3. Enable Anonymous Authentication if the guest/private sync design is retained.
4. Deploy `firestore.rules`.
5. Set admin custom claim (`admin: true`) only through a trusted server/Admin SDK.
6. Configure proper production signing; the current project still carries the original debug release-signing placeholder.

## Physical-device test required
Exact alarm, DND/Silent control, background location/geofencing, foreground Azan playback and launcher widgets are OS/device features. Test these on physical Android devices across Android 10/12/13/14/15+ before Play release.
