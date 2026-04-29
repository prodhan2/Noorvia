import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class HadithDemoPage extends StatefulWidget {
  @override
  _HadithDemoPageState createState() => _HadithDemoPageState();
}

class _HadithDemoPageState extends State<HadithDemoPage> {
  List<Hadith> hadiths = [];
  List<Hadith> filteredHadiths = [];
  bool isLoading = true;
  String searchQuery = '';
  Set<String> bookmarks = {};
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _fetchHadiths();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bookmarks = Set.from(prefs.getStringList('bookmarks') ?? []);
    });
  }

  Future<void> _fetchHadiths() async {
    try {
      final response = await http.get(Uri.parse(
          'https://alquranbd.com/api/hadith/bukhari/bn/$currentPage/$itemsPerPage'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hadithData = data as List;

        setState(() {
          hadiths.addAll(hadithData
              .map((h) => Hadith(
                    id: h['id'].toString(),
                    text: h['hadithBengali'],
                    arabic: h['hadithArabic'],
                    source: 'সহীহ বুখারী',
                    number: h['hadithNumber'].toString(),
                    chapter: h['chapterNameBengali'],
                  ))
              .toList());

          filteredHadiths = hadiths;
          isLoading = false;
          hasMore = hadithData.length == itemsPerPage;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching hadiths: $e');
    }
  }

  void _loadMore() {
    if (!isLoading && hasMore) {
      setState(() {
        currentPage++;
        isLoading = true;
      });
      _fetchHadiths();
    }
  }

  void _searchHadiths(String query) {
    setState(() {
      searchQuery = query;
      filteredHadiths = hadiths
          .where((hadith) =>
              hadith.text.toLowerCase().contains(query.toLowerCase()) ||
              hadith.number.contains(query))
          .toList();
    });
  }

  Future<void> _toggleBookmark(String hadithId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (bookmarks.contains(hadithId)) {
        bookmarks.remove(hadithId);
      } else {
        bookmarks.add(hadithId);
      }
    });
    await prefs.setStringList('bookmarks', bookmarks.toList());
  }

  void _shareHadith(Hadith hadith) {
    // share_plus not available on web — copy to clipboard instead
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('হাদিস কপি করা হয়েছে')),
      );
      return;
    }
    // On mobile: use clipboard as fallback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${hadith.text}\n- ${hadith.source}',
              maxLines: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('হাদিস সংগ্রহ', style: TextStyle(fontFamily: 'Bangla')),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F3443), Color(0xFF34E89E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _searchHadiths,
              decoration: InputDecoration(
                hintText: 'হাদিস খুঁজুন...',
                hintStyle: TextStyle(fontFamily: 'Bangla'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: isLoading && hadiths.isEmpty
                ? Center(child: CircularProgressIndicator())
                : filteredHadiths.isEmpty
                    ? Center(
                        child: Text(
                          'কোন হাদিস পাওয়া যায়নি',
                          style: TextStyle(fontFamily: 'Bangla', fontSize: 18),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              !isLoading &&
                              hasMore) {
                            _loadMore();
                          }
                          return true;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredHadiths.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= filteredHadiths.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final hadith = filteredHadiths[index];
                            return HadithCard(
                              hadith: hadith,
                              isBookmarked: bookmarks.contains(hadith.id),
                              onBookmark: _toggleBookmark,
                              onShare: _shareHadith,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class HadithCard extends StatelessWidget {
  final Hadith hadith;
  final bool isBookmarked;
  final Function(String) onBookmark;
  final Function(Hadith) onShare;

  const HadithCard({
    required this.hadith,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    hadith.number,
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Color(0xFF0F3443),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Color(0xFF34E89E) : Colors.grey,
                  ),
                  onPressed: () => onBookmark(hadith.id),
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.grey),
                  onPressed: () => onShare(hadith),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              hadith.chapter,
              style: TextStyle(
                fontFamily: 'Bangla',
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              hadith.text,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Bangla',
              ),
            ),
            SizedBox(height: 12),
            Text(
              hadith.arabic,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Arabic',
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                hadith.source,
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Bangla',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Hadith {
  final String id;
  final String text;
  final String arabic;
  final String source;
  final String number;
  final String chapter;

  Hadith({
    required this.id,
    required this.text,
    required this.arabic,
    required this.source,
    required this.number,
    required this.chapter,
  });
}
