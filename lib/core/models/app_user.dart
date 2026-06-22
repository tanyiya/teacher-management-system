import 'package:cloud_firestore/cloud_firestore.dart';

import '../../modules/teachers/models/teacher.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String profileImage;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.profileImage,
    required this.isActive,
    this.createdAt,
    this.lastLogin,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: (data['email'] ?? '').toString().trim().toLowerCase(),
      fullName: (data['fullName'] ?? data['displayName'] ?? '').toString().trim(),
      role: (data['role'] ?? '').toString().trim().toLowerCase(),
      profileImage: (data['profileImage'] ?? data['profileImageUrl'] ?? '').toString().trim(),
      isActive: data['isActive'] == true || (data['status'] ?? 'active') == 'active',
      createdAt: _dateFrom(data['createdAt']),
      lastLogin: _dateFrom(data['lastLogin']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'lastLogin': lastLogin == null ? null : Timestamp.fromDate(lastLogin!),
    };
  }

  TeacherRecord toTeacherRecord() {
    return TeacherRecord(
      id: uid,
      username: email.split('@').first,
      email: email,
      fullName: fullName.isEmpty ? email : fullName,
      role: role,
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
      status: isActive ? 'active' : 'disabled',
      documents: const {},
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
