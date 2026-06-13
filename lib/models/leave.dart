import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRecord {
  final String id;
  final String teacherId;
  final String teacherName;
  final String startDate;
  final String endDate;
  final double duration;
  final String type;
  final String status;
  final String documentUrl;
  final String documentName;
  final String remarks;
  final String principalNotes;
  final DateTime createdAt;

  LeaveRecord({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.type,
    required this.status,
    required this.documentUrl,
    required this.documentName,
    required this.remarks,
    required this.principalNotes,
    required this.createdAt,
  });

  factory LeaveRecord.fromMap(String id, Map<String, dynamic> data) {
    return LeaveRecord(
      id: id,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      duration: (data['duration'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'annual',
      status: data['status'] ?? 'pending',
      documentUrl: data['documentUrl'] ?? '',
      documentName: data['documentName'] ?? '',
      remarks: data['remarks'] ?? '',
      principalNotes: data['principalNotes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'startDate': startDate,
      'endDate': endDate,
      'duration': duration,
      'type': type,
      'status': status,
      'documentUrl': documentUrl,
      'documentName': documentName,
      'remarks': remarks,
      'principalNotes': principalNotes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
