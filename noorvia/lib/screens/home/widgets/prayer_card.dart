import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
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
  // TOP CARD — green background
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopCard(
      BuildContext context, PrayerProvider prayer, PrayerTimeModel? pt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
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
  // BOTTOM CARD — dark background
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomCard(
      BuildContext context, PrayerProvider prayer, PrayerTimeModel? pt) {
    final darkBg = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFF1E2235);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: prayer.isLoading && pt == null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: PrayerCardShimmer(isDark: true),
            )
          : pt == null
              ? const SizedBox(height: 80)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Left: circular timer ───────────────
                      _buildTimerSection(prayer, pt, darkBg),

                      // ── Vertical divider ───────────────────
                      Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.12),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'শেষ হতে বাকি',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
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
                            color: AppColors.primary,
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
                          color: Colors.white,
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
    final bg = isActive ? AppColors.primary : Colors.transparent;
    final textColor = Colors.white;
    final subColor = isActive
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.55);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
        borderRadius: isActive
            ? BorderRadius.zero
            : null,
      ),
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
                  color: isActive ? Colors.white : subColor,
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
                  color: Colors.white.withValues(alpha: 0.45),
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
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc — starts from top (-π/2), goes clockwise
    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
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
    const darkBg = Color(0xFF1E2235);

    if (_loading) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
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
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            _error!,
            style: GoogleFonts.hindSiliguri(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // Determine active countdown (the one still in future, or next sehri)
    final now = DateTime.now();
    final sehriPast = _isPast(_sehriTime, now);
    final activeCountdown = sehriPast ? _iftarCountdown : _sehriCountdown;

    return FadeTransition(
      opacity: _enterFade,
      child: SlideTransition(
        position: _enterSlide,
        child: Container(
          decoration: BoxDecoration(
            color: darkBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Main content ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // ── Col 1: সাহরি ──────────────────────
                      Expanded(
                        child: _buildTimeColumn(
                          icon: '🌙',
                          time: _fmt(_sehriTime),
                          label: 'পরবর্তী সাহরি',
                          isPast: sehriPast,
                        ),
                      ),

                      // ── Divider ────────────────────────────
                      _vDivider(),

                      // ── Col 2: ইফতার ──────────────────────
                      Expanded(
                        child: _buildTimeColumn(
                          icon: '🌅',
                          time: _fmt(_iftarTime),
                          label: 'পরবর্তী ইফতার',
                          isPast: _isPast(_iftarTime, now),
                        ),
                      ),

                      // ── Divider ────────────────────────────
                      _vDivider(),

                      // ── Col 3: Active countdown ────────────
                      Expanded(
                        child: _buildCountdownColumn(
                          countdown: activeCountdown,
                          label: _activeLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expand icon (top-right) ───────────────────
              Positioned(
                top: 8,
                right: 10,
                child: GestureDetector(
                  onTap: widget.onExpand,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn({
    required String icon,
    required String time,
    required String label,
    required bool isPast,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(
          time,
          style: GoogleFonts.hindSiliguri(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isPast
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // অ্যালার্ম button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'অ্যালার্ম সেট করা হয়েছে: $time',
                  style: GoogleFonts.hindSiliguri(),
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Text(
            'অ্যালার্ম',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownColumn({
    required String countdown,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 26), // align with time columns
        Text(
          countdown,
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}
