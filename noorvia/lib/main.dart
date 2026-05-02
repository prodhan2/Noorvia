import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async' show unawaited;
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/nav_provider.dart';
import 'core/providers/prayer_provider.dart';
import 'core/providers/audio_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/data_sync_service.dart';
import 'core/services/shake_detector_service.dart';
import 'core/services/scheduled_notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/floating_audio_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
    // Initialise local notifications (Android only)
    await LocalNotificationService.init();
    // Schedule daily morning (8:00) & night (21:00) notifications
    unawaited(ScheduledNotificationService.init());
  }

  // Background JSON sync — net পেলেই silently সব JSON reload করে
  unawaited(DataSyncService.instance.init());

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NoorviaApp());
}

// Global navigator key — used to access root Overlay from anywhere
final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

class NoorviaApp extends StatelessWidget {
  const NoorviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer3<ThemeProvider, AudioProvider, SettingsProvider>(
        builder: (context, themeProvider, audioProvider, settings, _) {
          return _AudioOverlayInjector(
            audioProvider: audioProvider,
            child: _GlobalShakeDetector(
              child: MaterialApp(
                navigatorKey: _navKey,
                title: 'নূরভিয়া',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.buildLight(settings.banglaFont, settings.accent),
                darkTheme: AppTheme.buildDark(settings.banglaFont, settings.accent),
                themeMode: themeProvider.themeMode,
                home: const SplashScreen(),
                builder: (context, child) {
                  // Apply global text scale to all text
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(settings.textScale),
                    ),
                    child: child!,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _GlobalShakeDetector
// App-wide shake detection — works on every screen, even when
// the notification screen is not open.
// Reads NotificationProvider from the root MultiProvider.
// ─────────────────────────────────────────────────────────────
class _GlobalShakeDetector extends StatefulWidget {
  final Widget child;
  const _GlobalShakeDetector({required this.child});

  @override
  State<_GlobalShakeDetector> createState() => _GlobalShakeDetectorState();
}

class _GlobalShakeDetectorState extends State<_GlobalShakeDetector>
    with WidgetsBindingObserver {
  ShakeDetectorService? _shakeDetector;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startShake());
  }

  void _startShake() {
    _shakeDetector?.dispose();
    _shakeDetector = ShakeDetectorService(onShake: () async {
      final provider = context.read<NotificationProvider>();
      await provider.showRandomLocalNotification();
    });
    _shakeDetector!.start();
  }

  // Resume shake when app comes to foreground.
  // Do NOT stop on paused/inactive — those states still have sensor access
  // on most Android devices (screen may still be on, app just lost focus).
  // Only stop when the process is truly detached / about to be killed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startShake();
    } else if (state == AppLifecycleState.detached) {
      _shakeDetector?.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────
// _AudioOverlayInjector
// Waits for the Navigator's Overlay to be ready, then inserts
// FloatingAudioPlayer into it. Uses navigatorKey so it survives
// all route changes. ListenableBuilder ensures the OverlayEntry
// rebuilds whenever AudioProvider notifies.
// ─────────────────────────────────────────────────────────────
class _AudioOverlayInjector extends StatefulWidget {
  final AudioProvider audioProvider;
  final Widget child;

  const _AudioOverlayInjector({
    required this.audioProvider,
    required this.child,
  });

  @override
  State<_AudioOverlayInjector> createState() => _AudioOverlayInjectorState();
}

class _AudioOverlayInjectorState extends State<_AudioOverlayInjector> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    // Wait for MaterialApp + Navigator + Overlay to be fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _insertEntry());
    });
  }

  void _insertEntry() {
    if (!mounted) return;

    final overlay = _navKey.currentState?.overlay;
    if (overlay == null) {
      // Retry once more if overlay not ready yet
      WidgetsBinding.instance.addPostFrameCallback((_) => _insertEntry());
      return;
    }

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => ListenableBuilder(
        listenable: widget.audioProvider,
        builder: (ctx, __) => ChangeNotifierProvider.value(
          value: widget.audioProvider,
          child: const FloatingAudioPlayer(),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
