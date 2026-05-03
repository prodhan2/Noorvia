# Prayer Alarm System - Architecture Diagram

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────┐      ┌──────────────────────┐       │
│  │  PrayerTimesPage     │      │ PrayerAlarmSettings  │       │
│  │                      │      │      Page            │       │
│  │  - Current Time      │      │                      │       │
│  │  - Next Prayer       │      │  - Enable/Disable    │       │
│  │  - Prayer Schedule   │      │  - Pre-Alarm Slider  │       │
│  │  - Location Display  │      │  - Azan Selection    │       │
│  │  - Quick Actions     │      │  - Volume Control    │       │
│  └──────────┬───────────┘      └──────────┬───────────┘       │
│             │                              │                   │
└─────────────┼──────────────────────────────┼───────────────────┘
              │                              │
              ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────┐      ┌──────────────────────┐       │
│  │  PrayerProvider      │      │ PrayerAlarmProvider  │       │
│  │                      │      │                      │       │
│  │  - Prayer Times      │      │  - Alarm Settings    │       │
│  │  - Location          │      │  - Azan Selection    │       │
│  │  - Hijri Date        │      │  - Volume/Vibration  │       │
│  │  - Next Prayer       │      │  - Test Playback     │       │
│  │  - Countdown         │      │  - Schedule Alarms   │       │
│  └──────────┬───────────┘      └──────────┬───────────┘       │
│             │                              │                   │
└─────────────┼──────────────────────────────┼───────────────────┘
              │                              │
              ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SERVICES                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────┐         │
│  │         PrayerAlarmService                       │         │
│  │                                                  │         │
│  │  - Initialize Notifications                     │         │
│  │  - Schedule Alarms                              │         │
│  │  - Cancel Alarms                                │         │
│  │  - Play/Stop Audio                              │         │
│  │  - Handle Permissions                           │         │
│  └──────────┬───────────────────────────────────────┘         │
│             │                                                  │
└─────────────┼──────────────────────────────────────────────────┘
              │
              ├─────────────┬─────────────┬─────────────┐
              ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL DEPENDENCIES                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   Flutter    │  │ AudioPlayers │  │   Timezone   │        │
│  │    Local     │  │              │  │              │        │
│  │Notifications │  │  - Play MP3  │  │  - Schedule  │        │
│  │              │  │  - Volume    │  │  - Convert   │        │
│  │  - Schedule  │  │  - Stop      │  │  - Local TZ  │        │
│  │  - Trigger   │  └──────────────┘  └──────────────┘        │
│  │  - Display   │                                             │
│  └──────────────┘                                             │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Shared     │  │  Geolocator  │  │     HTTP     │       │
│  │ Preferences  │  │              │  │              │       │
│  │              │  │  - Location  │  │  - API Call  │       │
│  │  - Save      │  │  - GPS       │  │  - Prayer    │       │
│  │  - Load      │  │  - Geocode   │  │    Times     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                               │
└───────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA STORAGE                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────┐      ┌──────────────────────┐       │
│  │  Local Storage       │      │   Asset Storage      │       │
│  │                      │      │                      │       │
│  │  - Alarm Settings    │      │  - Azan MP3 Files    │       │
│  │  - Prayer Times      │      │  - Default Audio     │       │
│  │  - User Preferences  │      │  - Custom Audio      │       │
│  └──────────────────────┘      └──────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────┐         │
│  │            Aladhan API                           │         │
│  │                                                  │         │
│  │  - Prayer Times by Coordinates                  │         │
│  │  - Prayer Times by City                         │         │
│  │  - Hijri Date Conversion                        │         │
│  │  - Multiple Calculation Methods                 │         │
│  └──────────────────────────────────────────────────┘         │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### 1. Prayer Times Flow
```
User Opens App
    ↓
PrayerProvider Initializes
    ↓
Request Location Permission
    ↓
Get GPS Coordinates
    ↓
Call Aladhan API
    ↓
Parse Prayer Times
    ↓
Cache Locally
    ↓
Update UI
    ↓
Start Real-time Clock
    ↓
Calculate Next Prayer
    ↓
Update Countdown
```

### 2. Alarm Scheduling Flow
```
User Opens Alarm Settings
    ↓
PrayerAlarmProvider Loads Settings
    ↓
User Enables Prayer Alarm
    ↓
User Sets Pre-Alarm Minutes
    ↓
Settings Saved to SharedPreferences
    ↓
PrayerAlarmService Calculates Alarm Time
    ↓
Schedule Notification with Timezone
    ↓
System Stores Pending Notification
    ↓
[Time Passes]
    ↓
System Triggers Notification
    ↓
User Taps Notification
    ↓
AudioPlayer Plays Azan
```

### 3. Audio Playback Flow
```
User Selects Azan
    ↓
Settings Updated
    ↓
User Taps Test Button
    ↓
PrayerAlarmProvider Calls Service
    ↓
PrayerAlarmService Loads Audio
    ↓
AudioPlayer Plays from Asset
    ↓
Volume Applied
    ↓
User Hears Audio
    ↓
User Taps Stop Button
    ↓
AudioPlayer Stops
```

