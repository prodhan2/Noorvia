// ============================================================
//  app_routes.dart  —  Noorvia centralized route & menu config
//
//  নতুন পেজ যোগ করতে:
//    1. নিচে AppRoute enum-এ নাম যোগ করুন
//    2. AppRouteConfig.all list-এ entry যোগ করুন
//    3. শেষ — বাকি সব (navbar, drawer, pages) auto-update হবে
// ============================================================

import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/tools/tools_screen.dart';
import '../../screens/quran/quran_screen.dart';
import '../../screens/dowa/dowa_screen.dart';
import '../../screens/login/login_screen.dart';

// ── Step 1: Route identifiers ────────────────────────────────
enum AppRoute {
  home,
  tools,
  quran,
  dowa,
  login,
}

// ── Step 2: Single config entry ──────────────────────────────
class AppRouteConfig {
  final AppRoute route;

  /// বাংলা লেবেল — navbar ও drawer-এ দেখাবে
  final String label;

  /// Drawer-এ দেখানো হবে কিনা
  final bool showInDrawer;

  /// Bottom navbar-এ দেখানো হবে কিনা
  final bool showInNavbar;

  /// Navbar icon (inactive)
  final IconData icon;

  /// Navbar icon (active/selected)
  final IconData activeIcon;

  /// Drawer icon
  final IconData drawerIcon;

  /// পেজ widget — lazy হওয়ার জন্য builder ব্যবহার করা হয়েছে
  final Widget Function() pageBuilder;

  const AppRouteConfig({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.drawerIcon,
    required this.pageBuilder,
    this.showInDrawer = true,
    this.showInNavbar = true,
  });

  // ── Step 3: Add / remove / reorder entries here ────────────
  static const List<AppRouteConfig> all = [
    AppRouteConfig(
      route: AppRoute.home,
      label: 'হোম',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      drawerIcon: Icons.home_outlined,
      pageBuilder: HomeScreen.new,
    ),
    AppRouteConfig(
      route: AppRoute.tools,
      label: 'টুলস',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      drawerIcon: Icons.build_outlined,
      showInNavbar: false, // navbar-এ নেই, শুধু drawer-এ
    ),
    AppRouteConfig(
      route: AppRoute.quran,
      label: 'কুরআন',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      drawerIcon: Icons.menu_book_outlined,
      pageBuilder: QuranScreen.new,
    ),
    AppRouteConfig(
      route: AppRoute.dowa,
      label: 'দু\'আ',
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism,
      drawerIcon: Icons.volunteer_activism_outlined,
      pageBuilder: DowaScreen.new,
    ),
    AppRouteConfig(
      route: AppRoute.login,
      label: 'লগইন',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      drawerIcon: Icons.person_outline,
      pageBuilder: LoginScreen.new,
    ),
  ];

  // ── Derived helpers (auto-computed, don't edit) ─────────────

  /// শুধু navbar-এর items
  static List<AppRouteConfig> get navbarItems =>
      all.where((r) => r.showInNavbar).toList();

  /// শুধু drawer-এর items
  static List<AppRouteConfig> get drawerItems =>
      all.where((r) => r.showInDrawer).toList();

  /// navbar index → AppRoute
  static AppRoute navbarRouteAt(int index) => navbarItems[index].route;

  /// AppRoute → navbar index (null if not in navbar)
  static int? navbarIndexOf(AppRoute route) {
    final idx = navbarItems.indexWhere((r) => r.route == route);
    return idx == -1 ? null : idx;
  }

  /// AppRoute → page widget
  static Widget pageFor(AppRoute route) {
    final cfg = all.firstWhere((r) => r.route == route);
    return cfg.pageBuilder();
  }

  /// All navbar pages in order (for IndexedStack)
  static List<Widget> get navbarPages =>
      navbarItems.map((r) => r.pageBuilder()).toList();
}
