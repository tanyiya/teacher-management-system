import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AlertNotification>> getNotifications(String userId) {
    return _db.collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => AlertNotification.fromMap(doc.id, doc.data())).toList()
    );
  }
}