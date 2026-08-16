import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/mosque.dart';
import '../models/smart_salah_settings.dart';
import 'mosque_service.dart';

class SmartSalahGeofenceResult {
  const SmartSalahGeofenceResult(this.ok, [this.error]);
  final bool ok;
  final String? error;
}

class SmartSalahService {
  static const _channel = MethodChannel(
    'com.butterflydevs.noorvia/prayer_alarm',
  );

  Future<Map<String, dynamic>> getNativeSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return {};
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'getSmartSalahSettings',
      );
      return Map<String, dynamic>.from(value ?? const {});
    } catch (_) {
      return {};
    }
  }

  Future<void> saveNativeSettings(SmartSalahSettings settings) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('saveSmartSalahSettings', settings.toMap());
    } catch (_) {}
  }

  Future<bool> hasDndAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('hasNotificationPolicyAccess') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openDndAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('openNotificationPolicyAccess');
    } catch (_) {}
  }

  Future<bool> hasMosqueLocationAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final fine = await Permission.location.status;
    final always = await Permission.locationAlways.status;
    return fine.isGranted && always.isGranted;
  }

  /// Requests foreground first, then background location. Android may require
  /// the second step from App Settings on newer versions; the UI handles that
  /// status without forcing the user.
  Future<bool> requestMosqueLocationAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    var fine = await Permission.location.status;
    if (!fine.isGranted) fine = await Permission.location.request();
    if (!fine.isGranted) return false;

    var always = await Permission.locationAlways.status;
    if (!always.isGranted) always = await Permission.locationAlways.request();
    return always.isGranted;
  }

  Future<bool> openAppPermissionSettings() => openAppSettings();

  Future<SmartSalahGeofenceResult> refreshMosqueGeofences({
    required int radius,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SmartSalahGeofenceResult(false, 'android_only');
    }
    if (!await hasMosqueLocationAccess()) {
      return const SmartSalahGeofenceResult(
        false,
        'background_location_permission',
      );
    }

    try {
      final mosqueService = MosqueService();
      final position = await mosqueService.getCurrentLocation();
      final mosques = await mosqueService.getNearbyMosquesWithCache(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInMeters: 5000,
      );
      if (mosques.isEmpty) {
        return const SmartSalahGeofenceResult(false, 'no_mosques');
      }
      final payload = mosques.take(50).map(_mosqueMap).toList(growable: false);
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'setMosqueGeofences',
        {'mosques': payload, 'radius': radius},
      );
      final ok = response?['ok'] == true;
      return SmartSalahGeofenceResult(ok, response?['error']?.toString());
    } catch (e) {
      return SmartSalahGeofenceResult(false, e.toString());
    }
  }

  Future<void> clearMosqueGeofences() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('clearMosqueGeofences');
    } catch (_) {}
  }

  Map<String, dynamic> _mosqueMap(Mosque mosque) => {
        'id': '${mosque.latitude.toStringAsFixed(6)}_${mosque.longitude.toStringAsFixed(6)}',
        'latitude': mosque.latitude,
        'longitude': mosque.longitude,
        'name': mosque.name,
      };
}
