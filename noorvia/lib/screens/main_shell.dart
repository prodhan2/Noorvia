import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/nav_provider.dart';
import 'home/home_screen.dart';
import 'tools/tools_screen.dart';
import 'quran/quran_screen.dart';
import 'dowa/dowa_screen.dart';
import 'login/login_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static final List<Widget> _pages = [
    const HomeScreen(),
    const ToolsScreen(),
    const QuranScreen(),
    const DowaScreen(),
    const LoginScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, isDark, themeProvider),
      drawer: _buildDrawer(context, isDark, themeProvider),
      body: IndexedStack(
        index: navProvider.currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(context, navProvider, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, ThemeProvider themeProvider) {
    final bgColor = isDark ? AppColors.darkBg : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Hamburger menu + Noorvia name
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'নূরভিয়া',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Noorvia',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: subColor,
                                letterSpacing: 1.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Date pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'এপ্রিল-৩০',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Location pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'ঢাকা',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Notification bell
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
                          )
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
                          child: Text('৬',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // Profile avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, bool isDark, ThemeProvider themeProvider) {
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
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
                      Text('🕌', style: const TextStyle(fontSize: 32)),
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
                  const SizedBox(height: 16),
                  Text(
                    'ইসলামিক জীবনযাপনের সঙ্গী',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(context, Icons.home_outlined, 'হোম', textColor, () {
                    context.read<NavProvider>().setIndex(0);
                    Navigator.pop(context);
                  }),
                  _drawerItem(context, Icons.build_outlined, 'টুলস', textColor, () {
                    context.read<NavProvider>().setIndex(1);
                    Navigator.pop(context);
                  }),
                  _drawerItem(context, Icons.menu_book_outlined, 'কুরআন', textColor, () {
                    context.read<NavProvider>().setIndex(2);
                    Navigator.pop(context);
                  }),
                  _drawerItem(context, Icons.volunteer_activism_outlined, 'দু\'আ', textColor, () {
                    context.read<NavProvider>().setIndex(3);
                    Navigator.pop(context);
                  }),
                  const Divider(height: 1),
                  _drawerItem(context, Icons.access_time_outlined, 'নামাজের সময়', textColor, () => Navigator.pop(context)),
                  _drawerItem(context, Icons.explore_outlined, 'কিবলা', textColor, () => Navigator.pop(context)),
                  _drawerItem(context, Icons.calendar_month_outlined, 'ইসলামিক ক্যালেন্ডার', textColor, () => Navigator.pop(context)),
                  _drawerItem(context, Icons.mosque_outlined, 'মসজিদ খুঁজি', textColor, () => Navigator.pop(context)),
                  const Divider(height: 1),
                  _drawerItem(context, Icons.settings_outlined, 'সেটিংস', textColor, () => Navigator.pop(context)),
                  _drawerItem(context, Icons.info_outline, 'আমাদের সম্পর্কে', textColor, () => Navigator.pop(context)),
                  // Day/Night toggle
                  ListTile(
                    leading: Icon(
                      themeProvider.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      themeProvider.isDark ? 'দিনের মোড' : 'রাতের মোড',
                      style: GoogleFonts.hindSiliguri(
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDark,
                      onChanged: (_) => themeProvider.toggleTheme(),
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
                style: GoogleFonts.hindSiliguri(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label,
      Color textColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          color: textColor,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildBottomNav(
      BuildContext context, NavProvider navProvider, bool isDark) {
    final items = [
      {'icon': Icons.menu_book_outlined, 'activeIcon': Icons.menu_book, 'label': 'ইলম'},
      {'icon': Icons.checklist_outlined, 'activeIcon': Icons.checklist, 'label': 'আমল'},
      {'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag, 'label': 'সেবা'},
      {'icon': Icons.grid_view_outlined, 'activeIcon': Icons.grid_view, 'label': 'বিবিধ'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'লগইন'},
    ];

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
              final isSelected = navProvider.currentIndex == index;
              final item = items[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => navProvider.setIndex(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top indicator line
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: isSelected ? 28 : 0,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Icon with background pill when selected
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
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
                            isSelected
                                ? item['activeIcon'] as IconData
                                : item['icon'] as IconData,
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
                          item['label'] as String,
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
