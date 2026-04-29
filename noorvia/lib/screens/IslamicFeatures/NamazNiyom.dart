import 'dart:async';
import 'dart:convert';
import 'ChapterDEtails.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // ignore: deprecated_member_use
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    Workmanager().registerPeriodicTask(
      "1",
      "fetchChaptersTask",
      frequency: const Duration(minutes: 15),
    );
  }

  runApp(const MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await fetchAndCacheChapters();
    return Future.value(true);
  });
}

const String jsonUrl = "https://app-backend-data.vercel.app/namazSHikkha.json";

Future<void> fetchAndCacheChapters() async {
  try {
    final response = await http.get(Uri.parse(jsonUrl));
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedChapters', response.body);
    } else {
      debugPrint("Background fetch failed: HTTP ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Background fetch failed: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Islamic Chapters',
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const ChapterListPage(),
    );
  }
}

class ChapterListPage extends StatefulWidget {
  const ChapterListPage({super.key});

  @override
  _ChapterListPageState createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> chapters = [];
  List<dynamic> filteredChapters = [];
  bool isLoading = true;
  bool isError = false;
  bool isSearchExpanded = false;
  bool isUsingCachedData = false;
  final TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    loadChapters();
    searchController.addListener(_filterChapters);
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.removeListener(_filterChapters);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadChapters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedChapters');

    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        chapters = json.decode(response.body);
        await prefs.setString('cachedChapters', response.body);
        setState(() {
          isLoading = false;
          isError = false;
          isUsingCachedData = false;
          filteredChapters = chapters;
        });
        _animationController.forward(from: 0.0);
        return;
      } else {
        throw Exception('Failed to fetch data: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Network fetch failed: $e");
      if (cachedData != null) {
        chapters = json.decode(cachedData);
        setState(() {
          isLoading = false;
          isError = false;
          isUsingCachedData = true;
          filteredChapters = chapters;
        });
        _animationController.forward(from: 0.0);
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    }
  }

  void _filterChapters() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      String query = searchController.text.toLowerCase();
      setState(() {
        filteredChapters = chapters.where((chapter) {
          return chapter['chapter'].toString().toLowerCase().contains(query) ||
              chapter['description'].toString().toLowerCase().contains(query);
        }).toList();
        _animationController.forward(from: 0.0); // Replay animation on filter
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ইসলামিক অধ্যায়সমূহ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSearchExpanded ? 200 : 50,
            child: isSearchExpanded
                ? TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search chapters...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          searchController.clear();
                          setState(() => isSearchExpanded = false);
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    autofocus: true,
                  )
                : IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isSearchExpanded = !isSearchExpanded;
                        if (!isSearchExpanded) searchController.clear();
                      });
                    },
                  ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ডেটা লোড করা যায়নি। ইন্টারনেট বা সার্ভারের সমস্যা হতে পারে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadChapters,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (isUsingCachedData)
                      Container(
                        color: Colors.yellow[100],
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          'Using cached data due to network issue',
                          style: TextStyle(color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        itemCount: filteredChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = filteredChapters[index];
                          final animation = Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index / filteredChapters.length),
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ));

                          return SlideTransition(
                            position: animation,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChapterDetailPage(
                                      chapterTitle: chapter['chapter'],
                                      chapterDescription:
                                          chapter['description'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(2, 2),
                                    ),
                                    BoxShadow(
                                      color:
                                          Colors.purpleAccent.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chapter['chapter'],
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          textAlign: TextAlign.justify,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Image.asset(
                                        'assets/images/star.gif',
                                        width: 30,
                                        height: 30,
                                      ),
                                    ],
                                  ),
                                  subtitle: MarkdownBody(
                                    data: chapter['description'],
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        color: Colors.grey,
                                        height: 1.5,
                                      ),
                                      textAlign: WrapAlignment.start,
                                    ),
                                    softLineBreak: true,
                                    selectable: true,
                                    onTapLink: (text, href, title) {
                                      if (href != null) {
                                        // Handle link tap (e.g., open in browser)
                                        debugPrint("Tapped link: $href");
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
