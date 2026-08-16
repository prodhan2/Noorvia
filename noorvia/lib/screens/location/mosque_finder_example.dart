import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import '../../widgets/amar_mosjid_button.dart';

/// Example screen showing how to integrate the "Amar Mosjid" feature
/// This demonstrates different ways to add the mosque finder to your app
class MosqueFinderExample extends StatelessWidget {
  const MosqueFinderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'মসজিদ খুঁজুন - উদাহরণ',
          style: TextStyle(fontFamily: null),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'আমার মসজিদ ফিচার',
              style: TextStyle(
                fontFamily: null,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার আশেপাশের মসজিদগুলো খুঁজে বের করুন এবং দিকনির্দেশনা পান',
              style: TextStyle(
                fontFamily: null,
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Full button example
            const Text(
              '১. পূর্ণ বাটন (হোম স্ক্রিনের জন্য)',
              style: TextStyle(
                fontFamily: null,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const AmarMosjidButton(),
            const SizedBox(height: 32),

            // Compact button example
            const Text(
              '২. কমপ্যাক্ট বাটন',
              style: TextStyle(
                fontFamily: null,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: AmarMosjidButton(isCompact: true)),
            const SizedBox(height: 32),

            // Features list
            const Text(
              'ফিচার সমূহ:',
              style: TextStyle(
                fontFamily: null,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.gps_fixed,
              'স্বয়ংক্রিয় লোকেশন সনাক্তকরণ',
              'আপনার বর্তমান অবস্থান স্বয়ংক্রিয়ভাবে সনাক্ত করে',
            ),
            _buildFeatureItem(
              Icons.mosque,
              'নিকটতম মসজিদ',
              'দূরত্ব অনুযায়ী সাজানো মসজিদের তালিকা',
            ),
            _buildFeatureItem(
              Icons.map,
              'গুগল ম্যাপস ইন্টিগ্রেশন',
              'সরাসরি গুগল ম্যাপসে দিকনির্দেশনা পান',
            ),
            _buildFeatureItem(
              Icons.tune,
              'কাস্টমাইজেবল রেডিয়াস',
              '১ থেকে ২০ কিলোমিটার পর্যন্ত অনুসন্ধান করুন',
            ),
            _buildFeatureItem(
              Icons.language,
              'বাংলা ভাষা সাপোর্ট',
              'সম্পূর্ণ বাংলা ইন্টারফেস',
            ),
            _buildFeatureItem(
              Icons.offline_bolt,
              'অফলাইন সাপোর্ট',
              'ইন্টারনেট না থাকলে সুন্দর এরর মেসেজ',
            ),
            const SizedBox(height: 32),

            // Technical details
            Container(
              padding: const EdgeInsets.all(16),
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
                        'প্রযুক্তিগত তথ্য',
                        style: TextStyle(
                          fontFamily: null,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTechDetail('ডেটা সোর্স', 'OpenStreetMap Overpass API'),
                  _buildTechDetail('লোকেশন', 'Geolocator Package'),
                  _buildTechDetail('দূরত্ব গণনা', 'Haversine Formula'),
                  _buildTechDetail('ম্যাপস', 'Google Maps Integration'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green[700], size: 24),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: null,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: null, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
