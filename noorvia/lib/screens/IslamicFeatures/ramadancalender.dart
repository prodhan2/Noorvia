import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/gradient_helper.dart';
import '../../core/providers/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Ramadan Calendar — Multi-year, scroll up/down for prev/next year
// ═══════════════════════════════════════════════════════════════

class RamadanCalendarPage extends StatefulWidget {
  const RamadanCalendarPage({super.key});

  @override
  State<RamadanCalendarPage> createState() => _RamadanCalendarPageState();
}

class _RamadanCalendarPageState extends State<RamadanCalendarPage> {
  // ── Multi-year data cache ─────────────────────────────────
  // Key: Hijri year (e.g. 1446, 1447, 1448)
  final Map<int, List<dynamic>> _cache = {};
  final Map<int, bool> _loadingYear = {};
  final Map<int, String?> _errorYear = {};

  // Current Hijri year visible in AppBar
  int _visibleHijriYear = _currentHijriYear();

  // The range of years to show (current ±3)
  late final int _minYear;
  late final int _maxYear;

  // City
  String _city = 'Dhaka';
  String _cityBnDisplay = 'ঢাকা';
  bool _locationLoading = false;

  // Clock
  Timer? _timer;
  DateTime _now = DateTime.now();

  // Scroll
  final ScrollController _scroll = ScrollController();

  // PDF generation state
  bool _pdfLoading = false;

  // Each year block height (approx) for year detection
  // We'll use a GlobalKey per year header to detect visibility
  final Map<int, GlobalKey> _yearKeys = {};

