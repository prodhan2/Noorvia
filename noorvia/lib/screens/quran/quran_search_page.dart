import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';

import '../../core/localization/app_i18n.dart';
import '../../core/quran/quran_search_repository.dart';
import '../../core/quran/quran_surah_meta.dart';
import '../../core/theme/app_theme.dart';
import 'surah_detail_page.dart';

class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final _controller = TextEditingController();
  List<QuranSearchResult> _results = const [];
  bool _loading = false;
  bool _offlineOnly = false;
  bool _searched = false;
  String _edition = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2 || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
    });
    final response = await QuranSearchRepository.instance.search(query);
    if (!mounted) return;
    setState(() {
      _results = response.results;
      _edition = response.edition;
      _offlineOnly = response.offlineOnly;
      _loading = false;
    });
  }

  void _open(QuranSearchResult result) {
    final meta = quranSurahs[(result.surahNumber - 1).clamp(0, 113).toInt()];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailPage(
          surahName: meta.banglaName,
          arabicName: meta.arabicName,
          surahNumber: result.surahNumber,
          ayatCount: meta.ayahCount,
          type: '',
          initialAyah: result.ayahNumber,
        ),
      ),
    );
  }

  String get _sourceLabel => switch (_edition) {
        'bn.bengali' => 'বাংলা অনুবাদ',
        'quran-uthmani' => 'আরবি কুরআন',
        _ => 'English — Saheeh International',
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkBg : const Color(0xFFF4F1E8);
    final card = dark ? AppColors.darkCard : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('কুরআন সার্চ')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: AppI18n.current('বাংলা, English বা আরবি শব্দ লিখুন...'),
                      prefixIcon: const Icon(Icons.manage_search_rounded),
                      suffixIcon: IconButton(
                        onPressed: _search,
                        icon: const Icon(Icons.search_rounded),
                      ),
                      filled: true,
                      fillColor: card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _edition.isEmpty
                              ? 'ভাষা অনুযায়ী নির্ভরযোগ্য Quran edition স্বয়ংক্রিয়ভাবে নির্বাচন হবে'
                              : 'সার্চ উৎস: $_sourceLabel${_offlineOnly ? ' • অফলাইন cache' : ''}',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !_searched
                      ? const _SearchIntro()
                      : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'কোনো আয়াত পাওয়া যায়নি',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 28),
                              itemCount: _results.length.clamp(0, 200),
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                return Material(
                                  color: card,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _open(result),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: .10),
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  '${result.surahNumber}:${result.ayahNumber}',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  result.englishName.isEmpty
                                                      ? result.surahName
                                                      : result.englishName,
                                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                                            ],
                                          ),
                                          const SizedBox(height: 9),
                                          Text(
                                            result.text,
                                            textDirection: result.edition == 'quran-uthmani'
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                            textAlign: result.edition == 'quran-uthmani'
                                                ? TextAlign.right
                                                : TextAlign.start,
                                            style: TextStyle(
                                              fontFamily: result.edition == 'quran-uthmani' ? 'NooreHuda' : null,
                                              fontSize: result.edition == 'quran-uthmani' ? 24 : 14,
                                              height: result.edition == 'quran-uthmani' ? 1.8 : 1.55,
                                            ),
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

class _SearchIntro extends StatelessWidget {
  const _SearchIntro();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore_rounded, size: 62, color: AppColors.primary),
              const SizedBox(height: 14),
              const Text('কুরআনের ভেতরে খুঁজুন', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(
                'বাংলা, English বা আরবি শব্দ লিখে সংশ্লিষ্ট আয়াত খুঁজুন। Internet না থাকলে আগে cache করা সূরাগুলোতেও search হবে।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.55),
              ),
            ],
          ),
        ),
      );
}
