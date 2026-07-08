import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/duty_assignment.dart';

class DutyAssignmentService {
  final _col = FirebaseFirestore.instance.collection('duty_assignments');

  // Live stream of all assignments
  Stream<List<DutyAssignment>> getAssignments() {
    return _col.orderBy('date').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyAssignment.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Live stream of assignments for a specific duty
  Stream<List<DutyAssignment>> getAssignmentsByDuty(String dutyId) {
    return _col
        .where('dutyId', isEqualTo: dutyId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyAssignment.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Live stream of assignments for a specific teacher
  Stream<List<DutyAssignment>> getAssignmentsByTeacher(String teacherId) {
    return _col
        .where('teacherIds', arrayContains: teacherId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyAssignment.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Live stream of assignments by date
  Stream<List<DutyAssignment>> getAssignmentsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _col
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutyAssignment.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Live stream of assignments by location
  Stream<List<DutyAssignment>> getAssignmentsByLocation(String locationId) {
    return _col
        .where('locationIds', arrayContains: locationId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutyAssignment.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Get assignment by ID
  Future<DutyAssignment?> getAssignmentById(String id) async {
    final doc = await _col.doc(id).get();

    if (!doc.exists) return null;

    return DutyAssignment.fromMap(doc.id, doc.data()!);
  }

  // Add assignment
  Future<String> addAssignment(DutyAssignment assignment) async {
    final doc = await _col.add(assignment.toMap());
    return doc.id;
  }

  // Update assignment
  Future<void> updateAssignment(DutyAssignment assignment) async {
    await _col.doc(assignment.id).update(assignment.toMap());
  }

  // Update only status
  Future<void> updateStatus(
    String id,
    DutyAssignmentStatus status,
  ) async {
    await _col.doc(id).update({
      'status': status.name,
    });
  }

  // Delete assignment
  Future<void> deleteAssignment(String id) async {
    await _col.doc(id).delete();
  }
}