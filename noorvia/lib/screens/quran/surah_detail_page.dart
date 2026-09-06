import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text;
import 'package:flutter/services.dart';
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:noorvia/core/localization/app_i18n.dart';
import 'package:provider/provider.dart';

import '../../core/data/local/local_store.dart';
import '../../core/providers/quran_reader_settings_provider.dart';
import '../../core/quran/quran_models.dart';
import '../../core/quran/quran_audio_cache_service.dart';
import '../../core/quran/quran_repository.dart';
import '../../core/quran/tajweed_text.dart';
import '../../core/theme/app_theme.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({
    super.key,
    required this.surahName,
    required this.arabicName,
    required this.surahNumber,
    required this.ayatCount,
    required this.type,
    this.initialAyah,
  });

  final String surahName;
  final String arabicName;
  final int surahNumber;
  final int ayatCount;
  final String type;
  final int? initialAyah;

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _bookmarks = {};
  List<GlobalKey> _ayahKeys = const [];

  QuranSurahData? _surah;
  bool _loading = true;
  bool _offlineFallback = false;
  String? _error;
  int? _playingIndex;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _loadedReciter;
  bool _downloadingAudio = false;
  double _downloadProgress = 0;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  @override
  void initState() {
    super.initState();
    _bindAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _bindAudio() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
    _positionSub = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _durationSub = _player.onDurationChanged.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value);
    });
    _completeSub = _player.onPlayerComplete.listen((_) => _onComplete());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final settings = context.read<QuranReaderSettingsProvider>();
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await QuranRepository.instance.getSurah(
        widget.surahNumber,
        reciter: settings.reciter,
        forceRefresh: forceRefresh,
      );
      final bookmarkData = await LocalStore.instance.getJson(
        'quran_bookmarks',
        '${widget.surahNumber}',
      );
      if (!mounted) return;
      setState(() {
        _surah = data;
        _loadedReciter = settings.reciter;
        _ayahKeys = List.generate(data.ayahs.length, (_) => GlobalKey());
        _bookmarks
          ..clear()
          ..addAll(
            ((bookmarkData?['ayahs'] as List?) ?? const [])
                .whereType<num>()
                .map((e) => e.toInt()),
          );
        _loading = false;
      });
      _saveProgress(widget.initialAyah ?? 1);
      if (widget.initialAyah != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah((widget.initialAyah! - 1).clamp(0, data.ayahs.length - 1).toInt());
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _playIndex(int index) async {
    final surah = _surah;
    if (surah == null || index < 0 || index >= surah.ayahs.length) return;
    final ayah = surah.ayahs[index];

    if (_playingIndex == index && _playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (_playingIndex == index && _playerState == PlayerState.paused) {
      await _player.resume();
      return;
    }

    setState(() {
      _playingIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    await _player.stop();
    final readerSettings = context.read<QuranReaderSettingsProvider>();
    Source source = UrlSource(ayah.audioUrl);
    try {
      final cached = await QuranAudioCacheService.instance.getCached(ayah.audioUrl);
      if (cached != null && await cached.exists()) {
        source = DeviceFileSource(cached.path);
      } else if (readerSettings.cacheAudioWhilePlaying) {
        final file = await QuranAudioCacheService.instance.getOrDownload(ayah.audioUrl);
        source = DeviceFileSource(file.path);
      }
    } catch (_) {
      // Streaming remains the fallback when caching fails.
    }
    await _player.play(source);
    await _player.setPlaybackRate(readerSettings.playbackSpeed);
    await _saveProgress(ayah.numberInSurah);
    _scrollToAyah(index);
  }

  Future<void> _downloadSurahAudio() async {
    final surah = _surah;
    if (surah == null || _downloadingAudio) return;
    setState(() {
      _downloadingAudio = true;
      _downloadProgress = 0;
    });
    try {
      await QuranAudioCacheService.instance.downloadSurah(
        surah,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() => _downloadProgress = total == 0 ? 0 : done / total);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই সূরার তিলাওয়াত অফলাইনের জন্য সংরক্ষিত হয়েছে')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অডিও ডাউনলোড সম্পন্ন হয়নি — ইন্টারনেট সংযোগ পরীক্ষা করুন')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAudio = false;
          _downloadProgress = 0;
        });
      }
    }
  }

  Future<void> _onComplete() async {
    final index = _playingIndex;
    final surah = _surah;
    if (index == null || surah == null) return;
    final settings = context.read<QuranReaderSettingsProvider>();

    if (settings.repeatMode == QuranRepeatMode.ayah) {
      await _playIndex(index);
      return;
    }
    final hasNext = index + 1 < surah.ayahs.length;
    if (settings.continuousPlayback && hasNext) {
      await _playIndex(index + 1);
      return;
    }
    if (settings.repeatMode == QuranRepeatMode.surah) {
      await _playIndex(0);
      return;
    }
    if (mounted) setState(() => _playingIndex = null);
  }

  void _scrollToAyah(int index) {
    if (!context.read<QuranReaderSettingsProvider>().autoScroll) return;
    if (index < 0 || index >= _ayahKeys.length) return;
    Future.delayed(const Duration(milliseconds: 140), () {
      final target = _ayahKeys[index].currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: .16,
        );
      }
    });
  }

  Future<void> _saveProgress(int ayahNumber) {
    final surah = _surah;
    QuranAyahData? ayah;
    if (surah != null && ayahNumber > 0 && ayahNumber <= surah.ayahs.length) {
      ayah = surah.ayahs[ayahNumber - 1];
    }
    return LocalStore.instance.putJson(
      'quran_progress',
      'last_read',
      {
        'surahNumber': widget.surahNumber,
        'ayahNumber': ayahNumber,
        if (ayah != null) 'page': ayah.page,
        if (ayah != null) 'juz': ayah.juz,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _toggleBookmark(QuranAyahData ayah) async {
    setState(() {
      if (!_bookmarks.add(ayah.numberInSurah)) {
        _bookmarks.remove(ayah.numberInSurah);
      }
    });
    await LocalStore.instance.putJson(
      'quran_bookmarks',
      '${widget.surahNumber}',
      {'ayahs': _bookmarks.toList()..sort()},
    );
  }

  Future<void> _openSettings() async {
    final before = context.read<QuranReaderSettingsProvider>().reciter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuranReaderSettingsSheet(),
    );
    if (!mounted) return;
    final after = context.read<QuranReaderSettingsProvider>().reciter;
    if (after != before || _loadedReciter != after) {
      await _player.stop();
      setState(() => _playingIndex = null);
      await _load();
    } else {
      await _player.setPlaybackRate(
        context.read<QuranReaderSettingsProvider>().playbackSpeed,
      );
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _completeSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<QuranReaderSettingsProvider>();
    final palette = _ReaderPalette.of(settings.readerTheme);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.header,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.surahName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            if (_surah != null)
              Text(
                '${_surah!.englishName} • ${_surah!.ayahs.length} আয়াত',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
          ],
        ),
        actions: [
          if (_surah != null)
            IconButton(
              tooltip: _downloadingAudio ? 'তিলাওয়াত ডাউনলোড হচ্ছে' : 'সূরার অডিও অফলাইনে সংরক্ষণ করুন',
              onPressed: _downloadingAudio ? null : _downloadSurahAudio,
              icon: _downloadingAudio
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: _downloadProgress <= 0 ? null : _downloadProgress,
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
            ),
          IconButton(
            tooltip: AppI18n.current('পাঠ সেটিংস'),
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: AppI18n.current('রিফ্রেশ'),
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? _LoadingView(palette: palette)
          : _error != null
              ? _ErrorView(
                  palette: palette,
                  onRetry: () => _load(forceRefresh: true),
                )
              : Column(
                  children: [
                    if (_offlineFallback)
                      const MaterialBanner(
                        content: Text('অফলাইন মোড — সংরক্ষিত কুরআন দেখানো হচ্ছে'),
                        actions: [SizedBox.shrink()],
                      ),
                    Expanded(
                      child: _buildMushaf(settings, palette),
                    ),
                    if (_playingIndex != null)
                      _AudioDock(
                        palette: palette,
                        ayah: _surah!.ayahs[_playingIndex!],
                        playing: _playerState == PlayerState.playing,
                        position: _position,
                        duration: _duration,
                        speed: settings.playbackSpeed,
                        onPlayPause: () => _playIndex(_playingIndex!),
                        onPrevious: _playingIndex! > 0
                            ? () => _playIndex(_playingIndex! - 1)
                            : null,
                        onNext: _playingIndex! + 1 < _surah!.ayahs.length
                            ? () => _playIndex(_playingIndex! + 1)
                            : null,
                        onSeek: (value) => _player.seek(value),
                      ),
                  ],
                ),
    );
  }

  Widget _buildMushaf(
    QuranReaderSettingsProvider settings,
    _ReaderPalette palette,
  ) {
    if (settings.layoutMode == QuranLayoutMode.study) {
      return _buildStudyReader(settings, palette);
    }
    return _buildPageMushaf(settings, palette);
  }

  Widget _buildPageMushaf(
    QuranReaderSettingsProvider settings,
    _ReaderPalette palette,
  ) {
    final surah = _surah!;
    final grouped = <int, List<int>>{};
    for (var i = 0; i < surah.ayahs.length; i++) {
      final rawPage = surah.ayahs[i].page;
      final page = rawPage <= 0 ? 0 : rawPage;
      grouped.putIfAbsent(page, () => <int>[]).add(i);
    }
    final pages = grouped.entries.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 28),
      itemCount: pages.length + 1,
      itemBuilder: (context, listIndex) {
        if (listIndex == 0) {
          return _MushafHeader(
            palette: palette,
            arabicName: surah.arabicName.isEmpty ? widget.arabicName : surah.arabicName,
            englishName: surah.englishName,
            meaning: surah.englishMeaning,
            revelationType: surah.revelationType,
            ayahCount: surah.ayahs.length,
            showBismillah: widget.surahNumber != 9,
          );
        }
        final pageEntry = pages[listIndex - 1];
        final indices = pageEntry.value;
        final first = surah.ayahs[indices.first];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              if (settings.showPageMarkers && pageEntry.key > 0)
                _PageMarker(page: pageEntry.key, juz: first.juz, palette: palette),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  children: indices.map((index) {
                    final ayah = surah.ayahs[index];
                    final active = settings.highlightPlayingAyah && _playingIndex == index;
                    return AnimatedContainer(
                      key: _ayahKeys[index],
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      decoration: BoxDecoration(
                        color: active ? palette.highlight : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: active
                            ? Border.all(color: palette.ornament.withValues(alpha: .6))
                            : null,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _playIndex(index),
                        onLongPress: () => _toggleBookmark(ayah),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (settings.showAyahNumber)
                                  _AyahRosette(number: ayah.numberInSurah, color: palette.ornament),
                                if (_bookmarks.contains(ayah.numberInSurah)) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.bookmark_rounded, size: 17, color: AppColors.gold),
                                ],
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ArabicAyahText(
                                    ayah: ayah,
                                    settings: settings,
                                    color: palette.arabic,
                                  ),
                                ),
                              ],
                            ),
                            if (settings.showTransliteration && ayah.transliteration.isNotEmpty) ...[
                              const SizedBox(height: 7),
                              material.Text(
                                ayah.transliteration,
                                style: TextStyle(
                                  color: palette.ornament,
                                  fontSize: settings.translationFontSize - 1,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            if (settings.showTranslation) ...[
                              const SizedBox(height: 7),
                              if (settings.translationMode != QuranTranslationMode.english && ayah.bangla.isNotEmpty)
                                material.Text(
                                  ayah.bangla,
                                  style: TextStyle(color: palette.translation, fontSize: settings.translationFontSize, height: 1.62),
                                ),
                              if (settings.translationMode == QuranTranslationMode.both && ayah.bangla.isNotEmpty && ayah.english.isNotEmpty)
                                const SizedBox(height: 6),
                              if (settings.translationMode != QuranTranslationMode.bangla && ayah.english.isNotEmpty)
                                material.Text(
                                  ayah.english,
                                  style: TextStyle(color: palette.translation, fontSize: settings.translationFontSize, height: 1.5),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudyReader(
    QuranReaderSettingsProvider settings,
    _ReaderPalette palette,
  ) {
    final surah = _surah!;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 28),
      itemCount: surah.ayahs.length + 1,
      itemBuilder: (context, listIndex) {
        if (listIndex == 0) {
          return _MushafHeader(
            palette: palette,
            arabicName: surah.arabicName.isEmpty ? widget.arabicName : surah.arabicName,
            englishName: surah.englishName,
            meaning: surah.englishMeaning,
            revelationType: surah.revelationType,
            ayahCount: surah.ayahs.length,
            showBismillah: widget.surahNumber != 9,
          );
        }
        final index = listIndex - 1;
        final ayah = surah.ayahs[index];
        final active = settings.highlightPlayingAyah && _playingIndex == index;
        final startsPage = index == 0 || surah.ayahs[index - 1].page != ayah.page;
        return Column(
          key: _ayahKeys[index],
          children: [
            if (settings.showPageMarkers && startsPage && ayah.page > 0)
              _PageMarker(page: ayah.page, juz: ayah.juz, palette: palette),
            _AyahBlock(
              ayah: ayah,
              palette: palette,
              settings: settings,
              active: active,
              bookmarked: _bookmarks.contains(ayah.numberInSurah),
              playing: _playingIndex == index && _playerState == PlayerState.playing,
              onPlay: () => _playIndex(index),
              onBookmark: () => _toggleBookmark(ayah),
              onCopy: () async {
                final translation = settings.translationMode == QuranTranslationMode.english
                    ? ayah.english
                    : ayah.bangla;
                await Clipboard.setData(
                  ClipboardData(
                    text: '${ayah.arabic}\n\n$translation\n\n${widget.surahNumber}:${ayah.numberInSurah}',
                  ),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('আয়াত কপি হয়েছে'), duration: Duration(seconds: 1)),
                );
              },
              onTap: () => _saveProgress(ayah.numberInSurah),
            ),
          ],
        );
      },
    );
  }
}

class _MushafHeader extends StatelessWidget {
  const _MushafHeader({
    required this.palette,
    required this.arabicName,
    required this.englishName,
    required this.meaning,
    required this.revelationType,
    required this.ayahCount,
    required this.showBismillah,
  });

  final _ReaderPalette palette;
  final String arabicName, englishName, meaning, revelationType;
  final int ayahCount;
  final bool showBismillah;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: palette.border, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: palette.ornament)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.auto_awesome, color: palette.ornament, size: 18),
                  ),
                  Expanded(child: Divider(color: palette.ornament)),
                ],
              ),
              const SizedBox(height: 8),
              material.Text(
                arabicName,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: palette.arabic,
                  fontFamily: 'NooreHuda',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              Text(
                '$englishName${meaning.isEmpty ? '' : ' • $meaning'}',
                style: TextStyle(color: palette.subText, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                '$ayahCount আয়াত${revelationType.isEmpty ? '' : ' • $revelationType'}',
                style: TextStyle(color: palette.subText, fontSize: 12),
              ),
              if (showBismillah) ...[
                const SizedBox(height: 14),
                Divider(color: palette.border),
                const SizedBox(height: 8),
                material.Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: palette.arabic,
                    fontFamily: 'NooreHuda',
                    fontSize: 24,
                    height: 1.8,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _PageMarker extends StatelessWidget {
  const _PageMarker({required this.page, required this.juz, required this.palette});
  final int page, juz;
  final _ReaderPalette palette;

  @override
  Widget build(BuildContext context) => Container(
        color: palette.paper,
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 5),
        child: Row(
          children: [
            Text('পারা $juz', style: TextStyle(color: palette.subText, fontSize: 11)),
            Expanded(child: Divider(indent: 9, endIndent: 9, color: palette.border)),
            Text('পৃষ্ঠা $page', style: TextStyle(color: palette.subText, fontSize: 11)),
          ],
        ),
      );
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    required this.ayah,
    required this.palette,
    required this.settings,
    required this.active,
    required this.bookmarked,
    required this.playing,
    required this.onPlay,
    required this.onBookmark,
    required this.onCopy,
    required this.onTap,
  });

  final QuranAyahData ayah;
  final _ReaderPalette palette;
  final QuranReaderSettingsProvider settings;
  final bool active, bookmarked, playing;
  final VoidCallback onPlay, onBookmark, onCopy, onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: active ? palette.highlight : palette.paper,
            border: Border(
              left: BorderSide(color: palette.border, width: 1.5),
              right: BorderSide(color: palette.border, width: 1.5),
              bottom: BorderSide(color: palette.border.withValues(alpha: .55)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (settings.showAyahNumber)
                    _AyahRosette(number: ayah.numberInSurah, color: palette.ornament),
                  const Spacer(),
                  _ReaderAction(
                    icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    tooltip: AppI18n.current('তিলাওয়াত'),
                    color: palette.ornament,
                    onTap: onPlay,
                  ),
                  _ReaderAction(
                    icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    tooltip: AppI18n.current('বুকমার্ক'),
                    color: bookmarked ? AppColors.gold : palette.ornament,
                    onTap: onBookmark,
                  ),
                  _ReaderAction(
                    icon: Icons.copy_rounded,
                    tooltip: AppI18n.current('কপি'),
                    color: palette.ornament,
                    onTap: onCopy,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ArabicAyahText(
                ayah: ayah,
                settings: settings,
                color: palette.arabic,
              ),
              if (settings.showTransliteration && ayah.transliteration.isNotEmpty) ...[
                const SizedBox(height: 9),
                material.Text(
                  ayah.transliteration,
                  style: TextStyle(
                    color: palette.ornament,
                    fontSize: settings.translationFontSize - 1,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
              ],
              if (settings.showTranslation) ...[
                const SizedBox(height: 9),
                Divider(color: palette.border.withValues(alpha: .65)),
                const SizedBox(height: 3),
                if (settings.translationMode != QuranTranslationMode.english && ayah.bangla.isNotEmpty)
                  material.Text(
                    ayah.bangla,
                    style: TextStyle(
                      color: palette.translation,
                      fontSize: settings.translationFontSize,
                      height: 1.65,
                    ),
                  ),
                if (settings.translationMode == QuranTranslationMode.both && ayah.bangla.isNotEmpty && ayah.english.isNotEmpty)
                  const SizedBox(height: 7),
                if (settings.translationMode != QuranTranslationMode.bangla && ayah.english.isNotEmpty)
                  material.Text(
                    ayah.english,
                    style: TextStyle(
                      color: palette.translation,
                      fontSize: settings.translationFontSize,
                      height: 1.55,
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
}

class _ArabicAyahText extends StatelessWidget {
  const _ArabicAyahText({
    required this.ayah,
    required this.settings,
    required this.color,
  });

  final QuranAyahData ayah;
  final QuranReaderSettingsProvider settings;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontFamily: settings.arabicFont == 'System' ? null : settings.arabicFont,
      fontSize: settings.arabicFontSize,
      height: settings.arabicLineHeight,
      fontWeight: FontWeight.w500,
    );
    if (settings.showTajweedColors && ayah.tajweed.isNotEmpty) {
      return TajweedText(ayah.tajweed, style: style);
    }
    return material.Text(
      ayah.arabic,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: style,
    );
  }
}

class _AyahRosette extends StatelessWidget {
  const _AyahRosette({required this.number, required this.color});
  final int number;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
        child: Text(
          '$number',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      );
}

class _ReaderAction extends StatelessWidget {
  const _ReaderAction({required this.icon, required this.tooltip, required this.color, required this.onTap});
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 21),
      );
}

class _AudioDock extends StatelessWidget {
  const _AudioDock({
    required this.palette,
    required this.ayah,
    required this.playing,
    required this.position,
    required this.duration,
    required this.speed,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
  });
  final _ReaderPalette palette;
  final QuranAyahData ayah;
  final bool playing;
  final Duration position, duration;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious, onNext;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Material(
      elevation: 12,
      color: palette.header,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'আয়াত ${ayah.numberInSurah}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text('${speed.toStringAsFixed(speed == 1 ? 0 : 1)}x', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              Slider(
                value: value,
                max: max,
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
                onChanged: duration.inMilliseconds <= 0
                    ? null
                    : (v) => onSeek(Duration(milliseconds: v.round())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: onPrevious, icon: const Icon(Icons.skip_previous_rounded, color: Colors.white)),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: palette.header, shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
                    onPressed: onPlayPause,
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: onNext, icon: const Icon(Icons.skip_next_rounded, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranReaderSettingsSheet extends StatelessWidget {
  const _QuranReaderSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<QuranReaderSettingsProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: .88,
        minChildSize: .55,
        maxChildSize: .96,
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 14),
            const Text('কুরআন পাঠ সেটিংস', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            _settingTitle('পাঠের ধরন'),
            SegmentedButton<QuranLayoutMode>(
              segments: const [
                ButtonSegment(value: QuranLayoutMode.mushaf, icon: Icon(Icons.menu_book_rounded), label: Text('মুসহাফ')),
                ButtonSegment(value: QuranLayoutMode.study, icon: Icon(Icons.view_agenda_outlined), label: Text('স্টাডি')),
              ],
              selected: {s.layoutMode},
              onSelectionChanged: (value) => s.update(layoutMode: value.first),
            ),
            const SizedBox(height: 14),
            _settingTitle('ডিসপ্লে'),
            SwitchListTile.adaptive(value: s.showTranslation, title: const Text('অনুবাদ দেখান'), onChanged: (v) => s.update(showTranslation: v)),
            SwitchListTile.adaptive(value: s.showTransliteration, title: const Text('উচ্চারণ দেখান'), onChanged: (v) => s.update(showTransliteration: v)),
            SwitchListTile.adaptive(value: s.showAyahNumber, title: const Text('আয়াত নম্বর দেখান'), onChanged: (v) => s.update(showAyahNumber: v)),
            SwitchListTile.adaptive(
              value: s.showTajweedColors,
              title: const Text('তাজবীদ কালার দেখান'),
              subtitle: const Text('মাদ্দ, গুন্নাহ, ইখফা, ইকলাব ও অন্যান্য তাজবীদ নিয়ম রঙে দেখুন'),
              onChanged: (v) => s.update(showTajweedColors: v),
            ),
            SwitchListTile.adaptive(value: s.highlightPlayingAyah, title: const Text('অডিও চললে আয়াত হাইলাইট করুন'), onChanged: (v) => s.update(highlightPlayingAyah: v)),
            SwitchListTile.adaptive(value: s.autoScroll, title: const Text('অডিওর সাথে স্বয়ংক্রিয় স্ক্রল'), onChanged: (v) => s.update(autoScroll: v)),
            SwitchListTile.adaptive(value: s.showPageMarkers, title: const Text('পৃষ্ঠা ও পারা চিহ্ন দেখান'), onChanged: (v) => s.update(showPageMarkers: v)),
            const Divider(),
            _settingTitle('অনুবাদের ভাষা'),
            DropdownButtonFormField<QuranTranslationMode>(
              value: s.translationMode,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: QuranTranslationMode.bangla, child: Text('বাংলা — মুহিউদ্দীন খান')),
                DropdownMenuItem(value: QuranTranslationMode.english, child: Text('English — Saheeh International')),
                DropdownMenuItem(value: QuranTranslationMode.both, child: Text('বাংলা + English')),
              ],
              onChanged: (v) { if (v != null) s.update(translationMode: v); },
            ),
            const SizedBox(height: 18),
            _settingTitle('কুরআনের ডিজাইন'),
            Wrap(
              spacing: 8,
              children: QuranReaderTheme.values.map((theme) => ChoiceChip(
                selected: s.readerTheme == theme,
                label: Text(switch (theme) {
                  QuranReaderTheme.paper => 'মুসহাফ পেপার',
                  QuranReaderTheme.clean => 'ক্লিন',
                  QuranReaderTheme.sepia => 'সেপিয়া',
                  QuranReaderTheme.night => 'নাইট',
                }),
                onSelected: (_) => s.update(readerTheme: theme),
              )).toList(),
            ),
            const SizedBox(height: 14),
            _SliderSetting(label: 'আরবি ফন্ট সাইজ', value: s.arabicFontSize, min: 20, max: 48, divisions: 28, onChanged: (v) => s.update(arabicFontSize: v)),
            _SliderSetting(label: 'অনুবাদ ফন্ট সাইজ', value: s.translationFontSize, min: 12, max: 24, divisions: 12, onChanged: (v) => s.update(translationFontSize: v)),
            _SliderSetting(label: 'আরবি লাইন স্পেসিং', value: s.arabicLineHeight, min: 1.5, max: 2.6, divisions: 11, onChanged: (v) => s.update(arabicLineHeight: v)),
            DropdownButtonFormField<String>(
              value: s.arabicFont,
              decoration: InputDecoration(labelText: AppI18n.current('আরবি ফন্ট'), border: const OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'NooreHuda', child: Text('NooreHuda — মুসহাফ স্টাইল')),
                DropdownMenuItem(value: 'NooreHera', child: Text('NooreHera')),
                DropdownMenuItem(value: 'System', child: Text('System Arabic')),
              ],
              onChanged: (v) { if (v != null) s.update(arabicFont: v); },
            ),
            const SizedBox(height: 18),
            _settingTitle('তিলাওয়াত'),
            DropdownButtonFormField<String>(
              value: s.reciter,
              decoration: InputDecoration(labelText: AppI18n.current('ক্বারী নির্বাচন করুন'), border: const OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'ar.alafasy', child: Text('Mishary Rashid Alafasy')),
                DropdownMenuItem(value: 'ar.husary', child: Text('Mahmoud Khalil Al-Husary')),
                DropdownMenuItem(value: 'ar.minshawi', child: Text('Muhammad Siddiq Al-Minshawi')),
                DropdownMenuItem(value: 'ar.sudais', child: Text('Abdul Rahman Al-Sudais')),
                DropdownMenuItem(value: 'ar.shuraim', child: Text('Saud Al-Shuraim')),
                DropdownMenuItem(value: 'ar.abdulbasit', child: Text('Abdul Basit Abdus Samad')),
                DropdownMenuItem(value: 'ar.ajamy', child: Text('Ahmed Al-Ajamy')),
                DropdownMenuItem(value: 'ar.hudhaify', child: Text('Ali Al-Hudhaify')),
              ],
              onChanged: (v) { if (v != null) s.update(reciter: v); },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(value: s.continuousPlayback, title: const Text('এক আয়াত শেষে পরের আয়াত অটো চালান'), onChanged: (v) => s.update(continuousPlayback: v)),
            SwitchListTile.adaptive(value: s.cacheAudioWhilePlaying, title: const Text('শোনার সময় অডিও অফলাইনের জন্য cache করুন'), onChanged: (v) => s.update(cacheAudioWhilePlaying: v)),
            const SizedBox(height: 4),
            DropdownButtonFormField<QuranRepeatMode>(
              value: s.repeatMode,
              decoration: InputDecoration(labelText: AppI18n.current('রিপিট মোড'), border: const OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: QuranRepeatMode.none, child: Text('রিপিট বন্ধ')),
                DropdownMenuItem(value: QuranRepeatMode.ayah, child: Text('বর্তমান আয়াত রিপিট')),
                DropdownMenuItem(value: QuranRepeatMode.surah, child: Text('পুরো সূরা রিপিট')),
              ],
              onChanged: (v) { if (v != null) s.update(repeatMode: v); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              value: s.playbackSpeed,
              decoration: InputDecoration(labelText: AppI18n.current('অডিও গতি'), border: const OutlineInputBorder()),
              items: const [.75, 1.0, 1.25, 1.5].map((v) => DropdownMenuItem(value: v, child: Text('${v}x'))).toList(),
              onChanged: (v) { if (v != null) s.update(playbackSpeed: v); },
            ),
            const SizedBox(height: 14),
            const Text(
              'কুরআনের আরবি ও অনুমোদিত অনুবাদ UI translation engine দিয়ে পরিবর্তন করা হয় না। আগে খোলা সূরা Isar-এ cache থাকলে internet ছাড়াই পড়া যাবে।',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary)),
      );
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.onChanged});
  final String label;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(value >= 10 ? 0 : 1)}'),
          Slider(value: value.clamp(min, max).toDouble(), min: min, max: max, divisions: divisions, onChanged: onChanged),
        ],
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.palette});
  final _ReaderPalette palette;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: palette.header),
          const SizedBox(height: 12),
          Text('কুরআনের নির্ভুল পাঠ লোড হচ্ছে...', style: TextStyle(color: palette.translation)),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.palette, required this.onRetry});
  final _ReaderPalette palette;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: palette.ornament),
            const SizedBox(height: 12),
            Text('এই সূরাটি এখনো অফলাইনে সংরক্ষিত নেই', textAlign: TextAlign.center, style: TextStyle(color: palette.translation, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('একবার internet-এ খুললে পরে Isar cache থেকে offline পড়তে পারবেন।', textAlign: TextAlign.center, style: TextStyle(color: palette.subText)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('আবার চেষ্টা করুন')),
          ]),
        ),
      );
}

