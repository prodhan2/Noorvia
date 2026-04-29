import 'package:flutter/material.dart';

class QuranDemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Al-Quran Audio'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SurahCard(
            number: 1,
            name: 'Al-Fatihah',
            translation: 'The Opening',
            verses: 7,
          ),
          SurahCard(
            number: 2,
            name: 'Al-Baqarah',
            translation: 'The Cow',
            verses: 286,
          ),
          SurahCard(
            number: 36,
            name: 'Ya-Sin',
            translation: 'Ya Sin',
            verses: 83,
          ),
          SurahCard(
            number: 55,
            name: 'Ar-Rahman',
            translation: 'The Beneficent',
            verses: 78,
          ),
          SurahCard(
            number: 67,
            name: 'Al-Mulk',
            translation: 'The Sovereignty',
            verses: 30,
          ),
          SurahCard(
            number: 112,
            name: 'Al-Ikhlas',
            translation: 'The Sincerity',
            verses: 4,
          ),
        ],
      ),
    );
  }
}

class SurahCard extends StatelessWidget {
  final int number;
  final String name;
  final String translation;
  final int verses;

  SurahCard({
    required this.number,
    required this.name,
    required this.translation,
    required this.verses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    translation,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text('$verses verses'),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.play_circle_fill, color: Colors.green),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerMethodCard extends StatelessWidget {
  final String title;
  final List<String> steps;

  PrayerMethodCard({
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            ...steps
                .map((step) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• '),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
