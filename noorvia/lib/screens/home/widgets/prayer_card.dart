import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/gradient_helper.dart';
import '../../../core/providers/prayer_provider.dart';
import '../../../widgets/shimmer.dart';

// ═══════════════════════════════════════════════════════════════
// PrayerCard — full redesign matching the reference image
// ═══════════════════════════════════════════════════════════════
class PrayerCard extends StatefulWidget {
  final bool isDark;
  const PrayerCard({super.key, required this.isDark});

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard>
    with TickerProviderStateMixin {
  // Entrance animation
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  // Pulsing dot
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  bool get isDark => widget.isDark;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _enterFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOut,
    );
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOutCubic,
    ));
    _enterCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Bangla digits ─────────────────────────────────────────
  String _bn(String s) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  // ── 24h → display (Bangla digits, keep 24h format like image) ─
  String _fmt(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return _bn(t);
    return '${_bn(parts[0].padLeft(2,'0'))}:${_bn(parts[1])}';
  }

  // ── Next prayer end time (the prayer after next) ──────────
  String _nextEnd(PrayerTimeModel pt, String currentPrayer) {
    final order = [
      {'name': 'ফজর',    'time': pt.fajr},
      {'name': 'সূর্যোদয়','time': pt.sunrise},
      {'name': 'যোহর',   'time': pt.dhuhr},
      {'name': 'আসর',    'time': pt.asr},
      {'name': 'মাগরিব', 'time': pt.maghrib},
      {'name': 'ইশা',    'time': pt.isha},
    ];
    for (int i = 0; i < order.length; i++) {
      if (order[i]['name'] == currentPrayer) {
        if (i + 1 < order.length) return order[i + 1]['time']!;
        return pt.fajr;
      }
    }
    return pt.fajr;
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final pt = prayer.prayerTimes;

    return FadeTransition(
      opacity: _enterFade,
      child: SlideTransition(
        position: _enterSlide,
        child: Column(
          children: [
            // ── TOP: Green date + sunrise/sunset card ─────────
            _buildTopCard(context, prayer, pt),
            const SizedBox(height: 2),
            // ── BOTTOM: Dark prayer times card ────────────────
            _buildBottomCard(context, prayer, pt),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOP CARD — Airkom purple/blue gradient background
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopCard(
      BuildContext context, PrayerProvider prayer, PrayerTimeModel? pt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3CE1), Color(0xFF4A6FE3), Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE1).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: Hijri + Bangla date ──────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                prayer.hijriDisplayDate.isNotEmpty
                    ? Text(
                        prayer.hijriDisplayDate,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : NShimmer(width: 160, height: 18, isDark: true),
                const SizedBox(height: 4),
                prayer.banglaDate.isNotEmpty
                    ? Text(
                        prayer.banglaDate,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      )
                    : NShimmer(width: 200, height: 13, isDark: true),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.35),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // ── Right: Sun icon + sunrise/sunset ──────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sun icon
                const Text('☀️', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                if (pt != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            _fmt(pt.sunrise),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'সূর্যোদয়',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _fmt(pt.maghrib),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'সূর্যাস্ত',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  NShimmer(width: 120, height: 30, isDark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BOTTOM CARD — White background (light design)
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomCard(
      BuildContext context, PrayerProvider prayer, PrayerTimeModel? pt) {
    const cardBg = Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: prayer.isLoading && pt == null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: PrayerCardShimmer(isDark: false),
            )
          : pt == null
              ? const SizedBox(height: 80)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Left: circular timer ───────────────
                      _buildTimerSection(prayer, pt, cardBg),

                      // ── Vertical divider ───────────────────
                      Container(
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.15),
                      ),

                      // ── Right: prayer list ─────────────────
                      Expanded(
                        child: _buildPrayerList(prayer, pt),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LEFT: current prayer name + circular countdown
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimerSection(
      PrayerProvider prayer, PrayerTimeModel pt, Color bg) {
    return SizedBox(
      width: 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current prayer name
            Text(
              prayer.currentPrayer.isNotEmpty ? prayer.currentPrayer : '--',
              style: GoogleFonts.hindSiliguri(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1836),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'শেষ হতে বাকি',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 14),

            // Circular progress with countdown
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _CircularTimerPainter(
                  progress: prayer.prayerProgress.clamp(0.0, 1.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pulsing dot
                      FadeTransition(
                        opacity: _pulseAnim,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.gradientStart,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildCountdownText(prayer),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1836),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildCountdownText(PrayerProvider prayer) {
    // Extract HH:MM:SS from timeRemaining or currentTime
    // Use currentTime seconds for live countdown display
    final t = prayer.currentTime; // "HH:MM:SS AM/PM" in Bangla
    // Just show timeRemaining compactly
    final rem = prayer.timeRemaining;
    if (rem.isEmpty) return '--:--';
    // Parse hours/minutes from timeRemaining string
    // Format: "X ঘণ্টা Y মিনিট বাকি" or "Y মিনিট বাকি"
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return _bn('$h:$m:$s');
  }

  // ─────────────────────────────────────────────────────────────
  // RIGHT: prayer list
  // ─────────────────────────────────────────────────────────────
  Widget _buildPrayerList(PrayerProvider prayer, PrayerTimeModel pt) {
    final prayers = [
      {'name': 'ফজর',    'start': pt.fajr,    'end': pt.sunrise},
      {'name': 'যুহর',   'start': pt.dhuhr,   'end': pt.asr},
      {'name': 'আসর',    'start': pt.asr,     'end': pt.maghrib},
      {'name': 'মাগরিব', 'start': pt.maghrib, 'end': pt.isha},
      {'name': 'ইশা',    'start': pt.isha,    'end': pt.tahajjud},
    ];

    // Map current prayer name to list name
    final currentName = _mapPrayerName(prayer.currentPrayer);

    return Column(
      children: prayers.map((p) {
        final isActive = p['name'] == currentName;
        return _buildPrayerRow(
          name: p['name']!,
          start: p['start']!,
          end: p['end']!,
          isActive: isActive,
          isLast: p['name'] == 'ইশা',
          pt: pt,
        );
      }).toList(),
    );
  }

  String _mapPrayerName(String name) {
    // provider uses যোহর, image uses যুহর — normalize
    if (name == 'যোহর') return 'যুহর';
    return name;
  }

  Widget _buildPrayerRow({
    required String name,
    required String start,
    required String end,
    required bool isActive,
    required bool isLast,
    required PrayerTimeModel pt,
  }) {
    // Active row: light peach/orange background like 2nd image
    final bgDecoration = isActive
        ? const BoxDecoration(
            color: Color(0xFFFFF3E8),
          )
        : BoxDecoration(
            color: Colors.transparent,
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
          );

    final textColor = const Color(0xFF1A1836);
    final subColor = isActive
        ? const Color(0xFF6C3CE1)
        : Colors.black;

    return Container(
      decoration: bgDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                '${_fmt(start)} - ${_fmt(end)}',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: subColor,
                ),
              ),
            ],
          ),
          // Extra info for Isha (মাকরুহ time)
          if (name == 'ইশা')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'মাকরুহ: রাত ${_fmt(pt.tahajjud)}',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Circular timer painter ───────────────────────────────────
class _CircularTimerPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  _CircularTimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 8.0;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc — starts from top (-π/2), goes clockwise
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = GradientHelper.gradientPaint(arcRect)
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// RamadanMiniCard — সাহরি / ইফতার countdown widget
// ═══════════════════════════════════════════════════════════════
class RamadanMiniCard extends StatefulWidget {
  final bool isDark;
  final VoidCallback onExpand;

  const RamadanMiniCard({
    super.key,
    required this.isDark,
    required this.onExpand,
  });

  @override
  State<RamadanMiniCard> createState() => _RamadanMiniCardState();
}

class _RamadanMiniCardState extends State<RamadanMiniCard>
    with SingleTickerProviderStateMixin {
  // ── API data ──────────────────────────────────────────────
  String _sehriTime  = '';   // "HH:MM"
  String _iftarTime  = '';   // "HH:MM"
  bool   _loading    = true;
  String? _error;

  // ── Live countdown ────────────────────────────────────────
  Timer? _timer;
  String _sehriCountdown = '--:--:--';
  String _iftarCountdown = '--:--:--';
  String _activeLabel    = 'সাহরির বাকি';

  // ── Entrance animation ────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final Animation<double>   _enterFade;
  late final Animation<Offset>   _enterSlide;

  bool get isDark => widget.isDark;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _fetchTodayTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── Fetch today's Fajr (সাহরি) & Maghrib (ইফতার) ─────────
  Future<void> _fetchTodayTimes() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final url =
          'https://api.aladhan.com/v1/timingsByCity/$dateStr?city=Dhaka&country=Bangladesh&method=2';

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final timings = data['data']['timings'] as Map<String, dynamic>;
        final fajr    = (timings['Fajr']    as String).split(' ').first;
        final maghrib = (timings['Maghrib'] as String).split(' ').first;

        if (mounted) {
          setState(() {
            _sehriTime = fajr;
            _iftarTime = maghrib;
            _loading   = false;
          });
          _startCountdown();
          _enterCtrl.forward();
        }
      } else {
        if (mounted) setState(() { _loading = false; _error = 'লোড ব্যর্থ'; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'নেটওয়ার্ক ত্রুটি'; });
    }
  }

  // ── Start 1-second tick ───────────────────────────────────
  void _startCountdown() {
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdowns();
    });
  }

  void _updateCountdowns() {
    final now = DateTime.now();

    setState(() {
      _sehriCountdown = _countdown(_sehriTime, now);
      _iftarCountdown = _countdown(_iftarTime, now);

      // Decide which countdown is "active" (the one still in future)
      final sehriPast = _isPast(_sehriTime, now);
      final iftarPast = _isPast(_iftarTime, now);

      if (!sehriPast) {
        _activeLabel = 'সাহরির বাকি';
      } else if (!iftarPast) {
        _activeLabel = 'ইফতারের বাকি';
      } else {
        _activeLabel = 'পরবর্তী সাহরির বাকি';
      }
    });
  }

  bool _isPast(String timeStr, DateTime now) {
    if (timeStr.isEmpty) return false;
    final parts = timeStr.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final target = DateTime(now.year, now.month, now.day, h, m);
    return now.isAfter(target);
  }

  String _countdown(String timeStr, DateTime now) {
    if (timeStr.isEmpty) return '--:--:--';
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      var target = DateTime(now.year, now.month, now.day, h, m);
      if (now.isAfter(target)) {
        // Already past today — show next day
        target = target.add(const Duration(days: 1));
      }
      final diff = target.difference(now);
      final hh = diff.inHours.toString().padLeft(2, '0');
      final mm = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return _bn('$hh:$mm:$ss');
    } catch (_) {
      return '--:--:--';
    }
  }

  // ── Bangla digits ─────────────────────────────────────────
  String _bn(String s) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  String _fmt(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return _bn(t);
    return '${_bn(parts[0].padLeft(2, '0'))}:${_bn(parts[1])}';
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Colors.white;

    if (_loading) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            _error!,
            style: GoogleFonts.hindSiliguri(
              color: Colors.black,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // Determine active countdown (the one still in future, or next sehri)
    final now = DateTime.now();
    final sehriPast = _isPast(_sehriTime, now);
    final iftarPast = _isPast(_iftarTime, now);
    final activeCountdown = sehriPast ? _iftarCountdown : _sehriCountdown;

    // Build human-readable countdown pill text
    String _pillText(String countdownHHMMSS) {
      // countdownHHMMSS is in Bangla digits "HH:MM:SS"
      // Convert back to parse
      String ascii = countdownHHMMSS;
      const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
      const e = ['0','1','2','3','4','5','6','7','8','9'];
      for (int i = 0; i < b.length; i++) ascii = ascii.replaceAll(b[i], e[i]);
      final parts = ascii.split(':');
      if (parts.length < 2) return countdownHHMMSS;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      if (h > 0) return _bn('আর $h ঘণ্টা $m মিনিট');
      return _bn('আর $m মিনিট');
    }

    final sehriPill = _pillText(_sehriCountdown);
    final iftarPill = _pillText(_iftarCountdown);

    return FadeTransition(
      opacity: _enterFade,
      child: SlideTransition(
        position: _enterSlide,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            child: Row(
              children: [
                // ── Col 1: সাহরি ────────────────────────────
                Expanded(
                  child: _buildIconColumn(
                    iconWidget: _circleIcon(
                      icon: Icons.nightlight_round,
                      bgColor: const Color(0xFF6C3CE1),
                      iconColor: Colors.white,
                    ),
                    time: _fmt(_sehriTime),
                    label: 'পরবর্তী সাহরি',
                    pillText: sehriPill,
                    pillBg: const Color(0xFFEDE7FF),
                    pillTextColor: const Color(0xFF6C3CE1),
                    isPast: sehriPast,
                  ),
                ),

                _vDivider(),

                // ── Col 2: ইফতার ────────────────────────────
                Expanded(
                  child: _buildIconColumn(
                    iconWidget: _circleIcon(
                      icon: Icons.wb_twilight_rounded,
                      bgColor: const Color(0xFFFF8C00),
                      iconColor: Colors.white,
                    ),
                    time: _fmt(_iftarTime),
                    label: 'পরবর্তী ইফতার',
                    pillText: iftarPill,
                    pillBg: const Color(0xFFFFF0E0),
                    pillTextColor: const Color(0xFFFF6B00),
                    isPast: iftarPast,
                  ),
                ),

                _vDivider(),

                // ── Col 3: Countdown ─────────────────────────
                Expanded(
                  child: _buildIconColumn(
                    iconWidget: _circleIcon(
                      icon: Icons.access_time_rounded,
                      bgColor: const Color(0xFF2979FF),
                      iconColor: Colors.white,
                    ),
                    time: activeCountdown,
                    label: _activeLabel,
                    pillText: 'মধ্যরাত শেষ',
                    pillBg: const Color(0xFFE3EEFF),
                    pillTextColor: const Color(0xFF2979FF),
                    isPast: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Colored circle with icon inside
  Widget _circleIcon({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  /// One column: icon + time + label + pill
  Widget _buildIconColumn({
    required Widget iconWidget,
    required String time,
    required String label,
    required String pillText,
    required Color pillBg,
    required Color pillTextColor,
    required bool isPast,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 8),
        Text(
          time,
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isPast ? Colors.black38 : const Color(0xFF1A1836),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 11,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // Pill button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            pillText,
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: pillTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      color: Colors.grey.withValues(alpha: 0.15),
    );
  }
}
