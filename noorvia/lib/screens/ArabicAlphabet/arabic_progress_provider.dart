import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArabicProgressProvider extends ChangeNotifier {
  static const _learnedKey = 'arabic_learned';
  static const _favKey = 'arabic_favorites';
  static const _streakKey = 'arabic_streak';
  static const _lastLoginKey = 'arabic_last_login';

  Set<String> _learned = {};
  Set<String> _favorites = {};
  int _streak = 0;

  int get learnedCount => _learned.length;
  int get streak => _streak;

  bool isLearned(String letter) => _learned.contains(letter);
  bool isFavorite(String letter) => _favorites.contains(letter);

  List<String> get favorites => _favorites.toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _learned = Set<String>.from(prefs.getStringList(_learnedKey) ?? []);
    _favorites = Set<String>.from(prefs.getStringList(_favKey) ?? []);
    _streak = prefs.getInt(_streakKey) ?? 0;

    // Update daily streak
    final lastLogin = prefs.getString(_lastLoginKey);
    final today = _todayStr();
    if (lastLogin == null) {
      _streak = 1;
    } else if (lastLogin != today) {
      final yesterday = _yesterdayStr();
      if (lastLogin == yesterday) {
        _streak += 1;
      } else {
        _streak = 1;
      }
    }
    await prefs.setString(_lastLoginKey, today);
    await prefs.setInt(_streakKey, _streak);
    notifyListeners();
  }

  Future<void> markLearned(String letter) async {
    if (_learned.contains(letter)) return;
    _learned.add(letter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_learnedKey, _learned.toList());
    notifyListeners();
  }

  Future<void> toggleFavorite(String letter) async {
    if (_favorites.contains(letter)) {
      _favorites.remove(letter);
    } else {
      _favorites.add(letter);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, _favorites.toList());
    notifyListeners();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _yesterdayStr() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month}-${yesterday.day}';
  }
}
