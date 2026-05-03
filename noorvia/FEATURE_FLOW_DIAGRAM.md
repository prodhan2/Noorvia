# 🔄 Mosque Finder - Feature Flow Diagram

## 📊 Complete User Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER STARTS                              │
│                    Clicks "আমার মসজিদ" Button                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NearbyMosquesScreen                            │
│                   Shows Loading Indicator                        │
│                   "আশেপাশের মসজিদ খুঁজছি..."                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MosqueService                                 │
│              getCurrentLocation()                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
    ┌───────────────────┐     ┌──────────────────────┐
    │ Location Services │     │ Permission Check     │
    │ Enabled?          │     │ Granted?             │
    └─────┬─────────────┘     └──────┬───────────────┘
          │                          │
          │ NO                       │ NO
          ▼                          ▼
    ┌─────────────────────────────────────────┐
    │         Show Error Message              │
    │  "লোকেশন সার্ভিস বন্ধ আছে"            │
    │  "লোকেশন অনুমতি প্রত্যাখ্যান করা হয়েছে" │
    │         [Retry Button]                  │
    └─────────────────────────────────────────┘
          │
          │ YES (Both)
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                Get GPS Coordinates                               │
│              latitude, longitude                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MosqueService                                 │
│           fetchNearbyMosques(lat, lon, radius)                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              OpenStreetMap Overpass API                          │
│         POST https://overpass-api.de/api/interpreter             │
│    Query: amenity=place_of_worship + religion=muslim            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
    ┌───────────────────┐     ┌──────────────────────┐
    │ Network Error     │     │ Success (200 OK)     │
    │ Timeout           │     │ JSON Response        │
    └─────┬─────────────┘     └──────┬───────────────┘
          │                          │
          │                          ▼
          │              ┌──────────────────────┐
          │              │ Parse JSON           │
          │              │ Create Mosque objects│
          │              │ Calculate distances  │
          │              │ Sort by distance     │
          │              └──────┬───────────────┘
          │                     │
          ▼                     ▼
    ┌─────────────────────────────────────────┐
    │         Show Error Message              │
    │  "ইন্টারনেট সংযোগ নেই"                 │
    │  "সার্ভার থেকে সাড়া পাওয়া যায়নি"     │
    │         [Retry Button]                  │
    └─────────────────────────────────────────┘
                             │
                             ▼
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
    ┌───────────────────┐     ┌──────────────────────┐
    │ Empty List        │     │ Mosques Found        │
    │ No mosques        │     │ List<Mosque>         │
    └─────┬─────────────┘     └──────┬───────────────┘
          │                          │
          ▼                          ▼
    ┌─────────────────────────────────────────┐
    │         Show Empty State                │
    │  "কোনো মসজিদ পাওয়া যায়নি"             │
    │  [Increase Radius Button]               │
    └─────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Display Mosque List                            │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐         │
│  │ ⭐ সবচেয়ে কাছের মসজিদ                             │         │
│  │ 🕌 Baitul Mukarram Mosque                          │         │
│  │ 📍 250 মিটার                                       │         │
│  │ [দিকনির্দেশনা] [ম্যাপে দেখুন]                     │         │
│  └────────────────────────────────────────────────────┘         │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐         │
│  │ 🕌 Jame Mosque                                     │         │
│  │ 📍 1.2 কিলোমিটার                                  │         │
│  │ [দিকনির্দেশনা] [ম্যাপে দেখুন]                     │         │
│  └────────────────────────────────────────────────────┘         │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐         │
│  │ 🕌 Central Mosque                                  │         │
│  │ 📍 2.5 কিলোমিটার                                  │         │
│  │ [দিকনির্দেশনা] [ম্যাপে দেখুন]                     │         │
│  └────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ User clicks "ম্যাপে দেখুন"
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Open Google Maps                               │
│         https://www.google.com/maps/search/                      │
│              ?api=1&query=lat,lon                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                       │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ AmarMosjidButton │  │ NearbyMosques    │  │ MosqueFinder │  │
│  │ Widget           │→ │ Screen           │  │ Demo         │  │
│  └──────────────────┘  └────────┬─────────┘  └──────────────┘  │
│                                 │                                │
└─────────────────────────────────┼────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SERVICE LAYER                            │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              MosqueService                                │   │
│  │  ┌────────────────────┐  ┌──────────────────────────┐   │   │
│  │  │ getCurrentLocation │  │ fetchNearbyMosques       │   │   │
│  │  │ - Check permission │  │ - Build Overpass query   │   │   │
│  │  │ - Get GPS coords   │  │ - Make HTTP request      │   │   │
│  │  │ - Handle errors    │  │ - Parse JSON response    │   │   │
│  │  └────────────────────┘  └──────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                 │                                │
└─────────────────────────────────┼────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         MODEL LAYER                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Mosque Model                                 │   │
│  │  - name: String                                           │   │
│  │  - latitude: double                                       │   │
│  │  - longitude: double                                      │   │
│  │  - distanceInMeters: double                               │   │
│  │  - address: String?                                       │   │
│  │                                                            │   │
│  │  Methods:                                                 │   │
│  │  - fromJson() → Parse OSM data                           │   │
│  │  - _calculateDistance() → Haversine formula              │   │
│  │  - getFormattedDistance() → Bengali string               │   │
│  │  - getGoogleMapsUrl() → Maps URL                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         EXTERNAL SERVICES                        │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Geolocator   │  │ OpenStreetMap│  │ Google Maps          │  │
│  │ Package      │  │ Overpass API │  │ (via url_launcher)   │  │
│  │              │  │              │  │                      │  │
│  │ - GPS        │  │ - Mosque data│  │ - Navigation         │  │
│  │ - Permissions│  │ - JSON       │  │ - Directions         │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 State Management Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              NearbyMosquesScreen State                           │
└─────────────────────────────────────────────────────────────────┘

