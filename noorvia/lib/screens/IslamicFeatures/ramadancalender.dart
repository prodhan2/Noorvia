import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════
// Ramadan Calendar — Table design matching reference images
// ═══════════════════════════════════════════════════════════════

class RamadanCalendarPage extends StatefulWidget {
  const RamadanCalendarPage({super.key});

  @override
  State<RamadanCalendarPage> createState() => _RamadanCalendarPageState();
}

class _RamadanCalendarPageState extends State<RamadanCalendarPage> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;
  String _city = 'Dhaka';
  Timer? _timer;
  DateTime _now = DateTime.now();

  final ScrollController _scroll = ScrollController();

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi',
    'Khulna', 'Barishal', 'Rangpur', 'Mymensingh',
  ];

  static const _cityBn = {
    'Dhaka': 'ঢাকা', 'Chittagong': 'চট্টগ্রাম', 'Sylhet': 'সিলেট',
    'Rajshahi': 'রাজশাহী', 'Khulna': 'খুলনা', 'Barishal': 'বরিশাল',
    'Rangpur': 'রংপুর', 'Mymensingh': 'ময়মনসিংহ',
  };

  // Section headers: days 1-10, 11-20, 21-30
  static const _sections = [
    {'label': 'রহমতের ১০ দিন',      'bg': Color(0xFFB8F0C8), 'text': Color(0xFF1B6B3A)},
    {'label': 'মাগফিরাতের ১০ দিন',  'bg': Color(0xFFFFF9C4), 'text': Color(0xFF7B6000)},
    {'label': 'নাজাতের ১০ দিন',     'bg': Color(0xFFBBDEFB), 'text': Color(0xFF0D47A1)},
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Fetch Ramadan data for current month/year ─────────────
  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch Ramadan month — try current year first
      // Ramadan 2026 = month 2-3, but we use Hijri calendar API
      // Use calendarByCity with Hijri month 9 (Ramadan)
      final now = DateTime.now();
      final url =
          'https://api.aladhan.com/v1/calendarByCity'
          '?city=$_city&country=Bangladesh&method=2'
          '&month=9&year=1447&calendarMethod=UAQ';

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (mounted) {
          setState(() {
            _data = body['data'] as List<dynamic>;
            _loading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
        }
      } else {
        if (mounted) setState(() { _loading = false; _error = 'ডেটা লোড ব্যর্থ হয়েছে'; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'নেটওয়ার্ক ত্রুটি: $e'; });
    }
  }

  // ── Scroll to today ───────────────────────────────────────
  void _scrollToToday() {
    if (_data.isEmpty || !_scroll.hasClients) return;
    final idx = _todayIndex();
    if (idx < 0) return;
    // header (56) + section headers (3 × 40) + rows (idx × 52)
    final sectionsBefore = idx ~/ 10;
    final offset = 56.0 + sectionsBefore * 40.0 + idx * 52.0;
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  int _todayIndex() {
    return _data.indexWhere((d) => _isToday(d));
  }

  bool _isToday(dynamic d) {
    final g = d['date']['gregorian'];
    return int.tryParse(g['day'].toString())   == _now.day   &&
           int.tryParse(g['month']['number'].toString()) == _now.month &&
           int.tryParse(g['year'].toString())  == _now.year;
  }

  // ── Bangla digits ─────────────────────────────────────────
  String _bn(String s) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  // ── 24h "HH:MM" → Bangla 12hr "HH:MM AM/PM" ─────────────
  String _fmt12(String raw) {
    try {
      final clean = raw.split(' ').first;
      final parts = clean.split(':');
      final h24 = int.parse(parts[0]);
      final m   = parts[1];
      final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
      final period = h24 >= 12 ? 'PM' : 'AM';
      return '${_bn(h12.toString().padLeft(2, '0'))}:${_bn(m)} $period';
    } catch (_) {
      return _bn(raw.split(' ').first);
    }
  }

  String _weekdayBn(String en) {
    const map = {
      'sunday': 'রবিবার', 'monday': 'সোমবার', 'tuesday': 'মঙ্গলবার',
      'wednesday': 'বুধবার', 'thursday': 'বৃহস্পতিবার',
      'friday': 'শুক্রবার', 'saturday': 'শনিবার',
    };
    return map[en.toLowerCase()] ?? en;
  }

  String _monthBn(String en) {
    const map = {
      'January': 'জানুয়ারি', 'February': 'ফেব্রুয়ারি', 'March': 'মার্চ',
      'April': 'এপ্রিল', 'May': 'মে', 'June': 'জুন',
      'July': 'জুলাই', 'August': 'আগস্ট', 'September': 'সেপ্টেম্বর',
      'October': 'অক্টোবর', 'November': 'নভেম্বর', 'December': 'ডিসেম্বর',
    };
    return map[en] ?? en;
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B6B3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'রমজান ক্যালেন্ডার ১৪৪৭',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          // City picker
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _city,
                dropdownColor: const Color(0xFF1B6B3A),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 20),
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white, fontSize: 13),
                items: _cities.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(_cityBn[c] ?? c,
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white, fontSize: 13)),
                )).toList(),
                onChanged: (v) {
                  if (v != null && v != _city) {
                    setState(() => _city = v);
                    _fetch();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
                strokeWidth: 2.5,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: GoogleFonts.hindSiliguri(
                              color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetch,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B6B3A)),
                        child: Text('আবার চেষ্টা করুন',
                            style: GoogleFonts.hindSiliguri(
                                color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _buildTable(),
      floatingActionButton: _data.isNotEmpty
          ? FloatingActionButton(
              onPressed: _scrollToToday,
              backgroundColor: const Color(0xFF1B6B3A),
              child: const Icon(Icons.today_rounded, color: Colors.white),
              tooltip: 'আজকে যান',
            )
          : null,
    );
  }

  // ── Full table ────────────────────────────────────────────
  Widget _buildTable() {
    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
        children: [
          // ── Column header ──────────────────────────────────
          _buildColumnHeader(),

          // ── Rows with section separators ───────────────────
          ..._buildAllRows(),

          // ── Footer note ────────────────────────────────────
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Column header row ─────────────────────────────────────
  Widget _buildColumnHeader() {
    const bg = Color(0xFF1B6B3A);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _hCell('রমাযান', flex: 2),
          _hCell('তারিখ',  flex: 3),
          _hCell('বার',    flex: 3),
          _hCell('সাহরী শেষ', flex: 3),
          _hCell('ইফতার', flex: 3),
        ],
      ),
    );
  }

  Widget _hCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.hindSiliguri(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Build all rows with section headers ───────────────────
  List<Widget> _buildAllRows() {
    final widgets = <Widget>[];
    for (int i = 0; i < _data.length; i++) {
      // Section header before day 1, 11, 21
      if (i == 0 || i == 10 || i == 20) {
        final sIdx = i ~/ 10;
        if (sIdx < _sections.length) {
          widgets.add(_buildSectionHeader(sIdx));
        }
      }
      widgets.add(_buildRow(_data[i], i));
    }
    return widgets;
  }

  // ── Section header ────────────────────────────────────────
  Widget _buildSectionHeader(int sIdx) {
    final s = _sections[sIdx];
    return Container(
      width: double.infinity,
      color: s['bg'] as Color,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        s['label'] as String,
        textAlign: TextAlign.center,
        style: GoogleFonts.hindSiliguri(
          color: s['text'] as Color,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }

  // ── Data row ──────────────────────────────────────────────
  Widget _buildRow(dynamic day, int index) {
    final isToday = _isToday(day);
    final g       = day['date']['gregorian'];
    final h       = day['date']['hijri'];
    final timings = day['timings'] as Map<String, dynamic>;

    final ramadanDay = _bn((index + 1).toString().padLeft(2, '0'));
    final dayNum     = _bn(g['day'].toString().padLeft(2, '0'));
    final monthNum   = _bn(g['month']['number'].toString().padLeft(2, '0'));
    final year       = _bn(g['year'].toString());
    final dateStr    = '$dayNum-$monthNum-$year';
    final weekday    = _weekdayBn(g['weekday']['en'] as String);

    // Sehri = Fajr − 5 min, Iftar = Maghrib + 3 min (as per note)
    final fajrRaw    = (timings['Fajr']    as String).split(' ').first;
    final maghribRaw = (timings['Maghrib'] as String).split(' ').first;
    final sehriTime  = _adjustTime(fajrRaw,    -5);
    final iftarTime  = _adjustTime(maghribRaw, +3);

    // Row colors
    Color rowBg;
    Color textColor;
    if (isToday) {
      rowBg     = const Color(0xFFE53935);
      textColor = Colors.white;
    } else if (index.isEven) {
      rowBg     = Colors.white;
      textColor = const Color(0xFF1A1A1A);
    } else {
      rowBg     = const Color(0xFFF7FFF7);
      textColor = const Color(0xFF1A1A1A);
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _dCell(ramadanDay, textColor, flex: 2,
              bold: isToday),
          _dCell(dateStr,    textColor, flex: 3),
          _dCell(weekday,    textColor, flex: 3),
          _dCell(_fmt12(sehriTime),  textColor, flex: 3,
              bold: isToday),
          _dCell(_fmt12(iftarTime),  textColor, flex: 3,
              bold: isToday),
        ],
      ),
    );
  }

  Widget _dCell(String text, Color color,
      {int flex = 1, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.hindSiliguri(
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Adjust time by ±minutes ───────────────────────────────
  String _adjustTime(String raw, int deltaMin) {
    try {
      final parts = raw.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final total = h * 60 + m + deltaMin;
      final nh = (total ~/ 60) % 24;
      final nm = total % 60;
      return '${nh.toString().padLeft(2, '0')}:${nm.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  // ── Footer note ───────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0FFF4),
      padding: const EdgeInsets.all(14),
      child: Text(
        'সতর্কতা: সাহরীর শেষ সময় ফজরের ওয়াক্তের ৫ মিনিট পূর্বে এবং ইফতার সূর্যাস্তের ৩ মিনিট পর বিবেচনা করা হয়েছে।',
        style: GoogleFonts.hindSiliguri(
          fontSize: 12,
          color: const Color(0xFF2E7D32),
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
