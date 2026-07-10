import 'package:cloud_firestore/cloud_firestore.dart';

enum DutyAssignmentStatus {
  assigned,
  inProgress,
  completed,
  cancelled,
}

/// Represents ONE venue's worth of a duty on a given date.
///
/// A duty with multiple venues (e.g. Arrival Duty at Main Door, Stairs,
/// Hall 1st Floor, Hall 2nd Floor) generates one `DutyAssignment` per venue,
/// each with its own dedicated `teacherIds`. This is a deliberate change
/// from an earlier version that stored `locationIds`/`teacherIds` as two
/// unpaired parallel lists on a single doc -- that made it impossible to
/// tell which teacher was actually in charge of which venue. One doc per
/// venue keeps that mapping explicit and lets the UI render one card per
/// venue for free.
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

  final String locationId;
  final String locationNameSnapshot;

  /// Teacher(s) in charge of this specific venue for this duty. Plural
  /// because a venue can require more than one teacher (e.g. Cleaning Duty
  /// - Dining Area needs 2), but always scoped to just this one venue.
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
    required this.locationId,
    required this.locationNameSnapshot,
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
      locationId: data['locationId']?.toString() ?? '',
      locationNameSnapshot: data['locationNameSnapshot']?.toString() ?? '',
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
      'locationId': locationId,
      'locationNameSnapshot': locationNameSnapshot,
      'teacherIds': teacherIds,
      'teacherNameSnapshots': teacherNameSnapshots,
      'status': status.name,
    };
  }

  DutyAssignment copyWith({
    String? dutyNameSnapshot,
    String? timeStart,
    String? timeEnd,
    String? locationNameSnapshot,
    List<String>? teacherIds,
    List<String>? teacherNameSnapshots,
    DutyAssignmentStatus? status,
  }) {
    return DutyAssignment(
      id: id,
      dutyId: dutyId,
      dutyNameSnapshot: dutyNameSnapshot ?? this.dutyNameSnapshot,
      date: date,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      locationId: locationId,
      locationNameSnapshot: locationNameSnapshot ?? this.locationNameSnapshot,
      teacherIds: teacherIds ?? this.teacherIds,
      teacherNameSnapshots: teacherNameSnapshots ?? this.teacherNameSnapshots,
      status: status ?? this.status,
    );
  }
}