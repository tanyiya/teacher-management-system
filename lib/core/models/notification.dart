import 'package:cloud_firestore/cloud_firestore.dart';

class AlertNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool read;
  final DateTime timestamp;
  final String type;

  AlertNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.read,
    required this.timestamp,
    required this.type,
  });

  factory AlertNotification.fromMap(String id, Map<String, dynamic> data) {
    // timestamp arrives as Firestore Timestamp (SDK) or ISO-8601 string (REST).
    final raw = data['timestamp'];
    DateTime ts;
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String && raw.isNotEmpty) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }
    return AlertNotification(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      timestamp: ts,
      type: data['type'] ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'read': read,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  // Backwards-compatible alias used by UI code
  bool get isRead => read;
}
