import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/local/local_store.dart';
import '../models/mosque.dart';

class WalkingRouteEstimate {
  final double distanceMeters;
  final int durationMinutes;
  final bool routed;
  const WalkingRouteEstimate({required this.distanceMeters, required this.durationMinutes, required this.routed});
}

class MosqueRouteService {
  static const _orsKey = String.fromEnvironment('ORS_API_KEY');

  Future<WalkingRouteEstimate> estimate({
    required double fromLat,
    required double fromLon,
    required Mosque mosque,
  }) async {
    final fallback = WalkingRouteEstimate(
      distanceMeters: mosque.distanceInMeters * 1.2,
      durationMinutes: mosque.estimatedWalkMinutes,
      routed: false,
    );
    if (_orsKey.isEmpty) return fallback;

    final cacheKey = '${fromLat.toStringAsFixed(3)}:${fromLon.toStringAsFixed(3)}:${mosque.osmId}';
    final cached = await LocalStore.instance.getJson('mosque_routes', cacheKey);
    if (cached != null) {
      final at = DateTime.tryParse(cached['cachedAt']?.toString() ?? '');
      if (at != null && DateTime.now().difference(at) < const Duration(hours: 6)) {
        return WalkingRouteEstimate(
          distanceMeters: (cached['distance'] as num?)?.toDouble() ?? fallback.distanceMeters,
          durationMinutes: (cached['minutes'] as num?)?.toInt() ?? fallback.durationMinutes,
          routed: true,
        );
      }
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/json'),
        headers: {'Authorization': _orsKey, 'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'coordinates': [[fromLon, fromLat], [mosque.longitude, mosque.latitude]]}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return fallback;
      final data = jsonDecode(response.body);
      final routes = data is Map ? data['routes'] : null;
      if (routes is! List || routes.isEmpty || routes.first is! Map) return fallback;
      final summary = (routes.first as Map)['summary'];
      if (summary is! Map) return fallback;
      final distance = (summary['distance'] as num?)?.toDouble();
      final durationSec = (summary['duration'] as num?)?.toDouble();
      if (distance == null || durationSec == null) return fallback;
      final result = WalkingRouteEstimate(distanceMeters: distance, durationMinutes: (durationSec / 60).ceil(), routed: true);
      await LocalStore.instance.putJson('mosque_routes', cacheKey, {'distance': distance, 'minutes': result.durationMinutes, 'cachedAt': DateTime.now().toIso8601String()});
      return result;
    } catch (_) {
      return fallback;
    }
  }
}
