import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class RuqyahDetoxMetadata {
  final String title;
  final String subtitle;
  final String disclaimer;

  const RuqyahDetoxMetadata({
    required this.title,
    required this.subtitle,
    required this.disclaimer,
  });

  factory RuqyahDetoxMetadata.fromJson(Map<String, dynamic> json) {
    return RuqyahDetoxMetadata(
      title: json['title']?.toString() ?? 'ডিটক্স রুকইয়াহ',
      subtitle: json['subtitle']?.toString() ?? '৭ দিনের ডিটক্স রুকইয়াহ প্রোগ্রাম',
      disclaimer: json['disclaimer']?.toString() ?? '',
    );
  }
}

class RuqyahDetoxChapter {
  final int id;
  final int chapterNo;
  final String dayLabel;
  final String title;
  final String subtitle;
  final Map<String, dynamic> raw;

  const RuqyahDetoxChapter({
    required this.id,
    required this.chapterNo,
    required this.dayLabel,
    required this.title,
    required this.subtitle,
    required this.raw,
  });

  factory RuqyahDetoxChapter.fromJson(Map<String, dynamic> json) {
    return RuqyahDetoxChapter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chapterNo: (json['chapter_no'] as num?)?.toInt() ?? 0,
      dayLabel: json['day_label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      raw: json,
    );
  }

  String get preview {
    for (final key in ['content', 'intro', 'closing_note', 'closing_dua']) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    for (final key in ['experiences', 'final_notes', 'faq']) {
      final value = raw[key];
      if (value is List && value.isNotEmpty) return value.first.toString();
    }
    final items = raw['items'];
    if (items is List && items.isNotEmpty && items.first is Map) {
      return (items.first as Map)['name']?.toString() ?? subtitle;
    }
    return subtitle;
  }
}

class RuqyahDetoxPage extends StatefulWidget {
  const RuqyahDetoxPage({super.key});

  @override
  State<RuqyahDetoxPage> createState() => _RuqyahDetoxPageState();
}

