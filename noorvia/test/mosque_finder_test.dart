import 'package:flutter_test/flutter_test.dart';
import 'package:noorvia/core/models/mosque.dart';

/// Unit tests for Mosque Finder feature
/// Run with: flutter test test/mosque_finder_test.dart
void main() {
  group('Mosque Model Tests', () {
    test('Mosque model should be created from JSON', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name': 'Baitul Mukarram Mosque',
          'name:bn': 'বায়তুল মোকাররম মসজিদ',
          'amenity': 'place_of_worship',
          'religion': 'muslim',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.name, 'Baitul Mukarram Mosque');
      expect(mosque.latitude, 23.8103);
      expect(mosque.longitude, 90.4125);
      expect(mosque.distanceInMeters, greaterThan(0));
    });

    test('Mosque should use Bengali name if available', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name:bn': 'বায়তুল মোকাররম মসজিদ',
          'amenity': 'place_of_worship',
          'religion': 'muslim',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.name, 'বায়তুল মোকাররম মসজিদ');
    });

    test('Mosque should use default name if no name provided', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'amenity': 'place_of_worship',
          'religion': 'muslim',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.name, 'নামহীন মসজিদ'); // Unnamed Mosque in Bengali
    });

    test('Distance calculation should be accurate', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      // Distance should be approximately 50-60 meters
      expect(mosque.distanceInMeters, greaterThan(40));
      expect(mosque.distanceInMeters, lessThan(70));
    });

    test('Formatted distance should show meters for short distances', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);
      final formattedDistance = mosque.getFormattedDistance();

      // Assert
      expect(formattedDistance, contains('মিটার')); // Should contain "meters" in Bengali
    });

    test('Formatted distance should show kilometers for long distances', () {
      // Arrange
      final json = {
        'lat': 24.0000, // Far away location
        'lon': 91.0000,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);
      final formattedDistance = mosque.getFormattedDistance();

      // Assert
      expect(formattedDistance, contains('কিলোমিটার')); // Should contain "kilometers" in Bengali
    });

    test('Google Maps URL should be correctly formatted', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);
      final url = mosque.getGoogleMapsUrl();

      // Assert
      expect(url, contains('https://www.google.com/maps/search/'));
      expect(url, contains('api=1'));
      expect(url, contains('query=23.8103,90.4125'));
    });

    test('Mosque should handle string coordinates', () {
      // Arrange
      final json = {
        'lat': '23.8103', // String instead of double
        'lon': '90.4125', // String instead of double
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.latitude, 23.8103);
      expect(mosque.longitude, 90.4125);
    });

    test('Mosque should handle address field', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name': 'Test Mosque',
          'addr:full': 'Dhaka, Bangladesh',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.address, 'Dhaka, Bangladesh');
    });

    test('Haversine formula should calculate zero distance for same location', () {
      // Arrange
      final json = {
        'lat': 23.8100,
        'lon': 90.4120,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.distanceInMeters, lessThan(1)); // Should be very close to 0
    });
  });

  group('Distance Calculation Tests', () {
    test('Distance between Dhaka and Chittagong should be approximately 200km', () {
      // Arrange
      final json = {
        'lat': 22.3569, // Chittagong
        'lon': 91.7832,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8103; // Dhaka
      final userLon = 90.4125;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);
      final distanceKm = mosque.distanceInMeters / 1000;

      // Assert
      expect(distanceKm, greaterThan(150)); // Should be more than 150km
      expect(distanceKm, lessThan(250)); // Should be less than 250km
    });

    test('Distance should be symmetric', () {
      // Arrange
      final json1 = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {'name': 'Mosque 1'},
      };
      final json2 = {
        'lat': 23.8200,
        'lon': 90.4200,
        'tags': {'name': 'Mosque 2'},
      };

      // Act
      final mosque1 = Mosque.fromJson(json1, 23.8200, 90.4200);
      final mosque2 = Mosque.fromJson(json2, 23.8103, 90.4125);

      // Assert
      // Distance should be approximately the same in both directions
      expect(
        (mosque1.distanceInMeters - mosque2.distanceInMeters).abs(),
        lessThan(1), // Difference should be less than 1 meter
      );
    });
  });

  group('Edge Cases', () {
    test('Should handle missing tags gracefully', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        // No tags field
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.name, 'নামহীন মসজিদ');
      expect(mosque.address, null);
    });

    test('Should handle empty tags', () {
      // Arrange
      final json = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {}, // Empty tags
      };
      final userLat = 23.8100;
      final userLon = 90.4120;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);

      // Assert
      expect(mosque.name, 'নামহীন মসজিদ');
    });

    test('Should handle very large distances', () {
      // Arrange
      final json = {
        'lat': -33.8688, // Sydney, Australia
        'lon': 151.2093,
        'tags': {
          'name': 'Test Mosque',
        },
      };
      final userLat = 23.8103; // Dhaka, Bangladesh
      final userLon = 90.4125;

      // Act
      final mosque = Mosque.fromJson(json, userLat, userLon);
      final distanceKm = mosque.distanceInMeters / 1000;

      // Assert
      expect(distanceKm, greaterThan(7000)); // Should be more than 7000km
      expect(distanceKm, lessThan(9000)); // Should be less than 9000km
    });
  });
}
