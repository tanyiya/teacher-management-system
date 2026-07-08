import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/duty_task_assignment.dart';

class DutyTaskAssignmentService {
  final _col = FirebaseFirestore.instance.collection('duty_task_assignments');

  // Live stream of all task assignments
  Stream<List<DutyTaskAssignment>> getTaskAssignments() {
    return _col.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyTaskAssignment.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Live stream of tasks under a duty assignment
  Stream<List<DutyTaskAssignment>> getTasksByAssignment(String dutyAssignmentId,) {
    return _col
        .where( 'dutyAssignmentId', isEqualTo: dutyAssignmentId,)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutyTaskAssignment.fromMap(doc.id, doc.data(),);
          }).toList();
        });
  }

  // Live stream of tasks assigned to a teacher
  Stream<List<DutyTaskAssignment>> getTasksByTeacher(String teacherId,) {
    return _col
        .where('teacherIds', arrayContains: teacherId,)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutyTaskAssignment.fromMap(doc.id, doc.data(),);
          }).toList();
        });
  }

  // Get task assignment by ID
  Future<DutyTaskAssignment?> getTaskAssignmentById(String id,) async {
    final doc = await _col.doc(id).get();

    if (!doc.exists) return null;

    return DutyTaskAssignment.fromMap( doc.id, doc.data()!,);
  }

  // Add task assignment
  Future<String> addTaskAssignment(
    DutyTaskAssignment assignment,
  ) async {
    final doc = await _col.add( assignment.toMap(),);

    return doc.id;
  }

  // Update task assignment
  Future<void> updateTaskAssignment(DutyTaskAssignment assignment,) async {
    await _col.doc(assignment.id).update(assignment.toMap(),);
  }

  // Mark task as completed
  Future<void> completeTask({
    required String id,
    required String teacherId,
    String? photoUrl,
  }) async {
    await _col.doc(id).update({
      'isCompleted': true,
      'completedAt': Timestamp.now(),
      'completedByTeacherId': teacherId,
      'photoUrl': photoUrl,
    });
  }

  // Mark task as incomplete
  Future<void> reopenTask(String id) async {
    await _col.doc(id).update({
      'isCompleted': false,
      'completedAt': null,
      'completedByTeacherId': null,
      'photoUrl': null,
    });
  }

  // Delete task assignment
  Future<void> deleteTaskAssignment(String id) async {
    await _col.doc(id).delete();
  }

  // Delete all tasks under a duty assignment
  Future<void> deleteTasksByAssignment(
    String dutyAssignmentId,
  ) async {
    final snapshot = await _col
        .where(
          'dutyAssignmentId',
          isEqualTo: dutyAssignmentId,
        )
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}