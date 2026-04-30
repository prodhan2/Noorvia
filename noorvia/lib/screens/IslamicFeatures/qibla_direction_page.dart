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

class QiblaDirectionPage extends StatefulWidget {
  const QiblaDirectionPage({super.key});

  @override
  State<QiblaDirectionPage> createState() => _QiblaDirectionPageState();
}

class _QiblaDirectionPageState extends State<QiblaDirectionPage>
    with SingleTickerProviderStateMixin {
  // Kaaba coordinates (Makkah)
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _currentHeading;
  double? _qiblaDirection;
  String? _locationName;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<CompassEvent>? _compassSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeQibla();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeQibla() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request location permission
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        setState(() {
          _errorMessage = 'লোকেশন পারমিশন প্রয়োজন।\nসেটিংস থেকে পারমিশন দিন।';
          _isLoading = false;
        });
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Calculate Qibla direction
      _qiblaDirection = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );

      // Show coordinates as location info
      _locationName =
          'অক্ষাংশ: ${position.latitude.toStringAsFixed(4)}°, '
          'দ্রাঘিমাংশ: ${position.longitude.toStringAsFixed(4)}°';

      // Start compass stream
      _compassSubscription?.cancel();
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (mounted && event.heading != null) {
          setState(() {
            _currentHeading = event.heading;
          });
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ত্রুটি হয়েছে।\nআবার চেষ্টা করুন।';
        _isLoading = false;
      });
    }
  }

  /// Calculates the bearing from [lat]/[lng] to the Kaaba in degrees (0–360).
  double _calculateQiblaDirection(double lat, double lng) {
    final latRad = _toRad(lat);
    final lngRad = _toRad(lng);
    final kaabaLatRad = _toRad(_kaabaLat);
    final kaabaLngRad = _toRad(_kaabaLng);

    final dLng = kaabaLngRad - lngRad;
    final y = math.sin(dLng) * math.cos(kaabaLatRad);
    final x = math.cos(latRad) * math.sin(kaabaLatRad) -
        math.sin(latRad) * math.cos(kaabaLatRad) * math.cos(dLng);
    final bearing = math.atan2(y, x);
    return (_toDeg(bearing) + 360) % 360;
  }

  double _toRad(double deg) => deg * math.pi / 180;
  double _toDeg(double rad) => rad * 180 / math.pi;

  /// Angle to rotate the needle so it points toward Qibla.
  double? get _needleAngle {
    if (_currentHeading == null || _qiblaDirection == null) return null;
    return (_qiblaDirection! - _currentHeading! + 360) % 360;
  }

  bool get _isAligned {
    final a = _needleAngle;
    return a != null && (a < 5 || a > 355);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'কিবলা নির্দেশক',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _initializeQibla,
            tooltip: 'রিফ্রেশ',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(textColor)
          : _errorMessage != null
              ? _buildErrorState(textColor, subColor, cardColor)
              : _buildCompassBody(isDark, textColor, subColor, cardColor),
    );
  }

  // ── Loading ──────────────────────────────────────────────
  Widget _buildLoadingState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'আপনার অবস্থান খুঁজছি...',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'একটু অপেক্ষা করুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: AppColors.lightSubText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────
  Widget _buildErrorState(Color textColor, Color subColor, Color cardColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  color: textColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _initializeQibla,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'আবার চেষ্টা করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: openAppSettings,
                child: Text(
                  'সেটিংস খুলুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main compass body ────────────────────────────────────
  Widget _buildCompassBody(
    bool isDark,
    Color textColor,
    Color subColor,
    Color cardColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            _buildLocationCard(textColor, subColor, cardColor),
            const SizedBox(height: 28),
            _buildCompassWidget(isDark, textColor, subColor, cardColor),
            const SizedBox(height: 28),
            _buildStatusBanner(textColor, subColor, cardColor),
            const SizedBox(height: 20),
            _buildInfoCard(textColor, subColor, cardColor),
          ],
        ),
      ),
    );
  }

  // ── Location info card ───────────────────────────────────
  Widget _buildLocationCard(Color textColor, Color subColor, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _locationName ?? '',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'কিবলার দিক: ${_qiblaDirection?.toStringAsFixed(1)}° উত্তর থেকে',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Compass widget ───────────────────────────────────────
  Widget _buildCompassWidget(
    bool isDark,
    Color textColor,
    Color subColor,
    Color cardColor,
  ) {
    final needleAngle = _needleAngle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🕋  কাবা শরীফের দিক',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer decorative ring
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                ),

                // Compass rose (rotates with device heading)
                if (_currentHeading != null)
                  Transform.rotate(
                    angle: _toRad(-_currentHeading!),
                    child: _buildCompassRose(textColor, subColor),
                  )
                else
                  _buildCompassRose(textColor, subColor),

                // Tick marks ring
                _buildTickMarks(),

                // Qibla needle (always points to Qibla)
                if (needleAngle != null)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Transform.rotate(
                      angle: _toRad(needleAngle),
                      child: _buildQiblaNeedle(),
                    ),
                  ),

                // Center hub
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),

                // No compass data overlay
                if (_currentHeading == null)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sensors, color: subColor, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'কম্পাস\nলোড হচ্ছে',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: subColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_currentHeading != null) ...[
            const SizedBox(height: 16),
            Text(
              'বর্তমান দিক: ${_currentHeading!.toStringAsFixed(0)}°',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: subColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompassRose(Color textColor, Color subColor) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // N
          _cardinalLabel('উ', 0, AppColors.primary, 20, FontWeight.w900),
          // E
          _cardinalLabel('পূ', 90, subColor, 16, FontWeight.w600),
          // S
          _cardinalLabel('দ', 180, subColor, 16, FontWeight.w600),
          // W
          _cardinalLabel('প', 270, subColor, 16, FontWeight.w600),
          // NE, SE, SW, NW
          _cardinalLabel('উপূ', 45, subColor, 11, FontWeight.w400),
          _cardinalLabel('দপূ', 135, subColor, 11, FontWeight.w400),
          _cardinalLabel('দপ', 225, subColor, 11, FontWeight.w400),
          _cardinalLabel('উপ', 315, subColor, 11, FontWeight.w400),
        ],
      ),
    );
  }

  Widget _cardinalLabel(
    String label,
    double angle,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    return Transform.rotate(
      angle: _toRad(angle),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Transform.rotate(
            angle: _toRad(-angle),
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: fontSize,
                fontWeight: weight,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTickMarks() {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _TickMarkPainter(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildQiblaNeedle() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Column(
        children: [
          // Needle tip — Kaaba icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _isAligned ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isAligned ? AppColors.primary : AppColors.primaryLight,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: _isAligned ? 0.5 : 0.25,
                      ),
                      blurRadius: _isAligned ? 20 : 8,
                      spreadRadius: _isAligned ? 4 : 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          // Needle shaft
          Container(
            width: 3,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status banner ────────────────────────────────────────
  Widget _buildStatusBanner(Color textColor, Color subColor, Color cardColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _isAligned
            ? AppColors.primary.withValues(alpha: 0.1)
            : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAligned ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isAligned
                ? Icons.check_circle_rounded
                : Icons.rotate_right_rounded,
            color: _isAligned ? AppColors.primary : subColor,
            size: 26,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _isAligned
                  ? '✨ আলহামদুলিল্লাহ! কিবলার দিকে আছেন'
                  : 'ফোনটি ঘুরিয়ে কিবলার দিক খুঁজুন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight:
                    _isAligned ? FontWeight.w700 : FontWeight.w500,
                color: _isAligned ? AppColors.primary : textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info / instructions card ─────────────────────────────
  Widget _buildInfoCard(Color textColor, Color subColor, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'কীভাবে ব্যবহার করবেন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _instruction('১', 'ফোনটি সমতল রাখুন', subColor),
          _instruction(
              '২', 'ধীরে ধীরে ঘুরান যতক্ষণ মসজিদ আইকন উপরে না আসে', subColor),
          _instruction(
              '৩', 'সবুজ বৃত্ত দেখলে বুঝবেন কিবলার দিকে আছেন', subColor),
          _instruction('৪', 'ধাতব বস্তু থেকে দূরে রাখুন', subColor),
        ],
      ),
    );
  }

  Widget _instruction(String num, String text, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: subColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom tick-mark painter ─────────────────────────────────
class _TickMarkPainter extends CustomPainter {
  final Color color;
  _TickMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 72; i++) {
      final angle = _toRad(i * 5.0);
      final isMajor = i % 9 == 0;
      final tickLen = isMajor ? 12.0 : 6.0;
      paint.strokeWidth = isMajor ? 2.0 : 1.0;

      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  double _toRad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(_TickMarkPainter old) => old.color != color;
}
