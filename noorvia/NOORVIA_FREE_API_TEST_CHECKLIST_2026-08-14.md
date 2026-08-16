# Noorvia Free API Expansion — Device / Release Test Checklist

## Build
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] `flutter analyze` has no errors
- [ ] `flutter test` passes
- [ ] Android debug APK builds
- [ ] Android release AAB builds with production signing

## Package / Firebase regression
- [ ] Android package is `com.butterflydevs.noorvia`
- [ ] Genuine Firebase `google-services.json` matches that package
- [ ] Existing Namaz Firestore sync still works
- [ ] Existing admin banner updates still work
- [ ] Existing Smart Salah/Azan exact alarm flow still works
- [ ] Existing widgets still refresh

## Bangla / English
- [ ] Switch Bangla -> English without reinstall
- [ ] Tools titles translate naturally
- [ ] Mosque/Musalla UI translates
- [ ] Hadith UI translates, while Hadith source text comes from the selected language edition
- [ ] Halal Ingredient Assistant translates
- [ ] Islamic Places UI translates
- [ ] Daily Hadith follows current app language after reopening/reloading Today

## Hadith
- [ ] Bukhari opens online
- [ ] Muslim opens online
- [ ] Nawawi opens online
- [ ] Search by word works after book is loaded
- [ ] Search by number works
- [ ] Bookmark toggle persists after app restart
- [ ] Arabic source button loads and caches Arabic
- [ ] Disable internet and reopen an already cached collection
- [ ] Daily Hadith appears on Noorvia Today
- [ ] Tap Daily Hadith -> Nawawi library

## Halal Ingredient Assistant
- [ ] Android camera permission prompt appears only when scanner is opened
- [ ] iOS camera description is present
- [ ] Scanner reads EAN/UPC barcode
- [ ] Manual barcode entry works
- [ ] Known Open Food Facts product loads
- [ ] Product image failure does not crash UI
- [ ] Ingredient text displays when available
- [ ] Concern flags display only as warnings, never as a Halal/Haram verdict
- [ ] Offline reopen of a previously scanned barcode uses Isar cache

## Mosque + Musalla
- [ ] Location permission flow works
- [ ] Nearby mosque list loads
- [ ] Musalla/prayer-room items appear where OSM has them
- [ ] Turning “show musalla” off hides them
- [ ] Radius 1/3/5/10/20 km reloads correctly
- [ ] Way/relation OSM items with center coordinates render
- [ ] Address/opening/wheelchair/Wudu hints do not crash when absent
- [ ] Offline cached mosque list opens within cache validity
- [ ] Walking navigation opens Google Maps (or another handler)
- [ ] Without ORS key, offline walking estimate displays
- [ ] With a development ORS key, routed ETA displays and is cached

## Islamic Places
- [ ] Location-based MediaWiki query works
- [ ] Bangla mode requests Bangla Wikipedia
- [ ] If no Bangla nearby result, English fallback can populate results
- [ ] Thumbnail failure does not crash
- [ ] Tap item opens the correct Wikipedia page
- [ ] Cached results reopen offline

## Safe cache cleaner
- [ ] Clear safe cache succeeds
- [ ] Hadith downloaded cache is cleared
- [ ] Food cache is cleared
- [ ] Wikimedia cache is cleared
- [ ] Route cache is cleared
- [ ] Namaz tracker history is NOT deleted
- [ ] Quran goal/bookmark/last-read is NOT deleted
- [ ] App/settings/language is NOT reset
- [ ] Hadith user bookmarks are NOT deleted

## Performance / abuse protection
- [ ] Hadith large-book first load has loading state and does not freeze UI
- [ ] Reopening a cached book is substantially faster
- [ ] Rapid radius refresh does not spam multiple visible errors
- [ ] API failures show cached/fallback data when available
- [ ] No API secret is committed to source control

## Final physical-device regression
- [ ] Android 12/13/14/15+ exact alarm permission path tested where available
- [ ] Background Smart Salah geofence tested
- [ ] DND/previous-mode restore tested
- [ ] Reboot alarm restore tested
- [ ] Quran audio/auto-highlight still works after new scanner plugin integration
