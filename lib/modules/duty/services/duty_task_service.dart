import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/duty_task.dart';

class DutyTaskService {
  final _col = FirebaseFirestore.instance.collection('duty_tasks');

  // Live stream of all duty tasks
  Stream<List<DutyTask>> getDutyTasks() {
    return _col.orderBy('sequence').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyTask.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Live stream of tasks belonging to a specific duty
  Stream<List<DutyTask>> getTasksByDuty(String dutyId) {
    return _col
        .where('dutyId', isEqualTo: dutyId)
        .orderBy('sequence')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyTask.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get a single task by ID
  Future<DutyTask?> getDutyTaskById(String id) async {
    final doc = await _col.doc(id).get();

    if (!doc.exists) return null;

    return DutyTask.fromMap(doc.id, doc.data()!);
  }

  // Add a new duty task
  Future<String> addDutyTask(DutyTask task) async {
    final doc = await _col.add(task.toMap());
    return doc.id;
  }

  // Update an existing duty task
  Future<void> updateDutyTask(DutyTask task) async {
    await _col.doc(task.id).update(task.toMap());
  }

  // Delete a duty task
  Future<void> deleteDutyTask(String id) async {
    await _col.doc(id).delete();
  }

  // Delete all tasks under a duty
  Future<void> deleteTasksByDuty(String dutyId) async {
    final snapshot = await _col.where('dutyId', isEqualTo: dutyId).get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}