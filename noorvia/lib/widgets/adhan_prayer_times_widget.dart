import 'package:flutter/material.dart' hide Text;
import 'package:noorvia/core/localization/localized_text.dart';

/// Example placeholder widget
/// This widget was previously using adhan_dart package which is no longer available
class AdhanPrayerTimesWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const AdhanPrayerTimesWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mosque, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Offline Prayer Times',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please use the main prayer times feature',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
