import 'dart:async';
import 'dart:convert';
import 'BanglaQuranSurahDetails.dart';
import 'QuranBanglaFavouritePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../widgets/shimmer.dart';


// ─── App theme colors ─────────────────────────────────────────
const _kPrimary      = AppColors.primary;       // 0xFF6C3CE1
const _kPrimaryDark  = AppColors.primaryDark;   // 0xFF4A2BAD
const _kPrimaryLight = AppColors.primaryLight;  // 0xFF9B6FF5

// ─── Background task setup ────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }
  runApp(const QuranApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "quranBackgroundUpdate":
        try {
          final prefs = await SharedPreferences.getInstance();
          return await _fetchAndCacheSurahs(prefs);
        } catch (_) {
          return false;
        }
      case "checkForUpdates":
        try {
          final prefs = await SharedPreferences.getInstance();
          if (await _checkIfUpdateNeeded(prefs)) {
            return await _fetchAndCacheSurahs(prefs);
          }
          return true;
        } catch (_) {
          return false;
        }
      default:
        return false;
    }
  });
}

Future<bool> _checkIfUpdateNeeded(SharedPreferences prefs) async {
  final lastUpdate = prefs.getInt('lastUpdate') ?? 0;
  return DateTime.now().millisecondsSinceEpoch - lastUpdate >
      const Duration(hours: 6).inMilliseconds;
}

Future<bool> _fetchAndCacheSurahs(SharedPreferences prefs) async {
  try {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) return false;
    const url =
        'https://cdn.jsdelivr.net/npm/quran-cloud@1.0.0/dist/chapters/bn/index.json';
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      await prefs.setString('cachedSurahs', res.body);
      await prefs.setInt('lastUpdate', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('lastUpdateSuccess', true);
      return true;
    }
    await prefs.setBool('lastUpdateSuccess', false);
    return false;
  } catch (_) {
    await prefs.setBool('lastUpdateSuccess', false);
    return false;
  }
}

// ─── QuranApp (standalone entry — not used inside Noorvia shell) ─
class QuranApp extends StatelessWidget {
  const QuranApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SurahListPage(),
      );
}

