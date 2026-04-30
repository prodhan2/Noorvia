# Requirements Document

## Introduction

এই ফিচারটি Noorvia ইসলামিক অ্যাপের জন্য একটি Prayer Times Calendar পেজ তৈরি করবে। পেজটি বাংলাভাষী মুসলিম ব্যবহারকারীদের জন্য ডিজাইন করা হয়েছে। Aladhan API ব্যবহার করে নির্বাচিত মাস ও বছরের প্রতিটি দিনের নামাজের সময়সূচি, সূর্যোদয়/সূর্যাস্ত, সাহরি/ইফতার এবং নামাজের নিষিদ্ধ সময় প্রদর্শন করবে। সম্পূর্ণ UI বাংলায় থাকবে এবং ব্যাকগ্রাউন্ড সাদা হবে।

## Glossary

- **PrayerTimesCalendarPage**: নামাজের সময়সূচি ক্যালেন্ডার পেজ — এই ফিচারের মূল Flutter widget
- **AladhanService**: Aladhan API (`https://api.aladhan.com/v1/calendarByCity`) থেকে ডেটা ফেচ করার সার্ভিস লেয়ার
- **DayCard**: একটি নির্দিষ্ট দিনের সমস্ত নামাজের সময় প্রদর্শনকারী কার্ড widget
- **PrayerTimeEntry**: একটি নির্দিষ্ট নামাজের নাম ও সময় ধারণকারী ডেটা মডেল
- **ForbiddenTimeSection**: নামাজের নিষিদ্ধ সময় (সকাল, দুপুর, সন্ধ্যা) প্রদর্শনকারী সেকশন
- **HijriDate**: ইসলামিক হিজরি তারিখ
- **BengaliCalendarDate**: বাংলা সনের তারিখ
- **Suhoor**: সাহরি — ফজরের আগের শেষ খাওয়ার সময় (Fajr সময়ের সমান)
- **Iftar**: ইফতার — মাগরিবের সময় (Maghrib সময়ের সমান)
- **Method**: Aladhan API-এর নামাজের সময় গণনা পদ্ধতি (Bangladesh-এর জন্য method=1)

---

## Requirements

### Requirement 1: পেজ নেভিগেশন ও AppBar

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি অ্যাপের মধ্যে থেকে Prayer Times Calendar পেজে নেভিগেট করতে চাই, যাতে আমি সহজে নামাজের সময়সূচি দেখতে পারি।

#### Acceptance Criteria

1. THE PrayerTimesCalendarPage SHALL একটি AppBar প্রদর্শন করবে যার title "ক্যালেন্ডার" বাংলায় লেখা থাকবে।
2. THE PrayerTimesCalendarPage SHALL AppBar-এর ডান দিকে একটি calendar/grid আইকন প্রদর্শন করবে।
3. THE PrayerTimesCalendarPage SHALL সম্পূর্ণ পেজের ব্যাকগ্রাউন্ড সাদা (`Colors.white`) রাখবে।
4. THE PrayerTimesCalendarPage SHALL AppBar-এর ব্যাকগ্রাউন্ড সবুজ (`Colors.green.shade700`) রাখবে।

---

### Requirement 2: মাস ও বছর নির্বাচন

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি যেকোনো মাস ও বছর নির্বাচন করতে চাই, যাতে আমি সেই মাসের সম্পূর্ণ নামাজের সময়সূচি দেখতে পারি।

#### Acceptance Criteria

1. THE PrayerTimesCalendarPage SHALL পেজের শীর্ষে দুটি Dropdown প্রদর্শন করবে — একটি মাসের জন্য এবং একটি বছরের জন্য।
2. THE PrayerTimesCalendarPage SHALL মাসের Dropdown-এ বাংলায় ১২টি মাসের নাম প্রদর্শন করবে (জানুয়ারি, ফেব্রুয়ারি, মার্চ, এপ্রিল, মে, জুন, জুলাই, আগস্ট, সেপ্টেম্বর, অক্টোবর, নভেম্বর, ডিসেম্বর)।
3. THE PrayerTimesCalendarPage SHALL বছরের Dropdown-এ ২০২৪ থেকে ২০৩০ পর্যন্ত বছরগুলো প্রদর্শন করবে।
4. WHEN ব্যবহারকারী একটি নতুন মাস বা বছর নির্বাচন করেন, THE AladhanService SHALL নতুন মাস ও বছরের ডেটা ফেচ করবে।
5. THE PrayerTimesCalendarPage SHALL পেজ লোড হওয়ার সময় বর্তমান মাস ও বছর ডিফল্ট হিসেবে নির্বাচিত রাখবে।