Initial State:
├── _mosques: []
├── _isLoading: false
├── _errorMessage: null
└── _searchRadius: 5000

                    │
                    │ initState()
                    ▼

Loading State:
├── _mosques: []
├── _isLoading: true ◄─── Shows CircularProgressIndicator
├── _errorMessage: null
└── _searchRadius: 5000

                    │
                    │ await _loadNearbyMosques()
                    ▼
            ┌───────┴────────┐
            │                │
            ▼                ▼
    Success State      Error State
    ├── _mosques: [...]    ├── _mosques: []
    ├── _isLoading: false  ├── _isLoading: false
    ├── _errorMessage: null├── _errorMessage: "Error..."
    └── _searchRadius: 5000└── _searchRadius: 5000
            │                │
            ▼                ▼
    Display List       Display Error
    with Cards         with Retry Button

                    │
                    │ User changes radius
                    ▼

Loading State (again):
├── _mosques: []
├── _isLoading: true
├── _errorMessage: null
└── _searchRadius: 10000 ◄─── Updated radius

                    │
                    │ Fetch with new radius
                    ▼
            (Repeat cycle)
```

---

## 🗺️ OpenStreetMap Query Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Build Overpass QL Query                       │
└─────────────────────────────────────────────────────────────────┘

Input:
├── latitude: 23.8103
├── longitude: 90.4125
└── radius: 5000 (meters)

                    │
                    ▼

Query Template:
┌─────────────────────────────────────────────────────────────────┐
│ [out:json][timeout:25];                                          │
│ (                                                                │
│   node["amenity"="place_of_worship"]["religion"="muslim"]       │
│       (around:5000,23.8103,90.4125);                             │
│   way["amenity"="place_of_worship"]["religion"="muslim"]        │
│       (around:5000,23.8103,90.4125);                             │
│   relation["amenity"="place_of_worship"]["religion"="muslim"]   │
│       (around:5000,23.8103,90.4125);                             │
│ );                                                               │
│ out center;                                                      │
└─────────────────────────────────────────────────────────────────┘

                    │
                    ▼

POST Request:
├── URL: https://overpass-api.de/api/interpreter
├── Headers: Content-Type: application/x-www-form-urlencoded
├── Body: data={query}
└── Timeout: 30 seconds

                    │
                    ▼

Response (JSON):
┌─────────────────────────────────────────────────────────────────┐
│ {                                                                │
│   "elements": [                                                  │
│     {                                                            │
│       "type": "node",                                            │
│       "id": 123456,                                              │
│       "lat": 23.8103,                                            │
│       "lon": 90.4125,                                            │
│       "tags": {                                                  │
│         "name": "Baitul Mukarram Mosque",                        │
│         "name:bn": "বায়তুল মোকাররম মসজিদ",                     │
│         "amenity": "place_of_worship",                           │
│         "religion": "muslim"                                     │
│       }                                                          │
│     },                                                           │
│     ...                                                          │
│   ]                                                              │
│ }                                                                │
└─────────────────────────────────────────────────────────────────┘

                    │
                    ▼

Parse & Transform:
├── Extract lat, lon from each element
├── Handle different types (node, way, relation)
├── Get name (prefer name:bn, fallback to name)
├── Calculate distance using Haversine
└── Create Mosque objects

                    │
                    ▼

Sort & Return:
└── List<Mosque> sorted by distanceInMeters (ascending)
```

---

## 📐 Haversine Distance Calculation

