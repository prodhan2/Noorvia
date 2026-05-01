// ============================================================
//  notification_model.dart
//  Islamic notification data model
// ============================================================

class IslamicNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String reference;
  final String schedule;

  const IslamicNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.reference,
    required this.schedule,
  });

  factory IslamicNotification.fromJson(Map<String, dynamic> json) {
    return IslamicNotification(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'reminder',
      reference: json['reference'] as String? ?? '',
      schedule: json['schedule'] as String? ?? 'daily',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'reference': reference,
        'schedule': schedule,
      };

  /// Icon emoji based on notification type
  String get typeIcon {
    switch (type) {
      case 'quran':
        return '📖';
      case 'hadith':
        return '📜';
      case 'prayer':
        return '🕌';
      case 'dua':
        return '🤲';
      case 'reminder':
      default:
        return '✨';
    }
  }

  /// Bangla label for type
  String get typeLabel {
    switch (type) {
      case 'quran':
        return 'কুরআন';
      case 'hadith':
        return 'হাদিস';
      case 'prayer':
        return 'নামাজ';
      case 'dua':
        return 'দোয়া';
      case 'reminder':
      default:
        return 'স্মরণ';
    }
  }
}
