import 'dart:async';
import 'dart:convert';
import 'package:dinajpur_city/IslamicFeatures/BangalQUran/BanglaQuranSurahDetails.dart';
import 'package:dinajpur_city/IslamicFeatures/BangalQUran/QuranBanglaFavouritePage.dart';
import 'package:dinajpur_city/IslamicFeatures/islamicdashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Workmanager on mobile platforms
  if (!kIsWeb) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  runApp(const QuranApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background task executed: $task");

    switch (task) {
      case "quranBackgroundUpdate":
        try {
          final prefs = await SharedPreferences.getInstance();
          final result = await _fetchAndCacheSurahs(prefs);
          return result;
        } catch (e) {
          print("Background task failed: $e");
          return false;
        }

      case "checkForUpdates":
        try {
          final prefs = await SharedPreferences.getInstance();
          final shouldUpdate = await _checkIfUpdateNeeded(prefs);
          if (shouldUpdate) {
            return await _fetchAndCacheSurahs(prefs);
          }
          return true;
        } catch (e) {
          print("Update check failed: $e");
          return false;
        }

      default:
        return false;
    }
  });
}

Future<bool> _checkIfUpdateNeeded(SharedPreferences prefs) async {
  try {
    final lastUpdate = prefs.getInt('lastUpdate') ?? 0;
    final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;

    // Check if cache is older than 6 hours
    return cacheAge > Duration(hours: 6).inMilliseconds;
  } catch (e) {
    return true; // Update if check fails
  }
}

