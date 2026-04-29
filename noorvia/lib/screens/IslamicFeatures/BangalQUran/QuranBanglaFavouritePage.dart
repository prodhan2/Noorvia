import 'dart:convert';

import 'package:dinajpur_city/IslamicFeatures/BangalQUran/BanglaQuran.dart';
import 'package:dinajpur_city/IslamicFeatures/BangalQUran/BanglaQuranSurahDetails.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ---------- Favorites Page ----------
class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Set<String> favSurahIds = {};
  Set<String> favVerseKeys = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    favSurahIds = (prefs.getStringList('favSurahs') ?? []).toSet();
    favVerseKeys = (prefs.getStringList('favVerses') ?? []).toSet();
    setState(() => loading = false);
  }

  Future<void> _removeFavSurah(String id) async {
    final prefs = await SharedPreferences.getInstance();
    favSurahIds.remove(id);
    await prefs.setStringList('favSurahs', favSurahIds.toList());
    setState(() {});
  }

  Future<void> _removeFavVerse(String key) async {
    final prefs = await SharedPreferences.getInstance();
    favVerseKeys.remove(key);
    await prefs.setStringList('favVerses', favVerseKeys.toList());
    setState(() {});
  }

  // helper to fetch surah index entry by id
  Future<Map<String, dynamic>?> _fetchSurahInfoById(String id) async {
    final url =
        'https://cdn.jsdelivr.net/npm/quran-cloud@1.0.0/dist/chapters/bn/index.json';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List;
      for (final item in list) {
        if ((item['id'] ?? '').toString() == id)
          return item as Map<String, dynamic>;
      }
    }
    return null;
  }

  // helper to fetch verse text quickly using surah link and verse id
  Future<Map<String, dynamic>?> _fetchVerseByKey(String key) async {
    // key format: "surahId-verseId"
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final sId = parts[0];
    final vId = int.tryParse(parts[1]);
    if (vId == null) return null;

    final surahInfo = await _fetchSurahInfoById(sId);
    if (surahInfo == null) return null;
    final link = surahInfo['link'] as String;
    final res = await http.get(Uri.parse(link));
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    final verses = data['verses'] as List<dynamic>;
    for (final v in verses) {
      if ((v['id'] ?? 0) == vId) {
        return {
          'surahId': sId,
          'surahName': surahInfo['translation'] ?? surahInfo['name'],
          'verseId': vId,
          'text': v['text'],
          'translation': v['translation'],
          'transliteration': v['transliteration'],
          'surahLink': link,
        };
      }
    }
    return null;
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
          'Favorites',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFavs,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Favorite Surahs
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Favorite Surahs',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (favSurahIds.isEmpty)
                              const Text('কোনো সূরা favorites এ নেই।')
                            else
                              FutureBuilder(
                                  future: _fetchAllFavSurahInfos(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Text(
                                          'Error: ${snapshot.error.toString()}');
                                    } else {
                                      final list = snapshot.data as List;
                                      return Column(
                                        children: list.map<Widget>((s) {
                                          final sid =
                                              (s['id'] ?? '').toString();
                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 0),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.teal,
                                              child: Text(
                                                sid,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            title: Text(
                                                s['translation'] ?? s['name']),
                                            subtitle: Text(
                                                s['transliteration'] ?? ''),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  _removeFavSurah(sid),
                                            ),
                                            onTap: () {
                                              // open surah detail page
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SurahDetailPage(
                                                          surahInfo: s),
                                                ),
                                              ).then((_) => _loadFavs());
                                            },
                                          );
                                        }).toList(),
                                      );
                                    }
                                  })
                          ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Favorite Verses
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Favorite Verses',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (favVerseKeys.isEmpty)
                              const Text('কোনো আয়াত favorites এ নেই।')
                            else
                              Column(
                                children: favVerseKeys.map<Widget>((key) {
                                  return FutureBuilder(
                                    future: _fetchVerseByKey(key),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: LinearProgressIndicator(),
                                        );
                                      } else if (snapshot.hasError ||
                                          snapshot.data == null) {
                                        return ListTile(
                                          title: Text(key),
                                          subtitle: const Text(
                                              'Unable to load verse'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                _removeFavVerse(key),
                                          ),
                                        );
                                      } else {
                                        final v = snapshot.data!;
                                        return ListTile(
                                          title: Text(
                                            v['surahName'] ?? 'Surah',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (v['text'] ?? '').toString(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (v['translation'] ?? '')
                                                    .toString(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.black87),
                                              )
                                            ],
                                          ),
                                          isThreeLine: true,
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                _removeFavVerse(key),
                                          ),
                                          onTap: () async {
                                            // open the surah detail page and scroll to verse
                                            final surahInfo =
                                                await _fetchSurahInfoById(
                                                    v['surahId'] ?? '');
                                            if (surahInfo != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SurahDetailPage(
                                                          surahInfo: surahInfo),
                                                ),
                                              ).then((_) => _loadFavs());
                                            }
                                          },
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              )
                          ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllFavSurahInfos() async {
    // fetch index and filter by fav ids
    final url =
        'https://cdn.jsdelivr.net/npm/quran-cloud@1.0.0/dist/chapters/bn/index.json';
    final res = await http.get(Uri.parse(url));
    final results = <Map<String, dynamic>>[];
    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List<dynamic>;
      for (final id in favSurahIds) {
        for (final item in list) {
          if ((item['id'] ?? '').toString() == id) {
            results.add(item as Map<String, dynamic>);
            break;
          }
        }
      }
    }
    return results;
  }
}
