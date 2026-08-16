# Noorvia advanced upgrade — change summary

Date: 2026-08-12

## Core identity
- Android namespace/applicationId → `com.butterflydevs.noorvia`.
- Related Android Kotlin package/channel and Apple/Linux bundle identifiers aligned.
- New official Firebase Android registration/config is still required before release.

## Prayer / Azan
- Native actual-prayer alarm and pre-reminder are now separate.
- Pre-reminder no longer plays the full Azan early.
- Actual Azan is played by a foreground media service using the bundled `assets/audio/azan.mp3`.
- Enabled alarms auto-resync whenever current prayer times are parsed/refreshed.
- Alarm recovery covers reboot, app update, clock/date/timezone changes and exact-alarm permission state changes.
- Offline prayer-time calculation mirrors the app's existing AlAdhan method 2 preset.

## Namaz tracker
- SharedPreferences remains the instant local cache.
- Every changed day is written under `users/{uid}/namaz_tracker/{yyyy-MM-dd}` in Cloud Firestore.
- Anonymous Firebase Auth provides the default private UID when no account is signed in.
- Cloud history wins for existing dates; legacy local-only dates migrate only after a server-backed snapshot.

## Admin banners
- Primary source is Firestore `banners`.
- Active banners update in realtime and are cached locally.
- Admin writes are protected by a Firebase custom claim in `firestore.rules`.
- Setting all banners inactive intentionally hides the carousel.
- Legacy OpenSheet remains an error/misconfiguration fallback.

## Ramadan offline
- Successful Ramadan API responses are persisted by city/Hijri year.
- With no network/cache, the app generates Ramadan dates and prayer times locally with `adhan_dart` + `hijri`.
- Bangladesh city calculations use UTC+6 in the local Ramadan fallback.

## Android home-screen widgets
- Prayer times widget.
- Next Azan widget with live countdown.
- Ramadan Sehri/Iftar widget.
- Direct pin request on supported Android launchers.
- Next-prayer label recalculates during widget refresh, with a live Android countdown; an actual prayer alarm refreshes it immediately to the following prayer. Ramadan day advances across midnight.

## Validation performed
- Android manifest/resource XML parsed successfully.
- JSON config parsed successfully.
- New Kotlin resource IDs/layout references checked.
- Old `com.butterflydevs.noorvia` / `com.noorvia.muslim_view` references removed from relevant source trees.
- Edited Dart files passed delimiter/relative-import static checks.
- Fixed one pre-existing bad relative import in `NamazNiyom.dart` discovered during validation.

## Remaining before production
1. Register `com.butterflydevs.noorvia` in Firebase and replace `google-services.json` with the official downloaded file.
2. Enable Anonymous Authentication and deploy `firestore.rules`.
3. Run `flutter pub get`, `flutter analyze`, Android debug/release builds and real-device alarm tests in a Flutter/Android SDK environment.
4. Replace debug release signing with the production keystore/Play App Signing setup.
5. Build the Phase 2 recoverable account flow and Phase 3 admin web panel when ready.
