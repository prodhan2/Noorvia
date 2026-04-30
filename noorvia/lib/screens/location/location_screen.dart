import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/prayer_provider.dart';

// ─────────────────────────────────────────────────────────────
// City data
// ─────────────────────────────────────────────────────────────
class _CityData {
  final String name;
  final String bangla;
  final String country;
  final double lat;
  final double lon;
  const _CityData(this.name, this.bangla, this.country, this.lat, this.lon);
}

const List<_CityData> _kCities = [
  _CityData('Dhaka',        'ঢাকা',         'BD', 23.8103,  90.4125),
  _CityData('Chittagong',   'চট্টগ্রাম',    'BD', 22.3569,  91.7832),
  _CityData('Sylhet',       'সিলেট',        'BD', 24.8949,  91.8687),
  _CityData('Rajshahi',     'রাজশাহী',      'BD', 24.3745,  88.6042),
  _CityData('Khulna',       'খুলনা',        'BD', 22.8456,  89.5403),
  _CityData('Barishal',     'বরিশাল',       'BD', 22.7010,  90.3535),
  _CityData('Rangpur',      'রংপুর',        'BD', 25.7439,  89.2752),
  _CityData('Mymensingh',   'ময়মনসিংহ',    'BD', 24.7471,  90.4203),
  _CityData('Comilla',      'কুমিল্লা',     'BD', 23.4607,  91.1809),
  _CityData('Narayanganj',  'নারায়ণগঞ্জ',  'BD', 23.6238,  90.4996),
  _CityData('Gazipur',      'গাজীপুর',      'BD', 23.9999,  90.4203),
  _CityData('Bogra',        'বগুড়া',        'BD', 24.8465,  89.3773),
  _CityData('Dinajpur',     'দিনাজপুর',     'BD', 25.6279,  88.6338),
  _CityData('Jessore',      'যশোর',         'BD', 23.1664,  89.2191),
  _CityData('Mecca',        'মক্কা',        'SA', 21.3891,  39.8579),
  _CityData('Medina',       'মদিনা',        'SA', 24.5247,  39.5692),
  _CityData('Riyadh',       'রিয়াদ',        'SA', 24.7136,  46.6753),
  _CityData('Dubai',        'দুবাই',        'AE', 25.2048,  55.2708),
  _CityData('London',       'লন্ডন',        'GB', 51.5074,  -0.1278),
  _CityData('New York',     'নিউ ইয়র্ক',   'US', 40.7128, -74.0060),
  _CityData('Kuala Lumpur', 'কুয়ালালামপুর', 'MY',  3.1390, 101.6869),
  _CityData('Jakarta',      'জাকার্তা',     'ID', -6.2088, 106.8456),
  _CityData('Istanbul',     'ইস্তাম্বুল',   'TR', 41.0082,  28.9784),
  _CityData('Cairo',        'কায়রো',        'EG', 30.0444,  31.2357),
  _CityData('Karachi',      'করাচি',        'PK', 24.8607,  67.0011),
  _CityData('Lahore',       'লাহোর',        'PK', 31.5204,  74.3587),
  _CityData('Delhi',        'দিল্লি',       'IN', 28.6139,  77.2090),
  _CityData('Kolkata',      'কলকাতা',       'IN', 22.5726,  88.3639),
];

