import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Day:   06:00 – 18:00  → light mode
// Night: 18:00 – 06:00  → dark mode
// User can still override manually; override is saved to prefs.
// If autoMode is on, manual override is ignored.

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool _autoMode = true; // auto by default

  bool get isDark => _isDark;
  bool get autoMode => _autoMode;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Timer? _autoTimer;

  ThemeProvider() {
    _loadPrefs();
  }

  // ── Load saved prefs ──────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _autoMode = prefs.getBool('autoMode') ?? true;
    if (_autoMode) {
      _applyAutoTheme();
      _startAutoTimer();
    } else {
      _isDark = prefs.getBool('isDark') ?? false;
    }
    notifyListeners();
  }

  // ── Auto theme: dark between 18:00–06:00 ─────────────────
  void _applyAutoTheme() {
    final hour = DateTime.now().hour;
    // Light: 6 AM to 6 PM  |  Dark: 6 PM to 6 AM
    _isDark = hour < 6 || hour >= 18;
  }

  // ── Check every minute ────────────────────────────────────
  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_autoMode) return;
      final wasDark = _isDark;
      _applyAutoTheme();
      if (_isDark != wasDark) notifyListeners();
    });
  }

  // ── Manual toggle (disables auto mode) ───────────────────
  Future<void> toggleTheme() async {
    _autoMode = false;
    _isDark = !_isDark;
    _autoTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoMode', false);
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  // ── Re-enable auto mode ───────────────────────────────────
  Future<void> enableAutoMode() async {
    _autoMode = true;
    _applyAutoTheme();
    _startAutoTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoMode', true);
    notifyListeners();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}
