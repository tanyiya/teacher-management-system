import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

// ── Import your existing Cloudinary service ───────────────
// Adjust this path if cloudinary_service.dart is in a different folder
import '../../../core/services/cloudinary_service.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── All reports for principal ─────────────────────────────
  Stream<List<FacilityReport>> getReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => FacilityReport.fromMap(d.id, d.data())).toList());
  }

  // ── Teacher's own reports — sorted client-side to avoid
  //    requiring a composite Firestore index ─────────────────
  Stream<List<FacilityReport>> getMyReports(String teacherId) {
    return _db
        .collection('reports')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => FacilityReport.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Submit report — upload image via Cloudinary ───────────
  Future<String> submitReport(
    FacilityReport report, {
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    final docRef = _db.collection('reports').doc();
    String photoUrl = '';

    // Upload image to Cloudinary if provided
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final ext = (fileName?.split('.').last ?? 'jpg').toLowerCase();
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}.$ext';

        final url = await CloudinaryService.uploadFile(
          imageBytes,
          uniqueName,
          folder: 'report-photos',
        );

        if (url != null) {
          photoUrl = url;
        } else {
          print('Cloudinary upload returned null — report saved without photo');
        }
      } catch (e) {
        print('Image upload failed: $e — report saved without photo');
      }
    }

    final finalReport = FacilityReport(
      id: docRef.id,
      teacherId: report.teacherId,
      teacherName: report.teacherName,
      category: report.category,
      description: report.description,
      photoUrl: photoUrl,
      status: 'Submitted',
      priority: report.priority,
      managementNotes: '',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await docRef.set(finalReport.toMap());

    // Notify all admins/principals
    await _notifyAdmins(
      reportId: docRef.id,
      teacherName: report.teacherName,
      category: report.category,
    );

    return docRef.id;
  }

  // ── Update report status + notify teacher ────────────────
  Future<void> updateReport({
    required String reportId,
    required String status,
    required String managementNotes,
    required String priority,
    required String teacherId,
    required String category,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'status': status,
      'managementNotes': managementNotes,
      'priority': priority,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    });

    await _notifyTeacher(
      teacherId: teacherId,
      reportId: reportId,
      status: status,
      category: category,
      notes: managementNotes,
    );
  }

  // ── Notify all admin/principal users ──────────────────────
  Future<void> _notifyAdmins({
    required String reportId,
    required String teacherName,
    required String category,
  }) async {
    try {
      final admins = await _db
          .collection('teachers')
          .where('role', whereIn: [
            'principal',
            'admin',
            'Principal',
            'Admin',
          ])
          .get();

      final batch = _db.batch();
      for (final admin in admins.docs) {
        final notifRef = _db.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': admin.id,
          'title': 'New Incident Report',
          'message':
              '$teacherName submitted a new $category. Tap to review.',
          'type': 'admin',
          'isRead': false,
          'reportId': reportId,
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Admin notification failed: $e');
    }
  }

  // ── Notify teacher when principal updates status ──────────
  Future<void> _notifyTeacher({
    required String teacherId,
    required String reportId,
    required String status,
    required String category,
    required String notes,
  }) async {
    try {
      final statusLabel = status == 'Under Review'
          ? 'is now under review'
          : status == 'Action Taken'
              ? 'has action taken'
              : status == 'Resolved'
                  ? 'has been resolved'
                  : 'has been updated';

      await _db.collection('notifications').add({
        'userId': teacherId,
        'title': 'Report Status Updated',
        'message':
            'Your $category $statusLabel.${notes.isNotEmpty ? ' Note: $notes' : ''}',
        'type': 'change_approved',
        'isRead': false,
        'reportId': reportId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Teacher notification failed: $e');
    }
  }
}