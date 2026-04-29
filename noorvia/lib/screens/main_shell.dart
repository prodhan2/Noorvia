// ============================================================
//  main_shell.dart
//  AppBar, Drawer, BottomNav — সব AppRoutes config থেকে আসে।
//  নতুন route যোগ করতে শুধু app_routes.dart এডিট করুন।
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/nav_provider.dart';
import '../core/providers/prayer_provider.dart';
import '../core/config/app_routes.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Build pages once — IndexedStack keeps them alive
  late final List<Widget> _pages = AppRoutes.buildNavbarPages();

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _NoorviaAppBar(isDark: isDark, theme: theme),
      drawer: _NoorviaDrawer(isDark: isDark, theme: theme),
      body: IndexedStack(
        index: nav.currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _NoorviaBottomNav(isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────
class _NoorviaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final ThemeProvider theme;

  const _NoorviaAppBar({required this.isDark, required this.theme});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkBg : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final prayer = context.watch<PrayerProvider>();
    final screenW = MediaQuery.of(context).size.width;
    final isSmall = screenW < 360;

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 12,
        right: 12,
        bottom: 8,
      ),
      child: Row(
        children: [
          // ── Hamburger + Brand ──────────────────────────────
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu,
                        color: AppColors.primary, size: 20),
                  ),
                  if (!isSmall) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'নূরভিয়া',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Noorvia',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: subColor,
                            letterSpacing: 1.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Location pill (real city from GPS) ─────────────
          GestureDetector(
            onTap: () => prayer.requestLocationAndFetch(),
            child: _Pill(
              color: isDark ? AppColors.darkCard : Colors.black87,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  prayer.isLoading
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white))
                      : const Icon(Icons.location_on_outlined,
                          color: Colors.white, size: 12),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isSmall ? 60 : 80),
                    child: Text(
                      prayer.cityDisplayName,
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ── Notification bell ──────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(Icons.notifications_outlined,
                    size: 18, color: textColor),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.notifRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '৬',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 6),

          // ── Profile avatar ─────────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Drawer  — AppRoutes.drawer থেকে auto-build হয়
// ─────────────────────────────────────────────────────────────
class _NoorviaDrawer extends StatelessWidget {
  final bool isDark;
  final ThemeProvider theme;

  const _NoorviaDrawer({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavProvider>();
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F4D2A), Color(0xFF2E8B57)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🕌', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'নূরভিয়া',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Noorvia',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ইসলামিক জীবনযাপনের সঙ্গী',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Nav items (auto from AppRoutes.drawer) ───────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Main nav items
                  ...AppRoutes.drawer.map((cfg) {
                    final isActive = context.watch<NavProvider>().current ==
                        cfg.route;
                    return _DrawerItem(
                      icon: cfg.effectiveDrawerIcon,
                      label: cfg.label,
                      textColor: textColor,
                      isActive: isActive,
                      onTap: () {
                        final navIdx = AppRoutes.navbarIndexOf(cfg.route);
                        if (navIdx != null) {
                          nav.goTo(cfg.route);
                        }
                        Navigator.pop(context);
                      },
                    );
                  }),

                  const Divider(height: 16),

                  // Extra static items (not in AppRoute enum)
                  _DrawerItem(
                    icon: Icons.access_time_outlined,
                    label: 'নামাজের সময়',
                    textColor: textColor,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.explore_outlined,
                    label: 'কিবলা',
                    textColor: textColor,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'ইসলামিক ক্যালেন্ডার',
                    textColor: textColor,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.mosque_outlined,
                    label: 'মসজিদ খুঁজি',
                    textColor: textColor,
                    onTap: () => Navigator.pop(context),
                  ),

                  const Divider(height: 16),

                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'সেটিংস',
                    textColor: textColor,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'আমাদের সম্পর্কে',
                    textColor: textColor,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Day / Night toggle
                  ListTile(
                    leading: Icon(
                      theme.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      theme.isDark ? 'দিনের মোড' : 'রাতের মোড',
                      style: GoogleFonts.hindSiliguri(
                          color: textColor, fontSize: 15),
                    ),
                    trailing: Switch(
                      value: theme.isDark,
                      onChanged: (_) => theme.toggleTheme(),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'সংস্করণ ১.০.০',
                style:
                    GoogleFonts.hindSiliguri(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom Nav  — AppRoutes.navbar থেকে auto-build হয়
// ─────────────────────────────────────────────────────────────
class _NoorviaBottomNav extends StatelessWidget {
  final bool isDark;

  const _NoorviaBottomNav({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final items = AppRoutes.navbar; // ← single source of truth

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final cfg = items[index];
              final isSelected = nav.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => nav.goToIndex(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 3,
                        width: isSelected ? 28 : 0,
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Icon pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: isSelected
                            ? const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isSelected ? cfg.activeIcon : cfg.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkSubText
                                  : AppColors.lightSubText),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cfg.label,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkSubText
                                  : AppColors.lightSubText),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Pill({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
        size: 22,
      ),
      title: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          color: isActive ? AppColors.primary : textColor,
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      tileColor: isActive
          ? AppColors.primary.withValues(alpha: 0.07)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
      dense: true,
    );
  }
}
