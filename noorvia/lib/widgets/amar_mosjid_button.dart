import 'package:flutter/material.dart';
import '../screens/location/nearby_mosques_screen.dart';

/// A beautiful button widget to navigate to nearby mosques screen
/// Can be placed anywhere in your app (home screen, drawer, etc.)
class AmarMosjidButton extends StatelessWidget {
  final bool isCompact;

  const AmarMosjidButton({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactButton(context);
    }
    return _buildFullButton(context);
  }

  /// Full-width card button with gradient
  Widget _buildFullButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToMosques(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mosque, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'আমার মসজিদ',
                      style: TextStyle(
                        fontFamily: null,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'আশেপাশের মসজিদ খুঁজুন',
                      style: TextStyle(
                        fontFamily: null,
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact button version
  Widget _buildCompactButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToMosques(context),
      icon: const Icon(Icons.mosque),
      label: const Text('আমার মসজিদ', style: TextStyle(fontFamily: null)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToMosques(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NearbyMosquesScreen()),
    );
  }
}
