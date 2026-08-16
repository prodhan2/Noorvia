import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../data/local/local_store.dart';
import '../models/mosque.dart';
import 'location_permission_service.dart';

/// Service class to handle mosque-related operations
/// Fetches nearby mosques from OpenStreetMap Overpass API with caching
class MosqueService {
  // Multiple Overpass API endpoints for redundancy
  static const List<String> _overpassApiUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];
  
  static const String _cacheNamespace = 'mosque_cache';
  static const String _cacheKey = 'nearby_mosques';
  
  // Cache duration: 1 hour
  static const Duration _cacheDuration = Duration(hours: 1);
  
  /// Get user's current location with proper permission handling
  Future<Position> getCurrentLocation() async {
    final permissionService = LocationPermissionService();
    
    // Verify permission is still valid
    final isGranted = await permissionService.verifyPermission();
    
    if (!isGranted) {
      if (permissionService.isPermissionDeniedForever()) {
        throw Exception('লোকেশন অনুমতি স্থায়ীভাবে প্রত্যাখ্যান করা হয়েছে। সেটিংস থেকে অনুমতি দিন।');
      } else {
        throw Exception('লোকেশন অনুমতি প্রত্যাখ্যান করা হয়েছে।');
      }
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('লোকেশন সার্ভিস বন্ধ আছে। দয়া করে চালু করুন।');
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
  node["place_of_worship"="musalla"](around:$radiusInMeters,$latitude,$longitude);
  way["place_of_worship"="musalla"](around:$radiusInMeters,$latitude,$longitude);
  relation["place_of_worship"="musalla"](around:$radiusInMeters,$latitude,$longitude);
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

        // Deduplicate union-query results and sort nearest first.
        final unique = <String, Mosque>{};
        for (final mosque in mosques) {
          unique[mosque.osmId] = mosque;
        }
        mosques = unique.values.toList()
          ..sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));

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

  /// Get cached mosques from the offline-first Isar store if available and valid.
  Future<List<Mosque>?> _getCachedMosques(
    double latitude,
    double longitude,
    int radiusInMeters,
  ) async {
    try {
      final cached = await LocalStore.instance.getJson(_cacheNamespace, _cacheKey);
      if (cached == null) return null;

      final cachedLat = (cached['latitude'] as num?)?.toDouble();
      final cachedLon = (cached['longitude'] as num?)?.toDouble();
      final cachedRadius = (cached['radius'] as num?)?.toInt();
      final cachedTimeStr = cached['cachedAt']?.toString();
      final items = cached['items'];

      if (cachedLat == null ||
          cachedLon == null ||
          cachedRadius == null ||
          cachedTimeStr == null ||
          items is! List) {
        return null;
      }

      final cachedTime = DateTime.tryParse(cachedTimeStr);
      if (cachedTime == null || DateTime.now().difference(cachedTime) > _cacheDuration) {
        return null;
      }

      final distance = Geolocator.distanceBetween(
        cachedLat,
        cachedLon,
        latitude,
        longitude,
      );
      if (distance > 500 || cachedRadius != radiusInMeters) return null;

      return items
          .whereType<Map>()
          .map((item) => Mosque.fromJson(
                Map<String, dynamic>.from(item),
                latitude,
                longitude,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Save nearby mosque results to Isar so they remain available offline.
  Future<void> _saveMosquesToCache(
    List<Mosque> mosques,
    double latitude,
    double longitude,
    int radiusInMeters,
  ) async {
    try {
      final items = mosques.map((mosque) {
        return <String, dynamic>{
          'type': mosque.osmId.split('/').first,
          'id': int.tryParse(mosque.osmId.split('/').last) ?? mosque.osmId.hashCode,
          'lat': mosque.latitude,
          'lon': mosque.longitude,
          'tags': <String, dynamic>{
            'name': mosque.name,
            'amenity': 'place_of_worship',
            'religion': 'muslim',
            if (mosque.type == 'musalla') 'place_of_worship': 'musalla',
            if (mosque.address != null) 'addr:full': mosque.address,
            if (mosque.openingHours != null) 'opening_hours': mosque.openingHours,
            if (mosque.serviceTimes != null) 'service_times': mosque.serviceTimes,
            if (mosque.level != null) 'level': mosque.level,
            if (mosque.wheelchair) 'wheelchair': 'yes',
            if (mosque.hasWuduHint) 'ablution': 'yes',
          },
        };
      }).toList();

      await LocalStore.instance.putJson(
        _cacheNamespace,
        _cacheKey,
        <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'radius': radiusInMeters,
          'cachedAt': DateTime.now().toIso8601String(),
          'items': items,
        },
      );
    } catch (_) {
      // Cache failure must never block mosque discovery.
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
