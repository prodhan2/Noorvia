// ============================================================
//  notification_screen.dart
//  Islamic Notifications — offline-first with cache support.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Root MultiProvider থেকে NotificationProvider নিয়ে pass করি
    // নতুন instance তৈরি করা হচ্ছে না — global provider ব্যবহার হচ্ছে
    return const _NotificationView();
  }
}

class _NotificationView extends StatefulWidget {
  const _NotificationView();

  @override
  State<_NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<_NotificationView> {
  Timer? _demoTimer;
  int _secondsLeft = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDemoTimer();
      _startCountdown();
    });
  }

  void _startDemoTimer() {
    _demoTimer = Timer(const Duration(minutes: 1), () async {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      if (!provider.hasData) return;
      final sent = await provider.showRandomLocalNotification();
      if (!mounted) return;
      if (sent) _showAutoSnackBar();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _secondsLeft = (_secondsLeft - 1).clamp(0, 60); });
      if (_secondsLeft == 0) t.cancel();
    });
  }

  void _showAutoSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('⏰', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text('১ মিনিট পূর্ণ! ডেমো নোটিফিকেশন পাঠানো হয়েছে',
            style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF1565C0),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final provider = context.watch<NotificationProvider>();
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, isDark, provider),
      body: _buildBody(context, isDark, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, NotificationProvider provider) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ইসলামিক নোটিফিকেশন',
                        style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (provider.hasData)
                      Text('${provider.notifications.length}টি বার্তা',
                          style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
              if (provider.state != NotifSyncState.firstSync)
                GestureDetector(
                  onTap: provider.state == NotifSyncState.refreshing ? null : () => provider.refresh(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                    ),
                    child: provider.state == NotifSyncState.refreshing
                        ? const Padding(padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, NotificationProvider provider) {
    switch (provider.state) {
      case NotifSyncState.firstSync:
        return _FirstSyncLoader(isDark: isDark);
      case NotifSyncState.error:
        return _ErrorView(isDark: isDark, message: provider.errorMessage, onRetry: () => provider.refresh());
      case NotifSyncState.loaded:
      case NotifSyncState.refreshing:
      case NotifSyncState.offline:
      case NotifSyncState.idle:
        return _NotificationList(isDark: isDark, provider: provider, secondsLeft: _secondsLeft);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// First Sync Loader
// ─────────────────────────────────────────────────────────────
class _FirstSyncLoader extends StatelessWidget {
  final bool isDark;
  const _FirstSyncLoader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.gradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Center(child: Text('🕌', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 28),
          Text('প্রথমবার ডেটা লোড হচ্ছে...',
              style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('ইসলামিক বার্তাগুলো ডাউনলোড করা হচ্ছে।\nএরপর অফলাইনেও কাজ করবে।',
              style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('একটু অপেক্ষা করুন...', style: GoogleFonts.hindSiliguri(fontSize: 12, color: subColor)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.isDark, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          Text('সংযোগ ব্যর্থ',
              style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 8),
          Text(message,
              style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('আবার চেষ্টা করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification List
// ─────────────────────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  final bool isDark;
  final NotificationProvider provider;
  final int secondsLeft;

  const _NotificationList({required this.isDark, required this.provider, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _StatusBanner(isDark: isDark, provider: provider, secondsLeft: secondsLeft)),
      SliverToBoxAdapter(child: _RandomHighlight(isDark: isDark, provider: provider, cardBg: cardBg, textColor: textColor, subColor: subColor)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final notif = provider.notifications[index];
              return _NotificationCard(notif: notif, isDark: isDark, cardBg: cardBg, textColor: textColor, subColor: subColor);
            },
            childCount: provider.notifications.length,
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final bool isDark;
  final NotificationProvider provider;
  final int secondsLeft;
  const _StatusBanner({required this.isDark, required this.provider, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final isOffline = provider.state == NotifSyncState.offline;
    final isRefreshing = provider.state == NotifSyncState.refreshing;
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOffline ? Colors.orange.withValues(alpha: 0.12)
              : isRefreshing ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOffline ? Colors.orange.withValues(alpha: 0.4)
                : isRefreshing ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : isRefreshing ? Icons.sync_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: isOffline ? Colors.orange : isRefreshing ? AppColors.primary : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline ? 'অফলাইন মোড — ক্যাশ থেকে লোড হয়েছে'
                  : isRefreshing ? 'আপডেট হচ্ছে...'
                  : 'সর্বশেষ আপডেট: ${provider.lastUpdatedText}',
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: isOffline ? Colors.orange.shade700 : isRefreshing ? AppColors.primary : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isRefreshing)
            GestureDetector(
              onTap: () => provider.refresh(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('আপডেট করুন', style: GoogleFonts.hindSiliguri(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📳', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text('ঝাঁকান → নতুন বার্তা', style: GoogleFonts.hindSiliguri(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: secondsLeft > 0 ? Colors.blue.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: secondsLeft > 0 ? Colors.blue.withValues(alpha: 0.25) : Colors.green.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(secondsLeft > 0 ? '⏱️' : '🔔', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                secondsLeft > 0 ? 'ডেমো: ${secondsLeft}s' : 'ডেমো হয়েছে!',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  color: secondsLeft > 0 ? Colors.blue.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Random Notification Highlight Card
// ─────────────────────────────────────────────────────────────
class _RandomHighlight extends StatefulWidget {
  final bool isDark;
  final NotificationProvider provider;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  const _RandomHighlight({required this.isDark, required this.provider, required this.cardBg, required this.textColor, required this.subColor});

  @override
  State<_RandomHighlight> createState() => _RandomHighlightState();
}

class _RandomHighlightState extends State<_RandomHighlight> {
  IslamicNotification? _random;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _random = widget.provider.getRandomNotification();
  }

  void _shuffle() => setState(() { _random = widget.provider.getRandomNotification(); });

  Future<void> _sendNotification() async {
    if (_sending) return;
    setState(() => _sending = true);
    final sent = await widget.provider.showRandomLocalNotification();
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent ? '✅ নোটিফিকেশন পাঠানো হয়েছে!' : '❌ ডেটা পাওয়া যায়নি',
          style: GoogleFonts.hindSiliguri(fontSize: 13)),
      backgroundColor: sent ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_random == null) return const SizedBox.shrink();
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_random!.typeIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('আজকের বার্তা', style: GoogleFonts.hindSiliguri(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: _shuffle,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 16),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(_random!.title, style: GoogleFonts.hindSiliguri(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            Text(_random!.message, style: GoogleFonts.hindSiliguri(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
            if (_random!.reference.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('— ${_random!.reference}', style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.offline_bolt_rounded, size: 10, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('লোকাল ক্যাশ থেকে', style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.white70)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _sendNotification,
            icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.notifications_active_rounded, size: 18),
            label: Text(_sending ? 'পাঠানো হচ্ছে...' : 'র‍্যান্ডম নোটিফিকেশন দেখান',
                style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Individual Notification Card
// ─────────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final IslamicNotification notif;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subColor;
  const _NotificationCard({required this.notif, required this.isDark, required this.cardBg, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text(notif.typeIcon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(notif.title,
                    style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.w700, color: textColor))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(notif.typeLabel, style: GoogleFonts.hindSiliguri(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 5),
              Text(notif.message, style: GoogleFonts.hindSiliguri(fontSize: 13, color: subColor, height: 1.5)),
              if (notif.reference.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('— ${notif.reference}',
                    style: GoogleFonts.hindSiliguri(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
