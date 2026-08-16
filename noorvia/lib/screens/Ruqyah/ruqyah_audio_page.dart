import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/audio_provider.dart';

// ─── Audio Model ──────────────────────────────────────────────

class RuqyahAudio {
  final int id;
  final String title;
  final String subtitle;
  final String size;
  final String duration;
  final String category;
  final String downloadUrl;

  const RuqyahAudio({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.size,
    required this.duration,
    required this.category,
    required this.downloadUrl,
  });

  factory RuqyahAudio.fromJson(Map<String, dynamic> json) {
    return RuqyahAudio(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      downloadUrl: json['download_url']?.toString() ?? '',
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────

class RuqyahAudioPage extends StatefulWidget {
  const RuqyahAudioPage({super.key});

  @override
  State<RuqyahAudioPage> createState() => _RuqyahAudioPageState();
}

class _RuqyahAudioPageState extends State<RuqyahAudioPage> {
  static const _apiUrl =
      'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/ruqyah_audio.json';

  List<RuqyahAudio> _audios = [];
  bool _loading = true;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  Future<void> _fetchAudios() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();

    // ── ১. Cache থেকে তাৎক্ষণিক দেখাও ───────────────────────
    final cached = prefs.getString('ruqyah_audio_cache');
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
        await prefs.setString('ruqyah_audio_cache', raw);
        _parseAndSet(raw, fromCache: false);
      } else {
        if (_audios.isEmpty) {
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
      if (_audios.isEmpty) {
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
      final audios = (data['audios'] as List<dynamic>? ?? [])
          .map((a) => RuqyahAudio.fromJson(a as Map<String, dynamic>))
          .where((a) => a.downloadUrl.isNotEmpty)
          .toList();
      setState(() {
        _audios = audios;
        _loading = false;
        _offline = fromCache;
      });
    } catch (_) {
      if (!fromCache) setState(() => _loading = false);
    }
  }

  void _playAudio(RuqyahAudio audio) {
    if (audio.downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('অডিও URL খালি আছে', style: GoogleFonts.hindSiliguri()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final audioProvider = context.read<AudioProvider>();
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'অডিও লোড হচ্ছে... ${audio.title}',
          style: GoogleFonts.hindSiliguri(),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    
    audioProvider.playAudio(
      url: audio.downloadUrl,
      surahName: audio.title,
      playingVerseId: audio.id,
    );
  }

  Future<void> _downloadAudio(RuqyahAudio audio) async {
    try {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ডাউনলোড শুরু হচ্ছে...',
            style: GoogleFonts.hindSiliguri(),
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      // Get the app's documents directory
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/ruqyah_audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Create file name from title
      final fileName = '${audio.id}_${audio.title.replaceAll(' ', '_')}.mp3';
      final filePath = '${audioDir.path}/$fileName';
      final file = File(filePath);

      // Check if already downloaded
      if (await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ফাইল ইতিমধ্যে ডাউনলোড করা আছে',
                style: GoogleFonts.hindSiliguri(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Download the file
      final response = await http.get(Uri.parse(audio.downloadUrl));
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ডাউনলোড সম্পন্ন! ${audio.size}',
                style: GoogleFonts.hindSiliguri(),
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'চালান',
                textColor: Colors.white,
                onPressed: () {
                  // Play the downloaded file
                  final audioProvider = context.read<AudioProvider>();
                  audioProvider.playAudio(
                    url: file.path,
                    surahName: audio.title,
                    playingVerseId: audio.id,
                  );
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('ডাউনলোড ব্যর্থ: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ডাউনলোড ব্যর্থ: $e',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              'রুকইয়াহ অডিও',
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              'শোনুন এবং সুস্থ হন',
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
            onPressed: _fetchAudios,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _ErrorWidget(message: _error!, onRetry: _fetchAudios)
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
                    itemCount: _audios.length,
                    itemBuilder: (context, index) {
                      final audio = _audios[index];
                      return _AudioCard(
                        audio: audio,
                        index: index,
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        onPlay: () => _playAudio(audio),
                        onDownload: () => _downloadAudio(audio),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Audio Card ───────────────────────────────────────────────

class _AudioCard extends StatelessWidget {
  final RuqyahAudio audio;
  final int index;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _AudioCard({
    required this.audio,
    required this.index,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
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
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
                      audio.title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (audio.subtitle.isNotEmpty)
                      Text(
                        audio.subtitle,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          color: subColor,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${audio.duration} • ${audio.size}',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 10,
                            color: subColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Play button
              GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Download button
              GestureDetector(
                onTap: onDownload,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
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
              style: GoogleFonts.hindSiliguri(fontSize: 15, color: Colors.grey),
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
