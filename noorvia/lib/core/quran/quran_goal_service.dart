import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/local/local_store.dart';
import '../services/firebase_session_service.dart';

class QuranGoalPlan {
  const QuranGoalPlan({
    required this.enabled,
    required this.startDate,
    required this.targetDate,
    required this.startPage,
    required this.currentPage,
    required this.totalPages,
    required this.dailyTargetPages,
    required this.hifzDailyAyahs,
    required this.hifzCompletedAyahs,
  });

  final bool enabled;
  final DateTime startDate;
  final DateTime targetDate;
  final int startPage;
  final int currentPage;
  final int totalPages;
  final int dailyTargetPages;
  final int hifzDailyAyahs;
  final int hifzCompletedAyahs;

  int get completedPages => (currentPage - startPage).clamp(0, totalPages);
  double get progress => totalPages <= 0 ? 0 : completedPages / totalPages;
  int get pagesRemaining => (totalPages - completedPages).clamp(0, totalPages);
  int get daysRemaining {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return b.difference(a).inDays.clamp(0, 9999);
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startDate': startDate.toUtc().toIso8601String(),
        'targetDate': targetDate.toUtc().toIso8601String(),
        'startPage': startPage,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'dailyTargetPages': dailyTargetPages,
        'hifzDailyAyahs': hifzDailyAyahs,
        'hifzCompletedAyahs': hifzCompletedAyahs,
      };

  factory QuranGoalPlan.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return QuranGoalPlan(
      enabled: json['enabled'] != false,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? now,
      targetDate: DateTime.tryParse(json['targetDate']?.toString() ?? '') ?? now.add(const Duration(days: 30)),
      startPage: (json['startPage'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 604,
      dailyTargetPages: (json['dailyTargetPages'] as num?)?.toInt() ?? 20,
      hifzDailyAyahs: (json['hifzDailyAyahs'] as num?)?.toInt() ?? 3,
      hifzCompletedAyahs: (json['hifzCompletedAyahs'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuranGoalService {
  QuranGoalService._();
  static final QuranGoalService instance = QuranGoalService._();

  static const _namespace = 'quran_goals_v1';
  static const _key = 'main';

  Future<QuranGoalPlan> load() async {
    final saved = await LocalStore.instance.getJson(_namespace, _key);
    var local = saved == null ? null : QuranGoalPlan.fromJson(saved);

    // Local-first: never block the Quran UI on cloud. If Firebase is
    // available, merge recoverable progress without allowing an older cloud
    // copy to reduce pages/ayahs already completed on this device.
    try {
      final user = await FirebaseSessionService.ensureSignedIn();
      if (user != null) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('quran_progress')
            .doc('goals');
        final snapshot = await ref.get();
        if (snapshot.exists && snapshot.data() != null) {
          final cloud = QuranGoalPlan.fromJson(snapshot.data()!);
          local = local == null ? cloud : _mergeProgress(local, cloud);
          await _saveLocal(local);
        }
      }
    } catch (_) {}

    if (local != null) return local;
    return createPlan(days: 30);
  }

  Future<QuranGoalPlan> createPlan({
    required int days,
    int startPage = 1,
    int hifzDailyAyahs = 3,
  }) async {
    final safeDays = days.clamp(1, 3650);
    final safeStart = startPage.clamp(1, 604);
    final pages = 605 - safeStart;
    final daily = (pages / safeDays).ceil().clamp(1, 604);
    final now = DateTime.now();
    final plan = QuranGoalPlan(
      enabled: true,
      startDate: now,
      targetDate: now.add(Duration(days: safeDays)),
      startPage: safeStart,
      currentPage: safeStart,
      totalPages: pages,
      dailyTargetPages: daily,
      hifzDailyAyahs: hifzDailyAyahs.clamp(1, 50),
      hifzCompletedAyahs: 0,
    );
    await save(plan);
    return plan;
  }

  Future<void> _saveLocal(QuranGoalPlan plan, {String syncStatus = 'local'}) =>
      LocalStore.instance.putJson(
        _namespace,
        _key,
        plan.toJson(),
        syncStatus: syncStatus,
      );

  Future<void> save(QuranGoalPlan plan) async {
    await _saveLocal(plan, syncStatus: 'pending');
    try {
      final user = await FirebaseSessionService.ensureSignedIn();
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quran_progress')
          .doc('goals')
          .set({
        ...plan.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _saveLocal(plan, syncStatus: 'synced');
    } catch (_) {
      // Firestore SDK will normally queue writes offline. If auth/network is
      // unavailable, the Isar copy remains authoritative until the next save.
    }
  }

  QuranGoalPlan _mergeProgress(QuranGoalPlan local, QuranGoalPlan cloud) {
    final useCloudPlan = cloud.currentPage > local.currentPage;
    final base = useCloudPlan ? cloud : local;
    return QuranGoalPlan(
      enabled: base.enabled,
      startDate: base.startDate,
      targetDate: base.targetDate,
      startPage: base.startPage,
      currentPage: local.currentPage > cloud.currentPage
          ? local.currentPage
          : cloud.currentPage,
      totalPages: base.totalPages,
      dailyTargetPages: base.dailyTargetPages,
      hifzDailyAyahs: base.hifzDailyAyahs,
      hifzCompletedAyahs: local.hifzCompletedAyahs > cloud.hifzCompletedAyahs
          ? local.hifzCompletedAyahs
          : cloud.hifzCompletedAyahs,
    );
  }

  Future<QuranGoalPlan> setCurrentPage(QuranGoalPlan plan, int page) async {
    final updated = QuranGoalPlan(
      enabled: plan.enabled,
      startDate: plan.startDate,
      targetDate: plan.targetDate,
      startPage: plan.startPage,
      currentPage: page.clamp(plan.startPage, 604),
      totalPages: plan.totalPages,
      dailyTargetPages: plan.dailyTargetPages,
      hifzDailyAyahs: plan.hifzDailyAyahs,
      hifzCompletedAyahs: plan.hifzCompletedAyahs,
    );
    await save(updated);
    return updated;
  }

  Future<QuranGoalPlan> addHifz(QuranGoalPlan plan, int delta) async {
    final updated = QuranGoalPlan(
      enabled: plan.enabled,
      startDate: plan.startDate,
      targetDate: plan.targetDate,
      startPage: plan.startPage,
      currentPage: plan.currentPage,
      totalPages: plan.totalPages,
      dailyTargetPages: plan.dailyTargetPages,
      hifzDailyAyahs: plan.hifzDailyAyahs,
      hifzCompletedAyahs: (plan.hifzCompletedAyahs + delta).clamp(0, 6236),
    );
    await save(updated);
    return updated;
  }

  Future<int?> lastReadPage() async {
    final progress = await LocalStore.instance.getJson('quran_progress', 'last_read');
    return (progress?['page'] as num?)?.toInt();
  }
}
