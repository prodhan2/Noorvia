import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data/local/local_store.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  List<RadioStation> radioStations = [];
  bool isLoading = true;
  String errorMessage = '';
  AudioPlayer audioPlayer = AudioPlayer();
  int? currentlyPlayingId;
  PlayerState playerState = PlayerState.stopped;
  Duration? duration, position;
  bool isConnected = true;
  late Stream<List<ConnectivityResult>> connectivityStream;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    fetchRadioStations();
    setupAudioPlayer();
  }

  void initConnectivity() {
    connectivityStream = Connectivity().onConnectivityChanged;
    connectivityStream.listen((result) {
      setState(() {
        isConnected = !result.contains(ConnectivityResult.none) ||
            result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.ethernet);
      });
      if (isConnected && radioStations.isEmpty) {
        fetchRadioStations();
      }
    });
  }

  Future<void> fetchRadioStations() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    final prefs = await SharedPreferences.getInstance();

    // 1) Isar cache first. Legacy SharedPreferences cache is kept as a
    // migration fallback for users upgrading from older Noorvia builds.
    try {
      final cached = await LocalStore.instance.getJson('radio_cache_v2', 'stations');
      final raw = cached?['radios'];
      if (raw is List) {
        final stations = raw
            .whereType<Map>()
            .map((item) => RadioStation.fromJson(Map<String, dynamic>.from(item)))
            .where((station) => station.url.isNotEmpty)
            .toList();
        if (stations.isNotEmpty && mounted) {
          setState(() {
            radioStations = stations;
            isLoading = false;
          });
        }
      }
    } catch (_) {}

    if (radioStations.isEmpty) {
      final legacy = prefs.getString('radio_cache');
      if (legacy != null) {
        try {
          final data = json.decode(legacy);
          final raw = data is Map ? data['radios'] : null;
          if (raw is List) {
            final stations = raw
                .whereType<Map>()
                .map((item) => RadioStation.fromJson(Map<String, dynamic>.from(item)))
                .where((station) => station.url.isNotEmpty)
                .toList();
            if (stations.isNotEmpty && mounted) {
              setState(() {
                radioStations = stations;
                isLoading = false;
              });
            }
          }
        } catch (_) {}
      }
    }

    if (!isConnected) {
      if (mounted) {
        setState(() {
          isLoading = false;
          if (radioStations.isEmpty) errorMessage = 'ইন্টারনেট সংযোগ নেই';
        });
      }
      return;
    }

    List<RadioStation> fresh = const [];

    // 2) Noorvia curated feed remains first priority.
    try {
      final response = await http
          .get(Uri.parse('https://data-rosy.vercel.app/radio.json'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final raw = data is Map ? data['radios'] : null;
        if (raw is List) {
          fresh = raw
              .whereType<Map>()
              .map((item) => RadioStation.fromJson(Map<String, dynamic>.from(item)))
              .where((station) => station.url.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}

    // 3) Global free/open Radio Browser fallback. This keeps Noorvia useful
    // even when the curated feed is temporarily unavailable.
    if (fresh.isEmpty) {
      try {
        fresh = await _fetchRadioBrowserStations();
      } catch (_) {}
    }

    if (fresh.isNotEmpty) {
      final normalized = {'radios': fresh.map((station) => station.toJson()).toList()};
      await LocalStore.instance.putJson('radio_cache_v2', 'stations', normalized);
      if (mounted) {
        setState(() {
          radioStations = fresh;
          isLoading = false;
          errorMessage = '';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
        if (radioStations.isEmpty) {
          errorMessage = 'রেডিও স্টেশন লোড করা যায়নি। আবার চেষ্টা করুন।';
        }
      });
    }
  }

  Future<List<RadioStation>> _fetchRadioBrowserStations() async {
    final queries = <Uri>[
      Uri.https('all.api.radio-browser.info', '/json/stations/search', {
        'tag': 'quran',
        'hidebroken': 'true',
        'limit': '80',
        'order': 'votes',
        'reverse': 'true',
      }),
      Uri.https('all.api.radio-browser.info', '/json/stations/search', {
        'tag': 'islamic',
        'hidebroken': 'true',
        'limit': '80',
        'order': 'votes',
        'reverse': 'true',
      }),
    ];

    final byUuid = <String, RadioStation>{};
    for (final uri in queries) {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Noorvia/1.0 (com.butterflydevs.noorvia)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) continue;
      final decoded = json.decode(response.body);
      if (decoded is! List) continue;
      for (final item in decoded.whereType<Map>()) {
        final station = RadioStation.fromRadioBrowser(
          Map<String, dynamic>.from(item),
        );
        if (station.url.isEmpty || station.name.isEmpty) continue;
        byUuid[station.stationUuid ?? station.url] = station;
      }
    }
    return byUuid.values.take(120).toList(growable: false);
  }

  void setupAudioPlayer() {
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          playerState = state;
        });
      }
    });

    audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          duration = d;
        });
      }
    });

    audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          position = p;
        });
      }
    });

    audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          currentlyPlayingId = null;
          playerState = PlayerState.stopped;
          position = Duration.zero;
        });
      }
    });
  }

  Future<void> toggleRadioPlayback(RadioStation station) async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    // Stop Quran/verse audio if playing
    if (context.mounted) {
      final audioProvider = context.read<AudioProvider>();
      if (audioProvider.isPlaying || audioProvider.isVisible) {
        await audioProvider.stop();
      }
    }

    if (currentlyPlayingId == station.id) {
      await audioPlayer.stop();
      setState(() {
        currentlyPlayingId = null;
        playerState = PlayerState.stopped;
      });
    } else {
      await audioPlayer.stop();
      if (station.source == 'Radio Browser' && station.stationUuid != null) {
        unawaited(_registerRadioBrowserClick(station.stationUuid!));
      }
      await audioPlayer.play(UrlSource(station.url));
      setState(() {
        currentlyPlayingId = station.id;
        playerState = PlayerState.playing;
      });
    }
  }

  Future<void> _registerRadioBrowserClick(String stationUuid) async {
    try {
      await http.get(
        Uri.https(
          'all.api.radio-browser.info',
          '/json/url/$stationUuid',
        ),
        headers: const {
          'User-Agent': 'Noorvia/1.0 (com.butterflydevs.noorvia)',
        },
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> refreshStations() async {
    await fetchRadioStations();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Islamic Radio Stations',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: refreshStations,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (currentlyPlayingId != null) _buildNowPlayingBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : RefreshIndicator(
                        onRefresh: refreshStations,
                        child: ListView.builder(
                          itemCount: radioStations.length,
                          itemBuilder: (context, index) {
                            final station = radioStations[index];
                            return RadioStationCard(
                              station: station,
                              isPlaying: currentlyPlayingId == station.id,
                              playerState: playerState,
                              onTap: () => toggleRadioPlayback(station),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingBar() {
    final currentStation = radioStations.firstWhere(
      (station) => station.id == currentlyPlayingId,
      orElse: () => RadioStation(
        id: -1,
        name: 'Unknown',
        url: '',
        img: '',
      ),
    );

    return Container(
      color: AppColors.lightBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            'NOW PLAYING',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  currentStation.img,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.radio, size: 50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStation.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (playerState == PlayerState.playing)
                      _buildProgressIndicator(),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  playerState == PlayerState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: AppColors.primary,
                  size: 32,
                ),
                onPressed: () => toggleRadioPlayback(currentStation),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: position != null && duration != null && duration!.inMilliseconds > 0
              ? position!.inMilliseconds / duration!.inMilliseconds
              : 0,
          backgroundColor: Colors.grey[300],
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class RadioStation {
  final int id;
  final String name;
  final String url;
  final String img;
  final String? stationUuid;
  final String source;

  const RadioStation({
    required this.id,
    required this.name,
    required this.url,
    required this.img,
    this.stationUuid,
    this.source = 'Noorvia',
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] ?? json['url_resolved'] ?? '').toString();
    final uuid = json['stationUuid']?.toString() ?? json['stationuuid']?.toString();
    return RadioStation(
      id: _coerceId(json['id'], uuid ?? url),
      name: (json['name'] ?? 'Islamic Radio').toString().trim(),
      url: url.trim(),
      img: (json['img'] ?? json['favicon'] ?? '').toString().trim(),
      stationUuid: uuid,
      source: (json['source'] ?? 'Noorvia').toString(),
    );
  }

  factory RadioStation.fromRadioBrowser(Map<String, dynamic> json) {
    final uuid = (json['stationuuid'] ?? '').toString();
    final url = (json['url_resolved'] ?? json['url'] ?? '').toString();
    return RadioStation(
      id: _stableId(uuid.isNotEmpty ? uuid : url),
      name: (json['name'] ?? 'Islamic Radio').toString().trim(),
      url: url.trim(),
      img: (json['favicon'] ?? '').toString().trim(),
      stationUuid: uuid.isEmpty ? null : uuid,
      source: 'Radio Browser',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'img': img,
        if (stationUuid != null) 'stationUuid': stationUuid,
        'source': source,
      };

  static int _coerceId(dynamic value, String fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? _stableId(fallback);
  }

  static int _stableId(String input) {
    // Stable positive 31-bit FNV-1a for UI identity/cache compatibility.
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}

class RadioStationCard extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final PlayerState playerState;
  final VoidCallback onTap;

  const RadioStationCard({
    super.key,
    required this.station,
    required this.isPlaying,
    required this.playerState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            station.img,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.radio),
          ),
        ),
        title: Text(
          station.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: _buildPlayPauseIcon(),
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPlayPauseIcon() {
    if (isPlaying) {
      return playerState == PlayerState.playing
          ? const Icon(Icons.pause, color: Colors.redAccent)
          : Icon(Icons.play_arrow, color: AppColors.primary);
    }
    return Icon(Icons.play_arrow, color: AppColors.primary);
  }
}
