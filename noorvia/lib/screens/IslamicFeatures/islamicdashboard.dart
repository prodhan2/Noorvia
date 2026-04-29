import 'AudioQuran.dart';
import 'BangalQUran/BanglaQuran.dart';
import 'NamazNiyom.dart';
import 'islamciradio.dart';
import 'otherpage.dart';
import 'ramadancalender.dart';
import 'tashbi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(IslamicApp());

class IslamicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamic App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      home: IslamicHomePage(),
      routes: {
        '/audio': (_) => QuranApp(),
        '/bangkay-quran': (_) => QuranApp(),
        '/calendar': (_) => RamadanCalendarPage(),
        '/namaz': (_) => ChapterListPage(),
        '/radio': (_) => RadioScreen(),
        '/tasbih': (_) => TasbihCounter(),
        // '/postimages': (_) => ImageUploader(),
      },
    );
  }
}

class GridItemData {
  final String svgPath;
  final String title;
  final String route;

  GridItemData({
    required this.svgPath,
    required this.title,
    required this.route,
  });
}

final List<GridItemData> gridItems = [
  GridItemData(
      svgPath: 'assets/images/audio.svg', title: 'অডিও', route: '/audio'),
  GridItemData(
      svgPath: 'assets/images/bangkayQuran.svg',
      title: 'বঙ্গানুবাদ কুরআন',
      route: '/bangkay-quran'),
  GridItemData(
      svgPath: 'assets/images/calender.svg',
      title: 'ক্যালেন্ডার',
      route: '/calendar'),
  GridItemData(
      svgPath: 'assets/images/namaz.svg', title: 'নামাজ', route: '/namaz'),
  GridItemData(
      svgPath: 'assets/images/radio.svg', title: 'রেডিও', route: '/radio'),
  GridItemData(
      svgPath: 'assets/images/tasbih.svg', title: 'তাসবিহ', route: '/tasbih'),
];

class IslamicHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white page background
      appBar: AppBar(
        title: const Text('বিউটিফুল দিনাজপুর ইসলামিক App'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF07FFEA), Color(0xFF2A33E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: gridItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 items per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final item = gridItems[index];
            return AnimatedGridItem(item: item);
          },
        ),
      ),
    );
  }
}

class AnimatedGridItem extends StatefulWidget {
  final GridItemData item;

  const AnimatedGridItem({Key? key, required this.item}) : super(key: key);

  @override
  State<AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<AnimatedGridItem> {
  double scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => scale = 0.95);

  void _onTapUp(TapUpDetails _) {
    setState(() => scale = 1.0);
    Navigator.pushNamed(context, widget.item.route);
  }

  void _onTapCancel() => setState(() => scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // No color, so default white background
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                widget.item.svgPath,
                height: 50,
                // no color override, keep original SVG colors
              ),
              const SizedBox(height: 12),
              Text(
                widget.item.title,
                style: const TextStyle(
                  color: Colors.black87, // dark text on white bg
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder pages for routes
