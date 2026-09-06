// ============================================================
//  quick_integration_example.dart
//  এই ফাইলটি দেখুন কিভাবে আযান সিস্টেম যুক্ত করবেন
// ============================================================

import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';
import 'prayer_times_navigation.dart';

// ═══════════════════════════════════════════════════════════════
// Example 1: Islamic Dashboard এ যুক্ত করুন
// ═══════════════════════════════════════════════════════════════
class IslamicDashboardExample extends StatelessWidget {
  const IslamicDashboardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইসলামিক ফিচার'),
        actions: [
          // AppBar এ সরাসরি আইকন বাটন
          PrayerTimesIconButton(),
          PrayerAlarmIconButton(),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // ── নামাজের সময় কার্ড ──
          PrayerTimesCard(),

          // ── আযান সেটিংস কার্ড ──
          PrayerAlarmCard(),

          // আপনার অন্যান্য কার্ড...
          _buildDummyCard('কুরআন', Icons.book_rounded),
          _buildDummyCard('হাদিস', Icons.menu_book_rounded),
          _buildDummyCard('দোয়া', Icons.favorite_rounded),
          _buildDummyCard('তাসবিহ', Icons.circle_outlined),
        ],
      ),
    );
  }

  Widget _buildDummyCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Example 2: List View এ যুক্ত করুন
// ═══════════════════════════════════════════════════════════════
class IslamicFeaturesListExample extends StatelessWidget {
  const IslamicFeaturesListExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ইসলামিক ফিচার')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── নামাজের সময় কার্ড ──
          PrayerTimesCard(),
          const SizedBox(height: 16),

          // ── আযান সেটিংস কার্ড ──
          PrayerAlarmCard(),
          const SizedBox(height: 16),

          // আপনার অন্যান্য items...
          _buildListItem('কুরআন', Icons.book_rounded),
          _buildListItem('হাদিস', Icons.menu_book_rounded),
          _buildListItem('দোয়া', Icons.favorite_rounded),
        ],
      ),
    );
  }

  Widget _buildListItem(String title, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Example 3: Drawer/Menu তে যুক্ত করুন
// ═══════════════════════════════════════════════════════════════
class DrawerExample extends StatelessWidget {
  const DrawerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF4A90D9)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Noorvia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ইসলামিক অ্যাপ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // ── নামাজের সময় ──
          PrayerTimesListTile(),

          // ── আযান সেটিংস ──
          PrayerAlarmListTile(),

          const Divider(),

          // আপনার অন্যান্য menu items...
          ListTile(
            leading: const Icon(Icons.book_rounded),
            title: const Text('কুরআন'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('হাদিস'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Example 4: Custom Button দিয়ে Navigate করুন
// ═══════════════════════════════════════════════════════════════
class CustomButtonExample extends StatelessWidget {
  const CustomButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Button Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── নামাজের সময় বাটন ──
            ElevatedButton.icon(
              onPressed: () => navigateToPrayerTimes(context),
              icon: const Icon(Icons.access_time_rounded),
              label: const Text('নামাজের সময়'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── আযান সেটিংস বাটন ──
            ElevatedButton.icon(
              onPressed: () => navigateToPrayerAlarmSettings(context),
              icon: const Icon(Icons.alarm_rounded),
              label: const Text('আযান সেটিংস'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Example 5: Floating Action Button
// ═══════════════════════════════════════════════════════════════
class FABExample extends StatelessWidget {
  const FABExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAB Example')),
      body: const Center(child: Text('Your content here')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => navigateToPrayerTimes(context),
        icon: const Icon(Icons.access_time_rounded),
        label: const Text('নামাজের সময়'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOW TO USE:
// ═══════════════════════════════════════════════════════════════
/*

1. আপনার যেকোনো ফাইলে import করুন:
   
   import 'screens/IslamicFeatures/prayer_times_navigation.dart';

2. যেকোনো একটি উপায় ব্যবহার করুন:

   A. Card ব্যবহার করুন:
      PrayerTimesCard()
      PrayerAlarmCard()

   B. ListTile ব্যবহার করুন:
      PrayerTimesListTile()
      PrayerAlarmListTile()

   C. Icon Button ব্যবহার করুন:
      PrayerTimesIconButton()
      PrayerAlarmIconButton()

   D. Function call করুন:
      navigateToPrayerTimes(context)
      navigateToPrayerAlarmSettings(context)

3. Run করুন:
   flutter pub get
   flutter run

4. Test করুন:
   - নামাজের সময় পেজ খুলুন
   - আযান সেটিংস পেজ খুলুন
   - সব ফিচার চেক করুন

*/