  static const _cities = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi',
    'Khulna', 'Barishal', 'Rangpur', 'Mymensingh',
  ];

  static const _cityBn = {
    'Dhaka': 'ঢাকা', 'Chittagong': 'চট্টগ্রাম', 'Sylhet': 'সিলেট',
    'Rajshahi': 'রাজশাহী', 'Khulna': 'খুলনা', 'Barishal': 'বরিশাল',
    'Rangpur': 'রংপুর', 'Mymensingh': 'ময়মনসিংহ',
  };

  // ── Beautiful Islamic color palette ──────────────────────
  static const _kEmerald      = Color(0xFF0D5C3A);
  static const _kEmeraldLight = Color(0xFF1A7A4E);
  static const _kGold         = Color(0xFFD4A017);
  static const _kGoldLight    = Color(0xFFF5C842);
  static const _kCream        = Color(0xFFFAF6EE);
  static const _kCreamDark    = Color(0xFFF0E8D5);
  static const _kNavy         = Color(0xFF1A2744);

  static const _sections = [
    {'label': 'রহমতের ১০ দিন',     'bg': Color(0xFFE8F5EE), 'text': Color(0xFF0D5C3A), 'accent': Color(0xFF0D5C3A)},
    {'label': 'মাগফিরাতের ১০ দিন', 'bg': Color(0xFFFFF8E8), 'text': Color(0xFF8B5E00), 'accent': Color(0xFFD4A017)},
    {'label': 'নাজাতের ১০ দিন',    'bg': Color(0xFFEAF2FF), 'text': Color(0xFF1A3A6B), 'accent': Color(0xFF2563EB)},
  ];

  // ── Compute current Hijri year ────────────────────────────
  static int _currentHijriYear() {
    // Approximate: Hijri year ≈ (Gregorian year - 622) * 1.0307
    final g = DateTime.now().year;
    return ((g - 622) * 1.0307).round();
  }

  @override
  void initState() {
    super.initState();
    final cur = _currentHijriYear();
    _minYear = cur - 3;
    _maxYear = cur + 3;
    _visibleHijriYear = cur;

    for (int y = _minYear; y <= _maxYear; y++) {
      _yearKeys[y] = GlobalKey();
    }

    _scroll.addListener(_onScroll);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Auto-scroll to current year section after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentYear();
    });

    _initLocation();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Detect which year is currently visible ────────────────
  void _onScroll() {
    for (int y = _minYear; y <= _maxYear; y++) {
      final key = _yearKeys[y];
      if (key == null) continue;
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      // If the year header is in the top half of the screen
      if (pos.dy >= 0 && pos.dy < MediaQuery.of(context).size.height * 0.6) {
        if (_visibleHijriYear != y) {
          setState(() => _visibleHijriYear = y);
        }
        break;
      }
    }
  }

  // ── Location init ─────────────────────────────────────────
  Future<void> _initLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) setState(() => _locationLoading = false);
        _fetchAllYears();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      try {
        final marks = await placemarkFromCoordinates(
            pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          final detected = p.locality ??
              p.subAdministrativeArea ??
              p.administrativeArea ?? 'Dhaka';
          final matched = _cities.firstWhere(
            (c) => c.toLowerCase() == detected.toLowerCase(),
            orElse: () => 'Dhaka',
          );
          if (mounted) {
            setState(() {
              _city = matched;
              _cityBnDisplay = _cityBn[matched] ?? matched;
              _locationLoading = false;
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => _locationLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
    _fetchAllYears();
  }

  // ── Fetch all years in range ──────────────────────────────
  void _fetchAllYears() {
    for (int y = _minYear; y <= _maxYear; y++) {
      _fetchYear(y);
    }
  }

  // ── Approximate Gregorian month/year when Ramadan starts for a Hijri year ──
  // Ramadan is month 9 of the Hijri calendar.
  // Approximate start: Hijri year × (354.367/365.25) days from epoch.
  // Simple formula: gYear ≈ hijriYear * 0.9702 + 621.57
  static ({int year, int month}) _ramadanGregorianStart(int hijriYear) {
    // Approximate Julian Day of 1 Ramadan
    // JD of 1 Muharram 1 AH ≈ 1948438.5
    // Each Hijri year ≈ 354.367 days
    final jd = 1948438.5 + (hijriYear - 1) * 354.367 + 8 * 29.5; // +8 months
    // Convert JD to Gregorian
    final z = (jd + 0.5).floor();
    final a = ((z - 1867216.25) / 36524.25).floor();
    final b = z + 1 + a - (a ~/ 4);
    final c = b + 1524;
    final d = ((c - 122.1) / 365.25).floor();
    final e = (365.25 * d).floor();
    final f = ((c - e) / 30.6001).floor();
    final month = f < 14 ? f - 1 : f - 13;
    final year  = month > 2 ? d - 4716 : d - 4715;
    return (year: year, month: month);
  }

  // ── Fetch one Hijri year's Ramadan data using Gregorian API ──────────────
  Future<void> _fetchYear(int hijriYear) async {
    if (_loadingYear[hijriYear] == true) return;
    setState(() {
      _loadingYear[hijriYear] = true;
      _errorYear[hijriYear] = null;
    });
    try {
      final start = _ramadanGregorianStart(hijriYear);
      // Ramadan spans ~30 days; may cross two Gregorian months.
      // Fetch the start month and optionally the next month, then filter.
      final allDays = <dynamic>[];

      Future<List<dynamic>> fetchMonth(int year, int month) async {
        final url =
            'https://api.aladhan.com/v1/calendarByCity/$year/$month'
            '?city=$_city&country=Bangladesh&method=2';
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          return (body['data'] as List<dynamic>?) ?? [];
        }
        return [];
      }

      // Fetch start month
      final m1 = await fetchMonth(start.year, start.month);
      allDays.addAll(m1);

      // Fetch next month too (Ramadan often spills over)
      final nextMonth = start.month == 12 ? 1 : start.month + 1;
      final nextYear  = start.month == 12 ? start.year + 1 : start.year;
      final m2 = await fetchMonth(nextYear, nextMonth);
      allDays.addAll(m2);

      // Filter only days whose hijri month == 9 (Ramadan)
      final ramadanDays = allDays.where((d) {
        final hMonth = d['date']?['hijri']?['month']?['number'];
        return hMonth != null && hMonth.toString() == '9';
      }).toList();

      // Sort by timestamp to be safe
      ramadanDays.sort((a, b) {
        final ta = int.tryParse(a['date']?['timestamp']?.toString() ?? '0') ?? 0;
        final tb = int.tryParse(b['date']?['timestamp']?.toString() ?? '0') ?? 0;
        return ta.compareTo(tb);
      });

      if (mounted) {
        setState(() {
          _cache[hijriYear] = ramadanDays;
          _loadingYear[hijriYear] = false;
        });
        if (hijriYear == _currentHijriYear()) {
          // Small delay so the newly built rows are laid out before scrolling
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _scrollToToday();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingYear[hijriYear] = false;
          _errorYear[hijriYear] = 'নেটওয়ার্ক ত্রুটি';
        });
      }
    }
  }

  // ── Re-fetch all when city changes ────────────────────────
  void _refetchAll() {
    _cache.clear();
    _fetchAllYears();
  }

  // ── Scroll to current year section (called on page open) ─
  void _scrollToCurrentYear() {
    final curYear = _currentHijriYear();
    final key = _yearKeys[curYear];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0.0, // align to top of viewport
    );
  }

  // ── Scroll to today ───────────────────────────────────────
  void _scrollToToday() {
    final curYear = _currentHijriYear();
    final key = _yearKeys[curYear];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    final data = _cache[curYear];
    if (data == null) return;

    final idx = data.indexWhere((d) => _isToday(d));

    // First scroll to the year header
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    ).then((_) {
      if (!_scroll.hasClients) return;
      if (idx < 0) return;

      // Each section header ~40px, each row ~52px, year banner ~44px
      // section headers appear at index 0, 10, 20
      final sectionHeadersBefore = (idx ~/ 10) + 1; // headers before this row
      final extra = 44.0                             // year banner
          + sectionHeadersBefore * 40.0              // section headers
          + idx * 52.0;                              // rows above today

      final target = (_scroll.offset + extra)
          .clamp(0.0, _scroll.position.maxScrollExtent);

      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  bool _isToday(dynamic d) {
    try {
      final ts = int.parse(d['date']['timestamp'].toString());
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
      return dt.day == _now.day &&
          dt.month == _now.month &&
          dt.year == _now.year;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  String _bn(String s) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

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

  // ── Gregorian year range label from cached data or approximation ─────────
  String _gregorianYearRange(int hijriYear) {
    final data = _cache[hijriYear];
    if (data != null && data.isNotEmpty) {
      // Get year from first and last day's readable field e.g. "01 Mar 2026"
      final first = data.first['date']['readable']?.toString() ?? '';
      final last  = data.last['date']['readable']?.toString() ?? '';
      final y1 = first.split(' ').lastOrNull ?? '';
      final y2 = last.split(' ').lastOrNull ?? '';
      if (y1.isNotEmpty && y2.isNotEmpty) {
        return y1 == y2 ? y1 : '$y1-$y2';
      }
    }
    // Fallback approximation
    final g1 = (hijriYear / 1.0307 + 622).round();
    return '$g1-${g1 + 1}';
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFFFF8E7);
    
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: GradientHelper.boxDecoration(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'রমজান ক্যালেন্ডার',
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                // Live year badge — gold accent
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(_visibleHijriYear),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gradientStart.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gradientEnd.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Text(
                      '${_bn(_visibleHijriYear.toString())} হি.',
                      style: GoogleFonts.hindSiliguri(
                        color: AppColors.gradientEnd,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_locationLoading)
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 1.5),
              )
            else
              Text(
                _cityBnDisplay,
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          // ── PDF Download button ──────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _pdfLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _generateAndDownloadPdf,
                    tooltip: 'PDF ডাউনলোড',
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _city,
                dropdownColor: AppColors.gradientStart,
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
                    setState(() {
                      _city = v;
                      _cityBnDisplay = _cityBn[v] ?? v;
                    });
                    _refetchAll();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          children: [
            // ── Sticky column header ───────────────────────
            _buildColumnHeader(),

            // ── All years ─────────────────────────────────
            for (int y = _minYear; y <= _maxYear; y++)
              _buildYearBlock(y),

            // ── Footer ────────────────────────────────────
            _buildFooter(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToToday,
        backgroundColor: AppColors.gradientStart,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.today_rounded, color: Colors.white),
        tooltip: 'আজকে যান',
      ),
    );
  }

  // ── Generate & download PDF for visible Hijri year ───────
  Future<void> _generateAndDownloadPdf() async {
    final hijriYear = _visibleHijriYear;
    final data = _cache[hijriYear];

    if (data == null || data.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'ডেটা লোড হয়নি। একটু অপেক্ষা করুন।',
          style: GoogleFonts.hindSiliguri(fontSize: 13),
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() => _pdfLoading = true);

    try {
      // Load a font that supports Bengali
      final ttf = await PdfGoogleFonts.hindSiliguriRegular();
      final ttfBold = await PdfGoogleFonts.hindSiliguriMedium();

      final pdf = pw.Document();

      // Colors
      final headerBg   = PdfColor.fromHex('6C3CE1');
      final headerText = PdfColors.white;
      final todayBg    = PdfColor.fromHex('6C3CE1');
      final sec1Bg     = PdfColor.fromHex('E8F5EE');
      final sec2Bg     = PdfColor.fromHex('FFF8E8');
      final sec3Bg     = PdfColor.fromHex('EAF2FF');
      final sec1Accent = PdfColor.fromHex('0D5C3A');
      final sec2Accent = PdfColor.fromHex('D4A017');
      final sec3Accent = PdfColor.fromHex('2563EB');
      final rowEven    = PdfColors.white;
      final rowOdd     = PdfColor.fromHex('FAF6EE');
      final textDark   = PdfColor.fromHex('1A1A1A');
      final textSub    = PdfColor.fromHex('555555');

      final gRange = _gregorianYearRange(hijriYear);
      final cityName = _cityBnDisplay;

      // Split data into sections of 10
      final sections = [
        {'label': 'রহমতের ১০ দিন',     'bg': sec1Bg, 'accent': sec1Accent},
        {'label': 'মাগফিরাতের ১০ দিন', 'bg': sec2Bg, 'accent': sec2Accent},
        {'label': 'নাজাতের ১০ দিন',    'bg': sec3Bg, 'accent': sec3Accent},
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => pw.Container(
            decoration: pw.BoxDecoration(color: headerBg),
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'রমজান ক্যালেন্ডার  •  $hijriYear হিজরি  •  $gRange',
                  style: pw.TextStyle(font: ttfBold, fontSize: 13, color: headerText),
                ),
                pw.Text(
                  cityName,
                  style: pw.TextStyle(font: ttf, fontSize: 11, color: headerText),
                ),
              ],
            ),
          ),
          footer: (ctx) => pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: sec2Accent, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'সাহরীর শেষ = ফজরের ৫ মিনিট পূর্বে  |  ইফতার = মাগরিবের ৩ মিনিট পর',
                  style: pw.TextStyle(font: ttf, fontSize: 8, color: textSub),
                ),
                pw.Text(
                  'পৃষ্ঠা ${ctx.pageNumber}/${ctx.pagesCount}',
                  style: pw.TextStyle(font: ttf, fontSize: 8, color: textSub),
                ),
              ],
            ),
          ),
          build: (ctx) {
            final widgets = <pw.Widget>[];

            // Column header row
            widgets.add(
              pw.Container(
                decoration: pw.BoxDecoration(color: headerBg),
                padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                child: pw.Row(children: [
                  _pdfCell('রমাযান', ttfBold, headerText, flex: 2),
                  _pdfCell('তারিখ',  ttfBold, headerText, flex: 4),
                  _pdfCell('বার',    ttfBold, headerText, flex: 3),
                  _pdfCell('সাহরী শেষ', ttfBold, headerText, flex: 3),
                  _pdfCell('ইফতার', ttfBold, headerText, flex: 3),
                ]),
              ),
            );

            for (int i = 0; i < data.length; i++) {
              // Section header every 10 rows
              if (i == 0 || i == 10 || i == 20) {
                final sIdx = i ~/ 10;
                final s = sections[sIdx];
                widgets.add(
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: s['bg'] as PdfColor,
                      border: pw.Border(
                        left: pw.BorderSide(color: s['accent'] as PdfColor, width: 3),
                      ),
                    ),
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: pw.Text(
                      s['label'] as String,
                      style: pw.TextStyle(font: ttfBold, fontSize: 11, color: s['accent'] as PdfColor),
                    ),
                  ),
                );
              }

              final day = data[i];
              final isToday = _isToday(day);
              final g = day['date']['gregorian'];
              final timings = day['timings'] as Map<String, dynamic>;
              final ramadanDay = _bn((i + 1).toString().padLeft(2, '0'));
              final readable = day['date']['readable']?.toString() ?? '';
              final weekday = _weekdayBn(g['weekday']['en'] as String);
              final fajrRaw = (timings['Fajr'] as String).split(' ').first;
              final maghribRaw = (timings['Maghrib'] as String).split(' ').first;
              final sehriTime = _fmt12(_adjustTime(fajrRaw, -5));
              final iftarTime = _fmt12(_adjustTime(maghribRaw, 3));

              final rowBg = isToday ? todayBg : (i.isEven ? rowEven : rowOdd);
              final textColor = isToday ? PdfColors.white : textDark;
              final sehriColor = isToday ? PdfColor.fromHex('B2EBD4') : PdfColor.fromHex('5C6BC0');
              final iftarColor = isToday ? PdfColor.fromHex('FFD580') : PdfColor.fromHex('E53935');

              widgets.add(
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: rowBg,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColor.fromHex('E0E0E0'), width: 0.5),
                      left: isToday
                          ? pw.BorderSide(color: PdfColor.fromHex('F5C842'), width: 3)
                          : pw.BorderSide(color: PdfColor.fromInt(0x00000000), width: 0),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: pw.Row(children: [
                    _pdfCell(ramadanDay, isToday ? ttfBold : ttfBold,
                        isToday ? PdfColor.fromHex('F5C842') : PdfColor.fromHex('6C3CE1'), flex: 2),
                    _pdfCell(readable,   ttf, textColor, flex: 4),
                    _pdfCell(weekday,    ttf, textColor, flex: 3),
                    _pdfCell(sehriTime,  isToday ? ttfBold : ttf, sehriColor, flex: 3),
                    _pdfCell(iftarTime,  isToday ? ttfBold : ttf, iftarColor, flex: 3),
                  ]),
                ),
              );
            }

            return widgets;
          },
        ),
      );

      // Share/save via printing package (works on Android, iOS, desktop)
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'ramadan_${hijriYear}_$_city.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'PDF তৈরি করতে সমস্যা হয়েছে।',
          style: GoogleFonts.hindSiliguri(fontSize: 13),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  // ── PDF cell helper ───────────────────────────────────────
  pw.Widget _pdfCell(String text, pw.Font font, PdfColor color, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 10, color: color),
      ),
    );
  }

  // ── Column header (sticky-like, always at top of list) ────
  Widget _buildColumnHeader() {
    return Container(
      decoration: GradientHelper.boxDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Row(
        children: [
          _hCell('রমাযান', flex: 2),
          _hCell('তারিখ',  flex: 4),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ),
    );
  }

  // ── One year block ────────────────────────────────────────
  Widget _buildYearBlock(int hijriYear) {
    final isLoading = _loadingYear[hijriYear] == true;
    final error     = _errorYear[hijriYear];
    final data      = _cache[hijriYear];
    final isCurrent = hijriYear == _currentHijriYear();
    final gRange    = _gregorianYearRange(hijriYear);

    return Column(
      key: _yearKeys[hijriYear],
      children: [
        // ── Year separator banner ──────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isCurrent
                ? AppColors.gradient
                : const LinearGradient(
                    colors: [Color(0xFF1A2744), Color(0xFF2A3F6B)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.gradientEnd : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'রমজান ${_bn(hijriYear.toString())} হিজরি  •  $gRange খ্রিস্টাব্দ',
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.gradientEnd : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        // ── Content ───────────────────────────────────────
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.gradientStart,
                strokeWidth: 2,
              ),
            ),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(error,
                    style: GoogleFonts.hindSiliguri(
                        color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _fetchYear(hijriYear),
                  child: Text('আবার চেষ্টা',
                      style: GoogleFonts.hindSiliguri(
                          color: AppColors.gradientStart)),
                ),
              ],
            ),
          )
        else if (data != null)
          ..._buildYearRows(data)
        else
          const SizedBox(height: 40),
      ],
    );
  }

  // ── Rows for one year ─────────────────────────────────────
  List<Widget> _buildYearRows(List<dynamic> data) {
    final widgets = <Widget>[];
    for (int i = 0; i < data.length; i++) {
      if (i == 0 || i == 10 || i == 20) {
        widgets.add(_buildSectionHeader(i ~/ 10));
      }
      widgets.add(_buildRow(data[i], i));
    }
    return widgets;
  }

  Widget _buildSectionHeader(int sIdx) {
    final s = _sections[sIdx];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: s['bg'] as Color,
        border: Border(
          left: BorderSide(color: s['accent'] as Color, width: 4),
          bottom: BorderSide(color: (s['accent'] as Color).withValues(alpha: 0.2), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: s['accent'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            s['label'] as String,
            style: GoogleFonts.hindSiliguri(
              color: s['text'] as Color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(dynamic day, int index) {
    final isToday = _isToday(day);
    final g       = day['date']['gregorian'];
    final timings = day['timings'] as Map<String, dynamic>;

    final ramadanDay = _bn((index + 1).toString().padLeft(2, '0'));

    // Use API's readable field directly — e.g. "01 Mar 2026"
    final readable   = day['date']['readable']?.toString() ?? g['date']?.toString() ?? '';
    final weekday    = _weekdayBn(g['weekday']['en'] as String);

    final fajrRaw    = (timings['Fajr']    as String).split(' ').first;
    final maghribRaw = (timings['Maghrib'] as String).split(' ').first;
    final sehriTime  = _adjustTime(fajrRaw, -5);
    final iftarTime  = _adjustTime(maghribRaw, 3);

    Color rowBg;
    Color textColor;
    Color? dayNumColor;
    if (isToday) {
      rowBg       = AppColors.gradientStart;
      textColor   = Colors.white;
      dayNumColor = AppColors.gradientEnd;
    } else if (index.isEven) {
      rowBg       = Colors.white;
      textColor   = const Color(0xFF1A1A1A);
      dayNumColor = AppColors.gradientStart;
    } else {
      rowBg       = _kCream;
      textColor   = const Color(0xFF1A1A1A);
      dayNumColor = AppColors.gradientStart;
    }

    return InkWell(
      onTap: () => _showDayPopup(context, day, index),
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(
            bottom: BorderSide(
                color: isToday
                    ? AppColors.gradientEnd.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.12),
                width: 0.8),
            left: isToday
                ? BorderSide(color: AppColors.gradientEnd, width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            _dCell(ramadanDay,        dayNumColor ?? textColor, flex: 2, bold: true),
            _dateCell(readable,       textColor, flex: 4),
            _dCell(weekday,           textColor, flex: 3),
            _dCell(_fmt12(sehriTime), isToday ? const Color(0xFFB2EBD4) : const Color(0xFF5C6BC0), flex: 3, bold: isToday),
            _dCell(_fmt12(iftarTime), isToday ? const Color(0xFFFFD580) : const Color(0xFFE53935), flex: 3, bold: isToday),
          ],
        ),
      ),
    );
  }

  // ── Navigate to day detail page ──────────────────────────
  void _showDayPopup(BuildContext context, dynamic day, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RamadanDayDetailPage(
          day: day,
          index: index,
          cityBn: _cityBnDisplay,
        ),
      ),
    );
  }

  Widget _dCell(String text, Color color,
      {int flex = 1, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            )),
      ),
    );
  }

  // Date cell uses Roboto to force English (Latin) digits
  Widget _dateCell(String text, Color color, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            )),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kCreamDark,
        border: Border(top: BorderSide(color: Color(0xFFD4A017), width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _kGold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'সতর্কতা: সাহরীর শেষ সময় ফজরের ওয়াক্তের ৫ মিনিট পূর্বে এবং ইফতার সূর্যাস্তের ৩ মিনিট পর বিবেচনা করা হয়েছে।',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: const Color(0xFF6B4C00),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Ramadan Day Detail Page
// ═══════════════════════════════════════════════════════════════

class RamadanDayDetailPage extends StatelessWidget {
  final dynamic day;
  final int index;
  final String cityBn;

  const RamadanDayDetailPage({
    super.key,
    required this.day,
    required this.index,
    required this.cityBn,
  });

  // ── Bengali digit converter ───────────────────────────────
  String _bn(String s) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

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
      return raw.split(' ').first;
    }
  }

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

  String _weekdayBn(String en) {
    const map = {
      'sunday': 'রবিবার', 'monday': 'সোমবার', 'tuesday': 'মঙ্গলবার',
      'wednesday': 'বুধবার', 'thursday': 'বৃহস্পতিবার',
      'friday': 'শুক্রবার', 'saturday': 'শনিবার',
    };
    return map[en.toLowerCase()] ?? en;
  }

  @override
  Widget build(BuildContext context) {
    final g          = day['date']['gregorian'];
    final h          = day['date']['hijri'];
    final timings    = day['timings'] as Map<String, dynamic>;
    final readable   = day['date']['readable']?.toString() ?? '';
    final hijriDate  = h['date']?.toString() ?? '';
    final hijriMonthEn = h['month']?['en']?.toString() ?? '';
    final hijriMonthAr = h['month']?['ar']?.toString() ?? '';
    final weekdayEn  = g['weekday']['en']?.toString() ?? '';
    final ramadanDay = index + 1;

    final fajrRaw    = (timings['Fajr']    as String).split(' ').first;
    final maghribRaw = (timings['Maghrib'] as String).split(' ').first;
    final sehriTime  = _fmt12(_adjustTime(fajrRaw, -5));
    final iftarTime  = _fmt12(_adjustTime(maghribRaw, 3));

    final prayerList = [
      {'label': 'ইমসাক',     'icon': Icons.nightlight_round,    'key': 'Imsak',    'color': const Color(0xFF5C6BC0)},
      {'label': 'ফজর',       'icon': Icons.wb_twilight_rounded,  'key': 'Fajr',     'color': const Color(0xFF7E57C2)},
      {'label': 'সূর্যোদয়',  'icon': Icons.wb_sunny_outlined,   'key': 'Sunrise',  'color': const Color(0xFFFF8F00)},
      {'label': 'যোহর',      'icon': Icons.wb_sunny_rounded,    'key': 'Dhuhr',    'color': const Color(0xFFEF6C00)},
      {'label': 'আসর',       'icon': Icons.cloud_outlined,      'key': 'Asr',      'color': const Color(0xFF00897B)},
      {'label': 'মাগরিব',    'icon': Icons.wb_twilight_rounded, 'key': 'Maghrib',  'color': const Color(0xFFE53935)},
      {'label': 'ইশা',       'icon': Icons.nights_stay_rounded, 'key': 'Isha',     'color': const Color(0xFF1565C0)},
      {'label': 'মধ্যরাত',   'icon': Icons.bedtime_rounded,     'key': 'Midnight', 'color': const Color(0xFF37474F)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ─────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: const Color(0xFF0D5C3A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D5C3A), Color(0xFF1A7A4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30, right: -30,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20, left: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 52),
                        // Ramadan day badge — gold
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFF5C842).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'রমজান ${_bn(ramadanDay.toString())}',
                            style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFFF5C842),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          readable,
                          style: GoogleFonts.roboto(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$hijriDate  •  $hijriMonthEn  $hijriMonthAr',
                          style: GoogleFonts.roboto(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _weekdayBn(weekdayEn),
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sehri & Iftar cards ──────────────────
                  Row(
                    children: [
                      _highlightCard('সাহরী শেষ', sehriTime,
                          Icons.nightlight_round, const Color(0xFF5C6BC0)),
                      const SizedBox(width: 12),
                      _highlightCard('ইফতার', iftarTime,
                          Icons.local_dining_rounded, const Color(0xFFD4A017)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Prayer times heading ─────────────────
                  Text(
                    'নামাজের সময়সূচি',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D5C3A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Prayer tiles ─────────────────────────
                  ...prayerList.map((p) {
                    final raw = (timings[p['key'] as String] as String?)
                            ?.split(' ')
                            .first ?? '';
                    return _prayerTile(
                      p['label'] as String,
                      _fmt12(raw),
                      p['icon'] as IconData,
                      p['color'] as Color,
                    );
                  }),

                  const SizedBox(height: 20),

                  // ── City info ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0D5C3A).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFF0D5C3A), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '$cityBn, বাংলাদেশ',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: const Color(0xFF0D5C3A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Footer note ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD4A017), size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'সতর্কতা: সাহরীর শেষ সময় ফজরের ৫ মিনিট পূর্বে এবং ইফতার মাগরিবের ৩ মিনিট পর।',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 11,
                              color: const Color(0xFF6B4C00),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightCard(
      String label, String time, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    )),
                Text(time,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 17,
                      color: color,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerTile(
      String label, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(time,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ),
        ],
      ),
    );
  }
}
