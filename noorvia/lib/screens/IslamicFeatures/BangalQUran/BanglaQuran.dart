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
import '../../../widgets/shimmer.dart';

// ─── App colors (matches Noorvia theme) ──────────────────────
const _kPrimary = Color(0xFF1B6B3A);
const _kPrimaryDark = Color(0xFF0F4D2A);
const _kPrimaryLight = Color(0xFF2E8B57);
const _kBg = Color(0xFFF2F2F2);
const _kCard = Colors.white;

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
    return Scaffold(
      backgroundColor: _kBg,
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
                  color: _kCard,
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
                  style: GoogleFonts.hindSiliguri(),
                  decoration: InputDecoration(
                    hintText: 'সূরার নাম বা অনুবাদ দিয়ে খুঁজুন...',
                    hintStyle: GoogleFonts.hindSiliguri(
                        color: Colors.grey, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: _kPrimary, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.grey, size: 18),
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
                  ? SurahListShimmer(isDark: false)
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
                                      color: Colors.grey, fontSize: 16)),
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
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _kPrimary,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refresh,
          tooltip: 'রিফ্রেশ',
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          tooltip: 'পছন্দের সূরা',
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => FavoritesPage()));
            await _loadFavs();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kPrimaryDark, _kPrimaryLight],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text('📖', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text('পবিত্র কুরআন',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('বাংলা অনুবাদ ও তিলাওয়াত',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Surah list tile ──────────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final dynamic surah;
  final bool isFav;
  final VoidCallback onFavTap;
  final VoidCallback onTap;
  final String bnNumber;

  const _SurahTile({
    required this.surah,
    required this.isFav,
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
          color: _kCard,
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
                child: Center(
                  child: Text(bnNumber,
                      style: GoogleFonts.hindSiliguri(
                          color: _kPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(translation.isNotEmpty ? translation : name,
                        style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMakki
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isMakki ? 'মাক্কী' : 'মাদানী',
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isMakki
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('$totalVerses আয়াত',
                            style: GoogleFonts.hindSiliguri(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Arabic name + fav
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20,
                          color: _kPrimary,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
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
            ],
          ),
        ),
      ),
    );
  }
}
