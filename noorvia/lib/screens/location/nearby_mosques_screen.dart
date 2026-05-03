import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/mosque.dart';
import '../../core/services/mosque_service.dart';

/// Screen to display nearby mosques based on user's current location
class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  final MosqueService _mosqueService = MosqueService();
  List<Mosque> _mosques = [];
  bool _isLoading = false;
  bool _isRefreshingInBackground = false;
  String? _errorMessage;
  int _searchRadius = 5000; // Default 5 km
  bool _autoSilentMode = false; // Auto silent/vibration when entering mosque
  String _silentModeType = 'vibration'; // 'vibration' or 'silent'

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNearbyMosques();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchRadius = prefs.getInt('mosque_search_radius') ?? 5000;
      _autoSilentMode = prefs.getBool('mosque_auto_silent') ?? false;
      _silentModeType = prefs.getString('mosque_silent_type') ?? 'vibration';
    });
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mosque_search_radius', _searchRadius);
    await prefs.setBool('mosque_auto_silent', _autoSilentMode);
    await prefs.setString('mosque_silent_type', _silentModeType);
  }

  /// Load nearby mosques with caching support
  Future<void> _loadNearbyMosques() async {
    // Only show loading on first load or when no cached data
    if (_mosques.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Get current location
      final position = await _mosqueService.getCurrentLocation();
      
      // Get mosques with cache (returns cached data immediately if available)
      final mosques = await _mosqueService.getNearbyMosquesWithCache(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInMeters: _searchRadius,
        onBackgroundRefresh: (refreshedMosques) {
          // This callback is called when background refresh completes
          if (mounted) {
            setState(() {
              _mosques = refreshedMosques;
              _isRefreshingInBackground = false;
            });
          }
        },
      );
      
      setState(() {
        _mosques = mosques;
        _isLoading = false;
        _isRefreshingInBackground = mosques.isNotEmpty; // If we got cached data, refresh is happening
      });

      if (mosques.isEmpty) {
        setState(() {
          _errorMessage = 'আশেপাশে কোনো মসজিদ পাওয়া যায়নি। অনুসন্ধান পরিসীমা বাড়ান।';
          // No mosques found nearby. Increase search radius.
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshingInBackground = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Open mosque location in Google Maps
  Future<void> _openInGoogleMaps(Mosque mosque) async {
    final url = Uri.parse(mosque.getGoogleMapsUrl());
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('গুগল ম্যাপস খুলতে ব্যর্থ'), // Failed to open Google Maps
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show radius selection dialog
  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'অনুসন্ধান পরিসীমা নির্বাচন করুন',
          style: TextStyle(fontFamily: 'Kalpurush'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadiusOption('১ কিলোমিটার', 1000),
            _buildRadiusOption('৩ কিলোমিটার', 3000),
            _buildRadiusOption('৫ কিলোমিটার', 5000),
            _buildRadiusOption('১০ কিলোমিটার', 10000),
            _buildRadiusOption('২০ কিলোমিটার', 20000),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusOption(String label, int radius) {
    return RadioListTile<int>(
      title: Text(label, style: const TextStyle(fontFamily: 'Kalpurush')),
      value: radius,
      groupValue: _searchRadius,
      onChanged: (value) {
        Navigator.pop(context);
        setState(() {
          _searchRadius = value!;
        });
        _loadNearbyMosques();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'আমার মসজিদ',
              style: TextStyle(
                fontFamily: 'Kalpurush',
                fontWeight: FontWeight.bold,
              ),
            ),
            // Show small indicator when refreshing in background
            if (_isRefreshingInBackground) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'অনুসন্ধান পরিসীমা',
            onPressed: _showRadiusDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'রিফ্রেশ করুন',
            onPressed: _loadNearbyMosques,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_mosques.isEmpty) {
      return _buildEmptyView();
    }

    return _buildMosqueList();
  }

  /// Loading indicator with message
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'আশেপাশের মসজিদ খুঁজছি...',
            style: TextStyle(
              fontFamily: 'Kalpurush',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'অনুগ্রহ করে অপেক্ষা করুন',
            style: TextStyle(
              fontFamily: 'Kalpurush',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Error view with retry button
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Kalpurush',
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNearbyMosques,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'আবার চেষ্টা করুন',
                style: TextStyle(fontFamily: 'Kalpurush'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state view
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mosque_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'কোনো মসজিদ পাওয়া যায়নি',
              style: TextStyle(
                fontFamily: 'Kalpurush',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার আশেপাশে কোনো মসজিদ খুঁজে পাওয়া যায়নি',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Kalpurush',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showRadiusDialog,
              icon: const Icon(Icons.tune),
              label: const Text(
                'অনুসন্ধান পরিসীমা বাড়ান',
                style: TextStyle(fontFamily: 'Kalpurush'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build mosque list with cards
  Widget _buildMosqueList() {
    return Column(
      children: [
        // Header with mosque count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            '${_mosques.length}টি মসজিদ পাওয়া গেছে',
            style: const TextStyle(
              fontFamily: 'Kalpurush',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Mosque list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mosques.length,
            itemBuilder: (context, index) {
              final mosque = _mosques[index];
              final isNearest = index == 0;
              return _buildMosqueCard(mosque, isNearest);
            },
          ),
        ),
      ],
    );
  }

  /// Build individual mosque card
  Widget _buildMosqueCard(Mosque mosque, bool isNearest) {
    return Card(
      elevation: isNearest ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNearest
            ? BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Container(
        decoration: isNearest
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nearest badge
              if (isNearest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'সবচেয়ে কাছের মসজিদ',
                        style: TextStyle(
                          fontFamily: 'Kalpurush',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isNearest) const SizedBox(height: 12),
              
              // Mosque name
              Row(
                children: [
                  Icon(
                    Icons.mosque,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mosque.name,
                      style: TextStyle(
                        fontFamily: 'Kalpurush',
                        fontSize: isNearest ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Distance
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mosque.getFormattedDistance(),
                    style: TextStyle(
                      fontFamily: 'Kalpurush',
                      fontSize: 15,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              // Address if available
              if (mosque.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.home,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mosque.address!,
                        style: TextStyle(
                          fontFamily: 'Kalpurush',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInGoogleMaps(mosque),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text(
                        'দিকনির্দেশনা',
                        style: TextStyle(fontFamily: 'Kalpurush'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openInGoogleMaps(mosque),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text(
                        'ম্যাপে দেখুন',
                        style: TextStyle(fontFamily: 'Kalpurush'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
