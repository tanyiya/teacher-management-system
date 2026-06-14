import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/duty.dart';

class DutyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<DutyTask>> getDutyTasks() {
    return _db.collection('duty_tasks').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => DutyTask.fromMap(doc.id, doc.data())).toList()
    );
  }

  Stream<List<DutyAssignment>> getAssignmentsForDate(String date) {
    return _db.collection('duty_assignments')
      .where('date', isEqualTo: date)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => DutyAssignment.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> updateAssignment(DutyAssignment assignment) async {
    await _db.collection('duty_assignments').doc(assignment.id).set(assignment.toMap());
  }
}