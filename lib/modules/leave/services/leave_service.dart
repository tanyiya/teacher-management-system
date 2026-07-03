import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
import '../models/leave.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notif = NotificationService();

  /// Applies for a new leave request and registers a notification for the principal
  Future<String> applyLeave(LeaveRecord leave) async {
    try {
      final docRef = await _db.collection('leaves').add({
        'teacherId': leave.teacherId,
        'teacherName': leave.teacherName,
        'startDate': leave.startDate,
        'endDate': leave.endDate,
        'duration': leave.duration,
        'type': leave.type.dbValue,
        'status': 'pending',
        'documentUrl': leave.documentUrl,
        'documentName': leave.documentName,
        'remarks': leave.remarks ?? '',
        'principalNotes': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify every principal — was previously hardcoded to a literal
      // 'admin-id' that matched no real user, so these never arrived.
      await _notif.sendToAdmins(
        title: 'New Leave Application: ${leave.teacherName}',
        message: '${leave.teacherName} applied for ${leave.duration} day(s) of ${leave.type.name} starting ${leave.startDate}.',
        type: 'leave',
        relatedId: leave.teacherId,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to apply leave: $e');
    }
  }

  /// Streams real-time leave list filtered by teacherId (or retrieves all if teacherId is null)
  Stream<List<LeaveRecord>> getLeaves({String? teacherId}) {
    Query query = _db.collection('leaves');
    
    if (teacherId != null && teacherId.isNotEmpty) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }
    
    // Ordered by latest startDate descending
    query = query.orderBy('startDate', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LeaveRecord.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Updates status ('approved' or 'rejected') and sends a real-time responsive notification to the teacher
  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status, // 'approved' or 'rejected'
    required String principalNotes,
    required String teacherId,
    required String leaveType,
    required double duration,
    required String startDate,
  }) async {
    try {
      await _db.collection('leaves').doc(leaveId).update({
        'status': status,
        'principalNotes': principalNotes,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final statusTitle = status == 'approved' ? 'Approved' : 'Rejected';

      // Send responsive notification to the teacher
      await _db.collection('notifications').add({
        'userId': teacherId,
        'title': 'Leave Application $statusTitle',
        'message': 'Your application for $duration day(s) of $leaveType leave starting $startDate has been $status. Notes: ${principalNotes.isNotEmpty ? principalNotes : "None"}',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'leave',
        'relatedId': teacherId,
      });
    } catch (e) {
      throw Exception('Failed to update leave status: $e');
    }
  }
}
