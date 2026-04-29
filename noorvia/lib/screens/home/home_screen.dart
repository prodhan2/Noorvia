import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/prayer_times.dart';
import 'widgets/section_header.dart';
import 'widgets/feature_grid_item.dart';
import 'widgets/prayer_card.dart';
import 'widgets/banner_card.dart';
import 'widgets/donation_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // Hijri date card
            _buildDateCard(context, isDark),
            const SizedBox(height: 8),

            // Prayer times card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PrayerCard(isDark: isDark),
            ),
            const SizedBox(height: 8),

            // Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BannerCard(isDark: isDark),
            ),
            const SizedBox(height: 16),

            // ইলম section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(
                title: 'ইলম',
                color: AppColors.ilomColor,
                onSearch: () {},
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildIlomGrid(context, isDark),
            ),
            const SizedBox(height: 16),

            // আমল section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(
                title: 'আমল',
                color: AppColors.amolColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildAmolGrid(context, isDark),
            ),
            const SizedBox(height: 16),

            // সেবা section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SectionHeader(
                title: 'সেবা',
                color: AppColors.sebaColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSebaGrid(context, isDark),
            ),
            const SizedBox(height: 16),

            // বিবিধ section
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
              child: _buildBibidhoGrid(context, isDark),
            ),
            const SizedBox(height: 16),

            // Donation card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DonationCard(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            PrayerTimesHelper.getHijriDate(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            PrayerTimesHelper.getBanglaCalDate(),
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIlomGrid(BuildContext context, bool isDark) {
    final items = [
      FeatureItem(emoji: '📖', label: 'কুরআন'),
      FeatureItem(emoji: '📚', label: 'কিতাব'),
      FeatureItem(emoji: '📜', label: 'হাদীস'),
      FeatureItem(emoji: '📝', label: 'প্রবন্ধ'),
      FeatureItem(emoji: '🎙️', label: 'বয়ান'),
      FeatureItem(emoji: '🎓', label: 'কুরআন\nশিক্ষা'),
      FeatureItem(emoji: '🕌', label: 'নামায শিক্ষা'),
    ];
    return _buildGrid(items, isDark);
  }

  Widget _buildAmolGrid(BuildContext context, bool isDark) {
    final items = [
      FeatureItem(emoji: '⏰', label: 'নামাযের\nসময়'),
      FeatureItem(emoji: '📖', label: 'তিলাওয়াত'),
      FeatureItem(emoji: '🤲', label: 'দু\'আ'),
      FeatureItem(emoji: '📿', label: 'তাসবীহ'),
      FeatureItem(emoji: '📋', label: 'আমল ট্রাকার'),
      FeatureItem(emoji: '🕋', label: 'হজ্জ ও উমরা'),
    ];
    return _buildGrid(items, isDark);
  }

  Widget _buildSebaGrid(BuildContext context, bool isDark) {
    final items = [
      FeatureItem(emoji: '💰', label: 'যাকাত\nফিতরা'),
      FeatureItem(emoji: '📦', label: 'বিনিয়োগ'),
      FeatureItem(emoji: '📞', label: 'দীনি জিজ্ঞাসা'),
      FeatureItem(emoji: '🧩', label: 'কুইজ'),
      FeatureItem(emoji: '💑', label: 'বিবাহ'),
      FeatureItem(emoji: '🛒', label: 'কেনাকাটা'),
      FeatureItem(emoji: '📰', label: 'চাকরি'),
      FeatureItem(emoji: '💬', label: 'সাপোর্ট'),
    ];
    return _buildGrid(items, isDark);
  }

  Widget _buildBibidhoGrid(BuildContext context, bool isDark) {
    final items = [
      FeatureItem(emoji: '🧭', label: 'কিবলা'),
      FeatureItem(emoji: '📍', label: 'মসজিদ খুঁজি'),
      FeatureItem(emoji: '🕌', label: 'আমার\nমসজিদ'),
      FeatureItem(emoji: '✨', label: 'আসমাউল\nহুসনা'),
      FeatureItem(emoji: '📺', label: 'লাইভ'),
      FeatureItem(emoji: '🌙', label: 'রোযা'),
      FeatureItem(emoji: '🌿', label: 'সুন্নাহ'),
      FeatureItem(emoji: '👶', label: 'ইসলামিক\nনাম'),
      FeatureItem(emoji: '📅', label: 'ক্যালেন্ডার'),
      FeatureItem(emoji: '⭐', label: 'গুরুত্বপূর্ণ\nদিন'),
      FeatureItem(emoji: '🔖', label: 'বুকমার্ক'),
      FeatureItem(emoji: '⚙️', label: 'অন্যান্য'),
    ];
    return _buildGrid(items, isDark);
  }

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
      itemBuilder: (context, index) {
        return FeatureGridItem(item: items[index], isDark: isDark);
      },
    );
  }
}
