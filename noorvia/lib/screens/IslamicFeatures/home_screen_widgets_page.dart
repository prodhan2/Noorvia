import 'package:flutter/material.dart' hide Text;
import 'package:muslim_view/core/localization/localized_text.dart';
import '../../core/services/native_prayer_alarm_service.dart';

class HomeScreenWidgetsPage extends StatelessWidget {
  const HomeScreenWidgetsPage({super.key});

  Future<void> _pin(BuildContext context, String type, String label) async {
    final ok = await NativePrayerAlarmService.requestPinWidget(type);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '$label হোম স্ক্রিনে যোগ করার অনুরোধ পাঠানো হয়েছে'
              : 'আপনার Launcher direct pin support করে না। Home screen চেপে ধরে Widgets → Noorvia থেকে যোগ করুন।',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('হোম স্ক্রিন উইজেট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Noorvia-এর সময়গুলো অ্যাপ না খুলেই ফোনের Home screen-এ দেখুন।',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          _WidgetCard(
            icon: Icons.schedule_rounded,
            title: 'নামাজের সময়',
            subtitle: 'ফজর, যোহর, আসর, মাগরিব ও ইশা',
            onTap: () => _pin(context, 'prayer', 'নামাজের সময় উইজেট'),
          ),
          _WidgetCard(
            icon: Icons.notifications_active_rounded,
            title: 'পরবর্তী আযান',
            subtitle: 'পরবর্তী নামাজ ও সময় এক নজরে',
            onTap: () => _pin(context, 'azan', 'পরবর্তী আযান উইজেট'),
          ),
          _WidgetCard(
            icon: Icons.nights_stay_rounded,
            title: 'রমজান',
            subtitle: 'রমজানের দিন, সেহরি ও ইফতারের সময়',
            onTap: () => _pin(context, 'ramadan', 'রমজান উইজেট'),
          ),
        ],
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WidgetCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_to_home_screen_rounded, size: 18),
          label: const Text('যোগ করুন'),
        ),
      ),
    );
  }
}
