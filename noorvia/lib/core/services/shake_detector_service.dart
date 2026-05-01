// ============================================================
//  shake_detector_service.dart
//  Accelerometer দিয়ে phone shake detect করে।
//  - start() → listening শুরু
//  - stop()  → stream বন্ধ
//  - onShake callback → shake হলে call হয়
//
//  Shake logic:
//    acceleration magnitude > threshold হলে shake count বাড়ে
//    কম সময়ে (shakeWindow) পর্যাপ্ত shake হলে onShake fire করে
//    cooldown period-এ duplicate trigger হয় না
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetectorService {
  // ── Tuning parameters ─────────────────────────────────────
  /// m/s² — এর বেশি হলে shake হিসেবে গণ্য
  static const double _shakeThreshold = 15.0;

  /// এই সময়ের মধ্যে (ms) কতটা shake হলে trigger হবে
  static const int _shakeWindowMs = 1000;

  /// window-এর মধ্যে কতটা shake লাগবে
  static const int _minShakeCount = 2;

  /// trigger হওয়ার পর কতক্ষণ (ms) ignore করবে
  static const int _cooldownMs = 1500;

  // ── Internal state ────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _subscription;
  final List<int> _shakeTimes = [];
  int _lastShakeTime = 0;

  /// Shake হলে এই callback call হবে
  final VoidCallback onShake;

  ShakeDetectorService({required this.onShake});

  // ── Start listening ───────────────────────────────────────
  void start() {
    _subscription?.cancel();
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval, // ~50ms
    ).listen(_onAccelerometer);
  }

  // ── Stop listening ────────────────────────────────────────
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _shakeTimes.clear();
  }

  // ── Process each accelerometer reading ───────────────────
  void _onAccelerometer(AccelerometerEvent event) {
    // Gravity-inclusive magnitude
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Subtract gravity (~9.8) to get net acceleration
    final netAccel = (magnitude - 9.8).abs();

    if (netAccel < _shakeThreshold) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Cooldown check — এইমাত্র trigger হলে ignore
    if (now - _lastShakeTime < _cooldownMs) return;

    // Window-এর বাইরের পুরনো entries সরাও
    _shakeTimes.removeWhere((t) => now - t > _shakeWindowMs);
    _shakeTimes.add(now);

    if (_shakeTimes.length >= _minShakeCount) {
      _shakeTimes.clear();
      _lastShakeTime = now;
      onShake();
    }
  }

  void dispose() => stop();
}

// Typedef so the file is self-contained
typedef VoidCallback = void Function();