---

### Requirement 3: Aladhan API থেকে ডেটা ফেচ

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি সঠিক ও আপডেটেড নামাজের সময়সূচি দেখতে চাই, যাতে আমি সময়মতো নামাজ আদায় করতে পারি।

#### Acceptance Criteria

1. THE AladhanService SHALL `https://api.aladhan.com/v1/calendarByCity?city={city}&country=Bangladesh&method=1&month={month}&year={year}` এন্ডপয়েন্ট থেকে ডেটা ফেচ করবে।
2. THE AladhanService SHALL ডিফল্ট শহর হিসেবে "Dhaka" ব্যবহার করবে।
3. WHEN API সফলভাবে রেসপন্স করে, THE PrayerTimesCalendarPage SHALL প্রতিটি দিনের নামাজের সময় প্রদর্শন করবে।
4. WHEN API ফেচ চলাকালীন, THE PrayerTimesCalendarPage SHALL একটি `CircularProgressIndicator` প্রদর্শন করবে।
5. IF API ফেচ ব্যর্থ হয়, THEN THE PrayerTimesCalendarPage SHALL বাংলায় একটি ত্রুটি বার্তা প্রদর্শন করবে এবং পুনরায় চেষ্টা করার বিকল্প দেবে।
6. THE AladhanService SHALL প্রতিটি দিনের জন্য নিম্নলিখিত সময়গুলো পার্স করবে: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha।

---

### Requirement 4: আজকের তারিখের হেডার ব্যানার

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি আজকের হিজরি তারিখ ও বাংলা তারিখ একসাথে দেখতে চাই, যাতে আমি ইসলামিক ক্যালেন্ডার সম্পর্কে সচেতন থাকতে পারি।

#### Acceptance Criteria

1. THE PrayerTimesCalendarPage SHALL ডেটা লোড হওয়ার পর একটি সবুজ হেডার ব্যানার প্রদর্শন করবে।
2. THE PrayerTimesCalendarPage SHALL হেডার ব্যানারে আজকের হিজরি তারিখ বাংলায় প্রদর্শন করবে (যেমন: "১৫ রমজান ১৪৪৬")।
3. THE PrayerTimesCalendarPage SHALL হেডার ব্যানারে আজকের গ্রেগরিয়ান তারিখ বাংলায় প্রদর্শন করবে (যেমন: "১৫ মার্চ ২০২৫")।
4. WHEN বর্তমান মাস নির্বাচিত না থাকে, THE PrayerTimesCalendarPage SHALL হেডার ব্যানারে নির্বাচিত মাসের প্রথম দিনের তথ্য প্রদর্শন করবে।

---

### Requirement 5: দৈনিক নামাজের সময় কার্ড

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি প্রতিটি দিনের সমস্ত নামাজের সময় একটি সুন্দর কার্ডে দেখতে চাই, যাতে আমি সহজে সময়সূচি অনুসরণ করতে পারি।

#### Acceptance Criteria

1. THE PrayerTimesCalendarPage SHALL প্রতিটি দিনের জন্য একটি আলাদা DayCard প্রদর্শন করবে।
2. THE DayCard SHALL দিনের তারিখ (গ্রেগরিয়ান ও হিজরি) কার্ডের শীর্ষে প্রদর্শন করবে।
3. THE DayCard SHALL নিম্নলিখিত নামাজের সময়গুলো বাংলা নামসহ প্রদর্শন করবে:
   - ফজর (Fajr)
   - যুহর (Dhuhr)
   - আসর (Asr)
   - মাগরিব (Maghrib)
   - ইশা (Isha)
4. THE DayCard SHALL নিম্নলিখিত অতিরিক্ত সময়গুলো প্রদর্শন করবে:
   - সূর্যোদয় (Sunrise)
   - সূর্যাস্ত (Sunset — Maghrib সময়ের সমান)
   - সাহরি (Suhoor — Fajr সময়ের সমান)
   - ইফতার (Iftar — Maghrib সময়ের সমান)
5. THE DayCard SHALL সময়গুলো ১২-ঘণ্টা ফরম্যাটে (AM/PM) প্রদর্শন করবে।
6. WHEN কোনো দিন আজকের তারিখ হয়, THE DayCard SHALL সেই কার্ডটি বিশেষভাবে হাইলাইট করবে (যেমন: সবুজ বর্ডার বা ব্যাকগ্রাউন্ড)।
7. WHEN কোনো দিন আজকের তারিখ হয়, THE DayCard SHALL একটি শেয়ার আইকন প্রদর্শন করবে।