// ─────────────────────────────────────────────────────────────
// LocationScreen
// ─────────────────────────────────────────────────────────────
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {

  // GPS state
  bool _gpsLoading = false;
  bool _gpsSuccess = false;
  String _gpsCity = '';
  String _gpsCountry = '';
  double? _gpsLat;
  double? _gpsLon;

  // Manual selection
  _CityData? _selectedCity;
  bool _useGps = false;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<_CityData> _searchResults = List.from(_kCities);
  bool _showSearch = false;

  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);

    // Load saved location
    _loadSaved();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prayer = context.read<PrayerProvider>();
    if (prayer.cityName.isNotEmpty) {
      final match = _kCities.where(
        (c) => c.name.toLowerCase() == prayer.cityName.toLowerCase()).toList();
      if (match.isNotEmpty) {
        setState(() { _selectedCity = match.first; _useGps = false; });
      }
    }
    if (prayer.latitude != null && prayer.longitude != null) {
      setState(() {
        _gpsLat = prayer.latitude;
        _gpsLon = prayer.longitude;
        _gpsCity = prayer.cityDisplayName;
        _gpsSuccess = true;
      });
    }
  }

  // ── GPS detect ────────────────────────────────────────────
  Future<void> _detectGps() async {
    if (kIsWeb) {
      _showMsg('Web এ GPS সরাসরি কাজ করে না। শহর ম্যানুয়ালি বেছে নিন।');
      return;
    }
    setState(() { _gpsLoading = true; _gpsSuccess = false; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        setState(() => _gpsLoading = false);
        _showMsg('অবস্থানের অনুমতি দেওয়া হয়নি');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      String city = '';
      String country = 'BD';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
        country = p.isoCountryCode ?? 'BD';
      }
      setState(() {
        _gpsLat = pos.latitude;
        _gpsLon = pos.longitude;
        _gpsCity = city;
        _gpsCountry = country;
        _gpsLoading = false;
        _gpsSuccess = true;
        _useGps = true;
        _selectedCity = null;
      });
      _checkCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _gpsLoading = false);
      _showMsg('অবস্থান পাওয়া যায়নি');
    }
  }

  // ── Search ────────────────────────────────────────────────
  void _onSearch(String q) {
    setState(() {
      if (q.isEmpty) {
        _searchResults = List.from(_kCities);
      } else {
        _searchResults = _kCities.where((c) =>
          c.bangla.contains(q) ||
          c.name.toLowerCase().contains(q.toLowerCase()),
        ).toList();
      }
    });
  }

  // ── Save ──────────────────────────────────────────────────
  Future<void> _save() async {
    final prayer = context.read<PrayerProvider>();
    if (_useGps && _gpsLat != null) {
      await prayer.requestLocationAndFetch();
      if (mounted) Navigator.pop(context);
      return;
    }
    if (_selectedCity != null) {
      await prayer.selectCity(_selectedCity!.name, _selectedCity!.country);
      if (mounted) Navigator.pop(context);
      return;
    }
    _showMsg('অনুগ্রহ করে একটি অবস্থান নির্বাচন করুন');
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.hindSiliguri()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Map preview URL (OpenStreetMap — no API key needed) ──
  // Used by _MapPreview widget directly

  bool get _canSave => _useGps && _gpsSuccess || _selectedCity != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'অবস্থান',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'অবস্থান নির্ধারণ করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'আমরা নামাজ এবং রোজার সঠিক সময় গণনার জন্য আপনার শহর ব্যবহার করব',
                    style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Map preview
                  _MapPreview(
                    lat: _gpsLat ?? _selectedCity?.lat ?? 23.8103,
                    lon: _gpsLon ?? _selectedCity?.lon ?? 90.4125,
                    cityName: _useGps ? _gpsCity : (_selectedCity?.bangla ?? 'ঢাকা'),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // GPS option
                  _OptionCard(
                    icon: Icons.gps_fixed_rounded,
                    title: 'GPS লোকেশন সেট করুন',
                    subtitle: _gpsSuccess
                        ? '$_gpsCity, $_gpsCountry'
                        : 'স্বয়ংক্রিয়ভাবে অবস্থান নির্ণয়',
                    selected: _useGps && _gpsSuccess,
                    loading: _gpsLoading,
                    checkAnim: _checkAnim,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: _gpsLoading ? null : _detectGps,
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('অথবা',
                            style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor)),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
                      ],
                    ),
                  ),

                  // Manual city option
                  _OptionCard(
                    icon: Icons.language_rounded,
                    title: 'শহর ম্যানুয়ালি বেছে নিন',
                    subtitle: _selectedCity != null && !_useGps
                        ? _selectedCity!.bangla
                        : 'শহর নির্বাচন করুন',
                    selected: _selectedCity != null && !_useGps,
                    loading: false,
                    checkAnim: _checkAnim,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    showArrow: true,
                    onTap: () => setState(() => _showSearch = !_showSearch),
                  ),

                  // City search panel
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: _showSearch
                        ? _CitySearchPanel(
                            searchCtrl: _searchCtrl,
                            results: _searchResults,
                            selected: _selectedCity,
                            cardBg: cardBg,
                            textColor: textColor,
                            subColor: subColor,
                            isDark: isDark,
                            onSearch: _onSearch,
                            onSelect: (city) {
                              setState(() {
                                _selectedCity = city;
                                _useGps = false;
                                _showSearch = false;
                                _searchCtrl.clear();
                                _searchResults = List.from(_kCities);
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? AppColors.primary : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _canSave ? 4 : 0,
                  ),
                  child: Text(
                    'সংরক্ষণ করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Map Preview Widget
// ─────────────────────────────────────────────────────────────
class _MapPreview extends StatelessWidget {
  final double lat;
  final double lon;
  final String cityName;
  final bool isDark;

  const _MapPreview({
    required this.lat, required this.lon,
    required this.cityName, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // OpenStreetMap tile (no API key needed)
            Image.network(
              'https://staticmap.openstreetmap.de/staticmap.php'
              '?center=$lat,$lon&zoom=12&size=600x200'
              '&markers=$lat,$lon,red-pushpin',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8F5E9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded,
                        size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(cityName,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16, color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8F5E9),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                  ),
                );
              },
            ),
            // Location pin overlay
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(cityName,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12, color: Colors.white,
                            fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Option Card
// ─────────────────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool loading;
  final Animation<double> checkAnim;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  final bool showArrow;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.loading,
    required this.checkAnim,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primary),
                    )
                  : Icon(icon,
                      color: selected ? AppColors.primary : Colors.grey,
                      size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12, color: subColor)),
                ],
              ),
            ),
            if (selected && !showArrow)
              ScaleTransition(
                scale: checkAnim,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18),
                ),
              )
            else if (showArrow)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  color: selected ? Colors.white : Colors.grey,
                  size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// City Search Panel
// ─────────────────────────────────────────────────────────────
class _CitySearchPanel extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<_CityData> results;
  final _CityData? selected;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  final bool isDark;
  final ValueChanged<String> onSearch;
  final ValueChanged<_CityData> onSelect;

  const _CitySearchPanel({
    required this.searchCtrl,
    required this.results,
    required this.selected,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: GoogleFonts.hindSiliguri(color: textColor),
              decoration: InputDecoration(
                hintText: 'শহর খুঁজুন...',
                hintStyle: GoogleFonts.hindSiliguri(
                  color: subColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 20),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: subColor, size: 18),
                        onPressed: () { searchCtrl.clear(); onSearch(''); },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBg
                    : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // City list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[100]),
              itemBuilder: (_, i) {
                final city = results[i];
                final isSel = selected?.name == city.name;
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        city.bangla.substring(0, 1),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSel ? AppColors.primary : subColor),
                      ),
                    ),
                  ),
                  title: Text(
                    city.bangla,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.primary : textColor),
                  ),
                  subtitle: Text(
                    '${city.name}, ${city.country}',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11, color: subColor)),
                  trailing: isSel
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => onSelect(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
