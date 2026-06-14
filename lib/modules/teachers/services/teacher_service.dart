import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';

class TeacherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TeacherRecord>> getTeachers() {
    return _db.collection('teachers').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => TeacherRecord.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<TeacherRecord?> getTeacherById(String id) async {
    final doc = await _db.collection('teachers').doc(id).get();
    if (doc.exists) {
      return TeacherRecord.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> updateTeacher(TeacherRecord teacher) async {
    await _db.collection('teachers').doc(teacher.id).set(teacher.toMap());
  }
}