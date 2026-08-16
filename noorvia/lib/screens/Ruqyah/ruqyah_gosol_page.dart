import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/audio_provider.dart';
import 'ruqyah_gosol_detail_page.dart';

// ─── Gosol Model ──────────────────────────────────────────────

class RuqyahGosol {
  final int id;
  final String title;
  final String content;

  const RuqyahGosol({
    required this.id,
    required this.title,
    required this.content,
  });

  factory RuqyahGosol.fromJson(Map<String, dynamic> json) {
    return RuqyahGosol(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────

class RuqyahGosolPage extends StatefulWidget {
  const RuqyahGosolPage({super.key});

  @override
  State<RuqyahGosolPage> createState() => _RuqyahGosolPageState();
}

class _RuqyahGosolPageState extends State<RuqyahGosolPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/ruqyah_gosol.json';

  List<RuqyahGosol> _gosols = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _fetchGosols();
  }

  Future<void> _fetchGosols() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();

    // ── ১. Cache থেকে তাৎক্ষণিক দেখাও ───────────────────────
    final cached = prefs.getString('ruqyah_gosol_cache');
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
        await prefs.setString('ruqyah_gosol_cache', raw);
        _parseAndSet(raw, fromCache: false);
      } else {
        if (_gosols.isEmpty) {
          setState(() {
            _error = 'সার্ভার থেকে ডেটা আনা যায়নি (${response.statusCode})';
            _loading = false;
          });
        } else {
          setState(() {
            _loading = false;
            _offline = true;
          });
        }
      }
    } catch (e) {
      if (_gosols.isEmpty) {
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
      final gosols = (data['items'] as List<dynamic>? ?? [])
          .map((g) => RuqyahGosol.fromJson(g as Map<String, dynamic>))
          .toList();
      setState(() {
        _gosols = gosols;
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) setState(() => _loading = false);
    }
  }

  void _playAudio(RuqyahGosol gosol) {
    // Gosol doesn't have audio, just show the content
    _showGosolDetail(gosol);
  }

  void _showGosolDetail(RuqyahGosol gosol) {
    final index = _gosols.indexOf(gosol);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuqyahGosolDetailPage(
          gosol: gosol,
          allGosols: _gosols,
          currentIndex: index >= 0 ? index : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
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
              'রুকইয়াহ গোসল',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              'জিন, যাদু ও বদনজর থেকে মুক্তির গোসল',
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
            onPressed: _fetchGosols,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _ErrorWidget(
                  message: _error!,
                  onRetry: _fetchGosols,
                )
              : Column(
                  children: [
                    if (_offline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.orange.withValues(alpha: 0.15),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'অফলাইন মোড — সংরক্ষিত ডেটা দেখাচ্ছে',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _gosols.length,
                        itemBuilder: (context, index) {
                          final gosol = _gosols[index];
                          return _GosolCard(
                            gosol: gosol,
                            index: index,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RuqyahGosolDetailPage(
                                    gosol: gosol,
                                    allGosols: _gosols,
                                    currentIndex: index,
                                  ),
                                ),
                              );
                            },
                            onPlay: () => _playAudio(gosol),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Gosol Card ───────────────────────────────────────────────

class _GosolCard extends StatelessWidget {
  final RuqyahGosol gosol;
  final int index;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _GosolCard({
    required this.gosol,
    required this.index,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Index badge
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
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gosol.title,
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
                      gosol.content.replaceAll('\\n', ' ').substring(0, (gosol.content.length > 80 ? 80 : gosol.content.length)),
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
              // Info icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
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