---

### Requirement 6: নামাজের নিষিদ্ধ সময় সেকশন

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি প্রতিটি দিনের নামাজের নিষিদ্ধ সময়গুলো জানতে চাই, যাতে আমি ভুল সময়ে নামাজ না পড়ি।

#### Acceptance Criteria

1. THE DayCard SHALL প্রতিটি দিনের কার্ডে "সালাতের নিষিদ্ধ সময়" শিরোনামসহ একটি ForbiddenTimeSection প্রদর্শন করবে।
2. THE ForbiddenTimeSection SHALL তিনটি নিষিদ্ধ সময় প্রদর্শন করবে:
   - সকাল: সূর্যোদয়ের সময় থেকে সূর্যোদয়ের ১৫ মিনিট পর পর্যন্ত
   - দুপুর: যুহরের ১৫ মিনিট আগে থেকে যুহরের সময় পর্যন্ত
   - সন্ধ্যা: মাগরিবের ১৫ মিনিট আগে থেকে মাগরিবের সময় পর্যন্ত
3. THE ForbiddenTimeSection SHALL প্রতিটি নিষিদ্ধ সময়ের রেঞ্জ "HH:MM - HH:MM" ফরম্যাটে প্রদর্শন করবে।

---

### Requirement 7: স্ক্রলযোগ্য তালিকা ও আজকের তারিখে স্ক্রল

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি পুরো মাসের ক্যালেন্ডার স্ক্রল করে দেখতে চাই এবং সহজে আজকের তারিখে ফিরে আসতে চাই।

#### Acceptance Criteria

1. THE PrayerTimesCalendarPage SHALL সমস্ত DayCard-গুলো একটি উল্লম্ব স্ক্রলযোগ্য তালিকায় প্রদর্শন করবে।
2. WHEN পেজ লোড হয় এবং বর্তমান মাস নির্বাচিত থাকে, THE PrayerTimesCalendarPage SHALL স্বয়ংক্রিয়ভাবে আজকের তারিখের DayCard-এ স্ক্রল করবে।
3. THE PrayerTimesCalendarPage SHALL একটি Floating Action Button প্রদর্শন করবে যা চাপলে আজকের তারিখের DayCard-এ স্ক্রল করবে।

---

### Requirement 8: সময় ফরম্যাটিং ও বাংলা সংখ্যা

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি সমস্ত সময় ও তারিখ বাংলায় দেখতে চাই, যাতে পেজটি আমার কাছে স্বাভাবিক ও পরিচিত মনে হয়।

#### Acceptance Criteria

1. THE PrayerTimesCalendarPage SHALL সমস্ত সংখ্যা বাংলা অঙ্কে (০-৯) প্রদর্শন করবে।
2. THE PrayerTimesCalendarPage SHALL সমস্ত মাসের নাম বাংলায় প্রদর্শন করবে।
3. THE PrayerTimesCalendarPage SHALL সমস্ত সাপ্তাহিক দিনের নাম বাংলায় প্রদর্শন করবে (রবিবার, সোমবার, মঙ্গলবার, বুধবার, বৃহস্পতিবার, শুক্রবার, শনিবার)।
4. THE PrayerTimesCalendarPage SHALL হিজরি মাসের নাম বাংলায় প্রদর্শন করবে (মুহাররম, সফর, রবিউল আউয়াল, ইত্যাদি)।

---

### Requirement 9: শেয়ার ফিচার

**User Story:** একজন ব্যবহারকারী হিসেবে, আমি আজকের নামাজের সময়সূচি অন্যদের সাথে শেয়ার করতে চাই।

#### Acceptance Criteria

1. WHEN ব্যবহারকারী আজকের DayCard-এর শেয়ার আইকনে ট্যাপ করেন, THE PrayerTimesCalendarPage SHALL একটি শেয়ার ডায়ালগ খুলবে।
2. THE PrayerTimesCalendarPage SHALL শেয়ার টেক্সটে আজকের তারিখ, হিজরি তারিখ এবং সমস্ত নামাজের সময় বাংলায় অন্তর্ভুক্ত করবে।
3. THE PrayerTimesCalendarPage SHALL শেয়ার টেক্সটে "Noorvia" অ্যাপের নাম অন্তর্ভুক্ত করবে।