class _RuqyahDetoxPageState extends State<RuqyahDetoxPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/detox_ruqyah.json';
  static const _cacheKey = 'ruqyah_detox_cache';

  RuqyahDetoxMetadata? _metadata;
  List<RuqyahDetoxChapter> _chapters = [];
  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetox();
  }

  Future<void> _fetchDetox() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) _parseAndSet(cached, fromCache: true);

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        await prefs.setString(_cacheKey, raw);
        _parseAndSet(raw, fromCache: false);
      } else if (_chapters.isEmpty) {
        setState(() {
          _error = 'সার্ভার থেকে ডেটা আনা যায়নি (${response.statusCode})';
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    } catch (_) {
      if (_chapters.isEmpty) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন';
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final chapters = (data['chapters'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RuqyahDetoxChapter.fromJson)
          .where((chapter) => chapter.title.isNotEmpty)
          .toList();

      setState(() {
        _metadata = RuqyahDetoxMetadata.fromJson(
          data['metadata'] as Map<String, dynamic>? ?? {},
        );
        _chapters = chapters;
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) {
        setState(() {
          _error = 'ডেটা পড়তে সমস্যা হয়েছে';
          _loading = false;
        });
      }
    }
  }

  void _openChapter(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetoxDetailPage(
          chapters: _chapters,
          initialIndex: index,
          metadata: _metadata,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ডিটক্স রুকইয়াহ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              '৭ দিনের ডিটক্স রুকইয়াহ প্রোগ্রাম',
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _fetchDetox,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _DetoxErrorWidget(message: _error!, onRetry: _fetchDetox)
              : Column(
                  children: [
                    if (_offline) const _OfflineBanner(),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchDetox,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          children: [
                            _DetoxHeaderCard(
                              metadata: _metadata,
                              totalChapters: _chapters.length,
                              textColor: textColor,
                              subColor: subColor,
                              cardColor: cardColor,
                            ),
                            const SizedBox(height: 14),
                            if ((_metadata?.disclaimer ?? '').isNotEmpty) ...[
                              _InfoBox(
                                icon: Icons.health_and_safety_outlined,
                                title: 'গুরুত্বপূর্ণ সতর্কতা',
                                text: _metadata!.disclaimer,
                                color: const Color(0xFFF59E0B),
                                textColor: textColor,
                                cardColor: cardColor,
                              ),
                              const SizedBox(height: 14),
                            ],
                            Text(
                              'অধ্যায়সমূহ',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._chapters.asMap().entries.map((entry) {
                              return _DetoxChapterCard(
                                chapter: entry.value,
                                index: entry.key,
                                cardColor: cardColor,
                                textColor: textColor,
                                subColor: subColor,
                                onTap: () => _openChapter(entry.key),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DetoxDetailPage extends StatefulWidget {
  final List<RuqyahDetoxChapter> chapters;
  final int initialIndex;
  final RuqyahDetoxMetadata? metadata;

  const _DetoxDetailPage({
    required this.chapters,
    required this.initialIndex,
    required this.metadata,
  });

  @override
  State<_DetoxDetailPage> createState() => _DetoxDetailPageState();
}

class _DetoxDetailPageState extends State<_DetoxDetailPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  RuqyahDetoxChapter get _chapter => widget.chapters[_currentIndex];

  void _goToPrevious() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _goToNext() {
    if (_currentIndex < widget.chapters.length - 1) setState(() => _currentIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ডিটক্স রুকইয়াহ',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.chapters.length}',
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _chapter.dayLabel.isNotEmpty
                          ? _chapter.dayLabel
                          : 'অধ্যায় #${_chapter.chapterNo}',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _chapter.title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  if (_chapter.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _chapter.subtitle,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _ChapterBody(
                chapter: _chapter,
                cardColor: cardColor,
                textColor: textColor,
                subColor: subColor,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: _NavButton(
                  label: 'আগে',
                  icon: Icons.arrow_back_ios_rounded,
                  enabled: _currentIndex > 0,
                  reverse: true,
                  onTap: _goToPrevious,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavButton(
                  label: 'পরে',
                  icon: Icons.arrow_forward_ios_rounded,
                  enabled: _currentIndex < widget.chapters.length - 1,
                  reverse: false,
                  onTap: _goToNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterBody extends StatelessWidget {
  final RuqyahDetoxChapter chapter;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _ChapterBody({
    required this.chapter,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final raw = chapter.raw;
    final widgets = <Widget>[];

    _addTextSection(widgets, 'বিস্তারিত', raw['content']);
    _addListSection(widgets, 'প্রশ্ন ও উত্তর', raw['faq'], Icons.help_outline_rounded);
    _addItemsSection(widgets, raw['items']);
    _addTextSection(widgets, 'প্রস্তুতি', raw['intro']);
    _addRecitationsSection(widgets, raw['recitations']);
    _addRoutineSection(widgets, raw['routine'], raw['routine_days']);
    _addListSection(widgets, 'সম্ভাব্য অভিজ্ঞতা', raw['experiences'], Icons.auto_awesome_rounded);
    _addListSection(widgets, 'শেষ কথা', raw['final_notes'], Icons.notes_rounded);
    _addTextSection(widgets, 'শেষ দোয়া', raw['closing_dua']);
    _addTextSection(widgets, 'নোট', raw['closing_note']);

    if (widgets.isEmpty) {
      widgets.add(_TextCard(
        title: 'বিস্তারিত',
        text: chapter.preview,
        icon: Icons.info_outline_rounded,
        cardColor: cardColor,
        textColor: textColor,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widgets.length; i++) ...[
          widgets[i],
          if (i != widgets.length - 1) const SizedBox(height: 16),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  void _addTextSection(List<Widget> widgets, String title, dynamic value) {
    if (value is! String || value.trim().isEmpty) return;
    widgets.add(_TextCard(
      title: title,
      text: value.trim(),
      icon: Icons.info_outline_rounded,
      cardColor: cardColor,
      textColor: textColor,
    ));
  }

  void _addListSection(
    List<Widget> widgets,
    String title,
    dynamic value,
    IconData icon,
  ) {
    if (value is! List || value.isEmpty) return;
    widgets.add(_BulletCard(
      title: title,
      items: value.map((item) => item.toString()).toList(),
      icon: icon,
      cardColor: cardColor,
      textColor: textColor,
    ));
  }

  void _addItemsSection(List<Widget> widgets, dynamic value) {
    if (value is! List || value.isEmpty) return;
    widgets.add(_StructuredCard(
      title: 'প্রয়োজনীয় উপাদান',
      icon: Icons.inventory_2_outlined,
      cardColor: cardColor,
      textColor: textColor,
      subColor: subColor,
      children: value.whereType<Map<String, dynamic>>().map((item) {
        final details = item['details'];
        return _NamedBlock(
          title: item['name']?.toString() ?? '',
          subtitle: item['amount']?.toString() ?? '',
          details: details is List ? details.map((d) => d.toString()).toList() : const [],
          textColor: textColor,
          subColor: subColor,
        );
      }).toList(),
    ));
  }

  void _addRecitationsSection(List<Widget> widgets, dynamic value) {
    if (value is! List || value.isEmpty) return;
    widgets.add(_StructuredCard(
      title: 'তিলাওয়াত',
      icon: Icons.menu_book_rounded,
      cardColor: cardColor,
      textColor: textColor,
      subColor: subColor,
      children: value.whereType<Map<String, dynamic>>().map((item) {
        return _RecitationBlock(
          data: item,
          textColor: textColor,
          subColor: subColor,
        );
      }).toList(),
    ));
  }

  void _addRoutineSection(List<Widget> widgets, dynamic value, dynamic routineDays) {
    if (value is! Map<String, dynamic>) return;
    widgets.add(_StructuredCard(
      title: routineDays is String && routineDays.isNotEmpty
          ? 'রুটিন: $routineDays'
          : 'রুটিন',
      icon: Icons.checklist_rounded,
      cardColor: cardColor,
      textColor: textColor,
      subColor: subColor,
      children: [
        _RoutineBlock(title: 'রাতে', items: value['night'], textColor: textColor),
        _RoutineBlock(title: 'সকালে', items: value['morning'], textColor: textColor),
        _RoutineBlock(title: 'অন্যান্য সময়', items: value['other_times'], textColor: textColor),
      ],
    ));
  }
}

class _DetoxHeaderCard extends StatelessWidget {
  final RuqyahDetoxMetadata? metadata;
  final int totalChapters;
  final Color textColor;
  final Color subColor;
  final Color cardColor;

  const _DetoxHeaderCard({
    required this.metadata,
    required this.totalChapters,
    required this.textColor,
    required this.subColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata?.title ?? 'ডিটক্স রুকইয়াহ',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metadata?.subtitle ?? '৭ দিনের ডিটক্স রুকইয়াহ প্রোগ্রাম',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalChapters টি অধ্যায়',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetoxChapterCard extends StatelessWidget {
  final RuqyahDetoxChapter chapter;
  final int index;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _DetoxChapterCard({
    required this.chapter,
    required this.index,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.preview.replaceAll('\n', ' '),
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: subColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color textColor;
  final Color cardColor;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: textColor,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color cardColor;
  final Color textColor;

  const _TextCard({
    required this.title,
    required this.text,
    required this.icon,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return _StructuredCard(
      title: title,
      icon: icon,
      cardColor: cardColor,
      textColor: textColor,
      subColor: textColor,
      children: [
        Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: textColor,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class _BulletCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color cardColor;
  final Color textColor;

  const _BulletCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return _StructuredCard(
      title: title,
      icon: icon,
      cardColor: cardColor,
      textColor: textColor,
      subColor: textColor,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _BulletLine(text: item, textColor: textColor),
        );
      }).toList(),
    );
  }
}

class _StructuredCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final List<Widget> children;

  const _StructuredCard({
    required this.title,
    required this.icon,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _NamedBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> details;
  final Color textColor;
  final Color subColor;

  const _NamedBlock({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _BulletLine(text: detail, textColor: subColor),
              )),
        ],
      ),
    );
  }
}

class _RecitationBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color textColor;
  final Color subColor;

  const _RecitationBlock({
    required this.data,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final duas = data['duas'];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title']?.toString() ?? '',
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if ((data['repeat']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data['repeat'].toString(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
          if ((data['arabic']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                data['arabic'].toString(),
                textAlign: TextAlign.right,
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 22,
                  color: textColor,
                  height: 1.9,
                ),
              ),
            ),
          ],
          if (duas is List && duas.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...duas.map((dua) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      dua.toString(),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.scheherazadeNew(
                        fontSize: 21,
                        color: textColor,
                        height: 1.8,
                      ),
                    ),
                  ),
                )),
          ],
          if ((data['note']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              data['note'].toString(),
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: subColor,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineBlock extends StatelessWidget {
  final String title;
  final dynamic items;
  final Color textColor;

  const _RoutineBlock({
    required this.title,
    required this.items,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items is! List || (items as List).isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ...(items as List).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BulletLine(text: item.toString(), textColor: textColor),
              )),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color textColor;

  const _BulletLine({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 9),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: textColor,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool reverse;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.reverse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon(
        icon,
        size: 16,
        color: enabled ? (reverse ? AppColors.primary : Colors.white) : Colors.grey.withValues(alpha: 0.5),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: enabled ? (reverse ? AppColors.primary : Colors.white) : Colors.grey.withValues(alpha: 0.5),
        ),
      ),
    ];

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: enabled && !reverse ? AppColors.gradient : null,
          color: enabled && reverse
              ? AppColors.primary.withValues(alpha: 0.1)
              : enabled
                  ? null
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: reverse ? content : content.reversed.toList(),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'অফলাইন মোড - সংরক্ষিত ডেটা দেখাচ্ছে',
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetoxErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetoxErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.hindSiliguri(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('আবার চেষ্টা করুন', style: GoogleFonts.hindSiliguri()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
