import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/local/local_store.dart';
import '../localization/app_i18n.dart';

enum AppLanguage { bangla, english }

class AppLanguageProvider extends ChangeNotifier {
  static const _namespace = 'settings';
  static const _key = 'language';
  static const MethodChannel _nativeChannel = MethodChannel('com.butterflydevs.noorvia/prayer_alarm');

  AppLanguage _language = AppLanguage.bangla;
  bool _loaded = false;

  AppLanguageProvider() {
    _load();
  }

  AppLanguage get language => _language;
  bool get loaded => _loaded;
  bool get isBangla => _language == AppLanguage.bangla;
  Locale get locale => Locale(isBangla ? 'bn' : 'en');

  Future<void> _load() async {
    try {
      final data = await LocalStore.instance.getJson(_namespace, _key);
      final value = data?['value']?.toString();
      if (value == 'en') _language = AppLanguage.english;
    } catch (_) {
      // Bangla is intentionally the safe/default language.
    }
    AppI18n.setCurrentLanguageCode(isBangla ? 'bn' : 'en');
    _loaded = true;
    notifyListeners();
    await _syncNativeLanguage();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    AppI18n.setCurrentLanguageCode(isBangla ? 'bn' : 'en');
    notifyListeners();
    await LocalStore.instance.putJson(
      _namespace,
      _key,
      {'value': isBangla ? 'bn' : 'en'},
    );
    await _syncNativeLanguage();
  }


  Future<void> _syncNativeLanguage() async {
    if (kIsWeb) return;
    try {
      await _nativeChannel.invokeMethod('setAppLanguage', {
        'language': isBangla ? 'bn' : 'en',
      });
    } catch (_) {
      // Native sync is best-effort (desktop/iOS do not expose this Android channel).
    }
  }

  Future<void> toggle() => setLanguage(
        isBangla ? AppLanguage.english : AppLanguage.bangla,
      );
}
