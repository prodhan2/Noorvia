import 'dart:math' show sin, cos, asin, sqrt, pi;

class Mosque {
  final String osmId;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceInMeters;
  final String? address;
  final String type; // mosque | musalla
  final String? openingHours;
  final String? serviceTimes;
  final String? level;
  final bool wheelchair;
  final bool hasWuduHint;

  const Mosque({
    required this.osmId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceInMeters,
    this.address,
    this.type = 'mosque',
    this.openingHours,
    this.serviceTimes,
    this.level,
    this.wheelchair = false,
    this.hasWuduHint = false,
  });

  factory Mosque.fromJson(Map<String, dynamic> json, double userLat, double userLon) {
    final lat = json['lat'] is String ? double.parse(json['lat']) : (json['lat'] as num).toDouble();
    final lon = json['lon'] is String ? double.parse(json['lon']) : (json['lon'] as num).toDouble();
    final tags = json['tags'] is Map ? Map<String, dynamic>.from(json['tags']) : <String, dynamic>{};
    final placeType = tags['place_of_worship']?.toString() == 'musalla' ? 'musalla' : 'mosque';
    final rawType = json['type']?.toString() ?? 'node';
    final rawId = json['id']?.toString() ?? '${lat}_$lon';
    final name = (tags['name:bn'] ?? tags['name'] ?? tags['name:en'] ?? (placeType == 'musalla' ? 'নামহীন মুসাল্লা' : 'নামহীন মসজিদ')).toString();
    final addressParts = [
      tags['addr:housenumber'], tags['addr:street'], tags['addr:suburb'], tags['addr:city']
    ].where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString()).toList();
    final address = tags['addr:full']?.toString() ?? (addressParts.isEmpty ? null : addressParts.join(', '));
    final wuduRaw = '${tags['ablution'] ?? ''} ${tags['wudu'] ?? ''} ${tags['washing_facilities'] ?? ''}'.toLowerCase();
    return Mosque(
      osmId: '$rawType/$rawId',
      name: name,
      latitude: lat,
      longitude: lon,
      distanceInMeters: _calculateDistance(userLat, userLon, lat, lon),
      address: address,
      type: placeType,
      openingHours: tags['opening_hours']?.toString(),
      serviceTimes: tags['service_times']?.toString(),
      level: tags['level']?.toString(),
      wheelchair: tags['wheelchair']?.toString().toLowerCase() == 'yes',
      hasWuduHint: wuduRaw.contains('yes') || wuduRaw.contains('wudu') || wuduRaw.contains('ablution'),
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final a = sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad);
    final safeA = a.clamp(0.0, 1.0);
    final c = 2 * asin(sqrt(safeA));
    return earthRadiusKm * c * 1000;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180.0;

  String getFormattedDistance({bool english = false}) {
    if (distanceInMeters < 1000) return '${distanceInMeters.toStringAsFixed(0)} ${english ? 'm' : 'মিটার'}';
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} ${english ? 'km' : 'কিলোমিটার'}';
  }

  int get estimatedWalkMinutes {
    // Straight-line distance × 1.2 walking detour factor at ~4.8 km/h.
    final minutes = (distanceInMeters * 1.2 / 80).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  String getGoogleMapsUrl() => 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=walking';
  String getOpenStreetMapUrl() => 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=18/$latitude/$longitude';
}
