// ============================================================
//  dowa_screen.dart
//  GitHub API থেকে dua.json fetch করে categories দেখায়
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import 'dua_list_page.dart';

// ─── Data Models ─────────────────────────────────────────────

class DuaCategory {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int count;
  final List<DuaItem> duas;

  const DuaCategory({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.count,
    required this.duas,
  });

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      id: json['id'] ?? '',
      emoji: json['emoji'] ?? '🤲',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      count: json['count'] ?? 0,
      duas: (json['duas'] as List<dynamic>? ?? [])
          .map((d) => DuaItem.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DuaItem {
  final int id;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String reference;
  final String virtue;
  final String? note;

  const DuaItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
    required this.virtue,
    this.note,
  });

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    return DuaItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      arabic: json['arabic'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
      reference: json['reference'] ?? '',
      virtue: json['virtue'] ?? '',
      note: json['note'] as String?,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────

class DowaScreen extends StatefulWidget {
  const DowaScreen({super.key});

  @override
  State<DowaScreen> createState() => _DowaScreenState();
}

class _DowaScreenState extends State<DowaScreen> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/dua.json';

  List<DuaCategory> _categories = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _fetchDuas();
  }

  Future<void> _fetchDuas() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();

    // ── ১. Cache থেকে তাৎক্ষণিক দেখাও ───────────────────────
    final cached = prefs.getString('dua_cache');
    if (cached != null) {
      _parseAndSet(cached, fromCache: true);
    }

    // ── ২. Network থেকে fresh data আনো ───────────────────────
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        await prefs.setString('dua_cache', raw);
        _parseAndSet(raw, fromCache: false);
      } else {
        if (_categories.isEmpty) {
          setState(() {
            _error = 'সার্ভার থেকে ডেটা আনা যায়নি (${response.statusCode})';
            _loading = false;
          });
        } else {
          setState(() { _loading = false; _offline = true; });
        }
      }
    } catch (e) {
      if (_categories.isEmpty) {
        setState(() {
          _error = 'ইন্টারনেট সংযোগ পরীক্ষা করুন';
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _offline = true; });
      }
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cats = (data['categories'] as List<dynamic>)
          .map((c) => DuaCategory.fromJson(c as Map<String, dynamic>))
          .toList();
      setState(() {
        _categories = cats;
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'দু\'আ ও যিকির',
              style: GoogleFonts.hindSiliguri(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),

          // ── Featured Banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4D2A), Color(0xFF2E8B57)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'বিসমিল্লাহির রাহমানির রাহিম',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'পরম করুণাময় অতি দয়ালু আল্লাহর নামে',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'বিভাগসমূহ',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (!_loading && _error == null)
                  Text(
                    '${_categories.length}টি বিভাগ',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Body ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _error != null
                    ? _ErrorWidget(
                        message: _error!,
                        onRetry: _fetchDuas,
                      )
                    : Column(
                        children: [
                          if (_offline)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              color: Colors.orange.withValues(alpha: 0.15),
                              child: Row(
                                children: [
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(
                                    'অফলাইন মোড — সংরক্ষিত ডেটা দেখাচ্ছে',
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 11, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return _CategoryCard(
                                  category: cat,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DuaListPage(category: cat),
                                      ),
                                    );
                                  },
                                );
                              },
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

// ─── Category Card ────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final DuaCategory category;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(
          category.title,
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${category.count}টি দু\'আ',
          style: GoogleFonts.hindSiliguri(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Error Widget ─────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

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
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
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
