import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/local/local_store.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class DataSourcesPage extends StatefulWidget {
  const DataSourcesPage({super.key});

  @override
  State<DataSourcesPage> createState() => _DataSourcesPageState();
}

class _DataSourcesPageState extends State<DataSourcesPage> {
  bool _clearing = false;

  static const _sources = <_SourceInfo>[
    _SourceInfo(
      title: 'Al Quran Cloud',
      subtitle: 'কুরআন, অনুবাদ, তাজবীদ ও তিলাওয়াত',
      icon: Icons.menu_book_rounded,
      url: 'https://alquran.cloud/',
      badge: 'FREE / KEYLESS',
    ),
    _SourceInfo(
      title: 'AlAdhan',
      subtitle: 'নামাজের সময়, হিজরি ক্যালেন্ডার ও কিবলা',
      icon: Icons.schedule_rounded,
      url: 'https://aladhan.com/',
      badge: 'FREE API',
    ),
    _SourceInfo(
      title: 'OpenStreetMap / Overpass',
      subtitle: 'কাছাকাছি মসজিদ ও উন্মুক্ত ম্যাপ ডেটা',
      icon: Icons.mosque_rounded,
      url: 'https://www.openstreetmap.org/',
      badge: 'OPEN DATA',
    ),
    _SourceInfo(
      title: 'Open-Meteo',
      subtitle: 'আবহাওয়া ও রমজান/সালাহ প্রসঙ্গ',
      icon: Icons.cloud_outlined,
      url: 'https://open-meteo.com/',
      badge: 'FREE TIER',
    ),
    _SourceInfo(
      title: 'Radio Browser',
      subtitle: 'গ্লোবাল কুরআন ও ইসলামিক রেডিও fallback',
      icon: Icons.radio_rounded,
      url: 'https://www.radio-browser.info/',
      badge: 'FREE / OPEN',
    ),
    _SourceInfo(
      title: 'Hadith API / jsDelivr',
      subtitle: 'বুখারি, মুসলিমসহ বহু হাদিস সংগ্রহ; বাংলা/ইংরেজি/আরবি',
      icon: Icons.auto_stories_rounded,
      url: 'https://github.com/fawazahmed0/hadith-api',
      badge: 'FREE / KEYLESS',
    ),
    _SourceInfo(
      title: 'Open Food Facts',
      subtitle: 'বারকোড থেকে উপাদান, অ্যালার্জেন ও খাদ্য-লেবেল তথ্য',
      icon: Icons.qr_code_scanner_rounded,
      url: 'https://world.openfoodfacts.org/',
      badge: 'OPEN DATA',
    ),
    _SourceInfo(
      title: 'Wikimedia / Wikipedia',
      subtitle: 'কাছাকাছি ইসলামিক স্থান, ইতিহাস ও উন্মুক্ত জ্ঞান',
      icon: Icons.travel_explore_rounded,
      url: 'https://www.mediawiki.org/wiki/API:Geosearch',
      badge: 'FREE / OPEN',
    ),
    _SourceInfo(
      title: 'openrouteservice',
      subtitle: 'মসজিদ/মুসাল্লায় হাঁটার রুট ও ETA (ঐচ্ছিক API key)',
      icon: Icons.directions_walk_rounded,
      url: 'https://openrouteservice.org/',
      badge: 'FREE TIER',
    ),
    _SourceInfo(
      title: 'Firebase / Firestore',
      subtitle: 'নিরাপদ ব্যবহারকারী sync, ব্যানার ও admin config',
      icon: Icons.cloud_sync_rounded,
      url: 'https://firebase.google.com/',
      badge: 'CLOUD SYNC',
    ),
  ];

  static const _safeCacheNamespaces = <String>[
    'prayer_cache_v3',
    'ramadan_calendar_v3',
    'mosque_cache',
    'banner_cache',
    'weather_cache_v1',
    'radio_cache_v2',
    'quran_search_v1',
    'hadith_api_v1',
    'open_food_facts',
    'wikimedia_islamic_places',
    'mosque_routes',
  ];

  Future<void> _open(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _clearSafeCaches() async {
    if (_clearing) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('অফলাইন ক্যাশ পরিষ্কার করবেন?'),
        content: const Text(
          'Prayer, Ramadan, mosque, route, weather, radio, Hadith, food ও search cache পরিষ্কার হবে। Namaz history, Quran bookmark, last-read, goal এবং settings মুছে যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ক্যাশ পরিষ্কার করুন'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    setState(() => _clearing = true);
    try {
      for (final namespace in _safeCacheNamespaces) {
        await LocalStore.instance.clearNamespace(namespace);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অফলাইন ক্যাশ পরিষ্কার হয়েছে')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final card = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('ডেটা সোর্স ও অফলাইন'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.white, size: 30),
                SizedBox(height: 12),
                Text(
                  'Noorvia Offline-First',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'অ্যাপ আগে local cache/Isar থেকে দ্রুত ডেটা দেখায়, তারপর internet থাকলে authoritative source থেকে refresh করে। ব্যক্তিগত Namaz/Quran progress আলাদা রেখে নিরাপদে sync করা হয়।',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'বিশ্বস্ত ডেটা সোর্স',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text),
          ),
          const SizedBox(height: 10),
          ..._sources.map(
            (source) => Card(
              color: card,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(source.icon, color: AppColors.primary),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        source.title,
                        style: TextStyle(color: text, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        source.badge,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(source.subtitle, style: TextStyle(color: sub, height: 1.35)),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _open(source.url),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Privacy by design',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text),
          ),
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.storage_rounded,
            title: 'Isar local database',
            body: 'Prayer/Ramadan cache, Quran progress, language, Smart Salah settings ও offline history device-এ রাখা যায়।',
            isDark: isDark,
          ),
          _InfoTile(
            icon: Icons.lock_outline_rounded,
            title: 'Secret mobile app-এ নয়',
            body: 'যে API client secret চায়, সেটি APK-এর মধ্যে hard-code না করে secure backend proxy দিয়ে ব্যবহার করতে হবে।',
            isDark: isDark,
          ),
          _InfoTile(
            icon: Icons.sync_rounded,
            title: 'Cloud sync selective',
            body: 'Firestore মূলত account restore, cross-device progress, admin banner/config এবং user-owned data sync-এর জন্য।',
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _clearing ? null : _clearSafeCaches,
            icon: _clearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cleaning_services_rounded),
            label: const Text('শুধু নিরাপদ offline cache পরিষ্কার করুন'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: sub, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  final String badge;

  const _SourceInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.badge,
  });
}
