import 'package:intl/intl.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'order_update', 'promo'
  final String? relatedId; // e.g. Order ID
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'info',
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(createdAt);
  }
}
