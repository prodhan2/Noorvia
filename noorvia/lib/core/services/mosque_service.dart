import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosque.dart';

/// Service class to handle mosque-related operations
/// Fetches nearby mosques from OpenStreetMap Overpass API with caching
class MosqueService {
  // Multiple Overpass API endpoints for redundancy
  static const List<String> _overpassApiUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];
  
  static const String _cacheKey = 'cached_mosques';
  static const String _cacheLocationKey = 'cached_location';
  static const String _cacheRadiusKey = 'cached_radius';
  static const String _cacheTimeKey = 'cached_time';
  
  // Cache duration: 1 hour
  static const Duration _cacheDuration = Duration(hours: 1);
  
  /// Get user's current location with proper permission handling
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('লোকেশন সার্ভিস বন্ধ আছে। দয়া করে চালু করুন।'); // Location services are disabled
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('লোকেশন অনুমতি প্রত্যাখ্যান করা হয়েছে।'); // Location permission denied
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('লোকেশন অনুমতি স্থায়ীভাবে প্রত্যাখ্যান করা হয়েছে। সেটিংস থেকে অনুমতি দিন।'); 
      // Location permission permanently denied
    }

    // Get current position with high accuracy
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Fetch nearby mosques from OpenStreetMap Overpass API
  /// [latitude] - User's current latitude
  /// [longitude] - User's current longitude
  /// [radiusInMeters] - Search radius (default: 5000 meters = 5 km)
  Future<List<Mosque>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusInMeters = 5000,
  }) async {
    // Try multiple API endpoints
    Exception? lastError;
    
    for (int i = 0; i < _overpassApiUrls.length; i++) {
      final apiUrl = _overpassApiUrls[i];
      
      try {
        print('🌐 Trying Overpass API endpoint ${i + 1}/${_overpassApiUrls.length}: $apiUrl');
        
        return await _fetchFromEndpoint(
          apiUrl: apiUrl,
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: radiusInMeters,
        );
      } catch (e) {
        print('❌ Endpoint ${i + 1} failed: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        
        // If not the last endpoint, continue to next one
        if (i < _overpassApiUrls.length - 1) {
          print('⏭️ Trying next endpoint...');
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
      }
    }
    
    // All endpoints failed
    throw lastError ?? Exception('সব সার্ভার থেকে ডেটা লোড করতে ব্যর্থ হয়েছে।');
  }
  
  /// Fetch from a specific Overpass API endpoint
  Future<List<Mosque>> _fetchFromEndpoint({
    required String apiUrl,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
  }) async {
    try {
      // Build Overpass QL query
      // This query searches for places of worship that are mosques
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusInMeters,$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusInMeters,$latitude,$longitude);
);
out center;
''';

      // Make HTTP POST request to Overpass API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: query,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('সার্ভার থেকে সাড়া পাওয়া যায়নি। আবার চেষ্টা করুন।'); // Server timeout
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        if (elements.isEmpty) {
          return [];
        }

        // Convert JSON elements to Mosque objects
        List<Mosque> mosques = [];
        for (var element in elements) {
          try {
            // Handle different element types (node, way, relation)
            Map<String, dynamic> mosqueData = {};
            
            if (element['type'] == 'node') {
              mosqueData = element;
            } else if (element['type'] == 'way' || element['type'] == 'relation') {
              // For ways and relations, use center coordinates
              if (element['center'] != null) {
                mosqueData = {
                  ...element,
                  'lat': element['center']['lat'],
                  'lon': element['center']['lon'],
                };
              } else {
                continue; // Skip if no center coordinates
              }
            }

            final mosque = Mosque.fromJson(mosqueData, latitude, longitude);
            mosques.add(mosque);
          } catch (e) {
            // Skip invalid mosque data
            continue;
          }
        }

        // Sort mosques by distance (nearest first)
        mosques.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));

        print('✅ Found ${mosques.length} mosques from $apiUrl');
        return mosques;
      } else if (response.statusCode == 429) {
        throw Exception('সার্ভার ব্যস্ত আছে। কিছুক্ষণ পর আবার চেষ্টা করুন।');
      } else if (response.statusCode >= 500) {
        throw Exception('সার্ভার সমস্যা। অন্য সার্ভার চেষ্টা করা হচ্ছে...');
      } else {
        throw Exception('ডেটা লোড করতে ব্যর্থ। স্ট্যাটাস কোড: ${response.statusCode}'); 
        // Failed to load data
      }
    } on http.ClientException catch (e) {
      // Network connection error
      throw Exception('ইন্টারনেট সংযোগ নেই। দয়া করে আপনার সংযোগ পরীক্ষা করুন।');
    } on FormatException catch (e) {
      // JSON parsing error
      throw Exception('ডেটা প্রসেস করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception('ইন্টারনেট সংযোগ নেই। দয়া করে আপনার সংযোগ পরীক্ষা করুন।'); 
        // No internet connection
      }
      rethrow;
    }
  }

  /// Get nearby mosques with automatic location detection
  Future<List<Mosque>> getNearbyMosques({int radiusInMeters = 5000}) async {
    final position = await getCurrentLocation();
    return await fetchNearbyMosques(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInMeters: radiusInMeters,
    );
  }

  /// Get cached mosques if available and valid
  Future<List<Mosque>?> _getCachedMosques(
    double latitude,
    double longitude,
    int radiusInMeters,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists
      final cachedData = prefs.getString(_cacheKey);
      final cachedLat = prefs.getDouble(_cacheLocationKey + '_lat');
      final cachedLon = prefs.getDouble(_cacheLocationKey + '_lon');
      final cachedRadius = prefs.getInt(_cacheRadiusKey);
      final cachedTimeStr = prefs.getString(_cacheTimeKey);
      
      if (cachedData == null || cachedLat == null || cachedLon == null || 
          cachedRadius == null || cachedTimeStr == null) {
        return null;
      }
      
      // Check if cache is still valid (within 1 hour)
      final cachedTime = DateTime.parse(cachedTimeStr);
      if (DateTime.now().difference(cachedTime) > _cacheDuration) {
        return null; // Cache expired
      }
      
      // Check if location and radius are similar
      final distance = Geolocator.distanceBetween(
        cachedLat, cachedLon, latitude, longitude,
      );
      
      // If user moved more than 500 meters or radius changed, invalidate cache
      if (distance > 500 || cachedRadius != radiusInMeters) {
        return null;
      }
      
      // Parse cached data
      final List<dynamic> jsonList = json.decode(cachedData);
      final mosques = jsonList.map((json) {
        return Mosque.fromJson(json, latitude, longitude);
      }).toList();
      
      return mosques;
    } catch (e) {
      // If any error in reading cache, return null
      return null;
    }
  }

  /// Save mosques to cache
  Future<void> _saveMosquesToCache(
    List<Mosque> mosques,
    double latitude,
    double longitude,
    int radiusInMeters,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert mosques to JSON
      final jsonList = mosques.map((mosque) {
        return {
          'lat': mosque.latitude,
          'lon': mosque.longitude,
          'tags': {
            'name': mosque.name,
            if (mosque.address != null) 'addr:full': mosque.address,
          },
        };
      }).toList();
      
      // Save to cache
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setDouble(_cacheLocationKey + '_lat', latitude);
      await prefs.setDouble(_cacheLocationKey + '_lon', longitude);
      await prefs.setInt(_cacheRadiusKey, radiusInMeters);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore cache save errors
    }
  }

  /// Get nearby mosques with caching support
  /// Returns cached data immediately if available, then refreshes in background
  Future<List<Mosque>> getNearbyMosquesWithCache({
    required double latitude,
    required double longitude,
    int radiusInMeters = 5000,
    Function(List<Mosque>)? onBackgroundRefresh,
  }) async {
    // Try to get cached data first
    final cachedMosques = await _getCachedMosques(
      latitude, longitude, radiusInMeters,
    );
    
    // If cache exists, return it immediately
    if (cachedMosques != null && cachedMosques.isNotEmpty) {
      // Refresh in background (don't await)
      _refreshInBackground(
        latitude, longitude, radiusInMeters, onBackgroundRefresh,
      );
      
      return cachedMosques;
    }
    
    // No cache, fetch fresh data
    final mosques = await fetchNearbyMosques(
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radiusInMeters,
    );
    
    // Save to cache
    await _saveMosquesToCache(mosques, latitude, longitude, radiusInMeters);
    
    return mosques;
  }

  /// Refresh data in background without blocking UI
  Future<void> _refreshInBackground(
    double latitude,
    double longitude,
    int radiusInMeters,
    Function(List<Mosque>)? onBackgroundRefresh,
  ) async {
    try {
      // Fetch fresh data
      final mosques = await fetchNearbyMosques(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      
      // Save to cache
      await _saveMosquesToCache(mosques, latitude, longitude, radiusInMeters);
      
      // Notify callback if provided
      if (onBackgroundRefresh != null) {
        onBackgroundRefresh(mosques);
      }
    } catch (e) {
      // Silently fail background refresh
      // User will continue to see cached data
    }
  }
}
