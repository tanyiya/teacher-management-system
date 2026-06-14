import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityReport {
  final String id;
  final String teacherId;
  final String teacherName;
  final String category;
  final String description;
  final String photoUrl;
  final String status;
  final String priority;
  final String managementNotes;
  final DateTime createdAt;
  final DateTime lastUpdated;

  FacilityReport({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.category,
    required this.description,
    required this.photoUrl,
    required this.status,
    required this.priority,
    required this.managementNotes,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory FacilityReport.fromMap(String id, Map<String, dynamic> data) {
    return FacilityReport(
      id: id,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      status: data['status'] ?? 'Submitted',
      priority: data['priority'] ?? 'Low',
      managementNotes: data['managementNotes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'category': category,
      'description': description,
      'photoUrl': photoUrl,
      'status': status,
      'priority': priority,
      'managementNotes': managementNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
