import 'package:cloud_firestore/cloud_firestore.dart';

import '../../teachers/models/teacher.dart';

class DutyExternalService {
  final _teacherCol =
      FirebaseFirestore.instance.collection('teachers');

  Stream<List<TeacherRecord>> fetchTeachers() {
    return _teacherCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeacherRecord.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }
}