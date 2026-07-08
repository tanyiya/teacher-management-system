import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/duty.dart';
import 'duty_task_service.dart';

class DutyService {
  final _col = FirebaseFirestore.instance.collection('duties');
  final _taskService = DutyTaskService();

  // Live stream of all duties
  Stream<List<Duty>> getDuties() {
    return _col.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Duty.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get a single duty by ID
  Future<Duty?> getDutyById(String id) async {
    final doc = await _col.doc(id).get();

    if (!doc.exists) return null;

    return Duty.fromMap(doc.id, doc.data()!);
  }

  // Add a new duty
  Future<String> addDuty(Duty duty) async {
    final doc = await _col.add(duty.toMap());
    return doc.id;
  }

  // Update an existing duty
  Future<void> updateDuty(Duty duty) async {
    await _col.doc(duty.id).update(duty.toMap());
  }

  // Delete a duty
  Future<void> deleteDuty(String id) async {
    await _taskService.deleteTasksByDuty(id);
    await _col.doc(id).delete();
  }
}