## 🔐 Permission Flow

```
App Starts
    ↓
Request Notification Permission
    ├─ Granted → Continue
    └─ Denied → Show Fallback UI
    ↓
Request Location Permission
    ├─ Granted → Get GPS Location
    └─ Denied → Use Manual City Selection
    ↓
Request Exact Alarm Permission (Android 12+)
    ├─ Granted → Schedule Exact Alarms
    └─ Denied → Show Warning
    ↓
All Permissions Ready
    ↓
Full Functionality Available
```

## 📦 Component Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                         main.dart                           │
│                                                             │
│  MultiProvider                                              │
│    ├─ ThemeProvider                                         │
│    ├─ NavProvider                                           │
│    ├─ PrayerProvider ◄──────────────────┐                  │
│    ├─ PrayerAlarmProvider ◄─────────┐   │                  │
│    ├─ AudioProvider                  │   │                  │
│    ├─ SettingsProvider               │   │                  │
│    └─ NotificationProvider           │   │                  │
│                                       │   │                  │
└───────────────────────────────────────┼───┼──────────────────┘
                                        │   │
                    ┌───────────────────┘   │
                    │                       │
                    ▼                       ▼
        ┌─────────────────────┐  ┌─────────────────────┐
        │ PrayerAlarmProvider │  │   PrayerProvider    │
        │                     │  │                     │
        │  Uses:              │  │  Uses:              │
        │  - PrayerAlarmSvc   │  │  - HTTP             │
        │  - SharedPrefs      │  │  - Geolocator       │
        │                     │  │  - SharedPrefs      │
        └──────────┬──────────┘  └─────────────────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ PrayerAlarmService  │
        │                     │
        │  Uses:              │
        │  - FlutterLocalNot  │
        │  - AudioPlayers     │
        │  - Timezone         │
        │  - SharedPrefs      │
        └─────────────────────┘
```

## 🎯 Key Design Patterns

### 1. Provider Pattern (State Management)
```
Provider (ChangeNotifier)
    ↓
Notifies Listeners
    ↓
UI Rebuilds Automatically
```

### 2. Service Pattern (Business Logic)
```
UI Layer
    ↓
Provider Layer
    ↓
Service Layer
    ↓
External Dependencies
```

### 3. Repository Pattern (Data Access)
```
Provider
    ↓
Service
    ↓
SharedPreferences / API
    ↓
Data Storage
```

## 🔄 State Management Flow

```
User Action
    ↓
Widget Calls Provider Method
    ↓
Provider Updates State
    ↓
Provider Calls Service
    ↓
Service Performs Operation
    ↓
Service Returns Result
    ↓
Provider Updates State
    ↓
Provider Calls notifyListeners()
    ↓
Consumer Widgets Rebuild
    ↓
UI Updates
```

## 📱 Notification Lifecycle

```
App Schedules Notification
    ↓
System Stores Notification
    ↓
App Can Be Closed
    ↓
[Time Passes]
    ↓
System Wakes Up
    ↓
System Triggers Notification
    ↓
Notification Appears
    ↓
User Taps Notification
    ↓
App Opens (if closed)
    ↓
Callback Executed
    ↓
Audio Plays
```

## 🎨 UI Component Hierarchy

```
PrayerTimesPage
├─ SliverAppBar
│  ├─ Gradient Background
│  ├─ Title
│  ├─ Location
│  ├─ Date
│  └─ Actions (Alarm Icon, Refresh)
├─ CurrentTimeCard
│  ├─ Current Time Display
│  └─ Next Prayer Card
│     ├─ Prayer Name
│     ├─ Time Remaining
│     └─ Progress Bar
├─ TodayPrayerTimesCard
│  └─ Prayer Rows (5)
│     ├─ Icon
│     ├─ Name
│     ├─ Time
│     └─ Alarm Indicator
└─ QuickActionsCard
   ├─ Alarm Settings Button
   └─ Change Location Button

PrayerAlarmSettingsPage
├─ SliverAppBar
│  └─ Gradient Background
├─ Prayer Alarm Cards (5)
│  ├─ Prayer Info
│  ├─ Enable Toggle
│  └─ Pre-Alarm Slider
├─ Azan Selection Card
│  ├─ Current Selection
│  ├─ Change Button
│  ├─ Test Button
│  └─ Stop Button
├─ Volume Control Card
│  └─ Volume Slider
└─ Vibration Toggle Card
   └─ Vibration Switch
```

## 🔧 Configuration Flow

```
App Initialization
    ↓
Initialize Timezone
    ↓
Initialize Providers
    ↓
Load Saved Settings
    ↓
Initialize Notification Service
    ↓
Request Permissions
    ↓
Load Prayer Times
    ↓
Schedule Alarms
    ↓
Start Real-time Updates
    ↓
App Ready
```

---

This architecture ensures:
- ✅ Separation of concerns
- ✅ Testability
- ✅ Maintainability
- ✅ Scalability
- ✅ Performance
- ✅ Reliability
