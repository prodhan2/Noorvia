import 'package:flutter/material.dart';
import '../config/app_routes.dart';

class NavProvider extends ChangeNotifier {
  // Default: first navbar item
  AppRoute _current = AppRoutes.navbar.first.route;

  AppRoute get current => _current;

  /// Current navbar index (for IndexedStack)
  int get currentIndex => AppRoutes.navbarIndexOf(_current) ?? 0;

  /// Navigate by AppRoute
  void goTo(AppRoute route) {
    if (_current == route) return;
    _current = route;
    notifyListeners();
  }

  /// Navigate by navbar index (tap on bottom nav)
  void goToIndex(int index) {
    goTo(AppRoutes.navbarAt(index).route);
  }
}
