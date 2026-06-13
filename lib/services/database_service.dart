import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/duty.dart';
import '../models/leave.dart';
import '../models/performance.dart';
import '../models/training.dart';
import '../models/report.dart';
import '../models/notification.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Teachers ---
  Stream<List<TeacherRecord>> getTeachers() {
    return _db.collection('teachers').snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => TeacherRecord.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> updateTeacher(TeacherRecord teacher) async {
    await _db.collection('teachers').doc(teacher.id).set(teacher.toMap());
  }

  // --- Duties ---
  Stream<List<DutyTask>> getDutyTasks() {
    return _db.collection('duty_tasks').snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => DutyTask.fromMap(doc.id, doc.data())).toList()
    );
  }

  Stream<List<DutyAssignment>> getAssignmentsForDate(String date) {
    return _db.collection('duty_assignments').where('date', isEqualTo: date).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => DutyAssignment.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> updateAssignment(DutyAssignment assignment) async {
    await _db.collection('duty_assignments').doc(assignment.id).set(assignment.toMap());
  }

  // --- Training ---
  Stream<List<TrainingPost>> getTrainingPosts() {
    return _db.collection('training_posts').orderBy('createdAt', descending: true).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => TrainingPost.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> applyForTraining(TrainingApplication app) async {
    await _db.collection('training_applications').doc(app.id).set(app.toMap());
  }

  // --- Leaves ---
  Stream<List<LeaveRecord>> getLeavesForTeacher(String teacherId) {
    return _db.collection('leaves').where('teacherId', isEqualTo: teacherId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => LeaveRecord.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> submitLeave(LeaveRecord leave) async {
    await _db.collection('leaves').doc(leave.id).set(leave.toMap());
  }

  // --- Reports ---
  Stream<List<FacilityReport>> getReports() {
    return _db.collection('reports').orderBy('createdAt', descending: true).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => FacilityReport.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> submitReport(FacilityReport report) async {
    await _db.collection('reports').doc(report.id).set(report.toMap());
  }
  
  // --- Notifications ---
  Stream<List<AlertNotification>> getNotifications(String userId) {
    return _db.collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => AlertNotification.fromMap(doc.id, doc.data())).toList()
    );
  }
}
