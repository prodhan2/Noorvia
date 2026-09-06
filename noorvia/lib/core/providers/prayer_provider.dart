import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/native_prayer_alarm_service.dart';
import '../services/integrated_prayer_alarm_service.dart';
import '../services/offline_prayer_calculator.dart';
import '../data/local/local_store.dart';

// ─── Prayer time model ────────────────────────────────────────
class PrayerTimeModel {
  final String fajr, sunrise, dhuhr, asr, maghrib, isha, tahajjud;
  PrayerTimeModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.tahajjud,
  });
}

// ─── Hijri date model ─────────────────────────────────────────
class HijriDateModel {
  final String day, month, year, monthAr, weekday;
  HijriDateModel({
    required this.day,
    required this.month,
    required this.year,
    required this.monthAr,
    required this.weekday,
  });
}

// ═══════════════════════════════════════════════════════════════
// PrayerProvider
// ═══════════════════════════════════════════════════════════════
class PrayerProvider extends ChangeNotifier {
  static const _cacheNamespace = 'prayer_cache_v3';
  static const _cacheKey = 'current';

  // State
  bool isLoading = true;
  bool isOffline = false; // true when network failed & no fresh data
  bool hasCachedData = false; // true when cache was loaded successfully
  bool locationDenied = false;
  bool locationDeniedForever = false;
  String cityName = 'ঢাকা';
  String countryName = 'BD';
  double? latitude;
  double? longitude;

  PrayerTimeModel? prayerTimes;
  HijriDateModel? hijriDate;
  String banglaDate = '';
  String currentTime = '';
  String nextPrayer = '';
  String nextPrayerTime = '';
  String timeRemaining = '';
  double prayerProgress = 0.0;
  String currentPrayer = '';

  Timer? _clockTimer;
  Timer? _refreshTimer;

