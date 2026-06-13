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
    return AlertNotification(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
}
