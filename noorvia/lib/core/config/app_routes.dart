// ============================================================
//  app_routes.dart  —  Noorvia centralized route & menu config
//
//  নতুন পেজ যোগ করতে মাত্র ৩টি কাজ:
//    1. AppRoute enum-এ নাম যোগ করুন
//    2. _configs list-এ একটি AppRouteConfig entry যোগ করুন
//    3. শেষ — navbar, drawer, pages সব auto-update হবে
// ============================================================

import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/tools/tools_screen.dart';
import '../../screens/IslamicFeatures/BangalQUran/BanglaQuran.dart';
import '../../screens/dowa/dowa_screen.dart';
import '../../screens/settings/settings_screen.dart';

// ─────────────────────────────────────────────────────────────
// Step 1 ▸ Route identifiers
//   নতুন route যোগ করলে এখানে enum value যোগ করুন
// ─────────────────────────────────────────────────────────────
enum AppRoute {
  home,
  tools,
  quran,
  dowa,
  settings,
}

// ─────────────────────────────────────────────────────────────
// Config model  (পরিবর্তন করার দরকার নেই)
// ─────────────────────────────────────────────────────────────
class AppRouteConfig {
  /// Route identifier
  final AppRoute route;

  /// বাংলা লেবেল — navbar ও drawer উভয়তে ব্যবহার হয়
  final String label;

  /// Bottom navbar-এ দেখাবে কিনা
  final bool showInNavbar;

  /// App drawer-এ দেখাবে কিনা
  final bool showInDrawer;

  /// Navbar inactive icon
  final IconData icon;

  /// Navbar active/selected icon
  final IconData activeIcon;

  /// Drawer icon (আলাদা না হলে icon-ই ব্যবহার হয়)
  final IconData? drawerIcon;

  /// পেজ widget builder
  final Widget Function() pageBuilder;

  const AppRouteConfig({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.pageBuilder,
    this.drawerIcon,
    this.showInNavbar = true,
    this.showInDrawer = true,
  });

  IconData get effectiveDrawerIcon => drawerIcon ?? icon;
}

// ─────────────────────────────────────────────────────────────
// Step 2 ▸ THE MASTER LIST  ← শুধু এখানে পরিবর্তন করুন
//
//   • showInNavbar: false  → শুধু drawer-এ থাকবে
//   • showInDrawer: false  → শুধু navbar-এ থাকবে
//   • উভয় true            → দুই জায়গায় থাকবে
//   • reorder করলে সব auto-update হয়
// ─────────────────────────────────────────────────────────────
final List<AppRouteConfig> appRoutes = [
  AppRouteConfig(
    route: AppRoute.home,
    label: 'হোম',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    pageBuilder: () => const HomeScreen(),
    showInNavbar: true,
    showInDrawer: true,
  ),
  AppRouteConfig(
    route: AppRoute.tools,
    label: 'টুলস',
    icon: Icons.build_outlined,
    activeIcon: Icons.build_rounded,
    pageBuilder: () => const ToolsScreen(),
    showInNavbar: false, // ← navbar-এ নেই, শুধু drawer-এ
    showInDrawer: true,
  ),
  AppRouteConfig(
    route: AppRoute.quran,
    label: 'কুরআন',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    // SurahListPage — QuranApp-এর home screen (QuranApp নিজে MaterialApp তাই সরাসরি দেওয়া যায় না)
    pageBuilder: () => const SurahListPage(),
    showInNavbar: true,
    showInDrawer: true,
  ),
  AppRouteConfig(
    route: AppRoute.dowa,
    label: 'দু\'আ',
    icon: Icons.volunteer_activism_outlined,
    activeIcon: Icons.volunteer_activism,
    pageBuilder: () => const DowaScreen(),
    showInNavbar: true,
    showInDrawer: true,
  ),
  AppRouteConfig(
    route: AppRoute.settings,
    label: 'সেটিংস',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    drawerIcon: Icons.settings_outlined,
    pageBuilder: () => const SettingsScreen(),
    showInNavbar: true,
    showInDrawer: true,
  ),
];

// ─────────────────────────────────────────────────────────────
// Step 3 ▸ Computed helpers  (পরিবর্তন করার দরকার নেই)
// ─────────────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  /// শুধু navbar items (showInNavbar == true)
  static List<AppRouteConfig> get navbar =>
      appRoutes.where((r) => r.showInNavbar).toList();

  /// শুধু drawer items (showInDrawer == true)
  static List<AppRouteConfig> get drawer =>
      appRoutes.where((r) => r.showInDrawer).toList();

  /// navbar index → config
  static AppRouteConfig navbarAt(int index) => navbar[index];

  /// AppRoute → navbar index  (null = not in navbar)
  static int? navbarIndexOf(AppRoute route) {
    final i = navbar.indexWhere((r) => r.route == route);
    return i == -1 ? null : i;
  }

  /// AppRoute → config
  static AppRouteConfig configOf(AppRoute route) =>
      appRoutes.firstWhere((r) => r.route == route);

  /// IndexedStack-এর জন্য navbar pages list
  static List<Widget> buildNavbarPages() =>
      navbar.map((r) => r.pageBuilder()).toList();
}
