import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// Global AudioProvider — app-wide background audio
// ═══════════════════════════════════════════════════════════════
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final BaseCacheManager _cache = DefaultCacheManager();

  // Current track info
  bool isPlaying = false;
  bool isVisible = false; // FAB visible
  int? playingVerseId;
  int? playingSurahId;
  String surahName = '';
  String verseText = '';
  Duration? duration;
  Duration? position;
  bool isLoading = false;

  // Settings — autoPlay default TRUE
  String reciter = 'MaherAlMuaiqly128kbps';
  bool autoPlay = true;   // ← default on
  bool useCached = true;
  bool showTranslit = true;
  bool showTranslation = true;
  double arabicSize = 26;

  // Callbacks
  Function(int)? onAutoPlayNext;      // called with nextVerseId
  Future<void> Function()? onSurahEnd; // called when last verse ends

  AudioProvider() {
    _initListeners();
    _loadSettings();
  }

  void _initListeners() {
    _player.onPlayerStateChanged.listen((s) {
      isPlaying = s == PlayerState.playing;
      notifyListeners();
    });
    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });
    _player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) {
      if (autoPlay && playingVerseId != null) {
        onAutoPlayNext?.call(playingVerseId! + 1);
      }
      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    reciter = prefs.getString('selectedReciter') ?? 'MaherAlMuaiqly128kbps';
    autoPlay = prefs.getBool('autoPlay') ?? true;  // default true
    useCached = prefs.getBool('useCachedAudio') ?? true;
    showTranslit = prefs.getBool('showTranslit') ?? true;
    showTranslation = prefs.getBool('showTranslation') ?? true;
    arabicSize = prefs.getDouble('arabicSize') ?? 26;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedReciter', reciter);
    await prefs.setBool('autoPlay', autoPlay);
    await prefs.setBool('useCachedAudio', useCached);
    await prefs.setBool('showTranslit', showTranslit);
    await prefs.setBool('showTranslation', showTranslation);
    await prefs.setDouble('arabicSize', arabicSize);
  }

  // ── Play a verse ──────────────────────────────────────────
  Future<void> playVerse({
    required int surahId,
    required int verseId,
    required String surahNameStr,
    required String verseTextStr,
  }) async {
    try {
      // Toggle pause if same verse
      if (playingVerseId == verseId &&
          playingSurahId == surahId &&
          isPlaying) {
        await _player.pause();
        return;
      }
      // Resume if paused on same verse
      if (playingVerseId == verseId &&
          playingSurahId == surahId &&
          !isPlaying) {
        await _player.resume();
        return;
      }

      await _player.stop();
      isLoading = true;
      playingVerseId = verseId;
      playingSurahId = surahId;
      surahName = surahNameStr;
      verseText = verseTextStr;
      isVisible = true;
      duration = null;
      position = null;
      notifyListeners();

      final sid = surahId.toString().padLeft(3, '0');
      final vid = verseId.toString().padLeft(3, '0');
      final url = 'https://everyayah.com/data/$reciter/$sid$vid.mp3';

      if (useCached && !kIsWeb) {
        try {
          final f = await _cache.getSingleFile(url);
          await _player.play(DeviceFileSource(f.path));
        } catch (_) {
          await _player.play(UrlSource(url));
        }
      } else {
        await _player.play(UrlSource(url));
      }

      isLoading = false;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    isPlaying = false;
    isVisible = false;
    playingVerseId = null;
    playingSurahId = null;
    notifyListeners();
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  void hideFab() {
    isVisible = false;
    notifyListeners();
  }

  void showFab() {
    if (playingVerseId != null) {
      isVisible = true;
      notifyListeners();
    }
  }

  bool isThisVersePlaying(int surahId, int verseId) {
    return playingSurahId == surahId &&
        playingVerseId == verseId &&
        isPlaying;
  }

  bool isThisVerseActive(int surahId, int verseId) {
    return playingSurahId == surahId && playingVerseId == verseId;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