```
┌─────────────────────────────────────────────────────────────────┐
│              Calculate Distance Between Two Points               │
└─────────────────────────────────────────────────────────────────┘

Input:
├── User Location: (lat1, lon1)
└── Mosque Location: (lat2, lon2)

                    │
                    ▼

Step 1: Convert to Radians
├── lat1_rad = lat1 × π / 180
├── lon1_rad = lon1 × π / 180
├── lat2_rad = lat2 × π / 180
└── lon2_rad = lon2 × π / 180

                    │
                    ▼

Step 2: Calculate Differences
├── dLat = lat2_rad - lat1_rad
└── dLon = lon2_rad - lon1_rad

                    │
                    ▼

Step 3: Haversine Formula
┌─────────────────────────────────────────────────────────────────┐
│ a = sin²(dLat/2) + cos(lat1_rad) × cos(lat2_rad) × sin²(dLon/2)│
│ c = 2 × arcsin(√a)                                              │
│ distance = R × c                                                 │
│ where R = 6371 km (Earth's radius)                              │
└─────────────────────────────────────────────────────────────────┘

                    │
                    ▼

Output:
└── distance in meters (R × c × 1000)

Example:
├── User: (23.8103, 90.4125)
├── Mosque: (23.8150, 90.4200)
└── Distance: ~750 meters
```

---

## 🎨 UI Rendering Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    build() Method                                │
└─────────────────────────────────────────────────────────────────┘

                    │
                    ▼

Check State:
├── _isLoading == true?
│   └── Show: _buildLoadingIndicator()
│       ├── CircularProgressIndicator
│       └── "আশেপাশের মসজিদ খুঁজছি..."
│
├── _errorMessage != null?
│   └── Show: _buildErrorView()
│       ├── Error Icon
│       ├── Error Message (Bengali)
│       └── Retry Button
│
├── _mosques.isEmpty?
│   └── Show: _buildEmptyView()
│       ├── Mosque Icon
│       ├── "কোনো মসজিদ পাওয়া যায়নি"
│       └── Increase Radius Button
│
└── else
    └── Show: _buildMosqueList()
        ├── Header: "X টি মসজিদ পাওয়া গেছে"
        └── ListView.builder
            └── For each mosque:
                _buildMosqueCard(mosque, isNearest)

                    │
                    ▼

Mosque Card Structure:
┌─────────────────────────────────────────────────────────────────┐
│ Card                                                             │
│  ├── Gradient Background (if nearest)                           │
│  ├── Border (if nearest)                                        │
│  └── Padding                                                    │
│      ├── Nearest Badge (if index == 0)                          │
│      │   └── "⭐ সবচেয়ে কাছের মসজিদ"                           │
│      ├── Row: Icon + Name                                       │
│      │   └── "🕌 Baitul Mukarram Mosque"                        │
│      ├── Row: Icon + Distance                                   │
│      │   └── "📍 250 মিটার"                                     │
│      ├── Row: Icon + Address (if available)                     │
│      │   └── "🏠 Dhaka, Bangladesh"                             │
│      └── Row: Two Buttons                                       │
│          ├── OutlinedButton: "দিকনির্দেশনা"                     │
│          └── ElevatedButton: "ম্যাপে দেখুন"                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 User Interaction Flow

```
User Action                    System Response
───────────                    ───────────────

Click "আমার মসজিদ"    →    Navigate to NearbyMosquesScreen
                                    │
                                    ▼
                            Show loading indicator
                                    │
                                    ▼
                            Request location permission
                                    │
                        ┌───────────┴───────────┐
                        │                       │
                        ▼                       ▼
                    Granted                 Denied
                        │                       │
                        ▼                       ▼
                Get GPS location        Show error message
                        │                       │
                        ▼                       │
                Fetch mosques                   │
                        │                       │
                        ▼                       │
                Display list                    │
                        │                       │
                        └───────────┬───────────┘
                                    │
Click "ম্যাপে দেখুন"    →    Open Google Maps
                                    │
                                    ▼
                            Show directions

Click "দিকনির্দেশনা"    →    Open Google Maps
                                    │
                                    ▼
                            Show directions

Click Tune Icon         →    Show radius dialog
                                    │
                                    ▼
Select Radius           →    Reload with new radius
                                    │
                                    ▼
                            Show updated list

Click Refresh           →    Reload mosque list
                                    │
                                    ▼
                            Show updated list
```

---

## 📊 Performance Timeline

```
Time (seconds)    Event
──────────────    ─────

0.0               User clicks button
0.1               Screen loads, shows loading indicator
0.2               Request location permission (if first time)
0.5-2.0           User grants permission
2.0-3.0           Get GPS coordinates
3.0-5.0           Fetch data from OpenStreetMap API
5.0-6.0           Parse JSON, calculate distances, sort
6.0               Display mosque list
                  
Total: 6-7 seconds (first time)
       2-3 seconds (subsequent times)
```

---

**This diagram shows the complete flow of the Mosque Finder feature!**

**For implementation details, see**: `MOSQUE_FINDER_GUIDE.md`

**For integration steps, see**: `MOSQUE_FINDER_INTEGRATION.md`

**May Allah accept this work. Ameen. 🤲**
