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
    this.photoUrl = '',
    this.status = 'Submitted',
    this.priority = 'Low',
    this.managementNotes = '',
    required this.createdAt,
    required this.lastUpdated,
  });

  String get reportedByName => teacherName;

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
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
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

  FacilityReport copyWith({
    String? status,
    String? managementNotes,
    String? priority,
    DateTime? lastUpdated,
  }) {
    return FacilityReport(
      id: id,
      teacherId: teacherId,
      teacherName: teacherName,
      category: category,
      description: description,
      photoUrl: photoUrl,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      managementNotes: managementNotes ?? this.managementNotes,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}