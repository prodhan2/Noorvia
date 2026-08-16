import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/local/local_store.dart';
import '../models/smart_salah_settings.dart';
import '../services/smart_salah_service.dart';
import '../services/firebase_session_service.dart';

class SmartSalahProvider extends ChangeNotifier {
  static const _namespace = 'settings';
  static const _key = 'smart_salah';

  final SmartSalahService _service = SmartSalahService();
  SmartSalahSettings _settings = const SmartSalahSettings();
  bool _loading = true;
  bool _saving = false;
  bool _dndAccess = false;
  bool _locationAccess = false;
  bool _nearMosque = false;
  String? _geofenceMessage;

  SmartSalahProvider() {
    unawaited(_load());
  }

  SmartSalahSettings get settings => _settings;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get dndAccess => _dndAccess;
  bool get locationAccess => _locationAccess;
  bool get nearMosque => _nearMosque;
  String? get geofenceMessage => _geofenceMessage;

  Future<void> _load() async {
    try {
      final local = await LocalStore.instance.getJson(_namespace, _key);
      if (local != null) {
        _settings = SmartSalahSettings.fromMap(local);
      } else {
        final native = await _service.getNativeSettings();
        if (native.isNotEmpty) _settings = SmartSalahSettings.fromMap(native);
      }
      await refreshStatus();
      unawaited(_mergeCloud());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    final native = await _service.getNativeSettings();
    _dndAccess = native['hasPolicyAccess'] == true || await _service.hasDndAccess();
    _nearMosque = native['nearMosque'] == true;
    _locationAccess = await _service.hasMosqueLocationAccess();
    notifyListeners();
  }

  Future<void> update(SmartSalahSettings value, {bool refreshGeofences = false}) async {
    _settings = value;
    _saving = true;
    notifyListeners();
    try {
      await LocalStore.instance.putJson(
        _namespace,
        _key,
        value.toMap(),
        syncStatus: 'pending',
      );
      await _service.saveNativeSettings(value);
      unawaited(_pushCloud(value));

      if (!value.enabled || !value.mosqueAware) {
        await _service.clearMosqueGeofences();
        _nearMosque = false;
      } else if (refreshGeofences && _locationAccess) {
        await this.refreshGeofences();
      }
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> requestLocationAccess() async {
    _locationAccess = await _service.requestMosqueLocationAccess();
    notifyListeners();
    if (_locationAccess && _settings.enabled && _settings.mosqueAware) {
      await refreshGeofences();
    }
    return _locationAccess;
  }

  Future<void> openAppSettings() => _service.openAppPermissionSettings();

  Future<void> openDndAccess() async {
    await _service.openDndAccess();
  }

  Future<void> refreshGeofences() async {
    _geofenceMessage = null;
    notifyListeners();
    final result = await _service.refreshMosqueGeofences(
      radius: _settings.mosqueRadius,
    );
    _geofenceMessage = result.ok ? 'মসজিদ অটো-ডিটেকশন প্রস্তুত' : _messageFor(result.error);
    await refreshStatus();
  }

  String _messageFor(String? error) {
    if (error == 'background_location_permission' || error == 'location_permission') {
      return 'মসজিদ অটো-ডিটেকশনের জন্য Always location permission দিন';
    }
    if (error == 'no_mosques') return '৫ কিমির মধ্যে মসজিদ পাওয়া যায়নি';
    return 'মসজিদ অটো-ডিটেকশন আপডেট করা যায়নি';
  }

  Future<void> _pushCloud(SmartSalahSettings value) async {
    try {
      final user = await FirebaseSessionService.ensureSignedIn();
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_salah')
          .set(value.toMap(), SetOptions(merge: true));
      await LocalStore.instance.putJson(
        _namespace,
        _key,
        value.toMap(),
        syncStatus: 'synced',
      );
    } catch (_) {
      // Local-first: Firestore will be retried the next time the user changes
      // settings or reopens this settings page.
    }
  }

  Future<void> _mergeCloud() async {
    try {
      final user = await FirebaseSessionService.ensureSignedIn();
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_salah')
          .get();
      if (!doc.exists || doc.data() == null) return;
      final cloud = SmartSalahSettings.fromMap(doc.data());
      _settings = cloud;
      await LocalStore.instance.putJson(
        _namespace,
        _key,
        cloud.toMap(),
        syncStatus: 'synced',
      );
      await _service.saveNativeSettings(cloud);
      notifyListeners();
    } catch (_) {}
  }
}
