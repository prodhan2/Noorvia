import 'package:flutter/foundation.dart';

import '../data/local/local_store.dart';

enum QuranTranslationMode { bangla, english, both }
enum QuranReaderTheme { paper, clean, sepia, night }
enum QuranRepeatMode { none, ayah, surah }
enum QuranLayoutMode { mushaf, study }

class QuranReaderSettingsProvider extends ChangeNotifier {
  static const _namespace = 'settings';
  static const _key = 'quran_reader';

  bool showTranslation = true;
  bool showTransliteration = false;
  bool showAyahNumber = true;
  bool showTajweedColors = false;
  bool autoScroll = true;
  bool highlightPlayingAyah = true;
  bool continuousPlayback = true;
  bool showPageMarkers = true;
  bool cacheAudioWhilePlaying = true;
  double arabicFontSize = 31;
  double translationFontSize = 15;
  double arabicLineHeight = 2.05;
  double playbackSpeed = 1.0;
  String arabicFont = 'NooreHuda';
  String reciter = 'ar.alafasy';
  QuranTranslationMode translationMode = QuranTranslationMode.bangla;
  QuranReaderTheme readerTheme = QuranReaderTheme.paper;
  QuranRepeatMode repeatMode = QuranRepeatMode.none;
  QuranLayoutMode layoutMode = QuranLayoutMode.mushaf;

  QuranReaderSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final data = await LocalStore.instance.getJson(_namespace, _key);
    if (data == null) return;
    showTranslation = data['showTranslation'] != false;
    showTransliteration = data['showTransliteration'] == true;
    showAyahNumber = data['showAyahNumber'] != false;
    showTajweedColors = data['showTajweedColors'] == true;
    autoScroll = data['autoScroll'] != false;
    highlightPlayingAyah = data['highlightPlayingAyah'] != false;
    continuousPlayback = data['continuousPlayback'] != false;
    showPageMarkers = data['showPageMarkers'] != false;
    cacheAudioWhilePlaying = data['cacheAudioWhilePlaying'] != false;
    arabicFontSize = (data['arabicFontSize'] as num?)?.toDouble() ?? 31;
    translationFontSize = (data['translationFontSize'] as num?)?.toDouble() ?? 15;
    arabicLineHeight = (data['arabicLineHeight'] as num?)?.toDouble() ?? 2.05;
    playbackSpeed = (data['playbackSpeed'] as num?)?.toDouble() ?? 1.0;
    arabicFont = data['arabicFont']?.toString() ?? 'NooreHuda';
    reciter = data['reciter']?.toString() ?? 'ar.alafasy';
    translationMode = QuranTranslationMode.values.firstWhere(
      (e) => e.name == data['translationMode'],
      orElse: () => QuranTranslationMode.bangla,
    );
    readerTheme = QuranReaderTheme.values.firstWhere(
      (e) => e.name == data['readerTheme'],
      orElse: () => QuranReaderTheme.paper,
    );
    repeatMode = QuranRepeatMode.values.firstWhere(
      (e) => e.name == data['repeatMode'],
      orElse: () => QuranRepeatMode.none,
    );
    layoutMode = QuranLayoutMode.values.firstWhere(
      (e) => e.name == data['layoutMode'],
      orElse: () => QuranLayoutMode.mushaf,
    );
    notifyListeners();
  }

  Future<void> update({
    bool? showTranslation,
    bool? showTransliteration,
    bool? showAyahNumber,
    bool? showTajweedColors,
    bool? autoScroll,
    bool? highlightPlayingAyah,
    bool? continuousPlayback,
    bool? showPageMarkers,
    bool? cacheAudioWhilePlaying,
    double? arabicFontSize,
    double? translationFontSize,
    double? arabicLineHeight,
    double? playbackSpeed,
    String? arabicFont,
    String? reciter,
    QuranTranslationMode? translationMode,
    QuranReaderTheme? readerTheme,
    QuranRepeatMode? repeatMode,
    QuranLayoutMode? layoutMode,
  }) async {
    if (showTranslation != null) this.showTranslation = showTranslation;
    if (showTransliteration != null) this.showTransliteration = showTransliteration;
    if (showAyahNumber != null) this.showAyahNumber = showAyahNumber;
    if (showTajweedColors != null) this.showTajweedColors = showTajweedColors;
    if (autoScroll != null) this.autoScroll = autoScroll;
    if (highlightPlayingAyah != null) this.highlightPlayingAyah = highlightPlayingAyah;
    if (continuousPlayback != null) this.continuousPlayback = continuousPlayback;
    if (showPageMarkers != null) this.showPageMarkers = showPageMarkers;
    if (cacheAudioWhilePlaying != null) this.cacheAudioWhilePlaying = cacheAudioWhilePlaying;
    if (arabicFontSize != null) this.arabicFontSize = arabicFontSize;
    if (translationFontSize != null) this.translationFontSize = translationFontSize;
    if (arabicLineHeight != null) this.arabicLineHeight = arabicLineHeight;
    if (playbackSpeed != null) this.playbackSpeed = playbackSpeed;
    if (arabicFont != null) this.arabicFont = arabicFont;
    if (reciter != null) this.reciter = reciter;
    if (translationMode != null) this.translationMode = translationMode;
    if (readerTheme != null) this.readerTheme = readerTheme;
    if (repeatMode != null) this.repeatMode = repeatMode;
    if (layoutMode != null) this.layoutMode = layoutMode;
    notifyListeners();
    await _save();
  }

  Future<void> _save() => LocalStore.instance.putJson(_namespace, _key, {
        'showTranslation': showTranslation,
        'showTransliteration': showTransliteration,
        'showAyahNumber': showAyahNumber,
        'showTajweedColors': showTajweedColors,
        'autoScroll': autoScroll,
        'highlightPlayingAyah': highlightPlayingAyah,
        'continuousPlayback': continuousPlayback,
        'showPageMarkers': showPageMarkers,
        'cacheAudioWhilePlaying': cacheAudioWhilePlaying,
        'arabicFontSize': arabicFontSize,
        'translationFontSize': translationFontSize,
        'arabicLineHeight': arabicLineHeight,
        'playbackSpeed': playbackSpeed,
        'arabicFont': arabicFont,
        'reciter': reciter,
        'translationMode': translationMode.name,
        'readerTheme': readerTheme.name,
        'repeatMode': repeatMode.name,
        'layoutMode': layoutMode.name,
      });
}
