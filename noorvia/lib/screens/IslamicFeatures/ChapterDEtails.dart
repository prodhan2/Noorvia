import 'package:flutter/material.dart';

class ChapterDetailPage extends StatefulWidget {
  final String chapterTitle;
  final String chapterDescription;

  const ChapterDetailPage({
    Key? key,
    required this.chapterTitle,
    required this.chapterDescription,
  }) : super(key: key);

  @override
  _ChapterDetailPageState createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  double fontSize = 18;
  Color textColor = Colors.black87;
  double scale = 1.0; // Zoom
  bool autoScroll = false;
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void startAutoScroll() async {
    if (!autoScroll) return;
    while (autoScroll && _scrollController.hasClients) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_scrollController.offset <
          _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(_scrollController.offset + 1);
      } else {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chapterTitle,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => buildSettingsSheet(),
              );
            },
          )
        ],
      ),
      body: InteractiveViewer(
        maxScale: 3.0,
        minScale: 1.0,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: Text(
              widget.chapterDescription,
              textAlign: TextAlign.justify,
              style:
                  TextStyle(fontSize: fontSize, color: textColor, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSettingsSheet() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('পাঠ সেটিংস',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),

          // Font Size
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ফন্ট সাইজ: ${fontSize.toInt()}'),
              Slider(
                value: fontSize,
                min: 12,
                max: 36,
                divisions: 24,
                label: fontSize.toInt().toString(),
                onChanged: (value) {
                  setState(() => fontSize = value);
                },
              ),
            ],
          ),

          // Text Color
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('টেক্সট কালার:'),
              Row(
                children: [
                  buildColorButton(Colors.black87),
                  buildColorButton(Colors.blueAccent),
                  buildColorButton(Colors.deepPurple),
                  buildColorButton(Colors.green),
                ],
              ),
            ],
          ),

          // Zoom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('জুম: ${scale.toStringAsFixed(1)}x'),
              Slider(
                value: scale,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() => scale = value);
                },
              ),
            ],
          ),

          // Auto scroll toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('স্বয়ংক্রিয় স্ক্রল'),
              Switch(
                value: autoScroll,
                onChanged: (value) {
                  setState(() {
                    autoScroll = value;
                    if (autoScroll) startAutoScroll();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          textColor = color;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: textColor == color ? Colors.white : Colors.grey, width: 2),
        ),
      ),
    );
  }
}
