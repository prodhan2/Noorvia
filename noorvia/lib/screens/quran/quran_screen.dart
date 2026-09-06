import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/local_store.dart';
import '../../core/localization/app_i18n.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/quran/quran_surah_meta.dart';
import '../../core/theme/app_theme.dart';
import 'mushaf_page.dart';
import 'quran_search_page.dart';
import 'quran_goals_page.dart';
import 'surah_detail_page.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _search = TextEditingController();
  List<QuranSurahMeta> _visible = quranSurahs;
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final data = await LocalStore.instance.getJson('quran_progress', 'last_read');
    if (!mounted) return;
    setState(() => _lastRead = data);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _visible = quranSurahs;
      } else {
        _visible = quranSurahs.where((s) {
          return s.number.toString() == q ||
              s.banglaName.toLowerCase().contains(q) ||
              s.englishName.toLowerCase().contains(q) ||
              s.arabicName.contains(value.trim());
        }).toList();
      }
    });
  }

  Future<void> _open(QuranSurahMeta surah, {int? ayah}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailPage(
          surahName: surah.banglaName,
          arabicName: surah.arabicName,
          surahNumber: surah.number,
          ayatCount: surah.ayahCount,
          type: '',
          initialAyah: ayah,
        ),
      ),
    );
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final language = context.watch<AppLanguageProvider>();
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF3F0E8);
    final card = isDark ? AppColors.darkCard : Colors.white;
    final text = isDark ? AppColors.darkText : const Color(0xFF183B2A);
    final sub = isDark ? AppColors.darkSubText : const Color(0xFF6B746F);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: _HeroHeader(
                  textColor: text,
                  subColor: sub,
                  onMushaf: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MushafPage()),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuranActionCard(
                        icon: Icons.manage_search_rounded,
                        title: 'কুরআন সার্চ',
                        subtitle: 'বাংলা • English • عربي',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuranSearchPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuranActionCard(
                        icon: Icons.track_changes_rounded,
                        title: 'খতম ও হিফজ',
                        subtitle: 'লক্ষ্য • অগ্রগতি',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuranGoalsPage()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_lastRead != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _ContinueCard(
                    color: card,
                    textColor: text,
                    subColor: sub,
                    progress: _lastRead!,
                    onTap: () {
                      final no = (_lastRead!['surahNumber'] as num?)?.toInt() ?? 1;
                      final ayah = (_lastRead!['ayahNumber'] as num?)?.toInt();
                      final surah = quranSurahs[(no - 1).clamp(0, 113).toInt()];
                      _open(surah, ayah: ayah);
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _search,
                  onChanged: _filter,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: AppI18n.current('সূরার নাম বা নম্বর দিয়ে খুঁজুন...'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              _filter('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: .12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: _visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final surah = _visible[index];
                  final displayName = language.isBangla
                      ? surah.banglaName
                      : surah.englishName;
                  return Material(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _open(surah),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            _SurahNumber(number: surah.number),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${surah.englishName}  •  ${surah.ayahCount} আয়াত',
                                    style: TextStyle(color: sub, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              surah.arabicName,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: text,
                                fontFamily: 'NooreHuda',
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: sub,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranActionCard extends StatelessWidget {
  const _QuranActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10.5), maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.textColor,
    required this.subColor,
    required this.onMushaf,
  });
  final Color textColor, subColor;
  final VoidCallback onMushaf;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A4A2D), Color(0xFF19754B)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পবিত্র কুরআন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'পড়ুন • শুনুন • অনুবাদ • অফলাইন',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: AppI18n.current('পেজ অনুযায়ী মুসহাফ পড়ুন'),
                  onPressed: onMushaf,
                  icon: const Icon(Icons.auto_stories_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NooreHuda',
                  fontSize: 23,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.color,
    required this.textColor,
    required this.subColor,
    required this.progress,
    required this.onTap,
  });
  final Color color, textColor, subColor;
  final Map<String, dynamic> progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surah = (progress['surahNumber'] as num?)?.toInt() ?? 1;
    final ayah = (progress['ayahNumber'] as num?)?.toInt() ?? 1;
    final meta = quranSurahs[(surah - 1).clamp(0, 113).toInt()];
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'যেখান থেকে পড়া শেষ করেছিলেন',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${meta.banglaName} • আয়াত $ayah',
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahNumber extends StatelessWidget {
  const _SurahNumber({required this.number});
  final int number;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: .785398,
              child: Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .45),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              '$number',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
