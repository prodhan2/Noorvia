# Noorvia Firebase setup (required before production release)

## 1. Register the new Android app

The source now uses:

`com.butterflydevs.noorvia`

In Firebase Console, add/register an Android app with that exact package name and download its new `google-services.json` into:

`android/app/google-services.json`

The file in this working snapshot was package-aligned only so the source migration is coherent; replace it with the officially generated file before release, especially before Google sign-in / restricted API-key use.

## 2. Enable Authentication

Firebase Console → Authentication → Sign-in method → enable **Anonymous**.

Noorvia uses anonymous auth as the invisible default identity so each user's namaz tracking can be private in Firestore. A future account screen can link the anonymous user to Google/phone/email without losing data.

## 3. Firestore collections

### `users/{uid}/namaz_tracker/{yyyy-MM-dd}`

Fields:
- `date`
- `prayers`: map of Bangla prayer name → status index
  - 0 = none
  - 1 = completed
  - 2 = missed
  - 3 = qaza
- `completedCount`
- `missedCount`
- `qazaCount`
- `updatedAt`

The app keeps a SharedPreferences copy for instant local UI and Firestore also queues/caches mobile reads/writes offline.

### `banners/{bannerId}`

Recommended fields:

```text
imageUrl: "https://..."
details: "..."
title: "..."
targetUrl: "https://..."   // optional
active: true
sortOrder: 10
```

The home poster/banner carousel reads this collection in realtime. If an admin intentionally leaves zero active banners, the carousel hides. The old OpenSheet source is used only as an error/misconfiguration fallback.

## 4. Admin banner writes

`firestore.rules` expects an admin custom claim:

`admin: true`

Set this claim only from a trusted server/Admin SDK. Normal/anonymous users can read active banners but cannot edit them.

## 5. Deploy rules

From the Flutter project directory after Firebase CLI setup:

```bash
firebase deploy --only firestore:rules
```

## 6. Android exact alarm permission

Noorvia now keeps `SCHEDULE_EXACT_ALARM` rather than `USE_EXACT_ALARM`. The user must grant exact-alarm access on Android versions that require it. The app already requests notification/exact-alarm access through its alarm initialization flow.

## 7. Important account note

Anonymous Auth gives the installation a private UID and keeps namaz tracking synced while that Firebase session exists. For restore after app uninstall or on a second phone, implement Phase 2 account linking (Google/phone/email) so the same UID/data can be recovered.
