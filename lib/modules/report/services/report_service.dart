import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // All reports — for principal
  Stream<List<FacilityReport>> getReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => FacilityReport.fromMap(d.id, d.data())).toList());
  }

  // Only this teacher's reports
  Stream<List<FacilityReport>> getMyReports(String teacherId) {
    return _db
        .collection('reports')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => FacilityReport.fromMap(d.id, d.data())).toList());
  }

  Future<String> submitReport(FacilityReport report,
      {Uint8List? imageBytes, String? fileName}) async {
    final docRef = _db.collection('reports').doc();
    String photoUrl = '';

    if (imageBytes != null && fileName != null) {
      final ref = _storage.ref('report_photos/${docRef.id}/$fileName');
      await ref.putData(imageBytes);
      photoUrl = await ref.getDownloadURL();
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
    return docRef.id;
  }

  Future<void> updateReport({
    required String reportId,
    required String status,
    required String managementNotes,
    required String priority,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'status': status,
      'managementNotes': managementNotes,
      'priority': priority,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    });
  }
}