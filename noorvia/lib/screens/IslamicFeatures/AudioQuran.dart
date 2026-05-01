import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_theme.dart';

class SurahDetailPage extends StatefulWidget {
  final Map<String, dynamic> surahInfo;
  const SurahDetailPage({super.key, required this.surahInfo});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? surahData;
  Set<String> favVerseKeys = {};

  // Audio player variables
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int? currentlyPlayingVerse;
  String selectedReciter =
      'AbdulBaset/Mujawwad'; // Default reciter from EveryAyah
  Duration? currentDuration;

  // List of available reciters from EveryAyah
  final List<Map<String, String>> reciters = [
    {'id': 'AbdulBaset/Mujawwad', 'name': 'Abdul Basit (Mujawwad)'},
    {'id': 'AbdulBaset/Murattal', 'name': 'Abdul Basit (Murattal)'},
    {'id': 'Abdurrahmaan_As-Sudais_192kbps', 'name': 'Sudais'},
    {'id': 'Hani_Rifai', 'name': 'Hani Rifai'},
    {'id': 'MaherAlMuaiqly128kbps', 'name': 'Maher Al Muaiqly'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDetail();
    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        currentDuration = duration;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    await _loadFavVerses();
    final link = widget.surahInfo['link'] as String;
    final res = await http.get(Uri.parse(link));
    if (res.statusCode == 200) {
      surahData = json.decode(res.body) as Map<String, dynamic>;
    } else {
      surahData = null;
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadFavVerses() async {
    final prefs = await SharedPreferences.getInstance();
    final verses = prefs.getStringList('favVerses') ?? [];
    favVerseKeys = verses.toSet();
  }

  Future<void> _toggleFavVerse(int verseId) async {
    final sId = (widget.surahInfo['id'] ?? '').toString();
    final key = '$sId-$verseId';
    final prefs = await SharedPreferences.getInstance();
    if (favVerseKeys.contains(key)) {
      favVerseKeys.remove(key);
    } else {
      favVerseKeys.add(key);
    }
    await prefs.setStringList('favVerses', favVerseKeys.toList());
    setState(() {});
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(favVerseKeys.contains(key)
            ? 'আয়াত favorites এ যোগ করা হলো'
            : 'আয়াত favorites থেকে মুছে ফেলা হলো'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _playVerseAudio(int verseId) async {
    try {
      if (isPlaying && currentlyPlayingVerse == verseId) {
        await audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
        return;
      }

      // Stop any currently playing audio
      await audioPlayer.stop();

      // Construct the audio URL using EveryAyah.com format
      final surahId = widget.surahInfo['id'].toString().padLeft(3, '0');
      final verseNum = verseId.toString().padLeft(3, '0');
      final audioUrl =
          'https://everyayah.com/data/${selectedReciter.split('/')[0]}/${selectedReciter.split('/')[1]}/$surahId$verseNum.mp3';

      setState(() {
        currentlyPlayingVerse = verseId;
        isPlaying = true;
      });

      await audioPlayer.play(UrlSource(audioUrl));

      audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          isPlaying = false;
          currentlyPlayingVerse = null;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio playback failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sName = widget.surahInfo['translation'] ?? widget.surahInfo['name'];
    final sTranslit = widget.surahInfo['transliteration'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$sName  ($sTranslit)',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedReciter = value;
              });
            },
            itemBuilder: (context) => reciters.map((reciter) {
              return PopupMenuItem(
                value: reciter['id'],
                child: Text(reciter['name']!),
              );
            }).toList(),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.voice_chat, color: Colors.white),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : surahData == null
              ? const Center(child: Text('Surah data load failed'))
              : Column(
                  children: [
                    // Reciter info
                    Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.headphones,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            reciters.firstWhere(
                                (r) => r['id'] == selectedReciter)['name']!,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: (surahData!['verses'] as List).length,
                        itemBuilder: (context, index) {
                          final verse = (surahData!['verses'] as List)[index];
                          final verseId = verse['id'] as int;
                          final verseKey =
                              '${widget.surahInfo['id'].toString()}-$verseId';
                          final isFav = favVerseKeys.contains(verseKey);
                          final isCurrentVersePlaying =
                              currentlyPlayingVerse == verseId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // header row: verse number, play button and favorite icon
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.primary,
                                            child: Text(
                                              verseId.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              isCurrentVersePlaying && isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () =>
                                                _playVerseAudio(verseId),
                                          ),
                                          Expanded(
                                            child: Text(
                                              verse['text'] ?? '',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav ? Colors.red : null,
                                            ),
                                            onPressed: () =>
                                                _toggleFavVerse(verseId),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        verse['transliteration'] ?? '',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.blueGrey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        verse['translation'] ?? '',
                                      ),
                                      if (isCurrentVersePlaying) ...[
                                        const SizedBox(height: 8),
                                        StreamBuilder<Duration>(
                                          stream: audioPlayer.onPositionChanged,
                                          builder: (context, snapshot) {
                                            final position =
                                                snapshot.data ?? Duration.zero;
                                            return StreamBuilder<Duration>(
                                              stream:
                                                  audioPlayer.onDurationChanged,
                                              builder: (context, snapshot) {
                                                final total = snapshot.data ??
                                                    Duration.zero;
                                                return Column(
                                                  children: [
                                                    Slider(
                                                      value: position.inSeconds
                                                          .toDouble(),
                                                      max: total.inSeconds > 0
                                                          ? total.inSeconds
                                                              .toDouble()
                                                          : 1,
                                                      onChanged: (value) {
                                                        audioPlayer.seek(
                                                            Duration(
                                                                seconds: value
                                                                    .toInt()));
                                                      },
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(_formatDuration(
                                                            position)),
                                                        Text(_formatDuration(
                                                            total)),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ]
                                    ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class SurahInfo {
  final int id;
  final String name;
  final String transliteration;
  final String translation;
  final String type;
  final int totalVerses;
  final String link;

  SurahInfo({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.translation,
    required this.type,
    required this.totalVerses,
    required this.link,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) {
    return SurahInfo(
      id: json['id'],
      name: json['name'],
      transliteration: json['transliteration'],
      translation: json['translation'],
      type: json['type'],
      totalVerses: json['total_verses'],
      link: json['link'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'transliteration': transliteration,
      'translation': translation,
      'type': type,
      'total_verses': totalVerses,
      'link': link,
    };
  }
}
