import 'package:flutter/material.dart';
import 'nearby_mosques_screen.dart';
import '../../widgets/amar_mosjid_button.dart';

/// Demo screen to test the Mosque Finder feature
/// Run this screen to see all the features in action
///
/// To test: Add this route to your app and navigate to it
class MosqueFinderDemo extends StatelessWidget {
  const MosqueFinderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'মসজিদ খুঁজুন - ডেমো',
          style: TextStyle(fontFamily: null),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              _buildHeroSection(),
              const SizedBox(height: 30),

              // Button Demos
              _buildSectionTitle('বাটন স্টাইল'),
              const SizedBox(height: 16),

              // Full Button
              const Text(
                '১. পূর্ণ বাটন (Full Button)',
                style: TextStyle(
                  fontFamily: null,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const AmarMosjidButton(),
              const SizedBox(height: 20),

              // Compact Button
              const Text(
                '২. কমপ্যাক্ট বাটন (Compact Button)',
                style: TextStyle(
                  fontFamily: null,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: AmarMosjidButton(isCompact: true)),
              const SizedBox(height: 20),

              // Custom Button
              const Text(
                '৩. কাস্টম বাটন (Custom Button)',
                style: TextStyle(
                  fontFamily: null,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCustomButton(context),
              const SizedBox(height: 30),

              // Features Section
              _buildSectionTitle('ফিচার সমূহ'),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.gps_fixed,
                'স্বয়ংক্রিয় লোকেশন',
                'আপনার বর্তমান অবস্থান স্বয়ংক্রিয়ভাবে সনাক্ত করে',
                Colors.blue,
              ),
              _buildFeatureCard(
                Icons.mosque,
                'নিকটতম মসজিদ',
                'দূরত্ব অনুযায়ী সাজানো মসজিদের তালিকা',
                Colors.green,
              ),
              _buildFeatureCard(
                Icons.map,
                'গুগল ম্যাপস',
                'সরাসরি গুগল ম্যাপসে দিকনির্দেশনা',
                Colors.red,
              ),
              _buildFeatureCard(
                Icons.tune,
                'কাস্টমাইজেবল',
                '১ থেকে ২০ কিলোমিটার পর্যন্ত অনুসন্ধান',
                Colors.orange,
              ),
              const SizedBox(height: 30),

              // Test Instructions
              _buildTestInstructions(),
              const SizedBox(height: 30),

              // Main Test Button
              _buildMainTestButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.mosque, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'আমার মসজিদ',
            style: TextStyle(
              fontFamily: null,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'আশেপাশের মসজিদ খুঁজুন',
            style: TextStyle(
              fontFamily: null,
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'GPS Location',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              SizedBox(width: 16),
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'OpenStreetMap',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: null,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NearbyMosquesScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mosque),
          SizedBox(width: 12),
          Text(
            'আমার মসজিদ খুঁজুন',
            style: TextStyle(
              fontFamily: null,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: null,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: null,
                      fontSize: 13,
                      color: Colors.grey[600],
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

  Widget _buildTestInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'টেস্ট করার নির্দেশনা',
                style: TextStyle(
                  fontFamily: null,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstruction('১', 'লোকেশন সার্ভিস চালু করুন'),
          _buildInstruction('২', 'ইন্টারনেট সংযোগ চেক করুন'),
          _buildInstruction('৩', 'নিচের বাটনে ক্লিক করুন'),
          _buildInstruction('৪', 'লোকেশন অনুমতি দিন'),
          _buildInstruction('৫', 'মসজিদের তালিকা দেখুন'),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: null,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: null, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTestButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NearbyMosquesScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'এখনই টেস্ট করুন',
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
