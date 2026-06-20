import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../modules/teachers/models/teacher.dart';
import '../../modules/teachers/services/teacher_service.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    TeacherService? teacherService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _teacherService = teacherService ?? TeacherService();

  final FirebaseFirestore _firestore;
  final TeacherService _teacherService;

  /// Ensure a corresponding AppUser exists for the given Firebase user.
  /// If a `users` doc exists it is returned. Otherwise try `teachers`.
  /// If neither exists, create a minimal `teachers` doc and return a generated
  /// `AppUser` instance.
  Future<AppUser?> ensureUserForFirebase(User firebaseUser) async {
    final uid = firebaseUser.uid;
    final existing = await getUser(uid);
    if (existing != null) return existing;

    // If there's a teacher record, map it to AppUser.
    final teacher = await _teacherService.getTeacherById(uid);
    if (teacher != null) {
      return AppUser(
        uid: teacher.id,
        email: teacher.email.trim().toLowerCase(),
        fullName: teacher.fullName.isNotEmpty ? teacher.fullName : teacher.email,
        role: teacher.role.toString().trim().toLowerCase(),
        profileImage: '',
        isActive: teacher.status == 'active',
        createdAt: null,
        lastLogin: null,
      );
    }

    // No user or teacher record exists: create a minimal teacher doc so the
    // app can proceed. Use reasonable defaults from the Firebase user.
    final email = (firebaseUser.email ?? '').trim().toLowerCase();
    final username = email.contains('@') ? email.split('@').first : email;
    final fullName = (firebaseUser.displayName ?? '').trim().isNotEmpty
        ? firebaseUser.displayName!.trim()
        : email;

    final newTeacher = TeacherRecord(
      id: uid,
      username: username,
      email: email,
      fullName: fullName,
      role: 'teacher',
      icNumber: '',
      gender: '',
      dob: '',
      address: '',
      phoneNumber: '',
      maritalStatus: '',
      emergencyContactName: '',
      emergencyContactNumber: '',
      currentScore: 100,
      yearlyKpi: 0,
      status: 'active',
      documents: {},
    );

    await _teacherService.updateTeacher(newTeacher);

    return AppUser(
      uid: uid,
      email: email,
      fullName: fullName,
      role: 'teacher',
      profileImage: '',
      isActive: true,
      createdAt: null,
      lastLogin: null,
    );
  }

  static const Set<String> validRoles = {'teacher', 'admin', 'principal'};

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) return AppUser.fromMap(doc.id, doc.data()!);

    // Fallback: try the teachers collection if users collection is not present.
    final teacher = await _teacherService.getTeacherById(uid);
    if (teacher != null) {
      return AppUser(
        uid: teacher.id,
        email: teacher.email.trim().toLowerCase(),
        fullName: teacher.fullName.isNotEmpty ? teacher.fullName : teacher.email,
        role: teacher.role.toString().trim().toLowerCase(),
        profileImage: '',
        isActive: teacher.status == 'active',
        createdAt: null,
        lastLogin: null,
      );
    }
    return null;
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return AppUser.fromMap(query.docs.first.id, query.docs.first.data());

    // Fallback: search teachers collection for the email
    try {
      final tq = await _firestore
          .collection('teachers')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (tq.docs.isNotEmpty) {
        final doc = tq.docs.first;
        final data = doc.data();
        return AppUser(
          uid: doc.id,
          email: (data['email'] ?? '').toString().trim().toLowerCase(),
          fullName: (data['fullName'] ?? data['displayName'] ?? '').toString().trim(),
          role: (data['role'] ?? 'teacher').toString().trim().toLowerCase(),
          profileImage: (data['profileImage'] ?? data['profileImageUrl'] ?? '').toString().trim(),
          isActive: (data['status'] ?? 'active') == 'active',
          createdAt: null,
          lastLogin: null,
        );
      }
    } catch (_) {}

    return null;
  }

  Future<TeacherRecord> getDashboardUser(AppUser appUser) async {
    final teacher = await _teacherService.getTeacherById(appUser.uid);
    return teacher ?? appUser.toTeacherRecord();
  }

  /// Resolve an email address for a given Firebase UID by checking `users`
  /// and then falling back to the `teachers` collection. Returns `null` if
  /// no email could be found.
  Future<String?> getEmailForUid(String uid) async {
    // Try users doc first
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final email = (data['email'] ?? data['emailAddress'] ?? '').toString().trim();
        if (email.isNotEmpty) return email;
      }
    } catch (_) {}

    // Fallback: teacher record
    try {
      final teacher = await _teacherService.getTeacherById(uid);
      if (teacher != null && teacher.email.trim().isNotEmpty) return teacher.email.trim();
    } catch (_) {}

    return null;
  }

  Future<void> updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String? validateUserForLogin(AppUser? user) {
    if (user == null) return 'User record is missing. Contact an administrator.';
    if (!user.isActive) return 'This account is disabled. Contact an administrator.';
    var roleNormalized = user.role.toString().trim().toLowerCase();
    if (roleNormalized.isEmpty) {
      roleNormalized = 'teacher'; // default to teacher when role missing
    }

    final bool roleOk = validRoles.contains(roleNormalized) ||
        validRoles.any((r) => roleNormalized.contains(r));
    if (!roleOk) {
      try {
        debugPrint('Invalid role for uid=${user.uid}: stored="${user.role}" normalized="$roleNormalized" validRoles=$validRoles');
      } catch (_) {}
      return 'This account has an invalid role. Contact an administrator.';
    }
    return null;
  }
}