class _ReaderPalette {
  const _ReaderPalette({required this.background, required this.paper, required this.header, required this.arabic, required this.translation, required this.subText, required this.border, required this.ornament, required this.highlight});
  final Color background, paper, header, arabic, translation, subText, border, ornament, highlight;

  static _ReaderPalette of(QuranReaderTheme theme) => switch (theme) {
        QuranReaderTheme.clean => const _ReaderPalette(
            background: Color(0xFFF2F6F3), paper: Colors.white, header: Color(0xFF0D5A38), arabic: Color(0xFF14241C), translation: Color(0xFF263C31), subText: Color(0xFF6C7A72), border: Color(0xFFD5E1DA), ornament: Color(0xFF227A52), highlight: Color(0xFFE1F3E9)),
        QuranReaderTheme.sepia => const _ReaderPalette(
            background: Color(0xFFE1CFA7), paper: Color(0xFFF6E9CC), header: Color(0xFF684E27), arabic: Color(0xFF2E2416), translation: Color(0xFF4D3D26), subText: Color(0xFF7A684E), border: Color(0xFFCAB483), ornament: Color(0xFF8B6A31), highlight: Color(0xFFFFE5A8)),
        QuranReaderTheme.night => const _ReaderPalette(
            background: Color(0xFF07110D), paper: Color(0xFF101D17), header: Color(0xFF123D2B), arabic: Color(0xFFF1E8CF), translation: Color(0xFFD0D8D3), subText: Color(0xFF8FA099), border: Color(0xFF284236), ornament: Color(0xFFC8A95B), highlight: Color(0xFF263B2E)),
        _ => const _ReaderPalette(
            background: Color(0xFFE8DDC5), paper: Color(0xFFFFF8E6), header: Color(0xFF315A3D), arabic: Color(0xFF2A241B), translation: Color(0xFF463E31), subText: Color(0xFF786E5E), border: Color(0xFFD7C9A5), ornament: Color(0xFF9B7B38), highlight: Color(0xFFFFE8A8)),
      };
}
