import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import '../widgets/poster_carousel_widget.dart';

class HomeExampleScreen extends StatelessWidget {
  const HomeExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('হোম'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ এখানে Poster Carousel Widget ব্যবহার করুন
            // এটি আপনার ছবিতে দেখানো জায়গায় বসবে
            const PosterCarouselWidget(
              height: 200, // উচ্চতা
              autoSlide: true, // অটো স্লাইড চালু
              autoSlideDuration: Duration(seconds: 3), // ৩ সেকেন্ড পর পর
              showIndicator: true, // নিচে ডট দেখাবে
              margin: EdgeInsets.all(16), // চারপাশে মার্জিন
              borderRadius: BorderRadius.all(Radius.circular(16)), // কোণা গোল
            ),

            // অন্যান্য content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'অন্যান্য বিষয়বস্তু',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // আপনার অন্যান্য widgets এখানে যোগ করুন
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.book),
                      title: const Text('কুরআন'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mosque),
                      title: const Text('নামাজের সময়'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
