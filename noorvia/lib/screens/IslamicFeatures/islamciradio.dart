import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamic Radio',
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0C3A25),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const RadioScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
    if (!isConnected) {
      setState(() {
        errorMessage = 'No internet connection';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://data-rosy.vercel.app/radio.json'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          radioStations = (data['radios'] as List)
              .map((station) => RadioStation.fromJson(station))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load radio stations (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
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

    if (currentlyPlayingId == station.id) {
      await audioPlayer.stop();
      setState(() {
        currentlyPlayingId = null;
        playerState = PlayerState.stopped;
      });
    } else {
      await audioPlayer.stop();
      await audioPlayer.play(UrlSource(station.url));
      setState(() {
        currentlyPlayingId = station.id;
        playerState = PlayerState.playing;
      });
    }
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
    return Scaffold(
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
          colors: [
            Color.fromARGB(255, 7, 255, 234),
            Color.fromARGB(255, 42, 51, 224)
          ],
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
      color: Colors.green[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            'NOW PLAYING',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
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
                  color: Colors.green,
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
          color: Colors.green,
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

  RadioStation({
    required this.id,
    required this.name,
    required this.url,
    required this.img,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      img: json['img'],
    );
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
          ? const Icon(Icons.pause, color: Colors.red)
          : const Icon(Icons.play_arrow, color: Colors.green);
    }
    return const Icon(Icons.play_arrow, color: Colors.green);
  }
}
