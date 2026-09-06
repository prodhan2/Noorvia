import 'package:flutter/material.dart' hide Text;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:noorvia/core/localization/app_i18n.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/local_store.dart';
import '../../core/models/hadith_record.dart';
import '../../core/services/hadith_service.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/quran/quran_goal_service.dart';
import '../../core/quran/daily_ayah_service.dart';
import '../../core/quran/quran_surah_meta.dart';
import '../../core/services/open_meteo_service.dart';
import '../../core/theme/app_theme.dart';
import '../IslamicFeatures/namaz_tracker_page.dart';
import '../IslamicFeatures/hidithdemo.dart';
import '../quran/quran_goals_page.dart';
import '../quran/quran_search_page.dart';
import '../quran/quran_screen.dart';
import '../quran/surah_detail_page.dart';

class DailyCompanionPage extends StatefulWidget {
  const DailyCompanionPage({super.key});

  @override
  State<DailyCompanionPage> createState() => _DailyCompanionPageState();
}

class _DailyCompanionPageState extends State<DailyCompanionPage> {
  NoorviaWeather? _weather;
  QuranGoalPlan? _goal;
  DailyAyah? _dailyAyah;
  HadithRecord? _dailyHadith;
  int _completedSalah = 0;
  bool _loadingExtras = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtras());
  }

  Future<void> _loadExtras() async {
    final prayer = context.read<PrayerProvider>();
    final lat = prayer.latitude ?? 23.8103;
    final lon = prayer.longitude ?? 90.4125;
    final weatherFuture = OpenMeteoService.instance.current(latitude: lat, longitude: lon);
    final goalFuture = QuranGoalService.instance.load();
    final salahFuture = _loadTodaySalah();
    final ayahFuture = _loadDailyAyah();
    final hadithFuture = _loadDailyHadith();
    final values = await Future.wait([
      weatherFuture,
      goalFuture,
      salahFuture,
      ayahFuture,
      hadithFuture,
    ]);
    if (!mounted) return;
    setState(() {
      _weather = values[0] as NoorviaWeather?;
      _goal = values[1] as QuranGoalPlan;
      _completedSalah = values[2] as int;
      _dailyAyah = values[3] as DailyAyah?;
      _dailyHadith = values[4] as HadithRecord?;
      _loadingExtras = false;
    });
  }

  Future<DailyAyah?> _loadDailyAyah() async {
    try {
      return await DailyAyahService.instance.today();
    } catch (_) {
      return null;
    }
  }

  Future<HadithRecord?> _loadDailyHadith() async {
    try {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
      final number = ((dayOfYear - 1) % 40) + 1;
      return await HadithService().loadOne(
        bookKey: 'nawawi',
        number: number,
        english: AppI18n.isEnglish(context),
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> _loadTodaySalah() async {
    final data = await LocalStore.instance.getJson('namaz_tracker', 'all');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = data?['records'];
    if (rows is! List) return 0;
    for (final raw in rows.whereType<Map>()) {
      if (raw['date']?.toString() != today) continue;
      final prayers = raw['prayers'];
      if (prayers is! Map) return 0;
      // PrayerStatus.completed is index 1 in Namaz Tracker.
      return prayers.values.where((value) => (value as num?)?.toInt() == 1).length;
    }
    return 0;
  }

  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkBg : const Color(0xFFF3F0E8);
    final card = dark ? AppColors.darkCard : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Noorvia Today'),
        actions: [
          IconButton(
            onPressed: _loadExtras,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'রিফ্রেশ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await prayer.requestLocationAndFetch();
          await _loadExtras();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF073E28), Color(0xFF16764A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${prayer.cityName} • ${prayer.hijriDate?.day ?? ''} ${prayer.hijriDate?.month ?? ''} ${prayer.hijriDate?.year ?? ''}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    prayer.nextPrayer.isEmpty ? 'পরবর্তী নামাজ' : prayer.nextPrayer,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    prayer.nextPrayerTime.isEmpty ? '--:--' : prayer.nextPrayerTime,
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(prayer.timeRemaining, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: prayer.prayerProgress.clamp(0, 1),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MetricCard(color: card, icon: '🕌', value: '$_completedSalah/5', label: 'আজকের নামাজ')),
                const SizedBox(width: 8),
                Expanded(child: _MetricCard(color: card, icon: '📖', value: _goal == null ? '—' : '${(_goal!.progress * 100).toStringAsFixed(0)}%', label: 'খতম অগ্রগতি')),
                const SizedBox(width: 8),
                Expanded(child: _MetricCard(color: card, icon: '🌙', value: prayer.hijriDate?.day.toString() ?? '—', label: 'হিজরি দিন')),
              ],
            ),
            const SizedBox(height: 12),
            _WeatherCard(color: card, weather: _weather, loading: _loadingExtras),
            const SizedBox(height: 12),
            if (_dailyAyah != null) ...[
              _DailyAyahCard(
                color: card,
                item: _dailyAyah!,
                onTap: () {
                  final meta = quranSurahs[
                    (_dailyAyah!.surahNumber - 1).clamp(0, 113).toInt()
                  ];
                  _go(
                    SurahDetailPage(
                      surahName: meta.banglaName,
                      arabicName: meta.arabicName,
                      surahNumber: _dailyAyah!.surahNumber,
                      ayatCount: meta.ayahCount,
                      type: '',
                      initialAyah: _dailyAyah!.ayah.numberInSurah,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (_dailyHadith != null) ...[
              _DailyHadithCard(
                color: card,
                item: _dailyHadith!,
                onTap: () => _go(const HadithDemoPage(initialBook: 'nawawi')),
              ),
              const SizedBox(height: 12),
            ],
            _Panel(
              color: card,
              title: 'আজকের কুরআন',
              child: Column(
                children: [
                  if (_goal != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
                      title: Text('দৈনিক লক্ষ্য: ${_goal!.dailyTargetPages} পৃষ্ঠা'),
                      subtitle: Text('বর্তমান পৃষ্ঠা ${_goal!.currentPage} • বাকি ${_goal!.pagesRemaining} পৃষ্ঠা'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => _go(const QuranGoalsPage()),
                    ),
                  Row(
                    children: [
                      Expanded(child: FilledButton.icon(onPressed: () => _go(const QuranScreen()), icon: const Icon(Icons.auto_stories_rounded), label: const Text('কুরআন পড়ুন'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(onPressed: () => _go(const QuranSearchPage()), icon: const Icon(Icons.search_rounded), label: const Text('আয়াত খুঁজুন'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Panel(
              color: card,
              title: 'আজকের আমল',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.check_circle_outline_rounded)),
                    title: const Text('নামাজ ট্র্যাকার'),
                    subtitle: Text('আজ $_completedSalahটি নামাজ সম্পন্ন হিসেবে চিহ্নিত'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _go(const NamazTrackerPage()),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(Icons.shield_moon_outlined)),
                    title: Text('Smart Salah Mode'),
                    subtitle: Text('নামাজের সময় ও মসজিদের অবস্থান অনুযায়ী ফোন mode স্বয়ংক্রিয়ভাবে নিয়ন্ত্রণ করুন'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyHadithCard extends StatelessWidget {
  const _DailyHadithCard({
    required this.color,
    required this.item,
    required this.onTap,
  });

  final Color color;
  final HadithRecord item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'আজকের হাদিস',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    Text(
                      '#${item.number}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.text,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.55),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.bookName,
                        style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                      ),
                    ),
                    const Text(
                      'হাদিস লাইব্রেরি →',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _DailyAyahCard extends StatelessWidget {
  const _DailyAyahCard({
    required this.color,
    required this.item,
    required this.onTap,
  });

  final Color color;
  final DailyAyah item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final english = AppI18n.isEnglish(context);
    final translation = english ? item.ayah.english : item.ayah.bangla;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'আজকের আয়াত',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  Text(
                    '${item.englishName} ${item.surahNumber}:${item.ayah.numberInSurah}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Quran Arabic and verified translation deliberately bypass
              // Noorvia's UI translation wrapper.
              SelectableText(
                item.ayah.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 25, height: 1.9, fontWeight: FontWeight.w500),
              ),
              if (translation.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  translation,
                  style: const TextStyle(fontSize: 13.5, height: 1.55),
                ),
              ],
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('আয়াতটি খুলুন →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.color, required this.icon, required this.value, required this.label});
  final Color color;
  final String icon, value, label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(17)),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 21)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          ],
        ),
      );
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.color, required this.weather, required this.loading});
  final Color color;
  final NoorviaWeather? weather;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final w = weather;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: loading && w == null
          ? const LinearProgressIndicator()
          : w == null
              ? const Row(children: [Icon(Icons.cloud_off_rounded), SizedBox(width: 10), Expanded(child: Text('আবহাওয়ার তথ্য এখন পাওয়া যাচ্ছে না'))])
              : Row(
                  children: [
                    Text(w.emoji, style: const TextStyle(fontSize: 38)),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${w.temperature.toStringAsFixed(0)}°C • ${w.condition}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('অনুভূত ${w.feelsLike.toStringAsFixed(0)}° • আর্দ্রতা ${w.humidity}% • বৃষ্টি ${w.precipitation.toStringAsFixed(1)} mm', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.title, required this.child});
  final Color color;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );
}
