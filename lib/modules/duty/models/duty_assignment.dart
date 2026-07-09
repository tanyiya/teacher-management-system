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

  /// Snapshot of the parent Duty's time window at the moment this
  /// assignment was generated. Kept here (rather than looked up from
  /// `Duty` on every read) so an assignment's schedule position stays
  /// stable even if the duty definition's time is edited later, and so
  /// screens don't need a `Duty` lookup just to render/position a block.
  final String timeStart;
  final String timeEnd;

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
    required this.timeStart,
    required this.timeEnd,
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
      timeStart: data['timeStart']?.toString() ?? '00:00',
      timeEnd: data['timeEnd']?.toString() ?? '00:00',
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
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'locationIds': locationIds,
      'locationNameSnapshots': locationNameSnapshots,
      'teacherIds': teacherIds,
      'teacherNameSnapshots': teacherNameSnapshots,
      'status': status.name,
    };
  }

  DutyAssignment copyWith({
    String? timeStart,
    String? timeEnd,
    List<String>? teacherIds,
    List<String>? teacherNameSnapshots,
    DutyAssignmentStatus? status,
  }) {
    return DutyAssignment(
      id: id,
      dutyId: dutyId,
      dutyNameSnapshot: dutyNameSnapshot,
      date: date,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      locationIds: locationIds,
      locationNameSnapshots: locationNameSnapshots,
      teacherIds: teacherIds ?? this.teacherIds,
      teacherNameSnapshots: teacherNameSnapshots ?? this.teacherNameSnapshots,
      status: status ?? this.status,
    );
  }
}