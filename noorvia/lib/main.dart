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

  // Firebase — skip on web (needs FirebaseOptions config for web)
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'নূরভিয়া',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Use navigatorObservers to inject FAB via Overlay
            // after the Navigator (and its Overlay) is ready
            home: const _AudioOverlayWrapper(child: SplashScreen()),
          );
        },
      ),
    );
  }
}

// Injects the FloatingAudioPlayer into the Navigator's Overlay
// so SnackBars and other Overlay-dependent widgets work correctly.
class _AudioOverlayWrapper extends StatefulWidget {
  final Widget child;
  const _AudioOverlayWrapper({required this.child});

  @override
  State<_AudioOverlayWrapper> createState() => _AudioOverlayWrapperState();
}

class _AudioOverlayWrapperState extends State<_AudioOverlayWrapper> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    // Insert after first frame so Overlay is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertOverlay());
  }

  void _insertOverlay() {
    final providerContext = context; // capture context with providers
    _entry = OverlayEntry(
      builder: (overlayCtx) => ChangeNotifierProvider.value(
        value: Provider.of<AudioProvider>(providerContext, listen: false),
        child: const FloatingAudioPlayer(),
      ),
    );
    Overlay.of(context).insert(_entry!);
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
