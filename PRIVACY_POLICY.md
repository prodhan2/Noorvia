# Privacy Policy for Noorvia

**Effective Date:** September 6, 2026  
**Last Updated:** September 6, 2026  
**Developer / Organization:** Butterfly Devs  
**App Name:** Noorvia (Android Package: `com.butterflydevs.noorvia`)  
**Contact Email:** support@butterflydevs.com  

---

## 1. Introduction
Welcome to **Noorvia**, developed by **Butterfly Devs** ("we", "our", or "us"). We are committed to protecting your privacy and ensuring you have a positive, spiritually fulfilling, and secure experience while using our mobile application.

This Privacy Policy explains how our app collects, uses, stores, and safeguards your information when you use the Noorvia mobile application across Android, iOS, and other supported platforms.

By downloading, installing, or using Noorvia, you agree to the collection and use of information in accordance with this Privacy Policy.

---

## 2. Core Philosophy: Offline-First & Privacy by Design
Noorvia is built with an **Offline-First** philosophy. Most features—including prayer time calculations, offline Quran reading, digital Tasbih, daily Duas, and Ruqyah guides—function entirely on your device without transmitting personal data to any external server. We do **not** sell, rent, trade, or monetize your personal information.

---

## 3. Information We Collect and How We Use It

### A. Location Data (Precise and Approximate)
* **What We Collect:** GPS coordinates (Latitude & Longitude) or user-selected city.
* **Why We Need It:**
  1. **Accurate Prayer Times & Azan:** To calculate precise local prayer times based on astronomical algorithms.
  2. **Qibla Compass:** To determine the exact angle and direction towards the Kaaba (Makkah).
  3. **Nearby Mosque Finder (Amar Mosjid):** To show mosques nearest to your current location.
* **Background Location (Optional):** Only if you explicitly enable the *Smart Salah Mode* to automatically detect when you enter a mosque and mute your phone during congregation.
* **How It Is Handled:** Location data is processed directly on your device. We do not track your movement history or store persistent location logs on our remote servers.

### B. Device Sensors (Magnetometer, Accelerometer & Gyroscope)
* **Why We Need It:** Used in real-time exclusively to operate the 3D Qibla Compass to detect device orientation.
* **How It Is Handled:** Sensor data is processed entirely in device memory and is never recorded, stored, or transmitted.

### C. Camera & Barcode Scanner (Optional)
* **Why We Need It:** If you use the Halal Ingredient Assistant to scan product barcodes.
* **How It Is Handled:** The camera is used solely to read product barcodes. No photos, videos, or facial data are captured, stored, or uploaded.

### D. Notifications & Alarms
* **Why We Need It:** To deliver scheduled Azan audio alarms, pre-prayer alerts, and daily Islamic reminders (morning and evening).
* **Permissions Used:** `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, and `FOREGROUND_SERVICE`.
* **How It Is Handled:** Alarms and notifications are scheduled and triggered locally by the operating system on your device.

### E. Do Not Disturb (DND) / Notification Policy Access (Optional)
* **Why We Need It:** If you enable the *Smart Salah Silent Mode*, this permission allows the app to automatically silence notifications and incoming ringtones during prayer times, and restore previous sound profiles afterwards.

### F. Firebase Services & Analytics
We use industry-standard Google Firebase services to ensure app stability and anonymous data synchronization:
* **Firebase Authentication:** Provides anonymous/session management so your saved bookmarks, Quran progress, and preferences can sync smoothly.
* **Cloud Firestore:** Stores optional cloud sync data (such as user favorites and progress).
* **Firebase Crashlytics & Performance (if enabled):** Collects non-identifiable technical diagnostics, error stack traces, and device OS version to help us fix crashes and improve stability.

---

## 4. Data Storage and Retention
* **Local Storage:** Your settings, prayer history, Quran bookmarks, and offline preferences are stored locally on your device using a secure embedded database (`Isar` / `SharedPreferences`).
* **Data Deletion:** You can delete all locally stored data at any time by clearing the application data/cache through your device settings or by uninstalling the application.

---

## 5. Third-Party Services
Our application may interact with trusted third-party service providers solely to facilitate core app features:
* **Google Play Services:** For core Android APIs, location services, and app updates. [Google Privacy Policy](https://policies.google.com/privacy)
* **Firebase (Google LLC):** For authentication, cloud database, and diagnostics. [Firebase Privacy Policy](https://firebase.google.com/support/privacy)
* **OpenStreetMap / Overpass API:** To fetch public mosque map information without sending personal identifiers.

We do not display third-party behavioral advertising or use third-party user tracking SDKs.

---

## 6. Children's Privacy (COPPA & GDPR Compliance)
Noorvia is an educational and religious companion suitable for audiences of all ages, including families and children. We do **not** knowingly collect or solicit personally identifiable information from children under the age of 13. If you believe that a child has provided us with personal information, please contact us, and we will promptly delete it.

---

## 7. Security of Your Data
We prioritize the security of your information. We implement modern security standards, HTTPS encryption for all network requests, and sandboxed on-device database storage. However, please remember that no method of electronic storage or transmission over the internet is 100% secure.

---

## 8. Permissions Summary

| Permission | Category | Purpose |
| :--- | :--- | :--- |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Location | Calculate prayer times, Qibla compass, find nearby mosques |
| `ACCESS_BACKGROUND_LOCATION` | Location (Optional) | Smart Salah auto-silent mode near registered mosques |
| `CAMERA` | Hardware (Optional) | Scan food barcodes for Halal ingredient lookup |
| `POST_NOTIFICATIONS` | Notifications | Send Azan alarms and daily prayer reminders |
| `SCHEDULE_EXACT_ALARM` | System | Trigger precise Azan playback at exact prayer times |
| `ACCESS_NOTIFICATION_POLICY` | System (Optional) | Mute/restore phone volume during prayer (Smart Salah) |
| `INTERNET` / `ACCESS_NETWORK_STATE` | Network | Audio Quran streaming, map data, Firebase sync |

---

## 9. Changes to This Privacy Policy
We may update our Privacy Policy periodically to reflect app improvements or regulatory changes. Any updates will be posted on this page with an updated "Last Updated" date. We encourage you to review this policy periodically.

---

## 10. Contact Us
If you have any questions, suggestions, or concerns regarding this Privacy Policy or your data, please feel free to reach out to us:

* **Organization:** Butterfly Devs
* **App:** Noorvia
* **Email:** support@butterflydevs.com
* **Website / Repository:** https://github.com/prodhan2/Noorvia