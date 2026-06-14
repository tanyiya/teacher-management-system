import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modules/teachers/models/teacher.dart';
import '../../modules/duty/models/duty.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedDatabase() async {
    try {
      // Seed Teachers if empty
      final teachersSnap = await _db.collection('teachers').limit(1).get();
      if (teachersSnap.docs.isEmpty) {
        await _seedTeachers();
      }

      // Seed Locations if empty
      final locationsSnap = await _db.collection('duty_locations').limit(1).get();
      if (locationsSnap.docs.isEmpty) {
        await _seedLocations();
      }

      // Seed Tasks if empty
      final tasksSnap = await _db.collection('duty_tasks').limit(1).get();
      if (tasksSnap.docs.isEmpty) {
        await _seedTasks();
      }
      
      print("Database Seeding Completed Successfully.");
    } catch (e) {
      print("Error seeding database: \$e");
    }
  }

  static Future<void> _seedTeachers() async {
    final batch = _db.batch();
    
    final teachers = [
      TeacherRecord(
        id: 't_sarah', username: 'sarah.j', email: 'sarah.j@school.edu', fullName: 'Sarah Jenkins',
        role: 'teacher', icNumber: '890101-10-1234', gender: 'Female', dob: '1989-01-01',
        address: '123 Edu Lane', phoneNumber: '012-3456789', maritalStatus: 'Single',
        emergencyContactName: 'John Jenkins', emergencyContactNumber: '012-9876543',
        currentScore: 85, yearlyKpi: 90, status: 'active', documents: {}
      ),
      TeacherRecord(
        id: 'p_admin', username: 'principal', email: 'admin@school.edu', fullName: 'Principal Smith',
        role: 'principal', icNumber: '750101-10-1234', gender: 'Male', dob: '1975-01-01',
        address: '1 Admin Way', phoneNumber: '011-3456789', maritalStatus: 'Married',
        emergencyContactName: 'Mary Smith', emergencyContactNumber: '011-9876543',
        currentScore: 100, yearlyKpi: 100, status: 'active', documents: {}
      ),
    ];

    for (var teacher in teachers) {
      final docRef = _db.collection('teachers').doc(teacher.id);
      batch.set(docRef, teacher.toMap());
    }

    await batch.commit();
  }

  static Future<void> _seedLocations() async {
    final batch = _db.batch();
    final locs = [
      DutyLocation(id: 'loc_hall', name: 'Assembly Hall', description: 'Main gathering hall'),
      DutyLocation(id: 'loc_gate', name: 'Main Gate', description: 'Front entrance'),
    ];

    for (var loc in locs) {
      final docRef = _db.collection('duty_locations').doc(loc.id);
      batch.set(docRef, loc.toMap());
    }
    await batch.commit();
  }

  static Future<void> _seedTasks() async {
    final batch = _db.batch();
    final tasks = [
      DutyTask(
        id: 'task_arrival', name: 'Morning Arrival', timeStart: '07:00', timeEnd: '07:30',
        frequency: 'Daily', locations: ['loc_gate'], minPeople: 2,
        checklistTemplates: ['Greet students', 'Check uniform'],
      ),
    ];

    for (var task in tasks) {
      final docRef = _db.collection('duty_tasks').doc(task.id);
      batch.set(docRef, task.toMap());
    }
    await batch.commit();
  }
}
