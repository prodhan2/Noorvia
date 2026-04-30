import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/nav_provider.dart';
import 'core/providers/prayer_provider.dart';
import 'core/providers/audio_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/floating_audio_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }

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
      ],
      child: Consumer2<ThemeProvider, AudioProvider>(
        builder: (context, themeProvider, audioProvider, _) {
          return _AudioOverlayInjector(
            audioProvider: audioProvider,
            child: MaterialApp(
              navigatorKey: _navKey,
              title: 'নূরভিয়া',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
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
