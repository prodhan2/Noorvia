import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> surahs = [
    {'number': '১', 'name': 'আল-ফাতিহা', 'arabic': 'الفاتحة', 'ayat': '৭ আয়াত', 'type': 'মাক্কী'},
    {'number': '২', 'name': 'আল-বাকারা', 'arabic': 'البقرة', 'ayat': '২৮৬ আয়াত', 'type': 'মাদানী'},
    {'number': '৩', 'name': 'আলে-ইমরান', 'arabic': 'آل عمران', 'ayat': '২০০ আয়াত', 'type': 'মাদানী'},
    {'number': '৪', 'name': 'আন-নিসা', 'arabic': 'النساء', 'ayat': '১৭৬ আয়াত', 'type': 'মাদানী'},
    {'number': '৫', 'name': 'আল-মায়িদা', 'arabic': 'المائدة', 'ayat': '১২০ আয়াত', 'type': 'মাদানী'},
    {'number': '৬', 'name': 'আল-আনআম', 'arabic': 'الأنعام', 'ayat': '১৬৫ আয়াত', 'type': 'মাক্কী'},
    {'number': '৭', 'name': 'আল-আরাফ', 'arabic': 'الأعراف', 'ayat': '২০৬ আয়াত', 'type': 'মাক্কী'},
    {'number': '৮', 'name': 'আল-আনফাল', 'arabic': 'الأنفال', 'ayat': '৭৫ আয়াত', 'type': 'মাদানী'},
    {'number': '৯', 'name': 'আত-তাওবা', 'arabic': 'التوبة', 'ayat': '১২৯ আয়াত', 'type': 'মাদানী'},
    {'number': '১০', 'name': 'ইউনুস', 'arabic': 'يونس', 'ayat': '১০৯ আয়াত', 'type': 'মাক্কী'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
                ],
              ),
              child: TextField(
                style: GoogleFonts.hindSiliguri(color: textColor),
                decoration: InputDecoration(
                  hintText: 'সূরা খুঁজুন...',
                  hintStyle: GoogleFonts.hindSiliguri(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.primary,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'সূরা'),
                Tab(text: 'পারা'),
                Tab(text: 'পৃষ্ঠা'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurahList(isDark, textColor, cardColor),
                _buildParaList(isDark, textColor, cardColor),
                _buildPageList(isDark, textColor, cardColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(bool isDark, Color textColor, Color cardColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  surah['number']!,
                  style: GoogleFonts.hindSiliguri(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(
              surah['name']!,
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${surah['ayat']} • ${surah['type']}',
              style: GoogleFonts.hindSiliguri(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              surah['arabic']!,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.primary,
                fontFamily: 'serif',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParaList(bool isDark, Color textColor, Color cardColor) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final banglaNumbers = ['১','২','৩','৪','৫','৬','৭','৮','৯','১০',
          '১১','১২','১৩','১৪','১৫','১৬','১৭','১৮','১৯','২০',
          '২১','২২','২৩','২৪','২৫','২৬','২৭','২৮','২৯','৩০'];
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Center(
            child: Text(
              banglaNumbers[index],
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageList(bool isDark, Color textColor, Color cardColor) {
    return Center(
      child: Text(
        'পৃষ্ঠা তালিকা',
        style: GoogleFonts.hindSiliguri(color: textColor, fontSize: 18),
      ),
    );
  }
}
