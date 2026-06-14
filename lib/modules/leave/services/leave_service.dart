import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<LeaveRecord>> getLeavesForTeacher(String teacherId) {
    return _db.collection('leaves')
      .where('teacherId', isEqualTo: teacherId)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => LeaveRecord.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> submitLeave(LeaveRecord leave) async {
    await _db.collection('leaves').doc(leave.id).set(leave.toMap());
  }
}