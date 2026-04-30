import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/gradient_helper.dart';

// ═══════════════════════════════════════════════════════════════
//  Prayer Times Calendar  —  Noorvia Islamic App
//  API: https://api.aladhan.com/v1/calendarByCity
// ═══════════════════════════════════════════════════════════════

const _kGreen1 = Color(0xFF1B5E20);
const _kGreen2 = Color(0xFF2E7D32);
const _kGreen3 = Color(0xFF43A047);
const _kGreenLight = Color(0xFFE8F5E9);
const _kGreenAccent = Color(0xFF66BB6A);
const _kFriday = Color(0xFFFFF8E1);
const _kFridayBorder = Color(0xFFFFD54F);
const _kForbidden = Color(0xFFB71C1C);
const _kForbiddenLight = Color(0xFF8B2020);

class PrayerTimesCalendarPage extends StatefulWidget {
  const PrayerTimesCalendarPage({super.key});

  @override
  State<PrayerTimesCalendarPage> createState() =>
      _PrayerTimesCalendarPageState();
}

class _PrayerTimesCalendarPageState extends State<PrayerTimesCalendarPage>
    with TickerProviderStateMixin {
  List<dynamic> _calendarData = [];
  bool _loading = false;
  String? _error;

  // ── Filters ────────────────────────────────────────────────
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String _city = 'Dhaka';
  String _country = 'Bangladesh';
  int _method = 1; // Karachi

  // ── Controllers ────────────────────────────────────────────
  late final ScrollController _scrollCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
    'মে', 'জুন', 'জুলাই', 'আগস্ট',
    'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  static const _methods = {
    1: 'কারাচি',
    2: 'ISNA',
    3: 'MWL',
    4: 'মক্কা',
    5: 'মিশর',
  };

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi',
    'Khulna', 'Barisal', 'Rangpur', 'Mymensingh',
  ];

  static const _cityBn = {
    'Dhaka': 'ঢাকা',
    'Chittagong': 'চট্টগ্রাম',
    'Sylhet': 'সিলেট',
    'Rajshahi': 'রাজশাহী',
    'Khulna': 'খুলনা',
    'Barisal': 'বরিশাল',
    'Rangpur': 'রংপুর',
    'Mymensingh': 'ময়মনসিংহ',
  };

  // ── Lifecycle ───────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _detectLocationAndFetch();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── City coordinates for nearest-city matching ─────────────
  static const _cityCoords = {
    'Dhaka':      [23.8103, 90.4125],
    'Chittagong': [22.3569, 91.7832],
    'Sylhet':     [24.8949, 91.8687],
    'Rajshahi':   [24.3745, 88.6042],
    'Khulna':     [22.8456, 89.5403],
    'Barisal':    [22.7010, 90.3535],
    'Rangpur':    [25.7439, 89.2752],
    'Mymensingh': [24.7471, 90.4203],
  };

  Future<void> _detectLocationAndFetch() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fetchCalendar();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _fetchCalendar();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 10));

      // Find nearest city
      String nearest = 'Dhaka';
      double minDist = double.infinity;
      _cityCoords.forEach((city, coords) {
        final d = _haversineKm(pos.latitude, pos.longitude, coords[0], coords[1]);
        if (d < minDist) {
          minDist = d;
          nearest = city;
        }
      });
      setState(() => _city = nearest);
    } catch (_) {
      // fallback to Dhaka
    }
    _fetchCalendar();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  // ── API ─────────────────────────────────────────────────────
  Future<void> _fetchCalendar() async {
    setState(() {
      _loading = true;
      _error = null;
      _calendarData = [];
    });
    _fadeCtrl.reset();

    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/calendarByCity'
        '?city=$_city&country=$_country'
        '&method=$_method&month=$_month&year=$_year',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _calendarData = json['data'] as List<dynamic>;
          _loading = false;
        });
        _fadeCtrl.forward();
        _scrollToToday();
      } else {
        setState(() {
          _error = 'সার্ভার ত্রুটি: ${res.statusCode}';
          _loading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _error = 'সংযোগ সময় শেষ। পুনরায় চেষ্টা করুন।';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ডেটা লোড হয়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        _loading = false;
      });
    }
  }

  void _scrollToToday() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final offset = (now.day - 1) * 320.0;
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            offset.clamp(0, _scrollCtrl.position.maxScrollExtent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────
  String _fmt(String? t) {
    if (t == null) return '--:--';
    return t.length > 5 ? t.substring(0, 5) : t;
  }

  bool _isToday(Map<String, dynamic> day) {
    final now = DateTime.now();
    final g = day['date']?['gregorian'];
    if (g == null) return false;
    return int.tryParse(g['day'] ?? '') == now.day &&
        int.tryParse(g['month']?['number'].toString() ?? '') == now.month &&
        int.tryParse(g['year'] ?? '') == now.year;
  }

  bool _isFriday(Map<String, dynamic> day) {
    final g = day['date']?['gregorian'];
    if (g == null) return false;
    final weekday = g['weekday']?['en'] ?? '';
    return weekday == 'Friday';
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGreenLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: GradientHelper.boxDecoration(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'নামাযের সময়সূচি',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${_cityBn[_city] ?? _city} — ${_months[_month - 1]} $_year',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: _showMonthYearPicker,
          tooltip: 'মাস/বছর বেছে নিন',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchCalendar,
          tooltip: 'রিফ্রেশ',
        ),
      ],
    );
  }

  Future<void> _showMonthYearPicker() async {
    int tempMonth = _month;
    int tempYear = _year;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: null,
              content: Container(
                decoration: GradientHelper.boxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'মাস ও বছর বেছে নিন',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  // ── Year row ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'বছর',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.white70, size: 22),
                            onPressed: () =>
                                setLocal(() => tempYear--),
                          ),
                          Text(
                            tempYear.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.white70, size: 22),
                            onPressed: () =>
                                setLocal(() => tempYear++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Month grid ────────────────────────────
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      final selected = tempMonth == i + 1;
                      return GestureDetector(
                        onTap: () => setLocal(() => tempMonth = i + 1),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.gradientStart
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.gradientStart
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _months[i],
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('বাতিল',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gradientStart,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _month = tempMonth;
                            _year = tempYear;
                          });
                          _fetchCalendar();
                        },
                        child: const Text('দেখুন'),
                      ),
                    ],
                  ),
                ],
              ),
              ),
              actions: const [],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      decoration: GradientHelper.darkBoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // City
          Expanded(
            child: _Dropdown<String>(
              value: _city,
              items: _cities,
              label: (v) => _cityBn[v] ?? v,
              onChanged: (v) {
                setState(() => _city = v);
                _fetchCalendar();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Month
          Expanded(
            child: _Dropdown<int>(
              value: _month,
              items: List.generate(12, (i) => i + 1),
              label: (v) => _months[v - 1],
              onChanged: (v) {
                setState(() => _month = v);
                _fetchCalendar();
              },
            ),
          ),
          const SizedBox(width: 8),
          // ── Year (unlimited scroll with +/- buttons) ──
          Expanded(
            child: _YearPicker(
              year: _year,
              onChanged: (v) {
                setState(() => _year = v);
                _fetchCalendar();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gradientStart),
            SizedBox(height: 16),
            Text('ডেটা লোড হচ্ছে...', style: TextStyle(color: AppColors.gradientStart)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: _kGreen3),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kGreen1, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gradientStart),
                onPressed: _fetchCalendar,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'পুনরায় চেষ্টা করুন',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_calendarData.isEmpty) {
      return const Center(child: Text('কোনো ডেটা নেই'));
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        itemCount: _calendarData.length,
        itemBuilder: (context, index) {
          final day = _calendarData[index] as Map<String, dynamic>;
          return _DayCard(
            day: day,
            isToday: _isToday(day),
            isFriday: _isFriday(day),
            fmt: _fmt,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _DayCard
// ═══════════════════════════════════════════════════════════════
class _DayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  final bool isToday;
  final bool isFriday;
  final String Function(String?) fmt;

  const _DayCard({
    required this.day,
    required this.isToday,
    required this.isFriday,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final timings = day['timings'] as Map<String, dynamic>? ?? {};
    final date = day['date'] as Map<String, dynamic>? ?? {};
    final gregorian = date['gregorian'] as Map<String, dynamic>? ?? {};
    final hijri = date['hijri'] as Map<String, dynamic>? ?? {};

    final dayNum = gregorian['day'] ?? '';
    final weekday = gregorian['weekday']?['en'] ?? '';
    final hijriDay = hijri['day'] ?? '';
    final hijriMonth = hijri['month']?['ar'] ?? '';
    final hijriYear = hijri['year'] ?? '';

    // Forbidden times
    final sunrise = fmt(timings['Sunrise'] as String?);
    final sunset = fmt(timings['Sunset'] as String?);
    final ishraq = _addMinutes(timings['Sunrise'] as String?, 20);
    final zawal = _zawalTime(timings['Dhuhr'] as String?);

    Color cardColor = Colors.white;
    Color borderColor = Colors.transparent;
    if (isToday) {
      cardColor = const Color(0xFFFFEBEE); // light red
      borderColor = Colors.red;
    } else if (isFriday) {
      cardColor = _kFriday;
      borderColor = _kFridayBorder;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: isToday
                ? BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  )
                : GradientHelper.boxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
            child: Row(
              children: [
                // Day number circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNum.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weekdayBn(weekday),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        '$hijriDay $hijriMonth $hijriYear হিজরি',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gradientStart,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'আজ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isFriday && !isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gradientEnd,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'জুমা',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Prayer times grid ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _PrayerCell(
                      label: 'ফজর',
                      time: fmt(timings['Fajr'] as String?),
                      isToday: isToday,
                    ),
                    _PrayerCell(
                      label: 'সূর্যোদয়',
                      time: sunrise,
                      isToday: isToday,
                    ),
                    _PrayerCell(
                      label: 'যোহর',
                      time: fmt(timings['Dhuhr'] as String?),
                      isToday: isToday,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PrayerCell(
                      label: 'আসর',
                      time: fmt(timings['Asr'] as String?),
                      isToday: isToday,
                    ),
                    _PrayerCell(
                      label: 'মাগরিব',
                      time: fmt(timings['Maghrib'] as String?),
                      isToday: isToday,
                    ),
                    _PrayerCell(
                      label: 'এশা',
                      time: fmt(timings['Isha'] as String?),
                      isToday: isToday,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Extra times
                Row(
                  children: [
                    _ExtraCell(
                      label: 'ইশরাক',
                      value: ishraq,
                      color: _kForbidden,
                    ),
                    _ExtraCell(
                      label: 'যাওয়াল',
                      value: zawal,
                      color: _kForbidden,
                    ),
                    _ExtraCell(
                      label: 'সূর্যাস্ত',
                      value: sunset,
                      color: _kGreen2,
                    ),
                  ],
                ),
                // Forbidden time chips
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _ForbiddenChip(
                      label: 'নিষিদ্ধ সময়',
                      range: 'সূর্যোদয়: $sunrise — ইশরাক: $ishraq',
                    ),
                    _ForbiddenChip(
                      label: 'যাওয়াল',
                      range: zawal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayBn(String en) {
    const map = {
      'Saturday': 'শনিবার',
      'Sunday': 'রবিবার',
      'Monday': 'সোমবার',
      'Tuesday': 'মঙ্গলবার',
      'Wednesday': 'বুধবার',
      'Thursday': 'বৃহস্পতিবার',
      'Friday': 'শুক্রবার',
    };
    return map[en] ?? en;
  }

  String _addMinutes(String? timeStr, int minutes) {
    if (timeStr == null) return '--:--';
    final clean = timeStr.length > 5 ? timeStr.substring(0, 5) : timeStr;
    final parts = clean.split(':');
    if (parts.length < 2) return '--:--';
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final total = h * 60 + m + minutes;
    final nh = (total ~/ 60) % 24;
    final nm = total % 60;
    return '${nh.toString().padLeft(2, '0')}:${nm.toString().padLeft(2, '0')}';
  }

  String _zawalTime(String? dhuhrStr) {
    if (dhuhrStr == null) return '--:--';
    final start = _addMinutes(dhuhrStr, -5);
    final end = _addMinutes(dhuhrStr, 5);
    return '$start–$end';
  }
}

// ═══════════════════════════════════════════════════════════════
//  _Dropdown
// ═══════════════════════════════════════════════════════════════
class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.gradientStart,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    label(e),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _PrayerCell
// ═══════════════════════════════════════════════════════════════
class _PrayerCell extends StatelessWidget {
  final String label;
  final String time;
  final bool isToday;

  const _PrayerCell({
    required this.label,
    required this.time,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isToday
              ? Colors.red.withValues(alpha: 0.08)
              : _kGreenLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? Colors.red : _kGreenAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isToday ? Colors.red[800] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.red[900] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _ExtraCell
// ═══════════════════════════════════════════════════════════════
class _ExtraCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ExtraCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _ForbiddenChip
// ═══════════════════════════════════════════════════════════════
class _ForbiddenChip extends StatelessWidget {
  final String label;
  final String range;

  const _ForbiddenChip({required this.label, required this.range});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kForbidden.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kForbidden.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: $range',
            style: TextStyle(
              fontSize: 10,
              color: _kForbiddenLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _YearPicker  —  unlimited year scroll with +/- buttons
// ═══════════════════════════════════════════════════════════════
class _YearPicker extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;

  const _YearPicker({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => onChanged(year - 1),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          Text(
            year.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(year + 1),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