  PrayerProvider() {
    _startClock();
    _init();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Start realtime clock ──────────────────────────────────
  void _startClock() {
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      _updatePrayerProgress();
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    currentTime = _formatTime(now);
    banglaDate = _getBanglaDate(now);
    notifyListeners();
  }

  // ── Init: get location then fetch data ────────────────────
  Future<void> _init() async {
    await _loadCached();
    await requestLocationAndFetch();
    // Refresh every 6 hours
    _refreshTimer = Timer.periodic(const Duration(hours: 6), (_) {
      requestLocationAndFetch();
    });
  }

  // ── Load cached data (Isar primary, SharedPreferences legacy migration) ──
  Future<void> _loadCached() async {
    try {
      var cached = await LocalStore.instance.getJson(_cacheNamespace, _cacheKey);

      // One-time migration from the old SharedPreferences prayer cache.
      if (cached == null) {
        final prefs = await SharedPreferences.getInstance();
        final legacyRaw = prefs.getString('prayer_data');
        if (legacyRaw != null) {
          try {
            cached = <String, dynamic>{
              'data': Map<String, dynamic>.from(json.decode(legacyRaw) as Map),
              'city': prefs.getString('prayer_city'),
              'country': prefs.getString('prayer_country'),
              'latitude': prefs.getDouble('prayer_lat'),
              'longitude': prefs.getDouble('prayer_lon'),
              'savedAt': DateTime.now().toUtc().toIso8601String(),
            };
            await LocalStore.instance.putJson(
              _cacheNamespace,
              _cacheKey,
              cached,
              syncStatus: 'migrated',
            );
          } catch (_) {}
        }
      }

      if (cached == null) return;
      cityName = cached['city']?.toString().isNotEmpty == true
          ? cached['city'].toString()
          : cityName;
      countryName = cached['country']?.toString().isNotEmpty == true
          ? cached['country'].toString()
          : countryName;
      latitude = (cached['latitude'] as num?)?.toDouble() ?? latitude;
      longitude = (cached['longitude'] as num?)?.toDouble() ?? longitude;

      final prayerData = cached['data'];
      if (prayerData is Map) {
        _parsePrayerData(Map<String, dynamic>.from(prayerData));
        hasCachedData = true;
        isLoading = false;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistCache({Map<String, dynamic>? prayerData}) async {
    try {
      final existing = await LocalStore.instance.getJson(_cacheNamespace, _cacheKey) ??
          <String, dynamic>{};
      final next = <String, dynamic>{
        ...existing,
        'city': cityName,
        'country': countryName,
        'latitude': latitude,
        'longitude': longitude,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        if (prayerData != null) 'data': prayerData,
      };
      await LocalStore.instance.putJson(
        _cacheNamespace,
        _cacheKey,
        next,
        syncStatus: 'cached',
      );
    } catch (_) {}
  }

  // ── Request location permission ───────────────────────────
  Future<void> requestLocationAndFetch() async {
    try {
      if (kIsWeb) {
        // Web: use IP-based location fallback
        await _fetchByCity('Dhaka', 'BD');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        locationDeniedForever = true;
        locationDenied = true;
        isLoading = false;
        notifyListeners();
        // Fallback to Dhaka
        await _fetchByCity('Dhaka', 'BD');
        return;
      }

      if (permission == LocationPermission.denied) {
        locationDenied = true;
        isLoading = false;
        notifyListeners();
        await _fetchByCity('Dhaka', 'BD');
        return;
      }

      // Get position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      latitude = pos.latitude;
      longitude = pos.longitude;

      // Reverse geocode
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName =
              p.locality ??
              p.subAdministrativeArea ??
              p.administrativeArea ??
              'ঢাকা';
          countryName = p.isoCountryCode ?? 'BD';
        }
      } catch (_) {}

      // Save location metadata in the Isar offline store.
      await _persistCache();

      await _fetchByCoords(latitude!, longitude!);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      await _fetchByCity('Dhaka', 'BD');
    }
  }

  // ── Fetch by coordinates ──────────────────────────────────
  Future<void> _fetchByCoords(double lat, double lon) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      // Prayer times
      final prayerUrl =
          'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lon&method=2';
      final prayerRes = await http
          .get(Uri.parse(prayerUrl))
          .timeout(const Duration(seconds: 15));

      if (prayerRes.statusCode != 200) {
        throw Exception('Prayer API ${prayerRes.statusCode}');
      }
      final data = json.decode(prayerRes.body);
      _parsePrayerData(data);
      hasCachedData = true;
      isOffline = false;
      await _persistCache(prayerData: Map<String, dynamic>.from(data));

      // Hijri date
      await _fetchHijriDate();

      isLoading = false;
      notifyListeners();
    } catch (_) {
      // Network failed: calculate today's prayer times locally instead of
      // leaving a previous-day API cache on screen.
      _useOfflineCalculation(lat, lon);
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch by city name ────────────────────────────────────
  Future<void> _fetchByCity(String city, String country) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      final url =
          'https://api.aladhan.com/v1/timingsByCity/$dateStr?city=$city&country=$country&method=2';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('Prayer API ${res.statusCode}');
      }
      final data = json.decode(res.body);
      _parsePrayerData(data);
      hasCachedData = true;
      isOffline = false;
      await _persistCache(prayerData: Map<String, dynamic>.from(data));

      await _fetchHijriDate();
      isLoading = false;
      notifyListeners();
    } catch (_) {
      final lat = latitude ?? 23.8103;
      final lon = longitude ?? 90.4125;
      _useOfflineCalculation(lat, lon);
      isLoading = false;
      notifyListeners();
    }
  }

  void _useOfflineCalculation(double lat, double lon) {
    try {
      final offline = OfflinePrayerCalculator.calculate(
        latitude: lat,
        longitude: lon,
        // Noorvia's current Bangla location flow is primarily Bangladesh.
        // Use UTC+6 for BD even if the phone timezone is temporarily wrong;
        // other countries keep the device-local timezone fallback.
        utcOffset: countryName.toUpperCase() == 'BD'
            ? const Duration(hours: 6)
            : null,
      );
      final tahajjud = _calcTahajjud(offline.isha, offline.fajr);
      prayerTimes = PrayerTimeModel(
        fajr: offline.fajr,
        sunrise: offline.sunrise,
        dhuhr: offline.dhuhr,
        asr: offline.asr,
        maghrib: offline.maghrib,
        isha: offline.isha,
        tahajjud: tahajjud,
      );
      hijriDate = HijriDateModel(
        day: offline.hijri.hDay.toString(),
        month: offline.hijri.hMonth.toString(),
        year: offline.hijri.hYear.toString(),
        monthAr: '',
        weekday: '',
      );
      hasCachedData = true;
      isOffline = true;
      _updatePrayerProgress();
      unawaited(_updateWidget());
      unawaited(IntegratedPrayerAlarmService().scheduleAllAlarms({
        'fajr': offline.fajr,
        'dhuhr': offline.dhuhr,
        'asr': offline.asr,
        'maghrib': offline.maghrib,
        'isha': offline.isha,
      }));
    } catch (_) {
      if (!hasCachedData) isOffline = true;
    }
  }

  // ── Fetch Hijri date ──────────────────────────────────────
  Future<void> _fetchHijriDate() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final url = 'https://api.aladhan.com/v1/gToH/$dateStr';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final hijri = data['data']['hijri'];
        final weekday = hijri['weekday'];
        hijriDate = HijriDateModel(
          day: hijri['day'].toString(),
          month: hijri['month']['number'].toString(),
          year: hijri['year'].toString(),
          monthAr: hijri['month']['ar'] ?? '',
          weekday: weekday['ar'] ?? '',
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Parse prayer API response ─────────────────────────────
  void _parsePrayerData(Map<String, dynamic> data) {
    try {
      final timings = data['data']['timings'] as Map<String, dynamic>;
      final fajr = _cleanTime(timings['Fajr'] ?? '04:05');
      final sunrise = _cleanTime(timings['Sunrise'] ?? '05:26');
      final dhuhr = _cleanTime(timings['Dhuhr'] ?? '11:51');
      final asr = _cleanTime(timings['Asr'] ?? '15:15');
      final maghrib = _cleanTime(timings['Maghrib'] ?? '18:26');
      final isha = _cleanTime(timings['Isha'] ?? '19:45');

      // Tahajjud = last third of night (between Isha and Fajr)
      final tahajjud = _calcTahajjud(isha, fajr);

      prayerTimes = PrayerTimeModel(
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        tahajjud: tahajjud,
      );

      // ── Parse hijri date from prayer API response ─────────
      try {
        final dateData = data['data']['date'];
        if (dateData != null) {
          final hijri = dateData['hijri'];
          if (hijri != null) {
            hijriDate = HijriDateModel(
              day: hijri['day']?.toString() ?? '',
              month: hijri['month']?['number']?.toString() ?? '',
              year: hijri['year']?.toString() ?? '',
              monthAr: hijri['month']?['ar'] ?? '',
              weekday: hijri['weekday']?['ar'] ?? '',
            );
          }
        }
      } catch (_) {}

      _updatePrayerProgress();

      // Keep widgets and enabled alarms in sync whenever fresh/cached prayer
      // times are parsed. Alarm settings themselves remain user-controlled.
      _updateWidget();
      unawaited(IntegratedPrayerAlarmService().scheduleAllAlarms({
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      }));
    } catch (_) {}
  }

  // ── Update Android widget with prayer times ───────────────
  Future<void> _updateWidget() async {
    if (prayerTimes == null) return;

    try {
      await NativePrayerAlarmService.updateWidget(
        fajr: prayerTimes!.fajr,
        dhuhr: prayerTimes!.dhuhr,
        asr: prayerTimes!.asr,
        maghrib: prayerTimes!.maghrib,
        isha: prayerTimes!.isha,
        location: cityDisplayName,
        nextPrayer: nextPrayer,
        nextPrayerTime: nextPrayerTime,
        ramadanDay: hijriDate?.day ?? '',
        isRamadan: hijriDate?.month == '9',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  String _cleanTime(String t) {
    // Remove timezone suffix like " (WIB)"
    return t.split(' ').first;
  }

  String _calcTahajjud(String isha, String fajr) {
    try {
      final ishaMin = _timeToMinutes(isha);
      var fajrMin = _timeToMinutes(fajr);
      if (fajrMin < ishaMin) fajrMin += 24 * 60;
      final nightDuration = fajrMin - ishaMin;
      final tahajjudMin = ishaMin + (nightDuration * 2 ~/ 3);
      return _minutesToTime(tahajjudMin % (24 * 60));
    } catch (_) {
      return '03:00';
    }
  }

  // ── Update next prayer & progress ────────────────────────
  void _updatePrayerProgress() {
    if (prayerTimes == null) return;

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    final prayers = [
      {'name': 'ফজর', 'time': prayerTimes!.fajr},
      {'name': 'সূর্যোদয়', 'time': prayerTimes!.sunrise},
      {'name': 'যোহর', 'time': prayerTimes!.dhuhr},
      {'name': 'আসর', 'time': prayerTimes!.asr},
      {'name': 'মাগরিব', 'time': prayerTimes!.maghrib},
      {'name': 'ইশা', 'time': prayerTimes!.isha},
    ];

    String next = 'ফজর';
    String nextTime = prayerTimes!.fajr;
    String current = 'ইশা';
    int prevMin = _timeToMinutes(prayerTimes!.isha);
    int nextMin = _timeToMinutes(prayerTimes!.fajr) + 24 * 60;

    for (int i = 0; i < prayers.length; i++) {
      final pMin = _timeToMinutes(prayers[i]['time']!);
      if (nowMin < pMin) {
        next = prayers[i]['name']!;
        nextTime = prayers[i]['time']!;
        nextMin = pMin;
        current = i > 0 ? prayers[i - 1]['name']! : 'ইশা';
        prevMin = i > 0
            ? _timeToMinutes(prayers[i - 1]['time']!)
            : _timeToMinutes(prayerTimes!.isha) - 24 * 60;
        break;
      }
    }

    nextPrayer = next;
    nextPrayerTime = _toBanglaTime(nextTime);
    currentPrayer = current;

    // Time remaining
    final diff = nextMin - nowMin;
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h > 0) {
      timeRemaining = '${_bn(h)} ঘণ্টা ${_bn(m)} মিনিট বাকি';
    } else {
      timeRemaining = '${_bn(m)} মিনিট বাকি';
    }

    // Progress
    final total = nextMin - prevMin;
    final elapsed = nowMin - prevMin;
    prayerProgress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
  }

  // ── Helpers ───────────────────────────────────────────────
  int _timeToMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${_bn(h)}:${_bn(m)}:${_bn(s)} $ampm';
  }

  String _toBanglaTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.parse(parts[0]);
    final m = parts[1];
    final bh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final ampm = h >= 12 ? 'PM' : 'AM';
    return '${_bn(bh)}:${_bn(m)} $ampm';
  }

  String _getBanglaDate(DateTime now) {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    const days = [
      'সোমবার',
      'মঙ্গলবার',
      'বুধবার',
      'বৃহস্পতিবার',
      'শুক্রবার',
      'শনিবার',
      'রবিবার',
    ];
    return '${days[now.weekday - 1]}, ${_bn(now.day)} ${months[now.month - 1]} ${_bn(now.year)}';
  }

  String _bn(dynamic n) {
    const e = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const b = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  // ── City display name in Bangla ───────────────────────────
  String get cityDisplayName {
    const map = {
      'Dhaka': 'ঢাকা',
      'Chittagong': 'চট্টগ্রাম',
      'Sylhet': 'সিলেট',
      'Rajshahi': 'রাজশাহী',
      'Khulna': 'খুলনা',
      'Barisal': 'বরিশাল',
      'Rangpur': 'রংপুর',
      'Mymensingh': 'ময়মনসিংহ',
      'Comilla': 'কুমিল্লা',
      'Narayanganj': 'নারায়ণগঞ্জ',
      'Gazipur': 'গাজীপুর',
      'Jessore': 'যশোর',
      'Bogra': 'বগুড়া',
      'Dinajpur': 'দিনাজপুর',
      'Cox\'s Bazar': 'কক্সবাজার',
      'Mecca': 'মক্কা',
      'Medina': 'মদিনা',
      'Riyadh': 'রিয়াদ',
      'Dubai': 'দুবাই',
      'London': 'লন্ডন',
      'New York': 'নিউ ইয়র্ক',
      'Kuala Lumpur': 'কুয়ালালামপুর',
      'Jakarta': 'জাকার্তা',
      'Istanbul': 'ইস্তাম্বুল',
      'Cairo': 'কায়রো',
      'Karachi': 'করাচি',
      'Lahore': 'লাহোর',
      'Delhi': 'দিল্লি',
      'Kolkata': 'কলকাতা',
    };
    return map[cityName] ?? cityName;
  }

  // ── Manual city selection ─────────────────────────────────
  Future<void> selectCity(String city, String country) async {
    cityName = city;
    countryName = country;
    isLoading = true;
    isOffline = false;
    notifyListeners();

    // Manual city selection becomes the active offline location. Coordinates
    // are cleared so a later auto-detect can replace them cleanly.
    latitude = null;
    longitude = null;
    await _persistCache();

    await _fetchByCity(city, country);
  }

  String get hijriDisplayDate {
    if (hijriDate == null) return '';
    final months = [
      '',
      'মুহাররম',
      'সফর',
      'রবিউল আউয়াল',
      'রবিউস সানি',
      'জুমাদাল উলা',
      'জুমাদাস সানি',
      'রজব',
      'শাবান',
      'রমজান',
      'শাওয়াল',
      'জিলকদ',
      'জিলহজ',
    ];
    final mNum = int.tryParse(hijriDate!.month) ?? 0;
    final mName = mNum > 0 && mNum < months.length
        ? months[mNum]
        : hijriDate!.monthAr;
    return '${_bn(hijriDate!.day)} $mName ${_bn(hijriDate!.year)} হিজরি';
  }
}
