import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

// ─── Modern color palette for Qibla page ───────────────────
class _QColors {
  static const teal        = Color(0xFF00897B);
  static const tealLight   = Color(0xFF4DB6AC);
  static const tealDark    = Color(0xFF00695C);
  static const gold        = Color(0xFFFFB300);
  static const bgLight     = Color(0xFFF0F7F6);
  static const bgDark      = Color(0xFF0D1F1E);
  static const cardLight   = Color(0xFFFFFFFF);
  static const cardDark    = Color(0xFF1A2E2C);
  static const ringLight   = Color(0xFFE0F2F1);
  static const ringDark    = Color(0xFF1F3533);
}

class QiblaDirectionPage extends StatefulWidget {
  const QiblaDirectionPage({super.key});

  @override
  State<QiblaDirectionPage> createState() => _QiblaDirectionPageState();
}

class _QiblaDirectionPageState extends State<QiblaDirectionPage>
    with TickerProviderStateMixin {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _currentHeading;
  double? _qiblaDirection;
  double? _distanceKm;
  String  _cityName    = '';
  String  _countryName = '';
  bool    _isLoading   = true;
  String? _errorMessage;
  StreamSubscription<CompassEvent>? _compassSub;

  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initQibla();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  Future<void> _initQibla() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() { _errorMessage = 'লোকেশন পারমিশন প্রয়োজন'; _isLoading = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _qiblaDirection = _bearing(pos.latitude, pos.longitude);
      _distanceKm     = _haversine(pos.latitude, pos.longitude);
      _cityName       = '${pos.latitude.toStringAsFixed(3)}°N';
      _countryName    = '${pos.longitude.toStringAsFixed(3)}°E';

      _compassSub?.cancel();
      _compassSub = FlutterCompass.events?.listen((e) {
        if (mounted && e.heading != null) setState(() => _currentHeading = e.heading);
      });
      setState(() => _isLoading = false);
    } catch (_) {
      setState(() { _errorMessage = 'ত্রুটি হয়েছে। আবার চেষ্টা করুন।'; _isLoading = false; });
    }
  }

  double _bearing(double lat, double lng) {
    final phi1 = _r(lat), phi2 = _r(_kaabaLat);
    final dLng = _r(_kaabaLng - lng);
    final y = math.sin(dLng) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
    return (_d(math.atan2(y, x)) + 360) % 360;
  }

  double _haversine(double lat, double lng) {
    const R = 6371.0;
    final phi1 = _r(lat), phi2 = _r(_kaabaLat);
    final dLat = _r(_kaabaLat - lat), dLng = _r(_kaabaLng - lng);
    final a = math.sin(dLat/2)*math.sin(dLat/2) +
              math.cos(phi1)*math.cos(phi2)*math.sin(dLng/2)*math.sin(dLng/2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
  }

  double _r(double d) => d * math.pi / 180;
  double _d(double r) => r * 180 / math.pi;

  double? get _needleAngle {
    if (_currentHeading == null || _qiblaDirection == null) return null;
    return (_qiblaDirection! - _currentHeading! + 360) % 360;
  }

  bool get _aligned {
    final a = _needleAngle;
    return a != null && (a < 5 || a > 355);
  }

  // ── helpers ──────────────────────────────────────────────
  String _toBanglaNum(String s) {
    const en = ['0','1','2','3','4','5','6','7','8','9','.'];
    const bn = ['০','১','২','৩','৪','৫','৬','৭','৮','৯','।'];
    for (int i = 0; i < en.length; i++) s = s.replaceAll(en[i], bn[i]);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg        = isDark ? _QColors.bgDark    : _QColors.bgLight;
    final card      = isDark ? _QColors.cardDark  : _QColors.cardLight;
    final ring      = isDark ? _QColors.ringDark  : _QColors.ringLight;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor  = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, textColor),
      body: _isLoading
          ? _loadingView(textColor)
          : _errorMessage != null
              ? _errorView(textColor, subColor, card)
              : _mainBody(isDark, textColor, subColor, card, ring),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'কিবলা কম্পাস',
        style: GoogleFonts.hindSiliguri(
          fontSize: 20, fontWeight: FontWeight.w700, color: textColor,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: _QColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.my_location_rounded, color: _QColors.teal, size: 20),
            onPressed: _initQibla,
            tooltip: 'রিফ্রেশ',
          ),
        ),
      ],
    );
  }

  // ── Loading ──────────────────────────────────────────────
  Widget _loadingView(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _rotateCtrl.value * 2 * math.pi,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _QColors.teal, width: 3),
                ),
                child: const Icon(Icons.explore_rounded, color: _QColors.teal, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('অবস্থান খুঁজছি...', style: GoogleFonts.hindSiliguri(fontSize: 16, color: textColor)),
          const SizedBox(height: 6),
          Text('একটু অপেক্ষা করুন', style: GoogleFonts.hindSiliguri(fontSize: 13, color: _QColors.teal)),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────
  Widget _errorView(Color textColor, Color subColor, Color card) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08), shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 40, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              Text(_errorMessage!, style: GoogleFonts.hindSiliguri(fontSize: 15, color: textColor, height: 1.6), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _initQibla,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('আবার চেষ্টা করুন', style: GoogleFonts.hindSiliguri(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _QColors.teal, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: openAppSettings,
                child: Text('সেটিংস খুলুন', style: GoogleFonts.hindSiliguri(fontSize: 14, color: _QColors.teal, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main body ────────────────────────────────────────────
  Widget _mainBody(bool isDark, Color textColor, Color subColor, Color card, Color ring) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          children: [
            _compassSection(isDark, textColor, subColor, card, ring),
            const SizedBox(height: 24),
            _infoSection(isDark, textColor, subColor, card),
            const SizedBox(height: 16),
            _hintCard(textColor, subColor, card),
          ],
        ),
      ),
    );
  }

  // ── Compass section ──────────────────────────────────────
  Widget _compassSection(bool isDark, Color textColor, Color subColor, Color card, Color ring) {
    final needleAngle = _needleAngle;
    final size = MediaQuery.of(context).size.width - 40;
    final compassSize = size.clamp(260.0, 340.0);

    return Column(
      children: [
        SizedBox(
          width: compassSize,
          height: compassSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Outermost shadow ring ──
              Container(
                width: compassSize,
                height: compassSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _QColors.teal.withValues(alpha: isDark ? 0.25 : 0.15),
                      blurRadius: 32, spreadRadius: 4,
                    ),
                  ],
                ),
              ),

              // ── Outer ring (tick marks) ──
              Container(
                width: compassSize,
                height: compassSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ring,
                  border: Border.all(color: _QColors.teal.withValues(alpha: 0.35), width: 2),
                ),
                child: CustomPaint(
                  painter: _CompassRingPainter(
                    primaryColor: _QColors.teal,
                    secondaryColor: _QColors.teal.withValues(alpha: 0.3),
                  ),
                ),
              ),

              // ── Inner compass disc (rotates with heading) ──
              Transform.rotate(
                angle: _currentHeading != null ? _r(-_currentHeading!) : 0,
                child: Container(
                  width: compassSize * 0.72,
                  height: compassSize * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _cardinalLabel('উ.',  0,   _QColors.teal,     compassSize * 0.72, 22, FontWeight.w900),
                      _cardinalLabel('পূ.', 90,  textColor,          compassSize * 0.72, 17, FontWeight.w700),
                      _cardinalLabel('দ.',  180, textColor,          compassSize * 0.72, 17, FontWeight.w700),
                      _cardinalLabel('প.',  270, textColor,          compassSize * 0.72, 17, FontWeight.w700),
                    ],
                  ),
                ),
              ),

              // ── Qibla needle (always points to Qibla) ──
              if (needleAngle != null)
                Transform.rotate(
                  angle: _r(needleAngle),
                  child: SizedBox(
                    width: compassSize * 0.72,
                    height: compassSize * 0.72,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _aligned ? _pulseAnim.value : 1.0,
                            child: _kaabaIcon(compassSize * 0.18),
                          ),
                        ),
                        // Needle shaft
                        Container(
                          width: 3,
                          height: compassSize * 0.14,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _aligned ? _QColors.gold : _QColors.teal,
                                (_aligned ? _QColors.gold : _QColors.teal).withValues(alpha: 0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Center hub ──
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _QColors.teal,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: _QColors.teal.withValues(alpha: 0.5), blurRadius: 8)],
                ),
              ),

              // ── No compass data ──
              if (_currentHeading == null)
                Container(
                  width: compassSize * 0.35,
                  height: compassSize * 0.35,
                  decoration: BoxDecoration(
                    color: card.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sensors_rounded, color: _QColors.teal, size: 28),
                      const SizedBox(height: 4),
                      Text('লোড হচ্ছে', style: GoogleFonts.hindSiliguri(fontSize: 11, color: _QColors.teal)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kaabaIcon(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _aligned ? _QColors.gold : _QColors.teal,
        boxShadow: [
          BoxShadow(
            color: (_aligned ? _QColors.gold : _QColors.teal).withValues(alpha: _aligned ? 0.6 : 0.35),
            blurRadius: _aligned ? 24 : 10,
            spreadRadius: _aligned ? 4 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🕋',
          style: TextStyle(fontSize: size * 0.52),
        ),
      ),
    );
  }

  Widget _cardinalLabel(String label, double angle, Color color, double parentSize, double fontSize, FontWeight weight) {
    return Transform.rotate(
      angle: _r(angle),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: parentSize * 0.06),
          child: Transform.rotate(
            angle: _r(-angle),
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(fontSize: fontSize, fontWeight: weight, color: color),
            ),
          ),
        ),
      ),
    );
  }

  // ── Info section ─────────────────────────────────────────
  Widget _infoSection(bool isDark, Color textColor, Color subColor, Color card) {
    final qibla = _qiblaDirection;
    final dist  = _distanceKm;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // City / coords
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_rounded, color: _QColors.teal, size: 18),
              const SizedBox(width: 6),
              Text(
                '$_cityName,  $_countryName',
                style: GoogleFonts.hindSiliguri(fontSize: 14, color: subColor),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Distance
          if (dist != null)
            Text(
              'কাবা থেকে দূরত্বঃ ${_toBanglaNum(dist.toStringAsFixed(0))} কিঃমিঃ',
              style: GoogleFonts.hindSiliguri(fontSize: 14, color: subColor),
            ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Qibla degree — big prominent text
          if (qibla != null)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.hindSiliguri(color: textColor),
                children: [
                  TextSpan(
                    text: 'উত্তর দিক থেকে কিবলার অভিমুখঃ ',
                    style: GoogleFonts.hindSiliguri(fontSize: 14, color: subColor),
                  ),
                  TextSpan(
                    text: '${_toBanglaNum(qibla.toStringAsFixed(0))}°',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 28, fontWeight: FontWeight.w900, color: _QColors.teal,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Aligned status chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _aligned
                  ? _QColors.teal.withValues(alpha: 0.12)
                  : _QColors.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _aligned ? _QColors.teal : _QColors.teal.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _aligned ? Icons.check_circle_rounded : Icons.rotate_right_rounded,
                  color: _QColors.teal, size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _aligned ? 'আলহামদুলিল্লাহ! কিবলামুখী' : 'ফোনটি ঘুরিয়ে কিবলা খুঁজুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: _aligned ? FontWeight.w700 : FontWeight.w500,
                    color: _QColors.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hint card ────────────────────────────────────────────
  Widget _hintCard(Color textColor, Color subColor, Color card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _QColors.teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _QColors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _QColors.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'বিঃদ্রঃ সঠিক দিক নির্দেশনার জন্য আপনার মোবাইল ফোনটি উপরে নিচে ডানে বামে ঘোরান।',
              style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Compass ring painter ─────────────────────────────────────
class _CompassRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  _CompassRingPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 4;

    for (int i = 0; i < 120; i++) {
      final angle   = _r(i * 3.0);
      final isMajor = i % 10 == 0;
      final isCard  = i % 30 == 0;
      final len     = isCard ? 14.0 : isMajor ? 9.0 : 5.0;
      final paint   = Paint()
        ..color       = isCard ? primaryColor : secondaryColor
        ..strokeWidth = isCard ? 2.5 : isMajor ? 1.5 : 1.0
        ..strokeCap   = StrokeCap.round;

      canvas.drawLine(
        Offset(cx + (r - len) * math.cos(angle), cy + (r - len) * math.sin(angle)),
        Offset(cx + r         * math.cos(angle), cy + r         * math.sin(angle)),
        paint,
      );
    }
  }

  double _r(double d) => d * math.pi / 180;

  @override
  bool shouldRepaint(_CompassRingPainter old) =>
      old.primaryColor != primaryColor || old.secondaryColor != secondaryColor;
}
