import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/local/local_store.dart';

class NoorviaWeather {
  const NoorviaWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
    required this.fetchedAt,
    this.fromCache = false,
  });

  final double temperature;
  final double feelsLike;
  final int humidity;
  final double precipitation;
  final double windSpeed;
  final int weatherCode;
  final DateTime fetchedAt;
  final bool fromCache;

  String get condition {
    if (weatherCode == 0) return 'পরিষ্কার আকাশ';
    if ([1, 2, 3].contains(weatherCode)) return 'আংশিক মেঘলা';
    if ([45, 48].contains(weatherCode)) return 'কুয়াশা';
    if ([51, 53, 55, 56, 57].contains(weatherCode)) return 'গুঁড়ি গুঁড়ি বৃষ্টি';
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(weatherCode)) return 'বৃষ্টি';
    if ([71, 73, 75, 77, 85, 86].contains(weatherCode)) return 'তুষারপাত';
    if ([95, 96, 99].contains(weatherCode)) return 'বজ্রঝড়';
    return 'আবহাওয়া';
  }

  String get emoji {
    if (weatherCode == 0) return '☀️';
    if ([1, 2, 3].contains(weatherCode)) return '⛅';
    if ([45, 48].contains(weatherCode)) return '🌫️';
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(weatherCode)) return '🌧️';
    if ([71, 73, 75, 77, 85, 86].contains(weatherCode)) return '❄️';
    if ([95, 96, 99].contains(weatherCode)) return '⛈️';
    return '🌤️';
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'precipitation': precipitation,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      };

  factory NoorviaWeather.fromJson(Map<String, dynamic> json, {bool fromCache = false}) =>
      NoorviaWeather(
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
        feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 0,
        humidity: (json['humidity'] as num?)?.toInt() ?? 0,
        precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
        windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0,
        weatherCode: (json['weatherCode'] as num?)?.toInt() ?? -1,
        fetchedAt: DateTime.tryParse(json['fetchedAt']?.toString() ?? '') ?? DateTime.now(),
        fromCache: fromCache,
      );
}

class OpenMeteoService {
  OpenMeteoService._();
  static final OpenMeteoService instance = OpenMeteoService._();

  static const _namespace = 'weather_cache_v1';

  Future<NoorviaWeather?> current({required double latitude, required double longitude}) async {
    final key = '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
    final cached = await LocalStore.instance.getJson(_namespace, key);
    if (cached != null) {
      final item = NoorviaWeather.fromJson(cached, fromCache: true);
      if (DateTime.now().difference(item.fetchedAt).inMinutes < 30) return item;
    }

    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
        'timezone': 'auto',
      });
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw Exception('Weather API ${response.statusCode}');
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final current = root['current'];
      if (current is! Map) throw Exception('Weather payload missing current');
      final map = Map<String, dynamic>.from(current);
      final item = NoorviaWeather(
        temperature: (map['temperature_2m'] as num?)?.toDouble() ?? 0,
        feelsLike: (map['apparent_temperature'] as num?)?.toDouble() ?? 0,
        humidity: (map['relative_humidity_2m'] as num?)?.toInt() ?? 0,
        precipitation: (map['precipitation'] as num?)?.toDouble() ?? 0,
        windSpeed: (map['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        weatherCode: (map['weather_code'] as num?)?.toInt() ?? -1,
        fetchedAt: DateTime.now(),
      );
      await LocalStore.instance.putJson(_namespace, key, item.toJson(), syncStatus: 'cached');
      return item;
    } catch (_) {
      return cached == null ? null : NoorviaWeather.fromJson(cached, fromCache: true);
    }
  }
}
