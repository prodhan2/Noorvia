import 'dart:math' show sin, cos, asin, sqrt, pi;

/// Model class representing a Mosque with its location and details
class Mosque {
  final String name;
  final double latitude;
  final double longitude;
  final double distanceInMeters;
  final String? address;

  Mosque({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceInMeters,
    this.address,
  });

  /// Factory constructor to create Mosque from OpenStreetMap JSON data
  factory Mosque.fromJson(Map<String, dynamic> json, double userLat, double userLon) {
    final lat = json['lat'] is String 
        ? double.parse(json['lat']) 
        : json['lat'].toDouble();
    final lon = json['lon'] is String 
        ? double.parse(json['lon']) 
        : json['lon'].toDouble();
    
    // Extract name from tags
    final tags = json['tags'] as Map<String, dynamic>?;
    String name = tags?['name'] ?? 
                  tags?['name:bn'] ?? 
                  tags?['name:en'] ?? 
                  'নামহীন মসজিদ'; // Unnamed Mosque in Bengali
    
    // Calculate distance using Haversine formula
    final distance = _calculateDistance(userLat, userLon, lat, lon);
    
    return Mosque(
      name: name,
      latitude: lat,
      longitude: lon,
      distanceInMeters: distance,
      address: tags?['addr:full'] ?? tags?['addr:street'],
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double _calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const double earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    
    final a = 
        sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * 
        cos(lat1Rad) * 
        cos(lat2Rad);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadiusKm * c * 1000; // Convert to meters
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Get formatted distance string
  String getFormattedDistance() {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} মিটার'; // meters in Bengali
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(2)} কিলোমিটার'; // kilometers in Bengali
    }
  }

  /// Get Google Maps URL for this mosque
  String getGoogleMapsUrl() {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }
}
