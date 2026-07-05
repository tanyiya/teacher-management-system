import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<FacilityReport?> getReportById(String id) async {
    final doc = await _db.collection('reports').doc(id).get();
    if (!doc.exists) return null;
    return FacilityReport.fromMap(doc.id, doc.data()!);
  }

  // ── All reports for principal ─────────────────────────────
  Stream<List<FacilityReport>> getReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => FacilityReport.fromMap(d.id, d.data())).toList());
  }

  // ── FIX: removed .orderBy to avoid composite index requirement ──
  // We sort client-side instead so no Firestore index is needed
  Stream<List<FacilityReport>> getMyReports(String teacherId) {
    return _db
        .collection('reports')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => FacilityReport.fromMap(d.id, d.data()))
              .toList();
          // Sort client-side: newest first
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Submit report + optional image + notify admin ─────────
  Future<String> submitReport(
    FacilityReport report, {
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    final docRef = _db.collection('reports').doc();
    String photoUrl = '';

    // Upload image if provided
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final ext = fileName?.split('.').last ?? 'jpg';
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ref =
            _storage.ref('report_photos/${docRef.id}/$uniqueName');
        final uploadTask = await ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/$ext'),
        );
        photoUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        // Log but don't block — report saves without photo
        print('Image upload failed: $e');
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

    // ── Notify all admins/principals ──────────────────────────
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

    // ── Notify teacher ────────────────────────────────────────
    await _notifyTeacher(
      teacherId: teacherId,
      reportId: reportId,
      status: status,
      category: category,
      notes: managementNotes,
    );
  }

  // ── Send notification to all admin/principal users ────────
  Future<void> _notifyAdmins({
    required String reportId,
    required String teacherName,
    required String category,
  }) async {
    try {
      // Get all principal/admin users
      final admins = await _db
          .collection('teachers')
          .where('role', whereIn: ['principal', 'admin', 'Principal', 'Admin'])
          .get();

      final batch = _db.batch();
      for (final admin in admins.docs) {
        final notifRef = _db.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': admin.id,
          'title': 'New Incident Report',
          'message':
              '$teacherName submitted a new $category. Tap to review.',
          'type': 'incident_report',
          'read': false,
          'relatedId': reportId,
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Admin notification failed: $e');
    }
  }

  // ── Send notification to teacher when status updated ──────
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