import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:muslim_view/core/localization/app_i18n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class HijamaContent {
  final HijamaSectionInfo section;
  final Map<String, dynamic> intro;
  final Map<String, dynamic> history;
  final Map<String, dynamic> nobobiTreatment;
  final Map<String, dynamic> benefits;
  final Map<String, dynamic> recommendedTime;
  final Map<String, dynamic> beforeHijama;
  final Map<String, dynamic> afterHijama;
  final Map<String, dynamic> avoidConditions;
  final Map<String, dynamic> therapyProcess;
  final Map<String, dynamic> hijamaPoints;
  final List<Map<String, dynamic>> specialTopics;
  final List<Map<String, dynamic>> faqs;
  final List<Map<String, dynamic>> hadiths;
  final List<String> references;

  const HijamaContent({
    required this.section,
    required this.intro,
    required this.history,
    required this.nobobiTreatment,
    required this.benefits,
    required this.recommendedTime,
    required this.beforeHijama,
    required this.afterHijama,
    required this.avoidConditions,
    required this.therapyProcess,
    required this.hijamaPoints,
    required this.specialTopics,
    required this.faqs,
    required this.hadiths,
    required this.references,
  });

  factory HijamaContent.fromJson(Map<String, dynamic> json) {
    return HijamaContent(
      section: HijamaSectionInfo.fromJson(_map(json['app_section'])),
      intro: _map(json['intro']),
      history: _map(json['history']),
      nobobiTreatment: _map(json['nobobi_treatment']),
      benefits: _map(json['benefits']),
      recommendedTime: _map(json['recommended_time']),
      beforeHijama: _map(json['before_hijama']),
      afterHijama: _map(json['after_hijama']),
      avoidConditions: _map(json['avoid_conditions']),
      therapyProcess: _map(json['therapy_process']),
      hijamaPoints: _map(json['hijama_points']),
      specialTopics: _mapList(json['special_topics']),
      faqs: _mapList(json['faq']),
      hadiths: _mapList(json['hadiths']),
      references: _stringList(json['references']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_map).where((item) => item.isNotEmpty).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class HijamaSectionInfo {
  final String title;
  final String subtitle;
  final String bannerImage;
  final Color themeColor;

  const HijamaSectionInfo({
    required this.title,
    required this.subtitle,
    required this.bannerImage,
    required this.themeColor,
  });

  factory HijamaSectionInfo.fromJson(Map<String, dynamic> json) {
    return HijamaSectionInfo(
      title: json['title']?.toString() ?? 'হিজামা',
      subtitle: json['subtitle']?.toString() ?? 'নববী চিকিৎসা পদ্ধতি',
      bannerImage: json['banner_image']?.toString() ?? '',
      themeColor: _colorFromHex(json['theme_color']?.toString()),
    );
  }

  static Color _colorFromHex(String? raw) {
    final hex = (raw ?? '').replaceAll('#', '').trim();
    if (hex.length != 6) return const Color(0xFF1E6F5C);
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class HijamaPage extends StatefulWidget {
  const HijamaPage({super.key});

  @override
  State<HijamaPage> createState() => _HijamaPageState();
}

class _HijamaPageState extends State<HijamaPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/hijama.json';
  static const _cacheKey = 'hijama_content_cache';

  final TextEditingController _searchCtrl = TextEditingController();
  HijamaContent? _content;
  bool _loading = true;
  bool _offline = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
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
      } else if (_content == null) {
        setState(() {
          _error =
              'সার্ভার থেকে হিজামার ডেটা আনা যায়নি (${response.statusCode})';
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    } catch (_) {
      if (_content == null) {
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
      final decoded = jsonDecode(_sanitizeJson(raw)) as Map<String, dynamic>;
      setState(() {
        _content = HijamaContent.fromJson(decoded);
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) {
        setState(() {
          _error = 'হিজামার ডেটা পড়া যায়নি';
          _loading = false;
        });
      }
    }
  }

  String _sanitizeJson(String raw) {
    return raw.replaceAllMapped(
      RegExp(r',\s*([}\]])'),
      (match) => match.group(1) ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final content = _content;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content?.section.title ?? 'হিজামা',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              content?.section.subtitle ?? 'নববী চিকিৎসা পদ্ধতি',
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
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading && content == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && content == null
          ? _ErrorView(message: _error!, onRetry: _fetchData)
          : _buildContent(context, content!, isDark),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HijamaContent content,
    bool isDark,
  ) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final accent = content.section.themeColor;
    final sections = _sections(content, cardColor, textColor, subColor, accent);
    final filtered = _query.isEmpty
        ? sections
        : sections
              .where(
                (section) => section.searchText.toLowerCase().contains(_query),
              )
              .toList();

    return Column(
      children: [
        if (_offline) const _OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            color: accent,
            onRefresh: _fetchData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _HeroCard(content: content, isDark: isDark, accent: accent),
                const SizedBox(height: 14),
                _SearchBox(controller: _searchCtrl, accent: accent),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  _EmptySearch(query: _searchCtrl.text)
                else
                  ...filtered.expand(
                    (section) => [section.child, const SizedBox(height: 12)],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_ContentSection> _sections(
    HijamaContent content,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color accent,
  ) {
    return [
      _ContentSection(
        searchText: '${content.intro['title']} ${content.intro['description']}',
        child: _IntroCard(
          data: content.intro,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.history['title']} ${_list(content.history['content']).join(' ')}',
        child: _BulletSection(
          icon: Icons.history_rounded,
          title: content.history['title']?.toString() ?? 'হিজামার ইতিহাস',
          items: _list(content.history['content']),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.nobobiTreatment['title']} ${content.nobobiTreatment['description']} ${_list(content.nobobiTreatment['used_for']).join(' ')}',
        child: _TextWithBulletsSection(
          icon: Icons.auto_awesome_rounded,
          title: content.nobobiTreatment['title']?.toString() ?? 'নববী চিকিৎসা',
          description: content.nobobiTreatment['description']?.toString() ?? '',
          itemsTitle: 'ব্যবহার করা হয়েছে',
          items: _list(content.nobobiTreatment['used_for']),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.benefits['title']} ${_list(content.benefits['items']).join(' ')}',
        child: _ChipSection(
          icon: Icons.health_and_safety_rounded,
          title:
              content.benefits['title']?.toString() ??
              'হিজামার সম্ভাব্য উপকারিতা',
          items: _list(content.benefits['items']),
          cardColor: cardColor,
          textColor: textColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.recommendedTime['title']} ${_list(content.recommendedTime['best_dates_hijri']).join(' ')} ${_list(content.recommendedTime['best_days']).join(' ')} ${content.recommendedTime['note']}',
        child: _RecommendedTimeSection(
          data: content.recommendedTime,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.beforeHijama['title']} ${_list(content.beforeHijama['items']).join(' ')}',
        child: _BulletSection(
          icon: Icons.check_circle_outline_rounded,
          title:
              content.beforeHijama['title']?.toString() ??
              'হিজামার পূর্ব প্রস্তুতি',
          items: _list(content.beforeHijama['items']),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.afterHijama['title']} ${_list(content.afterHijama['items']).join(' ')}',
        child: _BulletSection(
          icon: Icons.spa_rounded,
          title: content.afterHijama['title']?.toString() ?? 'হিজামার পর করণীয়',
          items: _list(content.afterHijama['items']),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.avoidConditions['title']} ${_list(content.avoidConditions['items']).join(' ')}',
        child: _BulletSection(
          icon: Icons.warning_amber_rounded,
          title:
              content.avoidConditions['title']?.toString() ??
              'যাদের সতর্ক থাকা উচিত',
          items: _list(content.avoidConditions['items']),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: Colors.orange,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.therapyProcess['title']} ${HijamaContent._mapList(content.therapyProcess['steps']).map((e) => '${e['title']} ${e['description']}').join(' ')}',
        child: _StepsSection(
          title:
              content.therapyProcess['title']?.toString() ??
              'হিজামা করার পদ্ধতি',
          steps: HijamaContent._mapList(content.therapyProcess['steps']),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText:
            '${content.hijamaPoints['title']} ${_list(content.hijamaPoints['points']).join(' ')}',
        child: _ChipSection(
          icon: Icons.location_on_rounded,
          title:
              content.hijamaPoints['title']?.toString() ??
              'হিজামার সাধারণ পয়েন্ট',
          items: _list(content.hijamaPoints['points']),
          cardColor: cardColor,
          textColor: textColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText: content.specialTopics
            .map((e) => '${e['title']} ${e['description']}')
            .join(' '),
        child: _TopicSection(
          title: 'বিশেষ আলোচনা',
          topics: content.specialTopics,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText: content.hadiths
            .map((e) => '${e['arabic']} ${e['bangla']} ${e['reference']}')
            .join(' '),
        child: _HadithSection(
          hadiths: content.hadiths,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText: content.faqs
            .map((e) => '${e['question']} ${e['answer']}')
            .join(' '),
        child: _FaqSection(
          faqs: content.faqs,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
      _ContentSection(
        searchText: content.references.join(' '),
        child: _BulletSection(
          icon: Icons.menu_book_rounded,
          title: 'রেফারেন্স',
          items: content.references,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          accent: accent,
        ),
      ),
    ];
  }

  List<String> _list(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class _ContentSection {
  final String searchText;
  final Widget child;

  const _ContentSection({required this.searchText, required this.child});
}

class _HeroCard extends StatelessWidget {
  final HijamaContent content;
  final bool isDark;
  final Color accent;

  const _HeroCard({
    required this.content,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            content.section.bannerImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: accent),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  content.section.title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content.section.subtitle,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;

  const _SearchBox({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.hindSiliguri(fontSize: 14),
      decoration: InputDecoration(
        hintText: AppI18n.current('হিজামা বিষয়ে খুঁজুন'),
        prefixIcon: Icon(Icons.search_rounded, color: accent),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: controller.clear,
              ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.55)),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color cardColor;
  final Color textColor;
  final Color accent;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.cardColor,
    required this.textColor,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _IntroCard({
    required this.data,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.medical_services_rounded,
      title: data['title']?.toString() ?? 'হিজামা কি?',
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: data['arabic']?.toString() ?? '', color: accent),
              _Pill(label: data['english']?.toString() ?? '', color: accent),
            ].where((pill) => pill.label.isNotEmpty).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            data['description']?.toString() ?? '',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13.5,
              height: 1.65,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _BulletSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: icon,
      title: title,
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 17, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13.5,
                      height: 1.45,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TextWithBulletsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String itemsTitle;
  final List<String> items;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _TextWithBulletsSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.itemsTitle,
    required this.items,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: icon,
      title: title,
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13.5,
              height: 1.6,
              color: subColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            itemsTitle,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => _Pill(label: item, color: accent))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color cardColor;
  final Color textColor;
  final Color accent;

  const _ChipSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.cardColor,
    required this.textColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: icon,
      title: title,
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => _Pill(label: item, color: accent))
            .toList(),
      ),
    );
  }
}

class _RecommendedTimeSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _RecommendedTimeSection({
    required this.data,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final dates = HijamaContent._stringList(data['best_dates_hijri']);
    final days = HijamaContent._stringList(data['best_days']);
    return _SectionCard(
      icon: Icons.calendar_month_rounded,
      title: data['title']?.toString() ?? 'হিজামার উত্তম সময়',
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...dates.map(
                (date) => _Pill(label: '$date হিজরি', color: accent),
              ),
              ...days.map((day) => _Pill(label: day, color: accent)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['note']?.toString() ?? '',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              height: 1.5,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> steps;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _StepsSection({
    required this.title,
    required this.steps,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.format_list_numbered_rounded,
      title: title,
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        children: steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step['step']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']?.toString() ?? '',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step['description']?.toString() ?? '',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12.5,
                          height: 1.45,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopicSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> topics;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _TopicSection({
    required this.title,
    required this.topics,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.tips_and_updates_rounded,
      title: title,
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        children: topics.map((topic) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic['title']?.toString() ?? '',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic['description']?.toString() ?? '',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5,
                    height: 1.45,
                    color: subColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HadithSection extends StatelessWidget {
  final List<Map<String, dynamic>> hadiths;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _HadithSection({
    required this.hadiths,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.local_library_rounded,
      title: 'হাদীস',
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        children: hadiths.map((hadith) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hadith['arabic']?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: 19,
                    height: 1.8,
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hadith['bangla']?.toString() ?? '',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      height: 1.45,
                      color: subColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(
                    label: hadith['reference']?.toString() ?? '',
                    color: accent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final List<Map<String, dynamic>> faqs;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final Color accent;

  const _FaqSection({
    required this.faqs,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.quiz_rounded,
      title: 'প্রশ্ন ও উত্তর',
      cardColor: cardColor,
      textColor: textColor,
      accent: accent,
      child: Column(
        children: faqs.map((faq) {
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              iconColor: accent,
              collapsedIconColor: accent,
              title: Text(
                faq['question']?.toString() ?? '',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq['answer']?.toString() ?? '',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12.5,
                      height: 1.55,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
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
            style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final String query;

  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 46, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '"$query" পাওয়া যায়নি',
            style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'আবার চেষ্টা করুন',
                style: GoogleFonts.hindSiliguri(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