Future<bool> _fetchAndCacheSurahs(SharedPreferences prefs) async {
  try {
    // Check connectivity before making request
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print("No internet connection for background update");
      return false;
    }

    final url =
        'https://cdn.jsdelivr.net/npm/quran-cloud@1.0.0/dist/chapters/bn/index.json';
    final res =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      await prefs.setString('cachedSurahs', res.body);
      await prefs.setInt('lastUpdate', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('lastUpdateSuccess', true);
      print("Background update successful");
      return true;
    } else {
      await prefs.setBool('lastUpdateSuccess', false);
      print("Background update failed with status: ${res.statusCode}");
      return false;
    }
  } catch (e) {
    await prefs.setBool('lastUpdateSuccess', false);
    print("Background update error: $e");
    return false;
  }
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Bangla',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SurahListPage(),
    );
  }
}

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
  final TextEditingController _searchController = TextEditingController();
  Set<String> favSurahIds = {};
  Set<String> favVerseKeys = {};
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, check for updates
      _checkForUpdatesOnResume();
    }
  }

  void _initializeApp() async {
    _setupBackgroundUpdates();
    await _loadAll();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && isOffline) {
        // Connection restored, try to update data
        _checkForUpdatesOnResume();
      }
      setState(() {
        isOffline = result == ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkForUpdatesOnResume() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldUpdate = await _checkIfUpdateNeeded(prefs);

    if (shouldUpdate) {
      await _refreshData(silent: true);
    }
  }

  void _setupBackgroundUpdates() async {
    if (kIsWeb) return;

    try {
      // Cancel existing tasks
      await Workmanager().cancelByTag("quranUpdate");

      // Register periodic task for updates (every 6 hours)
      await Workmanager().registerPeriodicTask(
        "quranUpdateTask",
        "quranBackgroundUpdate",
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        tag: "quranUpdate",
      );

      // Register task for checking updates when device is idle
      await Workmanager().registerPeriodicTask(
        "quranUpdateCheck",
        "checkForUpdates",
        frequency: const Duration(hours: 3),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        tag: "quranUpdateCheck",
      );

      print("Background tasks registered successfully");
    } catch (e) {
      print("Failed to register background tasks: $e");
    }
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([_loadSurahs(), _loadFavorites()]);
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        isOffline = true;
      });
      _showSnackBar('Offline mode: Using cached data');
    }
  }

  Future<void> _loadSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt('lastUpdate') ?? 0;
    final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;

    // Try to fetch fresh data if cache is older than 1 hour or doesn't exist
    if (cacheAge > Duration(hours: 1).inMilliseconds ||
        !prefs.containsKey('cachedSurahs')) {
      final success = await _fetchAndCacheSurahs(prefs);
      if (!success) {
        print("Using cached data due to fetch failure");
      }
    }

    // Load from cache
    final cachedData = prefs.getString('cachedSurahs');
    if (cachedData != null) {
      allSurahs = json.decode(cachedData);
      _applyFilter();
    } else {
      throw Exception('No cached data available');
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final surahList = prefs.getStringList('favSurahs') ?? [];
    final verseList = prefs.getStringList('favVerses') ?? [];
    favSurahIds = surahList.toSet();
    favVerseKeys = verseList.toSet();
    setState(() {});
  }

  Future<void> _toggleFavSurah(int id) async {
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

  void _applyFilter() {
    if (searchQuery.trim().isEmpty) {
      filteredSurahs = List.from(allSurahs);
    } else {
      final q = searchQuery.trim().toLowerCase();
      filteredSurahs = allSurahs.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final translit = (s['transliteration'] ?? '').toString().toLowerCase();
        final trans = (s['translation'] ?? '').toString().toLowerCase();
        return name.contains(q) || translit.contains(q) || trans.contains(q);
      }).toList();
    }
    setState(() {});
  }

  void _onSearchChanged(String v) {
    searchQuery = v;
    _applyFilter();
  }

  Future<void> _refreshData({bool silent = false}) async {
    if (!silent) {
      setState(() => isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await _fetchAndCacheSurahs(prefs);

      if (success) {
        await _loadSurahs();
        if (!silent) {
          setState(() {
            isLoading = false;
            isOffline = false;
          });
          _showSnackBar('Data updated successfully');
        }
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          isLoading = false;
          isOffline = true;
        });
        _showSnackBar('Failed to update. Using cached data.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final prefs = snapshot.data!;
        final lastUpdate = prefs.getInt('lastUpdate') ?? 0;
        final lastSuccess = prefs.getBool('lastUpdateSuccess') ?? false;

        if (lastUpdate == 0) return const SizedBox();

        final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
        final now = DateTime.now();
        final difference = now.difference(lastUpdateTime);

        String timeText;
        if (difference.inMinutes < 1) {
          timeText = 'Just now';
        } else if (difference.inHours < 1) {
          timeText = '${difference.inMinutes} minutes ago';
        } else if (difference.inHours < 24) {
          timeText = '${difference.inHours} hours ago';
        } else {
          timeText = '${difference.inDays} days ago';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                lastSuccess ? Icons.check_circle : Icons.error,
                color: lastSuccess ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Last update: $timeText',
                style: TextStyle(
                  color: lastSuccess ? Colors.green : Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'কুরআন বাংলা অনুবাদ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => IslamicApp()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesPage(),
                ),
              );
              await _loadFavorites();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isOffline)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.amber,
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, size: 20),
                        SizedBox(width: 8),
                        Text('You are currently offline'),
                      ],
                    ),
                  ),
                _buildLastUpdateInfo(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'সূরা খুঁজুন... (নাম/অ্যাডভান্স)',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: filteredSurahs.isEmpty
                      ? const Center(child: Text('কোনো সূরা পাওয়া যাচ্ছে না।'))
                      : RefreshIndicator(
                          onRefresh: () => _refreshData(silent: false),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: filteredSurahs.length,
                            itemBuilder: (context, index) {
                              final s = filteredSurahs[index];
                              final sid = (s['id'] ?? '').toString();
                              final isFav = favSurahIds.contains(sid);
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Text(
                                      sid,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    '${s['name'] ?? ''}  (${s['transliteration'] ?? ''})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(s['translation'] ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Text(
                                            '${s['total_verses'] ?? 0} আয়াত'),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isFav
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              isFav ? Colors.redAccent : null,
                                        ),
                                        onPressed: () {
                                          _toggleFavSurah(s['id'] as int);
                                          ScaffoldMessenger.of(context)
                                              .removeCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(isFav
                                                  ? 'সূরা মুছে ফেলা হয়েছে favorites থেকে'
                                                  : 'সূরা favorites এ যোগ করা হয়েছে'),
                                              duration:
                                                  const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => SurahDetailPage(
                                                surahInfo: s,
                                              )),
                                    );
                                    await _loadFavorites();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                )
              ],
            ),
    );
  }
}
