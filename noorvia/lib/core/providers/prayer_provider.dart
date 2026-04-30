import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  // State
  bool isLoading = true;
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

  // ── Load cached data ──────────────────────────────────────
  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('prayer_data');
      final cachedCity = prefs.getString('prayer_city');
      final cachedLat = prefs.getDouble('prayer_lat');
      final cachedLon = prefs.getDouble('prayer_lon');

      if (cachedCity != null) cityName = cachedCity;
      if (cachedLat != null) latitude = cachedLat;
      if (cachedLon != null) longitude = cachedLon;

      if (cached != null) {
        final data = json.decode(cached);
        _parsePrayerData(data);
        isLoading = false;
        notifyListeners();
      }
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
            pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.locality ??
              p.subAdministrativeArea ??
              p.administrativeArea ??
              'ঢাকা';
          countryName = p.isoCountryCode ?? 'BD';
        }
      } catch (_) {}

      // Save
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_city', cityName);
      await prefs.setDouble('prayer_lat', latitude!);
      await prefs.setDouble('prayer_lon', longitude!);

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
      final prayerRes =
          await http.get(Uri.parse(prayerUrl)).timeout(const Duration(seconds: 15));

      if (prayerRes.statusCode == 200) {
        final data = json.decode(prayerRes.body);
        _parsePrayerData(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prayer_data', prayerRes.body);
      }

      // Hijri date
      await _fetchHijriDate();

      isLoading = false;
      notifyListeners();
    } catch (_) {
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
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _parsePrayerData(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prayer_data', res.body);
      }

      await _fetchHijriDate();
      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Hijri date ──────────────────────────────────────
  Future<void> _fetchHijriDate() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final url = 'https://api.aladhan.com/v1/gToH/$dateStr';
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

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

      _updatePrayerProgress();
    } catch (_) {}
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
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    const days = [
      'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার',
      'শুক্রবার', 'শনিবার', 'রবিবার'
    ];
    return '${days[now.weekday - 1]}, ${_bn(now.day)} ${months[now.month - 1]} ${_bn(now.year)}';
  }

  String _bn(dynamic n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  // ── City display name in Bangla ───────────────────────────
  String get cityDisplayName {
    const map = {
      'Dhaka': 'ঢাকা', 'Chittagong': 'চট্টগ্রাম',
      'Sylhet': 'সিলেট', 'Rajshahi': 'রাজশাহী',
      'Khulna': 'খুলনা', 'Barisal': 'বরিশাল',
      'Rangpur': 'রংপুর', 'Mymensingh': 'ময়মনসিংহ',
      'Comilla': 'কুমিল্লা', 'Narayanganj': 'নারায়ণগঞ্জ',
      'Gazipur': 'গাজীপুর', 'Jessore': 'যশোর',
      'Bogra': 'বগুড়া', 'Dinajpur': 'দিনাজপুর',
      'Cox\'s Bazar': 'কক্সবাজার',
      'Mecca': 'মক্কা', 'Medina': 'মদিনা', 'Riyadh': 'রিয়াদ',
      'Dubai': 'দুবাই', 'London': 'লন্ডন',
      'New York': 'নিউ ইয়র্ক', 'Kuala Lumpur': 'কুয়ালালামপুর',
      'Jakarta': 'জাকার্তা', 'Istanbul': 'ইস্তাম্বুল',
      'Cairo': 'কায়রো', 'Karachi': 'করাচি',
      'Lahore': 'লাহোর', 'Delhi': 'দিল্লি', 'Kolkata': 'কলকাতা',
    };
    return map[cityName] ?? cityName;
  }

  // ── Manual city selection ─────────────────────────────────
  Future<void> selectCity(String city, String country) async {
    cityName = city;
    countryName = country;
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_city', city);
    await prefs.setString('prayer_country', country);
    // Clear lat/lon so next auto-detect starts fresh
    await prefs.remove('prayer_lat');
    await prefs.remove('prayer_lon');
    latitude = null;
    longitude = null;

    await _fetchByCity(city, country);
  }

  String get hijriDisplayDate {
    if (hijriDate == null) return '';
    final months = [
      '', 'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি',
      'জুমাদাল উলা', 'জুমাদাস সানি', 'রজব', 'শাবান',
      'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ'
    ];
    final mNum = int.tryParse(hijriDate!.month) ?? 0;
    final mName = mNum > 0 && mNum < months.length ? months[mNum] : hijriDate!.monthAr;
    return '${_bn(hijriDate!.day)} $mName ${_bn(hijriDate!.year)} হিজরি';
  }
}
