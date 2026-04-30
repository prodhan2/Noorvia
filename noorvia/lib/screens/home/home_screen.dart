import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/nav_provider.dart';
import '../../core/providers/prayer_provider.dart';
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
import '../common/coming_soon_page.dart';
import '../../widgets/shimmer.dart';
import 'widgets/section_header.dart';
import 'widgets/feature_grid_item.dart';
import 'widgets/prayer_card.dart';
import 'widgets/banner_card.dart';
import 'widgets/donation_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── push a full-screen page ──────────────────────────────
  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ── coming soon shortcut ─────────────────────────────────
  void _soon(BuildContext context, String title, String emoji,
      [String? desc]) {
    _go(context, ComingSoonPage(title: title, emoji: emoji, description: desc));
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
            _buildDateCard(context, isDark),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PrayerCard(isDark: isDark),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BannerCard(isDark: isDark),
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
                  title: 'বিবিধ', color: AppColors.bibidhoColor),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildGrid(_bibidhoItems(context), isDark),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const DonationCard(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Date card — real Hijri + Bangla date from AlAdhan API ──
  Widget _buildDateCard(BuildContext context, bool isDark) {
    final prayer = context.watch<PrayerProvider>();
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Hijri date — bold, large
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: prayer.hijriDisplayDate.isNotEmpty
                    ? Text(
                        prayer.hijriDisplayDate,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : NShimmer(width: 220, height: 20, isDark: isDark),
              ),
              const SizedBox(width: 6),
              const Text('🌙', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          // Bangla date — smaller, grey
          prayer.banglaDate.isNotEmpty
              ? Text(
                  prayer.banglaDate,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: subColor,
                  ),
                  textAlign: TextAlign.center,
                )
              : NShimmer(width: 260, height: 13, isDark: isDark),
        ],
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
          onTap: () => _go(context, const ChapterListPage()),
        ),
        FeatureItem(
          emoji: '📜',
          label: 'হাদীস',
          onTap: () => _go(context, HadithDemoPage()),
        ),
        FeatureItem(
          emoji: '📝',
          label: 'প্রবন্ধ',
          onTap: () => _soon(context, 'প্রবন্ধ', '📝',
              'ইসলামিক প্রবন্ধ ও নিবন্ধ পড়ুন'),
        ),
        FeatureItem(
          emoji: '🎙️',
          label: 'বয়ান',
          onTap: () => _go(context, const RadioScreen()),
        ),
        FeatureItem(
          emoji: '🎓',
          label: 'কুরআন\nশিক্ষা',
          onTap: () => _go(context, const SurahListPage()),
        ),
        FeatureItem(
          emoji: '🕌',
          label: 'নামায শিক্ষা',
          onTap: () => _go(context, const ChapterListPage()),
        ),
      ];

  // ══════════════════════════════════════════════════════════
  // আমল
  // ══════════════════════════════════════════════════════════
  List<FeatureItem> _amolItems(BuildContext context) => [
        FeatureItem(
          emoji: '⏰',
          label: 'নামাযের\nসময়',
          onTap: () => _soon(context, 'নামাযের সময়', '⏰',
              'আপনার এলাকার নামাজের সময়সূচি'),
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
          onTap: () => _soon(context, 'আমল ট্রাকার', '📋',
              'প্রতিদিনের আমল ট্র্যাক করুন'),
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
          onTap: () => _soon(context, 'যাকাত ও ফিতরা', '💰',
              'যাকাত ও ফিতরার পরিমাণ হিসাব করুন'),
        ),
        FeatureItem(
          emoji: '📦',
          label: 'বিনিয়োগ',
          onTap: () => _soon(context, 'ইসলামিক বিনিয়োগ', '📦',
              'হালাল বিনিয়োগের তথ্য ও পরামর্শ'),
        ),
        FeatureItem(
          emoji: '📞',
          label: 'দীনি জিজ্ঞাসা',
          onTap: () => _soon(context, 'দীনি জিজ্ঞাসা', '📞',
              'আলেমদের কাছে দীনি প্রশ্ন করুন'),
        ),
        FeatureItem(
          emoji: '🧩',
          label: 'কুইজ',
          onTap: () => _soon(context, 'ইসলামিক কুইজ', '🧩',
              'ইসলামিক জ্ঞান যাচাই করুন'),
        ),
        FeatureItem(
          emoji: '💑',
          label: 'বিবাহ',
          onTap: () => _soon(context, 'ইসলামিক বিবাহ', '💑',
              'ইসলামিক বিবাহ সংক্রান্ত তথ্য'),
        ),
        FeatureItem(
          emoji: '🛒',
          label: 'কেনাকাটা',
          onTap: () => _soon(context, 'হালাল কেনাকাটা', '🛒',
              'হালাল পণ্য ও সেবার তালিকা'),
        ),
        FeatureItem(
          emoji: '📰',
          label: 'চাকরি',
          onTap: () => _soon(context, 'ইসলামিক চাকরি', '📰',
              'হালাল চাকরির বিজ্ঞপ্তি'),
        ),
        FeatureItem(
          emoji: '💬',
          label: 'সাপোর্ট',
          onTap: () => _soon(context, 'সাপোর্ট', '💬',
              'আমাদের সাথে যোগাযোগ করুন'),
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
          onTap: () => _soon(context, 'মসজিদ খুঁজি', '📍',
              'কাছের মসজিদ খুঁজে নিন'),
        ),
        FeatureItem(
          emoji: '🕌',
          label: 'আমার\nমসজিদ',
          onTap: () => _soon(context, 'আমার মসজিদ', '🕌',
              'আপনার মসজিদের তথ্য ও সময়সূচি'),
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
          onTap: () => _soon(context, 'সুন্নাহ', '🌿',
              'নবীজির (সা.) সুন্নাহ ও আদর্শ জীবনযাপন'),
        ),
        FeatureItem(
          emoji: '👶',
          label: 'ইসলামিক\nনাম',
          onTap: () => _soon(context, 'ইসলামিক নাম', '👶',
              'সুন্দর ইসলামিক নাম ও অর্থ খুঁজুন'),
        ),
        FeatureItem(
          emoji: '📅',
          label: 'ক্যালেন্ডার',
          onTap: () => _go(context, const PrayerTimesCalendarPage()),
        ),
        FeatureItem(
          emoji: '⭐',
          label: 'গুরুত্বপূর্ণ\nদিন',
          onTap: () => _soon(context, 'গুরুত্বপূর্ণ দিন', '⭐',
              'ইসলামিক গুরুত্বপূর্ণ দিন ও তারিখ'),
        ),
        FeatureItem(
          emoji: '🔖',
          label: 'বুকমার্ক',
          onTap: () => _soon(context, 'বুকমার্ক', '🔖',
              'আপনার সেভ করা আয়াত ও দু\'আ'),
        ),
        FeatureItem(
          emoji: '⚙️',
          label: 'অন্যান্য',
          onTap: () => _soon(context, 'অন্যান্য', '⚙️',
              'আরও ফিচার শীঘ্রই যোগ হবে'),
        ),
      ];
}