// ═══════════════════════════════════════════════════════════════
// SurahListPage
// ═══════════════════════════════════════════════════════════════
class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});
  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage>
    with WidgetsBindingObserver {
  List<dynamic> allSurahs = [];
  List<dynamic> filteredSurahs = [];
  bool isLoading = true;
  bool isOffline = false;
  String searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  Set<String> favSurahIds = {};
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _searchCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkUpdatesOnResume();
  }

  void _init() async {
    _setupBgTasks();
    await _loadAll();
    _connSub = Connectivity().onConnectivityChanged.listen((r) {
      final offline = r == ConnectivityResult.none ||
          (!r.contains(ConnectivityResult.wifi) &&
           !r.contains(ConnectivityResult.mobile) &&
           !r.contains(ConnectivityResult.ethernet));
      if (!offline && isOffline) _checkUpdatesOnResume();
      setState(() => isOffline = offline);
    });
  }

  void _setupBgTasks() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByTag("quranUpdate");
      await Workmanager().registerPeriodicTask(
        "quranUpdateTask", "quranBackgroundUpdate",
        frequency: const Duration(hours: 6),
        constraints: Constraints(networkType: NetworkType.connected),
        tag: "quranUpdate",
      );
    } catch (_) {}
  }

  Future<void> _checkUpdatesOnResume() async {
    final prefs = await SharedPreferences.getInstance();
    if (await _checkIfUpdateNeeded(prefs)) await _refresh(silent: true);
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([_loadSurahs(), _loadFavs()]);
    } catch (_) {
      isOffline = true;
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _loadSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final age = DateTime.now().millisecondsSinceEpoch - (prefs.getInt('lastUpdate') ?? 0);
    if (age > const Duration(hours: 1).inMilliseconds ||
        !prefs.containsKey('cachedSurahs')) {
      await _fetchAndCacheSurahs(prefs);
    }
    final cached = prefs.getString('cachedSurahs');
    if (cached != null) {
      allSurahs = json.decode(cached);
      _filter();
    } else {
      throw Exception('No cached data');
    }
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    favSurahIds = (prefs.getStringList('favSurahs') ?? []).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFav(int id) async {
    final key = id.toString();
    final prefs = await SharedPreferences.getInstance();
    if (favSurahIds.contains(key)) {
      favSurahIds.remove(key);
    } else {
      favSurahIds.add(key);
    }
    await prefs.setStringList('favSurahs', favSurahIds.toList());
    setState(() {});
  }

  void _filter() {
    final q = searchQuery.trim().toLowerCase();
    filteredSurahs = q.isEmpty
        ? List.from(allSurahs)
        : allSurahs.where((s) {
            return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
                (s['transliteration'] ?? '').toString().toLowerCase().contains(q) ||
                (s['translation'] ?? '').toString().toLowerCase().contains(q);
          }).toList();
    if (mounted) setState(() {});
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await _fetchAndCacheSurahs(prefs)) {
        await _loadSurahs();
        if (!silent && mounted) {
          setState(() {
            isLoading = false;
            isOffline = false;
          });
          _snack('ডেটা আপডেট হয়েছে ✓');
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() {
          isLoading = false;
          isOffline = true;
        });
        _snack('আপডেট ব্যর্থ। ক্যাশ ব্যবহার হচ্ছে।');
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.hindSiliguri()),
      backgroundColor: _kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Bangla number helper ──────────────────────────────────
  String _bn(dynamic n) {
    const e = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    var s = n.toString();
    for (int i = 0; i < e.length; i++) s = s.replaceAll(e[i], b[i]);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
        body: Column(
          children: [
            // Offline banner
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('অফলাইন মোড — ক্যাশ ডেটা ব্যবহার হচ্ছে',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 12, color: Colors.orange.shade800)),
                  ],
                ),
              ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8)
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    searchQuery = v;
                    _filter();
                  },
                  style: GoogleFonts.hindSiliguri(
                      color: isDark ? AppColors.darkText : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'সূরার নাম বা অনুবাদ দিয়ে খুঁজুন...',
                    hintStyle: GoogleFonts.hindSiliguri(
                        color: isDark ? AppColors.darkSubText : Colors.grey,
                        fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: isDark ? AppColors.darkSubText : Colors.grey,
                                size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              searchQuery = '';
                              _filter();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: isLoading
                  ? SurahListShimmer(isDark: isDark)
                  : filteredSurahs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔍',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('কোনো সূরা পাওয়া যায়নি',
                                  style: GoogleFonts.hindSiliguri(
                                      color: isDark ? AppColors.darkSubText : Colors.grey,
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: _kPrimary,
                          onRefresh: () => _refresh(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            itemCount: filteredSurahs.length,
                            itemBuilder: (ctx, i) =>
                                _SurahTile(
                              surah: filteredSurahs[i],
                              isFav: favSurahIds
                                  .contains(filteredSurahs[i]['id'].toString()),
                              onFavTap: () =>
                                  _toggleFav(filteredSurahs[i]['id'] as int),
                              bnNumber: _bn(filteredSurahs[i]['id']),
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor,
                              onTap: () async {
                                await Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => SurahDetailPage(
                                        surahInfo: filteredSurahs[i]),
                                  ),
                                );
                                await _loadFavs();
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: _kPrimary,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('📖', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('পবিত্র কুরআন',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(width: 8),
          Container(width: 1.2, height: 16, color: Colors.white30),
          const SizedBox(width: 8),
          Text('বাংলা অনুবাদ ও তিলাওয়াত',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 11, color: Colors.white70)),
        ],
      ),
      centerTitle: false,
      titleSpacing: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          onPressed: _refresh,
          tooltip: 'রিফ্রেশ',
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
          tooltip: 'পছন্দের সূরা',
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => FavoritesPage()));
            await _loadFavs();
          },
        ),
      ],
    );
  }
}

// ─── Surah list tile ──────────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final dynamic surah;
  final bool isFav;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onFavTap;
  final VoidCallback onTap;
  final String bnNumber;

  const _SurahTile({
    required this.surah,
    required this.isFav,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onFavTap,
    required this.onTap,
    required this.bnNumber,
  });

  @override
  Widget build(BuildContext context) {
    final name = surah['name'] ?? '';
    final translit = surah['transliteration'] ?? '';
    final translation = surah['translation'] ?? '';
    final totalVerses = surah['total_verses'] ?? 0;
    final type = (surah['type'] ?? '').toString().toLowerCase();
    final isMakki = type == 'meccan' || type == 'makki';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  bnNumber,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Surah info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$translit • $translation',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isMakki ? 'মক্কী' : 'মাদানী'} • $totalVerses আয়াত',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11,
                        color: _kPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Favourite button
              GestureDetector(
                onTap: onFavTap,
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
