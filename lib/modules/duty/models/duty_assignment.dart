import 'package:cloud_firestore/cloud_firestore.dart';

enum DutyAssignmentStatus {
  assigned,
  inProgress,
  completed,
  cancelled,
}

class DutyAssignment {
  final String id;
  final String dutyId;
  final String dutyNameSnapshot;
  final DateTime date;
  final List<String> locationIds;
  final List<String> locationNameSnapshots;
  final List<String> teacherIds;
  final List<String> teacherNameSnapshots;
  final DutyAssignmentStatus status;

  const DutyAssignment({
    required this.id,
    required this.dutyId,
    required this.dutyNameSnapshot,
    required this.date,
    required this.locationIds,
    required this.locationNameSnapshots,
    required this.teacherIds,
    required this.teacherNameSnapshots,
    this.status = DutyAssignmentStatus.assigned,
  });

  factory DutyAssignment.fromMap(String id, Map<String, dynamic> data) {
    return DutyAssignment(
      id: id,
      dutyId: data['dutyId']?.toString() ?? '',
      dutyNameSnapshot: data['dutyNameSnapshot']?.toString() ?? '',
      date: (data['date'] as Timestamp).toDate(),
      locationIds: List<String>.from(data['locationIds'] ?? []),
      locationNameSnapshots: List<String>.from(data['locationNameSnapshots'] ?? []),
      teacherIds: List<String>.from(data['teacherIds'] ?? []),
      teacherNameSnapshots: List<String>.from(data['teacherNameSnapshots'] ?? []),
      status: DutyAssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DutyAssignmentStatus.assigned,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyId': dutyId,
      'dutyNameSnapshot': dutyNameSnapshot,
      'date': Timestamp.fromDate(date),
      'locationIds': locationIds,
      'locationNameSnapshots': locationNameSnapshots,
      'teacherIds': teacherIds,
      'teacherNameSnapshots': teacherNameSnapshots,
      'status': status.name,
    };
  }

  DutyAssignment copyWith({
    List<String>? teacherIds,
    List<String>? teacherNameSnapshots,
    DutyAssignmentStatus? status,
  }) {
    return DutyAssignment(
      id: id,
      dutyId: dutyId,
      dutyNameSnapshot: dutyNameSnapshot,
      date: date,
      locationIds: locationIds,
      locationNameSnapshots: locationNameSnapshots,
      teacherIds: teacherIds ?? this.teacherIds,
      teacherNameSnapshots: teacherNameSnapshots ?? this.teacherNameSnapshots,
      status: status ?? this.status,
    );
  }
}