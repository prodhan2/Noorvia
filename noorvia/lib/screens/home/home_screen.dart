import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/nav_provider.dart';
import '../../core/config/app_routes.dart';
import '../IslamicFeatures/BangalQUran/BanglaQuran.dart';
import '../IslamicFeatures/tashbi.dart';
import '../IslamicFeatures/NamazNiyom.dart';
import '../IslamicFeatures/hidithdemo.dart';
import '../IslamicFeatures/islamciradio.dart';
import '../IslamicFeatures/ramadancalender.dart';
import '../IslamicFeatures/calendar.dart';
import '../IslamicFeatures/AsmaulHusna/asmaul_husna_page.dart';
import '../IslamicFeatures/qibla_direction_page.dart';
import '../Ruqyah/ruqyah_list_page.dart';
import '../Ruqyah/ruqyah_home_page.dart';
import '../IslamicNames/islamic_names_page.dart';
import '../ArabicAlphabet/arabic_alphabet_home.dart';
import '../IslamicBooks/islamic_books_page.dart';

import '../common/web_view_page.dart';

import '../IslamicFeatures/namaz_tracker_page.dart';
import '../common/coming_soon_page.dart';
import 'widgets/section_header.dart';
import 'widgets/feature_grid_item.dart';
import 'widgets/prayer_card.dart';
import 'widgets/banner_card.dart';
import 'widgets/donation_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Prayer card: index 0
  late final Animation<double> _prayerFade;
  late final Animation<Offset> _prayerSlide;

  // Banner card: index 1
  late final Animation<double> _bannerFade;
  late final Animation<Offset> _bannerSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Prayer card — starts immediately, done by 65%
    _prayerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _prayerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));

    // Banner card — starts at 35%, done by 100%
    _bannerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── push a full-screen page ──────────────────────────────
  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ── coming soon shortcut ─────────────────────────────────
  void _soon(BuildContext context, String title, String emoji, [String? desc]) {
    _go(context, ComingSoonPage(title: title, emoji: emoji, description: desc));
  }

  // ── মসজিদ খুঁজি — Google Maps এ নিয়ে যাবে ──────────────
  Future<void> _findMosque(BuildContext context) async {
    try {
      // Permission check
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('লোকেশন পারমিশন দিন'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = pos.latitude;
      final lng = pos.longitude;

      // Google Maps URL — nearby mosques search
      final uri = Uri.parse(
        'https://www.google.com/maps/search/mosque/@$lat,$lng,15z',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: maps intent
        final fallback = Uri.parse(
          'geo:$lat,$lng?q=mosque&z=15',
        );
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('লোকেশন পাওয়া যায়নি, আবার চেষ্টা করুন'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ── switch bottom-nav tab ────────────────────────────────
  void _tab(BuildContext context, AppRoute route) {
    context.read<NavProvider>().goTo(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Prayer card (slides from bottom) ─────────
            FadeTransition(
              opacity: _prayerFade,
              child: SlideTransition(
                position: _prayerSlide,
                child: PrayerCard(isDark: isDark),
              ),
            ),
            const SizedBox(height: 8),
            // ── Ramadan mini card ─────────────────────────
            FadeTransition(
              opacity: _bannerFade,
              child: SlideTransition(
                position: _bannerSlide,
                child: RamadanMiniCard(
                  isDark: isDark,
                  onExpand: () => _go(context, RamadanCalendarPage()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Banner card ───────────────────────────────
            FadeTransition(
              opacity: _bannerFade,
              child: SlideTransition(
                position: _bannerSlide,
                child: BannerCard(isDark: isDark),
              ),
            ),
            const SizedBox(height: 16),

            // ── ইলম ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(
                title: 'ইলম',
                color: AppColors.ilomColor,
                onSearch: () => _tab(context, AppRoute.quran),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildGrid(_ilomItems(context), isDark),
            ),
            const SizedBox(height: 16),

            // ── আমল ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(title: 'আমল', color: AppColors.amolColor),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildGrid(_amolItems(context), isDark),
            ),
            const SizedBox(height: 16),

            // ── সেবা ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(title: 'সেবা', color: AppColors.sebaColor),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildGrid(_sebaItems(context), isDark),
            ),
            const SizedBox(height: 16),

            // ── বিবিধ ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(
                title: 'বিবিধ',
                color: AppColors.bibidhoColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildGrid(_bibidhoItems(context), isDark),
            ),
            const SizedBox(height: 16),

            const DonationCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Grid builder ──────────────────────────────────────────
  Widget _buildGrid(List<FeatureItem> items, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          FeatureGridItem(item: items[index], isDark: isDark),
    );
  }

  // ══════════════════════════════════════════════════════════
  // ইলম
  // ══════════════════════════════════════════════════════════
  List<FeatureItem> _ilomItems(BuildContext context) => [
    FeatureItem(
      emoji: '📖',
      label: 'কুরআন',
      onTap: () => _go(context, const SurahListPage()),
    ),
    FeatureItem(
      emoji: '📚',
      label: 'কিতাব',
      onTap: () => _go(context, const IslamicBooksPage()),
    ),
    FeatureItem(
      emoji: '📜',
      label: 'হাদীস',
      onTap: () => _go(context, HadithDemoPage()),
    ),
    FeatureItem(
      emoji: '📝',
      label: 'প্রবন্ধ',
      onTap: () =>
          _soon(context, 'প্রবন্ধ', '📝', 'ইসলামিক প্রবন্ধ ও নিবন্ধ পড়ুন'),
    ),
    FeatureItem(
      emoji: '🎙️',
      label: 'বয়ান',
      onTap: () => _go(context, const RadioScreen()),
    ),
    FeatureItem(
      emoji: '🎓',
      label: 'কুরআন\nশিক্ষা',
      onTap: () => _go(context, const ArabicAlphabetHome()),
    ),
    FeatureItem(
      emoji: '🕌',
      label: 'নামায শিক্ষা',
      onTap: () => _go(context, const ChapterListPage()),
    ),
    FeatureItem(
      emoji: '🌿',
      label: 'রুকইয়াহ',
      onTap: () => _go(context, const RuqyahHomePage()),
    ),
    FeatureItem(
      emoji: '🗓️',
      label: 'নামাজ\nট্র্যাকার',
      onTap: () => _go(context, const NamazTrackerPage()),
    ),
  ];

  // ══════════════════════════════════════════════════════════
  // আমল
  // ══════════════════════════════════════════════════════════
  List<FeatureItem> _amolItems(BuildContext context) => [
    FeatureItem(
      emoji: '⏰',
      label: 'নামাযের\nসময়',
      onTap: () => _go(context, const PrayerTimesCalendarPage()),
    ),
    FeatureItem(
      emoji: '📖',
      label: 'তিলাওয়াত',
      onTap: () => _go(context, const SurahListPage()),
    ),
    FeatureItem(
      emoji: '🤲',
      label: 'দু\'আ',
      onTap: () => _tab(context, AppRoute.dowa),
    ),
    FeatureItem(
      emoji: '📿',
      label: 'তাসবীহ',
      onTap: () => _go(context, TasbihCounter()),
    ),
    FeatureItem(
      emoji: '📋',
      label: 'আমল ট্রাকার',
      onTap: () =>
          _soon(context, 'আমল ট্রাকার', '📋', 'প্রতিদিনের আমল ট্র্যাক করুন'),
    ),
    FeatureItem(
      emoji: '🕋',
      label: 'হজ্জ ও উমরা',
      onTap: () => _go(context, RamadanCalendarPage()),
    ),
  ];

  // ══════════════════════════════════════════════════════════
  // সেবা
  // ══════════════════════════════════════════════════════════
  List<FeatureItem> _sebaItems(BuildContext context) => [
    FeatureItem(
      emoji: '💰',
      label: 'যাকাত\nফিতরা',
      onTap: () => _soon(
        context,
        'যাকাত ও ফিতরা',
        '💰',
        'যাকাত ও ফিতরার পরিমাণ হিসাব করুন',
      ),
    ),
    FeatureItem(
      emoji: '📦',
      label: 'বিনিয়োগ',
      onTap: () => _soon(
        context,
        'ইসলামিক বিনিয়োগ',
        '📦',
        'হালাল বিনিয়োগের তথ্য ও পরামর্শ',
      ),
    ),
    FeatureItem(
      emoji: '📞',
      label: 'দীনি জিজ্ঞাসা',
      onTap: () => _soon(
        context,
        'দীনি জিজ্ঞাসা',
        '📞',
        'আলেমদের কাছে দীনি প্রশ্ন করুন',
      ),
    ),
    FeatureItem(
      emoji: '🧩',
      label: 'কুইজ',
      imageUrl:
          'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamic_Quiz/quiz.webp',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WebViewPage(
            url: 'https://www.iqcbd.org/',
            title: 'ইসলামিক কুইজ',
          ),
        ),
      ),
    ),
    FeatureItem(
      emoji: '💑',
      label: 'বিবাহ',
      onTap: () =>
          _soon(context, 'ইসলামিক বিবাহ', '💑', 'ইসলামিক বিবাহ সংক্রান্ত তথ্য'),
    ),
    FeatureItem(
      emoji: '🛒',
      label: 'কেনাকাটা',
      onTap: () =>
          _soon(context, 'হালাল কেনাকাটা', '🛒', 'হালাল পণ্য ও সেবার তালিকা'),
    ),
    FeatureItem(
      emoji: '📰',
      label: 'চাকরি',
      onTap: () =>
          _soon(context, 'ইসলামিক চাকরি', '📰', 'হালাল চাকরির বিজ্ঞপ্তি'),
    ),
    FeatureItem(
      emoji: '💬',
      label: 'সাপোর্ট',
      onTap: () => _soon(context, 'সাপোর্ট', '💬', 'আমাদের সাথে যোগাযোগ করুন'),
    ),
  ];

  // ══════════════════════════════════════════════════════════
  // বিবিধ
  // ══════════════════════════════════════════════════════════
  List<FeatureItem> _bibidhoItems(BuildContext context) => [
    FeatureItem(
      emoji: '🧭',
      label: 'কিবলা',
      onTap: () => _go(context, const QiblaDirectionPage()),
    ),
    FeatureItem(
      emoji: '📍',
      label: 'মসজিদ খুঁজি',
      onTap: () => _findMosque(context),
    ),
    FeatureItem(
      emoji: '🕌',
      label: 'আমার\nমসজিদ',
      onTap: () =>
          _soon(context, 'আমার মসজিদ', '🕌', 'আপনার মসজিদের তথ্য ও সময়সূচি'),
    ),
    FeatureItem(
      emoji: '✨',
      label: 'আসমাউল\nহুসনা',
      onTap: () => _go(context, const AsmaulHusnaPage()),
    ),
    FeatureItem(
      emoji: '📺',
      label: 'লাইভ',
      onTap: () => _go(context, const RadioScreen()),
    ),
    FeatureItem(
      emoji: '🌙',
      label: 'রোযা',
      onTap: () => _go(context, RamadanCalendarPage()),
    ),
    FeatureItem(
      emoji: '🌿',
      label: 'সুন্নাহ',
      onTap: () => _soon(
        context,
        'সুন্নাহ',
        '🌿',
        'নবীজির (সা.) সুন্নাহ ও আদর্শ জীবনযাপন',
      ),
    ),
    FeatureItem(
      emoji: '👶',
      label: 'ইসলামিক\nনাম',
      onTap: () => _go(context, const IslamicNamesPage()),
    ),
    FeatureItem(
      emoji: '📅',
      label: 'ক্যালেন্ডার',
      onTap: () => _go(context, PrayerTimesCalendarPage()),
    ),
    FeatureItem(
      emoji: '⭐',
      label: 'গুরুত্বপূর্ণ\nদিন',
      onTap: () => _soon(
        context,
        'গুরুত্বপূর্ণ দিন',
        '⭐',
        'ইসলামিক গুরুত্বপূর্ণ দিন ও তারিখ',
      ),
    ),
    FeatureItem(
      emoji: '🔖',
      label: 'বুকমার্ক',
      onTap: () =>
          _soon(context, 'বুকমার্ক', '🔖', 'আপনার সেভ করা আয়াত ও দু\'আ'),
    ),
    FeatureItem(
      emoji: '⚙️',
      label: 'অন্যান্য',
      onTap: () => _soon(context, 'অন্যান্য', '⚙️', 'আরও ফিচার শীঘ্রই যোগ হবে'),
    ),
  ];
}
