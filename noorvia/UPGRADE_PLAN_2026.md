# Noorvia advanced upgrade plan — 2026

## Implemented in this snapshot

- Android/application package migration to `com.butterflydevs.noorvia`.
- Anonymous Firebase session foundation for private user data.
- Namaz tracker: local-first + Firestore per-day sync, with server-first conflict protection and one-time migration of local-only dates.
- Firestore-admin-controlled banners with cached/OpenSheet error fallback; an intentional zero-active-banner state now hides the carousel rather than reviving an old banner.
- Three Android home-screen widgets: full prayer times, next Azan with live countdown, Ramadan sehri/iftar.
- In-app widget pin request on Android 8+ supported launchers.
- Next-Azan widget recalculates the next prayer during widget refresh, shows a live countdown, and refreshes immediately after an enabled prayer alarm fires; Ramadan day advances across midnight from the last synced Hijri day.
- Ramadan API data persisted locally and full offline Ramadan generation fallback.
- Prayer time network failure now has local astronomical calculation fallback.
- Auto alarm re-sync whenever prayer times are refreshed/parsed.
- Pre-alarm fixed: reminder only; full Azan plays at the real prayer time.
- Azan playback moved to an Android foreground media service for better lock-screen/background reliability.
- Reboot/package-update alarm restore remains enabled.
- Alarm restore also reacts to manual clock/date/timezone changes and exact-alarm permission grants.
- Desired native alarms remain persisted even while exact-alarm access is denied, so they can be restored after permission is granted.
- Removed `USE_EXACT_ALARM`; retained user-granted `SCHEDULE_EXACT_ALARM` path.

## Phase 2 — account & sync

- Add visible account screen: Continue without account / Google / phone / email.
- Link anonymous uid to permanent account so existing tracker data is retained.
- Sync user settings, alarm preferences, bookmarks, Tasbih, Quran progress, Arabic-learning progress and streaks.
- Device list + last sync + manual backup/restore.

## Phase 3 — admin control plane

- Admin web panel (Firebase Auth + custom claims) for banners, notices, feature flags, Ramadan adjustments, API source priority and maintenance mode.
- Firestore `app_config/public` document for calculation method, offsets per city/prayer, Ramadan day correction and minimum app version.
- Push announcements through Firebase Cloud Messaging.
- Scheduled banner publish/unpublish and targeting by country/app version.

## Phase 4 — prayer/azan reliability

- Precompute and schedule a rolling 7–14 day exact-alarm window from local coordinates.
- Daily background refresh to replace fallback alarm times with updated values.
- Per-prayer Azan selection, separate pre-reminder sound, DND guidance and OEM battery-optimization guidance.
- Optional Bangladesh Islamic Foundation / local mosque correction offsets while keeping calculated fallback.
- Alarm diagnostics screen: permission, next trigger, battery restrictions, last fired time, next five alarms.

## Phase 5 — widgets & glance experience

- Widget configuration: location, calculation method, Bangla/English, compact/large layout.
- Daily Quran ayah / Dua widget.
- Namaz tracker widget with one-tap completed marking (authenticated write).
- Tasbih counter widget.
- Dynamic Android 12+ widget colors and richer previews.

## Phase 6 — advanced Islamic features

- Mosque jamaat/Iqamah crowdsourced schedule with verified mosque admin ownership.
- Ramadan fasting tracker and missed-fast/qaza tracker.
- Quran reading goals, khatam plan, streaks and cloud backup.
- Smart daily dashboard based on next prayer, Ramadan state, unfinished goals and saved content.
- Offline download manager for Quran audio, Ruqyah, books and learning packs.
- Search across Quran, Dua, Hadith/books and local content.

## Phase 7 — engineering/release hardening

- Replace debug release signing with production keystore + Play App Signing.
- Crashlytics, Performance Monitoring and privacy-safe analytics.
- Firestore App Check, stricter rules tests, rate limiting/abuse controls.
- CI build pipeline, flavors (`dev`, `staging`, `prod`) and environment config.
- Remove duplicate/legacy implementations and add unit/widget/integration tests for prayer calculation, alarm scheduling and offline sync.

## Current production hand-off notes

- No new Flutter dependency was required for the implemented scope; the project already contained Firebase, Adhan, Hijri, notifications and local-storage packages.
- The upgraded source cannot be considered Firebase-production-ready until Firebase Console has a newly registered Android app for `com.butterflydevs.noorvia` and its official `google-services.json` replaces the package-aligned placeholder in this snapshot.
- A full Flutter/Gradle build was not possible in the editing environment because the Flutter/Android SDK toolchain is not installed here. XML/JSON, resource references, package migration and edited-source delimiter/import checks were performed statically.
- A dedicated admin web UI is Phase 3. Right now an authenticated admin with the custom claim can manage `banners` through Firebase/Firestore tooling.
- Long-term no-open daily prayer-time correction (rolling 7–14 day schedules/background recomputation) remains Phase 4; today the native alarm self-reschedules as a safety fallback and fresh app prayer-time sync corrects it whenever data refreshes.
