import 'package:geolocator/geolocator.dart';

/// Global service to handle location permissions across the entire app
/// Ensures permission is requested only once and cached for subsequent use
class LocationPermissionService {
  static final LocationPermissionService _instance = LocationPermissionService._internal();
  
  bool _permissionRequested = false;
  LocationPermission _cachedPermission = LocationPermission.denied;

  LocationPermissionService._internal();

  factory LocationPermissionService() {
    return _instance;
  }

  /// Initialize location permissions at app startup
  /// Call this once in main.dart or in the root widget
  Future<void> initializePermissions() async {
    if (_permissionRequested) {
      return; // Already initialized
    }

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('লোকেশন সার্ভিস বন্ধ আছে। দয়া করে চালু করুন।');
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Cache the permission status
      _cachedPermission = permission;
      _permissionRequested = true;

      print('📍 Location permission initialized: $permission');
    } catch (e) {
      print('❌ Error initializing location permission: $e');
      _permissionRequested = true; // Mark as requested even if failed
    }
  }

  /// Get the cached permission status
  /// Returns the last known permission status without requesting again
  LocationPermission getCachedPermission() {
    return _cachedPermission;
  }

  /// Check if permission is granted
  bool isPermissionGranted() {
    return _cachedPermission == LocationPermission.whileInUse ||
        _cachedPermission == LocationPermission.always;
  }

  /// Check if permission was permanently denied
  bool isPermissionDeniedForever() {
    return _cachedPermission == LocationPermission.deniedForever;
  }

  /// Verify permission is still valid (in case user changed it in settings)
  /// This checks the actual permission without requesting again
  Future<bool> verifyPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      _cachedPermission = permission;
      return isPermissionGranted();
    } catch (e) {
      print('❌ Error verifying permission: $e');
      return false;
    }
  }

  /// Open app settings to allow user to grant permission manually
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Reset the permission cache (useful for testing or if user changes settings)
  void resetCache() {
    _permissionRequested = false;
    _cachedPermission = LocationPermission.denied;
  }
}
