import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/performance.dart';

class PerformanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PerformanceLog>> getPerformanceLogsForTeacher(String teacherId) {
    return _db
        .collection('performance_logs')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PerformanceLog.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<WarningRecord>> getWarningsForTeacher(String teacherId) {
    return _db
        .collection('teacher_warnings')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WarningRecord.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addPerformanceLog(PerformanceLog log) async {
    await _db.collection('performance_logs').doc(log.id).set(log.toMap());
  }

  Future<void> addWarningRecord(WarningRecord warning) async {
    await _db.collection('teacher_warnings').doc(warning.id).set(warning.toMap());
  }
}
