// import 'dart:async';
// import 'dart:convert';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';

// import '../common/web_view_page.dart';

// class IQCHomePage extends StatefulWidget {
//   const IQCHomePage({super.key});

//   @override
//   State<IQCHomePage> createState() => _IQCHomePageState();
// }

// class _IQCHomePageState extends State<IQCHomePage> {
//   static const _apiUrl =
//       'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamic_Quiz/iqc_info.json';
//   static const _quizUrl = 'https://www.iqcbd.org/';
//   static const _facebookUrl = 'https://www.facebook.com/share/1EqEi66QYH/';
//   static const _telegramUrl = 'https://t.me/+51a05LB7CUYxZTZl';

//   final PageController _bannerController = PageController(viewportFraction: .9);
//   Timer? _bannerTimer;

//   IQCInfo _info = IQCInfo.fallback();
//   bool _isLoading = true;
//   bool _hasLoadError = false;
//   int _bannerIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _fetchIQCInfo();
//   }

//   @override
//   void dispose() {
//     _bannerTimer?.cancel();
//     _bannerController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchIQCInfo() async {
//     setState(() {
//       _isLoading = true;
//       _hasLoadError = false;
//     });

//     try {
//       final response = await http
//           .get(Uri.parse(_apiUrl))
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode != 200) {
//         throw Exception('IQC API returned ${response.statusCode}');
//       }

//       final json = jsonDecode(utf8.decode(response.bodyBytes));
//       if (json is! Map<String, dynamic>) {
//         throw const FormatException('Invalid IQC API response');
//       }

//       if (!mounted) return;
//       setState(() {
//         _info = IQCInfo.fromJson(json);
//         _isLoading = false;
//       });
//       _startBannerTimer();
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _info = IQCInfo.fallback();
//         _isLoading = false;
//         _hasLoadError = true;
//       });
//       _startBannerTimer();
//     }
//   }

//   void _startBannerTimer() {
//     _bannerTimer?.cancel();
//     if (_info.banners.length < 2) return;

//     _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
//       if (!mounted || !_bannerController.hasClients) return;
//       final next = (_bannerIndex + 1) % _info.banners.length;
//       _bannerController.animateToPage(
//         next,
//         duration: const Duration(milliseconds: 450),
//         curve: Curves.easeOutCubic,
//       );
//     });
//   }

//   Future<void> _openExternal(String url) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }

//   void _openQuizWebView([String url = _quizUrl]) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => WebViewPage(url: url, title: 'ইসলামিক কুইজ'),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7F2),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: const Color(0xFF0B4D3A),
//         foregroundColor: Colors.white,
//         title: Text(
//           'Islamic Quiz Contest',
//           style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
//         ),
//         centerTitle: true,
//       ),
//       body: RefreshIndicator(
//         onRefresh: _fetchIQCInfo,
//         color: const Color(0xFF0B4D3A),
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.only(bottom: 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _heroSection(),
//                     if (_hasLoadError) _errorNotice(),
//                     const SizedBox(height: 18),
//                     _bannerSection(),
//                     const SizedBox(height: 18),
//                     _statsSection(_info.stats),
//                     const SizedBox(height: 18),
//                     _aboutSection(),
//                     const SizedBox(height: 18),
//                     _activitiesSection(),
//                     const SizedBox(height: 18),
//                     _quizSection(_info.quizzes),
//                     const SizedBox(height: 18),
//                     _socialSection(),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _heroSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF083D31), Color(0xFF127455)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           const Icon(Icons.auto_stories, color: Color(0xFFF6D56A), size: 50),
//           const SizedBox(height: 12),
//           Text(
//             'Islamic Quiz Contest - IQC',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.hindSiliguri(
//               fontSize: 25,
//               fontWeight: FontWeight.w800,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             'বর্তমান প্রজন্মের কাছে ইসলাম পৌঁছানোর একটি অরাজনৈতিক ক্ষুদ্র প্রয়াস',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.hindSiliguri(
//               fontSize: 15,
//               height: 1.5,
//               color: Colors.white.withValues(alpha: .92),
//             ),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton.icon(
//             onPressed: () => _openQuizWebView(),
//             icon: const Icon(Icons.quiz_outlined),
//             label: Text(
//               'Participate Quiz',
//               style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFFF6D56A),
//               foregroundColor: const Color(0xFF083D31),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _errorNotice() {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF7E8),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFF1D09A)),
//       ),
//       child: Text(
//         'লাইভ তথ্য লোড করা যায়নি, সংরক্ষিত তথ্য দেখানো হচ্ছে।',
//         style: GoogleFonts.hindSiliguri(
//           color: const Color(0xFF795008),
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Widget _bannerSection() {
//     final banners = _info.banners;
//     if (banners.isEmpty) return const SizedBox.shrink();

//     return SizedBox(
//       height: 196,
//       child: PageView.builder(
//         controller: _bannerController,
//         itemCount: banners.length,
//         onPageChanged: (index) => setState(() => _bannerIndex = index),
//         itemBuilder: (context, index) {
//           final banner = banners[index];
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 6),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(8),
//               onTap: () => _openExternal(banner.link),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     CachedNetworkImage(
//                       imageUrl: banner.imageUrl,
//                       fit: BoxFit.cover,
//                       placeholder: (_, __) => Container(
//                         color: const Color(0xFFE3EFE8),
//                         child: const Center(child: CircularProgressIndicator()),
//                       ),
//                       errorWidget: (_, __, ___) => Container(
//                         color: const Color(0xFF0B4D3A),
//                         child: const Icon(
//                           Icons.image_not_supported_outlined,
//                           color: Colors.white,
//                           size: 42,
//                         ),
//                       ),
//                     ),
//                     DecoratedBox(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.black.withValues(alpha: .72),
//                             Colors.black.withValues(alpha: .08),
//                           ],
//                           begin: Alignment.bottomCenter,
//                           end: Alignment.topCenter,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       left: 16,
//                       right: 16,
//                       bottom: 14,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             banner.title,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.hindSiliguri(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                           Text(
//                             banner.description,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.hindSiliguri(
//                               color: Colors.white.withValues(alpha: .88),
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _statsSection(IQCStats stats) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 1.55,
//         children: [
//           _statCard('Weekly Quiz', stats.totalWeeklyQuizzes, Icons.event_note),
//           _statCard('Mega Quiz', stats.totalMegaQuizzes, Icons.emoji_events),
//           _statCard(
//             'Ramadan Project',
//             stats.totalRamadanProjects,
//             Icons.mosque,
//           ),
//           _statCard('Participants', stats.totalParticipants, Icons.groups),
//         ],
//       ),
//     );
//   }

//   Widget _statCard(String title, int value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFD8E7DE)),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: const Color(0xFFE8F5EE),
//             child: Icon(icon, color: const Color(0xFF0B4D3A)),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '$value+',
//                   style: GoogleFonts.hindSiliguri(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w800,
//                     color: const Color(0xFF0B4D3A),
//                   ),
//                 ),
//                 Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: GoogleFonts.hindSiliguri(
//                     fontSize: 13,
//                     color: Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _aboutSection() {
//     return _sectionCard(
//       title: 'পরিচিতি',
//       icon: Icons.volunteer_activism_outlined,
//       child: Text(
//         'Islamic Quiz Contest (IQC) বর্তমান প্রজন্মের কাছে ইসলাম পৌঁছানোর একটি অরাজনৈতিক ক্ষুদ্র প্রয়াস। কুইজ, সচেতনতা ও শিক্ষামূলক কার্যক্রমের মাধ্যমে সহজভাবে ইসলামি জ্ঞান ছড়িয়ে দেওয়ার চেষ্টা করা হয়।',
//         style: GoogleFonts.hindSiliguri(fontSize: 15, height: 1.6),
//       ),
//     );
//   }

//   Widget _activitiesSection() {
//     return _sectionCard(
//       title: 'কার্যক্রম',
//       icon: Icons.checklist_rtl,
//       child: const Column(
//         children: [
//           _ActivityRow(icon: Icons.event_note, text: '৬১টি সাপ্তাহিক কুইজ'),
//           _ActivityRow(icon: Icons.emoji_events, text: '৩০টি মেগা কুইজ'),
//           _ActivityRow(
//             icon: Icons.nightlight_round,
//             text: '৫টি রমাদান প্রজেক্ট',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _quizSection(List<IQCQuiz> quizzes) {
//     return _sectionCard(
//       title: 'চলমান কুইজ',
//       icon: Icons.quiz_outlined,
//       child: quizzes.isEmpty
//           ? Text(
//               'নতুন কুইজের তথ্য শীঘ্রই যুক্ত হবে।',
//               style: GoogleFonts.hindSiliguri(color: Colors.black54),
//             )
//           : Column(
//               children: quizzes.map((quiz) {
//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF8FBF7),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: const Color(0xFFD8E7DE)),
//                   ),
//                   child: Row(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: CachedNetworkImage(
//                           imageUrl: quiz.imageUrl,
//                           width: 58,
//                           height: 58,
//                           fit: BoxFit.cover,
//                           errorWidget: (_, __, ___) => Container(
//                             width: 58,
//                             height: 58,
//                             color: const Color(0xFFE8F5EE),
//                             child: const Icon(
//                               Icons.menu_book,
//                               color: Color(0xFF0B4D3A),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               quiz.title,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: GoogleFonts.hindSiliguri(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: 15,
//                               ),
//                             ),
//                             Text(
//                               quiz.description,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: GoogleFonts.hindSiliguri(
//                                 color: Colors.black54,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         tooltip: 'Open quiz',
//                         onPressed: () => _openQuizWebView(quiz.quizLink),
//                         icon: const Icon(Icons.arrow_forward_ios, size: 18),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//     );
//   }

//   Widget _socialSection() {
//     return _sectionCard(
//       title: 'যোগাযোগ',
//       icon: Icons.link,
//       child: Row(
//         children: [
//           Expanded(
//             child: _socialButton('Facebook', Icons.facebook, _facebookUrl),
//           ),
//           const SizedBox(width: 10),
//           Expanded(child: _socialButton('Telegram', Icons.send, _telegramUrl)),
//         ],
//       ),
//     );
//   }

//   Widget _socialButton(String text, IconData icon, String url) {
//     return OutlinedButton.icon(
//       onPressed: () => _openExternal(url),
//       icon: Icon(icon),
//       label: Text(text, overflow: TextOverflow.ellipsis),
//       style: OutlinedButton.styleFrom(
//         foregroundColor: const Color(0xFF0B4D3A),
//         side: const BorderSide(color: Color(0xFF0B4D3A)),
//         padding: const EdgeInsets.symmetric(vertical: 13),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   Widget _sectionCard({
//     required String title,
//     required IconData icon,
//     required Widget child,
//   }) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: .05),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: const Color(0xFF0B4D3A)),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: GoogleFonts.hindSiliguri(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     color: const Color(0xFF0B4D3A),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           child,
//         ],
//       ),
//     );
//   }
// }

// class _ActivityRow extends StatelessWidget {
//   final IconData icon;
//   final String text;

//   const _ActivityRow({required this.icon, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF0B4D3A), size: 22),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: GoogleFonts.hindSiliguri(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class IQCInfo {
//   final List<IQCBanner> banners;
//   final List<IQCQuiz> quizzes;
//   final IQCStats stats;

//   const IQCInfo({
//     required this.banners,
//     required this.quizzes,
//     required this.stats,
//   });

//   factory IQCInfo.fromJson(Map<String, dynamic> json) {
//     return IQCInfo(
//       banners: _list(
//         json['banners'],
//       ).map((item) => IQCBanner.fromJson(item)).toList(),
//       quizzes: _list(
//         json['quizzes'],
//       ).map((item) => IQCQuiz.fromJson(item)).toList(),
//       stats: IQCStats.fromJson(_map(json['stats'])),
//     );
//   }

//   factory IQCInfo.fallback() {
//     return const IQCInfo(
//       banners: [
//         IQCBanner(
//           id: 1,
//           title: 'Mega Quiz #29',
//           description: 'বিশেষ মেগা কুইজ প্রতিযোগিতা',
//           imageUrl:
//               'https://i.ibb.co.com/1fDKn2pQ/546920346-1741846050078387-6395574068466367809-n.jpg',
//           link: _IQCHomePageState._facebookUrl,
//         ),
//       ],
//       quizzes: [
//         IQCQuiz(
//           id: 1,
//           title: 'সাপ্তাহিক কুইজ #61',
//           description: 'ইসলাম সম্পর্কিত ২০টি প্রশ্ন',
//           imageUrl:
//               'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/islamic_Quiz/quiz.webp',
//           quizLink: _IQCHomePageState._quizUrl,
//           type: 'weekly',
//           date: '2024-01-15',
//         ),
//       ],
//       stats: IQCStats(
//         totalWeeklyQuizzes: 61,
//         totalMegaQuizzes: 30,
//         totalRamadanProjects: 5,
//         totalParticipants: 15000,
//       ),
//     );
//   }

//   static List<Map<String, dynamic>> _list(dynamic value) {
//     if (value is! List) return const [];
//     return value
//         .whereType<Map>()
//         .map((item) => Map<String, dynamic>.from(item))
//         .toList();
//   }

//   static Map<String, dynamic> _map(dynamic value) {
//     if (value is! Map) return const {};
//     return Map<String, dynamic>.from(value);
//   }
// }

// class IQCBanner {
//   final int id;
//   final String title;
//   final String description;
//   final String imageUrl;
//   final String link;

//   const IQCBanner({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.imageUrl,
//     required this.link,
//   });

//   factory IQCBanner.fromJson(Map<String, dynamic> json) {
//     return IQCBanner(
//       id: _asInt(json['id']),
//       title: _asString(json['title'], 'IQC Banner'),
//       description: _asString(json['description'], ''),
//       imageUrl: _asString(json['imageUrl'], ''),
//       link: _asString(json['link'], _IQCHomePageState._quizUrl),
//     );
//   }
// }

// class IQCQuiz {
//   final int id;
//   final String title;
//   final String description;
//   final String imageUrl;
//   final String quizLink;
//   final String type;
//   final String date;

//   const IQCQuiz({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.imageUrl,
//     required this.quizLink,
//     required this.type,
//     required this.date,
//   });

//   factory IQCQuiz.fromJson(Map<String, dynamic> json) {
//     return IQCQuiz(
//       id: _asInt(json['id']),
//       title: _asString(json['title'], 'ইসলামিক কুইজ'),
//       description: _asString(json['description'], ''),
//       imageUrl: _asString(json['imageUrl'], ''),
//       quizLink: _asString(json['quizLink'], _IQCHomePageState._quizUrl),
//       type: _asString(json['type'], ''),
//       date: _asString(json['date'], ''),
//     );
//   }
// }

// class IQCStats {
//   final int totalWeeklyQuizzes;
//   final int totalMegaQuizzes;
//   final int totalRamadanProjects;
//   final int totalParticipants;

//   const IQCStats({
//     required this.totalWeeklyQuizzes,
//     required this.totalMegaQuizzes,
//     required this.totalRamadanProjects,
//     required this.totalParticipants,
//   });

//   factory IQCStats.fromJson(Map<String, dynamic> json) {
//     return IQCStats(
//       totalWeeklyQuizzes: _asInt(json['totalWeeklyQuizzes']),
//       totalMegaQuizzes: _asInt(json['totalMegaQuizzes']),
//       totalRamadanProjects: _asInt(json['totalRamadanProjects']),
//       totalParticipants: _asInt(json['totalParticipants']),
//     );
//   }
// }

// int _asInt(dynamic value) {
//   if (value is int) return value;
//   if (value is num) return value.toInt();
//   return int.tryParse(value?.toString() ?? '') ?? 0;
// }

// String _asString(dynamic value, String fallback) {
//   final text = value?.toString().trim();
//   return text == null || text.isEmpty ? fallback : text;
// }
