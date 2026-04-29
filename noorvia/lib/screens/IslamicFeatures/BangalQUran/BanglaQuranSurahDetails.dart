import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SurahDetailPage extends StatefulWidget {
  final Map surahInfo;
  const SurahDetailPage({super.key, required this.surahInfo});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? surahData;
  Set<String> favVerseKeys = {}; // "surahId-verseId"

  // Audio player variables
  final AudioPlayer audioPlayer = AudioPlayer();
  final BaseCacheManager audioCacheManager = DefaultCacheManager();
  bool isPlaying = false;
  int? currentlyPlayingVerse;
  String selectedReciter = 'MaherAlMuaiqly128kbps'; // Default reciter
  Duration? currentDuration;
  Duration? currentPosition;
  bool autoPlayEnabled = false;
  final ScrollController _scrollController = ScrollController();
  bool useCachedAudio = true;

  // List of available reciters
  final List<Map<String, String>> reciters = [
    {'id': 'MaherAlMuaiqly128kbps', 'name': 'Maher Al Muaiqly'},
    {
      'id': 'AbdulSamad_64kbps_QuranExplorer.Com',
      'name': 'Abdul Basit Abdul Samad'
    },
    {'id': 'Abdul_Basit_Mujawwad_128kbps', 'name': 'Abdul Basit Mujawwad'},
    {'id': 'Abdul_Basit_Murattal_192kbps', 'name': 'Abdul Basit Murattal'},
    {'id': 'Abdul_Basit_Murattal_64kbps', 'name': 'Abdul Basit Murattal'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadAppSettings();
    await _loadFavVerses();
    await _loadDetail();

    // Setup audio player listeners
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          currentDuration = duration;
        });
      }
    });

    audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    audioPlayer.onPlayerComplete.listen((event) {
      if (mounted && autoPlayEnabled && currentlyPlayingVerse != null) {
        final nextVerse = currentlyPlayingVerse! + 1;
        if (surahData != null &&
            nextVerse <= (surahData!['verses'] as List).length) {
          _playVerseAudio(nextVerse);
          _scrollToVerse(nextVerse);
        }
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    // Try to load from cache first
    final cachedData = await _getCachedSurahData();
    if (cachedData != null && mounted) {
      setState(() {
        surahData = cachedData;
        isLoading = false;
      });
    }

    // Then load from network
    try {
      final link = widget.surahInfo['link'] as String;
      final res = await http.get(Uri.parse(link));
      if (res.statusCode == 200) {
        final newData = json.decode(res.body) as Map<String, dynamic>;
        await _cacheSurahData(newData);

        if (mounted) {
          setState(() {
            surahData = newData;
            isLoading = false;
          });
        }
      } else if (mounted && surahData == null) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && surahData == null) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cacheSurahData(Map<String, dynamic> data) async {
    if (kIsWeb) return; // Web has limitations with large data storage

    try {
      final prefs = await SharedPreferences.getInstance();
      final surahId = widget.surahInfo['id'].toString();
      await prefs.setString('surah_$surahId', json.encode(data));
    } catch (e) {
      debugPrint('Failed to cache surah data: $e');
    }
  }

  Future<Map<String, dynamic>?> _getCachedSurahData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surahId = widget.surahInfo['id'].toString();
      final cachedData = prefs.getString('surah_$surahId');
      if (cachedData != null) {
        return json.decode(cachedData) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to load cached surah data: $e');
    }
    return null;
  }

  Future<void> _loadFavVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verses = prefs.getStringList('favVerses') ?? [];
      if (mounted) {
        setState(() {
          favVerseKeys = verses.toSet();
        });
      }
    } catch (e) {
      debugPrint('Failed to load favorite verses: $e');
    }
  }

  Future<void> _loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          autoPlayEnabled = prefs.getBool('autoPlay') ?? false;
          useCachedAudio = prefs.getBool('useCachedAudio') ?? true;
          selectedReciter =
              prefs.getString('selectedReciter') ?? 'MaherAlMuaiqly128kbps';
        });
      }
    } catch (e) {
      debugPrint('Failed to load app settings: $e');
    }
  }

  Future<void> _saveAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoPlay', autoPlayEnabled);
      await prefs.setBool('useCachedAudio', useCachedAudio);
      await prefs.setString('selectedReciter', selectedReciter);
    } catch (e) {
      debugPrint('Failed to save app settings: $e');
    }
  }

  Future<void> _toggleFavVerse(int verseId) async {
    try {
      final sId = (widget.surahInfo['id'] ?? '').toString();
      final key = '$sId-$verseId';
      final prefs = await SharedPreferences.getInstance();

      if (favVerseKeys.contains(key)) {
        favVerseKeys.remove(key);
      } else {
        favVerseKeys.add(key);
      }

      await prefs.setStringList('favVerses', favVerseKeys.toList());

      if (mounted) {
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
    } catch (e) {
      debugPrint('Failed to toggle favorite verse: $e');
    }
  }

  Future<void> _playVerseAudio(int verseId) async {
    try {
      if (isPlaying && currentlyPlayingVerse == verseId) {
        await audioPlayer.pause();
        return;
      }

      // Stop any currently playing audio
      await audioPlayer.stop();

      // Construct the audio URL
      final surahId = widget.surahInfo['id'].toString().padLeft(3, '0');
      final verseNum = verseId.toString().padLeft(3, '0');

      String audioUrl;
      if (selectedReciter.contains('/')) {
        final parts = selectedReciter.split('/');
        audioUrl =
            'https://everyayah.com/data/${parts[0]}/${parts[1]}/$surahId$verseNum.mp3';
      } else {
        audioUrl =
            'https://everyayah.com/data/$selectedReciter/$surahId$verseNum.mp3';
      }

      if (mounted) {
        setState(() {
          currentlyPlayingVerse = verseId;
        });
      }

      if (useCachedAudio && !kIsWeb) {
        try {
          final file = await audioCacheManager.getSingleFile(audioUrl);
          await audioPlayer.play(DeviceFileSource(file.path));
        } catch (e) {
          // Fallback to streaming if caching fails
          debugPrint('Cache failed, falling back to streaming: $e');
          await audioPlayer.play(UrlSource(audioUrl));
        }
      } else {
        await audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio playback failed: ${e.toString()}')),
        );
      }
      debugPrint('Audio playback error: $e');
    }
  }

  Future<void> _preCacheAudioForSurah() async {
    if (kIsWeb || surahData == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting audio caching...')),
      );
    }

    final verses = surahData!['verses'] as List;
    final surahId = widget.surahInfo['id'].toString().padLeft(3, '0');

    for (final verse in verses) {
      final verseId = verse['id'] as int;
      final verseNum = verseId.toString().padLeft(3, '0');

      String audioUrl;
      if (selectedReciter.contains('/')) {
        final parts = selectedReciter.split('/');
        audioUrl =
            'https://everyayah.com/data/${parts[0]}/${parts[1]}/$surahId$verseNum.mp3';
      } else {
        audioUrl =
            'https://everyayah.com/data/$selectedReciter/$surahId$verseNum.mp3';
      }

      try {
        await audioCacheManager.downloadFile(audioUrl);
      } catch (e) {
        debugPrint('Failed to cache audio for verse $verseId: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio caching completed!')),
      );
    }
  }

  void _scrollToVerse(int verseId) {
    if (surahData == null || !_scrollController.hasClients) return;

    final verses = surahData!['verses'] as List;
    final index = verses.indexWhere((v) => v['id'] == verseId);
    if (index != -1) {
      final position = index * 180.0;
      _scrollController.animateTo(
        position.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showVerseSelector() {
    if (surahData == null) return;

    final verses = surahData!['verses'] as List;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Verse'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return ListTile(
                title: Text('Verse ${verse['id']}'),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToVerse(verse['id']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Auto Play Next Verse'),
                    value: autoPlayEnabled,
                    onChanged: (value) {
                      setState(() {
                        autoPlayEnabled = value;
                      });
                    },
                  ),
                  if (!kIsWeb)
                    SwitchListTile(
                      title: const Text('Use Cached Audio'),
                      value: useCachedAudio,
                      onChanged: (value) {
                        setState(() {
                          useCachedAudio = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  const Text('Reciter:'),
                  DropdownButton<String>(
                    value: selectedReciter,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedReciter = newValue;
                        });
                      }
                    },
                    items: reciters.map<DropdownMenuItem<String>>(
                        (Map<String, String> reciter) {
                      return DropdownMenuItem<String>(
                        value: reciter['id'],
                        child: Text(reciter['name']!),
                      );
                    }).toList(),
                  ),
                  if (!kIsWeb) const SizedBox(height: 16),
                  if (!kIsWeb)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _preCacheAudioForSurah();
                      },
                      child: const Text('Pre-cache Audio for this Surah'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _saveAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
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
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: _showVerseSelector,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : surahData == null
              ? const Center(child: Text('Surah data load failed'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.teal.withOpacity(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.headphones,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            reciters.firstWhere(
                                (r) => r['id'] == selectedReciter)['name']!,
                            style: const TextStyle(color: Colors.teal),
                          ),
                          if (autoPlayEnabled) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.autorenew,
                                size: 16, color: Colors.teal),
                            const SizedBox(width: 4),
                            const Text('Auto',
                                style: TextStyle(color: Colors.teal)),
                          ],
                          if (useCachedAudio && !kIsWeb) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.storage,
                                size: 16, color: Colors.teal),
                            const SizedBox(width: 4),
                            const Text('Cached',
                                style: TextStyle(color: Colors.teal)),
                          ]
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
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
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.teal,
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
                                              color: Colors.teal,
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
                                        if (currentDuration != null)
                                          Column(
                                            children: [
                                              Slider(
                                                value: (currentPosition ??
                                                        Duration.zero)
                                                    .inMilliseconds
                                                    .toDouble(),
                                                max: currentDuration!
                                                    .inMilliseconds
                                                    .toDouble(),
                                                onChanged: (value) {
                                                  audioPlayer.seek(Duration(
                                                      milliseconds:
                                                          value.toInt()));
                                                },
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(_formatDuration(
                                                        currentPosition ??
                                                            Duration.zero)),
                                                    Text(_formatDuration(
                                                        currentDuration!)),
                                                  ],
                                                ),
                                              ),
                                            ],
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
