# Noorvia Max — Production Test Checklist

## 1. Toolchain
- [ ] `flutter pub get`
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] `flutter analyze` = no errors
- [ ] `flutter test`
- [ ] debug APK builds
- [ ] release AAB builds with production signing

## 2. Package/Firebase
- [ ] Android package is `com.butterflydevs.noorvia`
- [ ] genuine matching Firebase `google-services.json`
- [ ] Anonymous Auth enabled if guest cloud sync is retained
- [ ] Firestore rules deployed and emulator-tested
- [ ] user A cannot read/write user B data
- [ ] only trusted admin claims can write admin content

## 3. Offline / Isar
- [ ] cold start offline after one prior online sync
- [ ] prayer/Ramadan cache works
- [ ] Namaz history survives restart
- [ ] Quran last-read/bookmark/goal survives restart
- [ ] Quran cached Surah opens offline
- [ ] Quran search falls back to cached Surahs offline
- [ ] radio catalogue is visible offline after prior sync
- [ ] safe cache-clear does not delete progress/history/settings

## 4. Quran Pro+
- [ ] all 114 Surahs show real source data
- [ ] Arabic diacritics display correctly
- [ ] Bangla and English verified translations are not UI-machine-translated
- [ ] Tajweed colors on/off
- [ ] Mushaf and Study modes
- [ ] Arabic/translation font size and line spacing
- [ ] reciter selection
- [ ] speed/repeat/continuous playback
- [ ] Ayah highlight follows recitation at Ayah level
- [ ] auto-scroll
- [ ] per-Surah offline audio download/cache
- [ ] global search in Bangla, English, Arabic
- [ ] result opens the correct Ayah
- [ ] Khatam planner progress
- [ ] Hifz counter
- [ ] Firestore backup/restore of Quran goal
- [ ] Daily Ayah opens correct Surah/Ayah

## 5. Smart Salah / alarms
- [ ] Prayer Time Only mode
- [ ] Nearby Mosque + Prayer Time mode
- [ ] per-prayer toggles
- [ ] before/after window
- [ ] Vibrate
- [ ] Silent
- [ ] DND after granting Notification Policy Access
- [ ] previous mode restores correctly
- [ ] already-silent phone is not incorrectly restored to normal
- [ ] ENTER/DWELL/EXIT mosque behavior
- [ ] background location denied path is clear
- [ ] reboot reschedule
- [ ] timezone/date/time change reschedule
- [ ] exact-alarm permission denied/granted path
- [ ] pre-reminder is not full Azan
- [ ] actual prayer time plays Azan

## 6. Widgets
- [ ] Prayer Times widget
- [ ] Next Azan + countdown widget
- [ ] Ramadan Sehri/Iftar widget
- [ ] Bangla widget labels
- [ ] English widget labels
- [ ] widget updates after prayer passes
- [ ] widget updates after timezone/location/prayer refresh

## 7. Noorvia Today
- [ ] next prayer and countdown/progress
- [ ] Hijri date
- [ ] today's completed Salah count
- [ ] Khatam progress
- [ ] current weather and cached fallback
- [ ] Daily Ayah
- [ ] Quran/Search quick actions

## 8. Radio
- [ ] curated Noorvia feed
- [ ] simulate curated feed failure and verify Radio Browser fallback
- [ ] Quran/Islamic stations returned
- [ ] broken stream handling
- [ ] station image missing fallback
- [ ] playback stops Quran audio before radio starts
- [ ] cached station list persists

## 9. Localization
- [ ] Bangla -> English live switch
- [ ] English -> Bangla live switch
- [ ] Settings/Quran/Today/Radio/Smart Salah checked manually
- [ ] Android notifications follow language
- [ ] Android widgets follow language
- [ ] Quran Arabic/verified translations remain unchanged

## 10. Store readiness
- [ ] privacy policy
- [ ] data-safety form matches actual collection/permissions
- [ ] background-location disclosure if mosque-aware mode is published
- [ ] exact-alarm Play policy reviewed
- [ ] Open-Meteo usage plan appropriate for commercial status
- [ ] Quran/translation/reciter attribution reviewed
- [ ] OSM attribution/usage requirements reviewed
- [ ] Crashlytics/App Check/production monitoring configured
