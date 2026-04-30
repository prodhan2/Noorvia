import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/providers/prayer_provider.dart';

const _kPrimary = Color(0xFF1B6B3A);

// ═══════════════════════════════════════════════════════════════
// Show location picker bottom sheet
// ═══════════════════════════════════════════════════════════════
void showLocationPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<PrayerProvider>(),
      child: const _LocationPickerSheet(),
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  bool _isTracking = false;
  bool _isLocating = false;
  String _detectedCity = '';
  String _detectedCountry = '';
  String _statusMessage = 'GPS দিয়ে আপনার অবস্থান নির্ণয় করুন';

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    // Auto-start location detection when sheet opens
    _detectLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ── One-time location detect ──────────────────────────────
  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _statusMessage = 'অবস্থান খোঁজা হচ্ছে...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _isLocating = false;
          _statusMessage = 'অবস্থানের অনুমতি দেওয়া হয়নি';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() {
        _isLocating = false;
        _statusMessage = 'অবস্থান পাওয়া যায়নি, আবার চেষ্টা করুন';
      });
    }
  }

  // ── Start realtime tracking ───────────────────────────────
  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() => _statusMessage = 'অবস্থানের অনুমতি দেওয়া হয়নি');
      return;
    }

    setState(() {
      _isTracking = true;
      _statusMessage = 'রিয়েলটাইম ট্র্যাকিং চলছে...';
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // update every 100 meters
      ),
    ).listen(
      (pos) async {
        await _reverseGeocode(pos.latitude, pos.longitude);
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isTracking = false;
            _statusMessage = 'ট্র্যাকিং বন্ধ হয়ে গেছে';
          });
        }
      },
    );
  }

  // ── Stop tracking ─────────────────────────────────────────
  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _isTracking = false;
      _statusMessage = 'ট্র্যাকিং বন্ধ করা হয়েছে';
    });
  }

  // ── Reverse geocode lat/lon → city name ───────────────────
  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ??
            p.subAdministrativeArea ??
            p.administrativeArea ??
            '';
        final country = p.isoCountryCode ?? 'BD';

        if (mounted) {
          setState(() {
            _detectedCity = city;
            _detectedCountry = country;
            _isLocating = false;
            _statusMessage = _isTracking
                ? 'রিয়েলটাইম ট্র্যাকিং চলছে...'
                : 'অবস্থান পাওয়া গেছে';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _statusMessage = 'শহরের নাম পাওয়া যায়নি';
        });
      }
    }
  }

  // ── Apply detected location to provider ──────────────────
  void _applyLocation() {
    if (_detectedCity.isEmpty) return;
    final prayer = context.read<PrayerProvider>();
    Navigator.pop(context);
    prayer.requestLocationAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: _kPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'অবস্থান',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: subColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Main location card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  // GPS icon + status
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: _isLocating
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isTracking
                                    ? Icons.gps_fixed
                                    : Icons.my_location,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detectedCity.isNotEmpty
                                  ? _detectedCity
                                  : 'অবস্থান শনাক্ত হয়নি',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _detectedCity.isNotEmpty
                                    ? _kPrimary
                                    : subColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusMessage,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tracking indicator
                      if (_isTracking)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Current prayer city from provider
                  if (prayer.cityDisplayName.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mosque,
                              color: _kPrimary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'নামাজের সময় চলছে: ${prayer.cityDisplayName}',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13,
                              color: _kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Detect once
                Expanded(
                  child: _ActionButton(
                    icon: Icons.location_searching,
                    label: 'অবস্থান নিন',
                    color: _kPrimary,
                    onTap: _isLocating ? null : _detectLocation,
                  ),
                ),
                const SizedBox(width: 10),
                // Toggle tracking
                Expanded(
                  child: _ActionButton(
                    icon: _isTracking ? Icons.gps_off : Icons.gps_fixed,
                    label: _isTracking ? 'ট্র্যাকিং বন্ধ' : 'লাইভ ট্র্যাক',
                    color: _isTracking ? Colors.red : Colors.blue,
                    onTap: _isTracking ? _stopTracking : _startTracking,
                  ),
                ),
                const SizedBox(width: 10),
                // Apply
                Expanded(
                  child: _ActionButton(
                    icon: Icons.check_circle,
                    label: 'প্রয়োগ করুন',
                    color: _detectedCity.isNotEmpty ? _kPrimary : Colors.grey,
                    onTap: _detectedCity.isNotEmpty ? _applyLocation : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'GPS স্বয়ংক্রিয়ভাবে আপনার অবস্থান শনাক্ত করে নামাজের সঠিক সময় দেখাবে।',
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: subColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable action button ────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
