# Noorvia Ultra — Release Test Checklist

## Build
- [ ] `flutter pub get`
- [ ] regenerate Isar schema with build_runner
- [ ] `flutter analyze` has no errors
- [ ] `flutter test`
- [ ] Android debug APK builds
- [ ] Android release AAB builds with production signing

## Language
- [ ] Bangla → English updates current screen without restart
- [ ] English → Bangla updates current screen without restart
- [ ] language persists after force close/reboot
- [ ] prayer notifications follow language
- [ ] all 3 Android widgets follow language
- [ ] Quran Arabic text is unchanged by language switch
- [ ] verified Bangla/English Quran translations remain unchanged

## Quran
- [ ] all 114 Surahs open with real data
- [ ] offline reopened Surah loads from Isar
- [ ] Mushaf mode looks correct in light/dark reader themes
- [ ] Study mode actions work
- [ ] audio playback works for all exposed reciters
- [ ] active Ayah highlights during playback
- [ ] auto-scroll follows active Ayah
- [ ] previous/next/repeat/continuous playback work
- [ ] playback speed works
- [ ] full Surah audio download works
- [ ] downloaded audio works in airplane mode
- [ ] bookmark and last-read persist

## Smart Salah
- [ ] disabled state never changes phone mode
- [ ] Prayer Time Only works without background location
- [ ] mosque-aware mode requests required permissions clearly
- [ ] geofence does not trigger on quick drive-by where DWELL is expected
- [ ] Vibrate mode works
- [ ] Silent mode works with required policy access
- [ ] DND works with policy access
- [ ] priority/emergency caller behavior follows Android DND policy
- [ ] previous mode restores after configured window
- [ ] stale restore from an older prayer does not override a newer session
- [ ] reboot/timezone/time change restores scheduling

## Namaz tracker
- [ ] offline status update is immediate
- [ ] Isar history survives restart
- [ ] queued Firestore sync completes after internet returns
- [ ] two-device data does not erase unrelated dates
- [ ] Firestore rules block another uid

## Widgets
- [ ] Prayer Times widget can be pinned
- [ ] Next Azan widget can be pinned and countdown advances
- [ ] Ramadan widget can be pinned
- [ ] midnight/day changes refresh correctly
- [ ] cached/offline values remain usable

## Firebase/admin
- [ ] genuine google-services.json matches `com.butterflydevs.noorvia`
- [ ] Anonymous Auth enabled if used
- [ ] firestore.rules deployed
- [ ] normal user cannot edit banners/app_config
- [ ] admin custom claim can edit banners/app_config
