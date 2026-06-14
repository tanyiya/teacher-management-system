import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FacilityReport>> getReports() {
    return _db.collection('reports')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => FacilityReport.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> submitReport(FacilityReport report) async {
    await _db.collection('reports').doc(report.id).set(report.toMap());
  }
}