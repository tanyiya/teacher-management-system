import 'package:cloud_firestore/cloud_firestore.dart';

enum DutySwapStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

enum DutySwapRequesterType {
  teacher,
  admin,
}

class DutySwap {
  final String id;
  final String dutyAssignmentId;
  final String dutyNameSnapshot;

  /// Snapshot of the assignment's own date/time/venue at the moment the
  /// swap was requested, so the request card (and the accept/reject inbox)
  /// can show "when and where" without a separate assignment lookup.
  final DateTime date;
  final String timeStart;
  final String timeEnd;
  final String locationNameSnapshot;

  final String currentTeacherId;
  final String currentTeacherNameSnapshot;

  final String replacementTeacherId;
  final String replacementTeacherNameSnapshot;

  final String requestedById;
  final String requestedByNameSnapshot;
  final DutySwapRequesterType requesterType;

  final DutySwapStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const DutySwap({
    required this.id,
    required this.dutyAssignmentId,
    required this.dutyNameSnapshot,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.locationNameSnapshot,
    required this.currentTeacherId,
    required this.currentTeacherNameSnapshot,
    required this.replacementTeacherId,
    required this.replacementTeacherNameSnapshot,
    required this.requestedById,
    required this.requestedByNameSnapshot,
    required this.requesterType,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory DutySwap.fromMap(String id, Map<String, dynamic> data) {
    return DutySwap(
      id: id,
      dutyAssignmentId: data['dutyAssignmentId']?.toString() ?? '',
      dutyNameSnapshot: data['dutyNameSnapshot']?.toString() ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeStart: data['timeStart']?.toString() ?? '00:00',
      timeEnd: data['timeEnd']?.toString() ?? '00:00',
      locationNameSnapshot: data['locationNameSnapshot']?.toString() ?? '',
      currentTeacherId: data['currentTeacherId']?.toString() ?? '',
      currentTeacherNameSnapshot: data['currentTeacherNameSnapshot']?.toString() ?? '',
      replacementTeacherId: data['replacementTeacherId']?.toString() ?? '',
      replacementTeacherNameSnapshot:
          data['replacementTeacherNameSnapshot']?.toString() ?? '',
      requestedById: data['requestedById']?.toString() ?? '',
      requestedByNameSnapshot: data['requestedByNameSnapshot']?.toString() ?? '',
      requesterType: DutySwapRequesterType.values.firstWhere(
        (e) => e.name == data['requesterType'],
        orElse: () => DutySwapRequesterType.teacher,
      ),
      status: DutySwapStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DutySwapStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyAssignmentId': dutyAssignmentId,
      'dutyNameSnapshot': dutyNameSnapshot,
      'date': Timestamp.fromDate(date),
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'locationNameSnapshot': locationNameSnapshot,
      'currentTeacherId': currentTeacherId,
      'currentTeacherNameSnapshot': currentTeacherNameSnapshot,
      'replacementTeacherId': replacementTeacherId,
      'replacementTeacherNameSnapshot': replacementTeacherNameSnapshot,
      'requestedById': requestedById,
      'requestedByNameSnapshot': requestedByNameSnapshot,
      'requesterType': requesterType.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt == null ? null : Timestamp.fromDate(respondedAt!),
    };
  }

  DutySwap copyWith({
    DutySwapStatus? status,
    DateTime? respondedAt,
  }) {
    return DutySwap(
      id: id,
      dutyAssignmentId: dutyAssignmentId,
      dutyNameSnapshot: dutyNameSnapshot,
      date: date,
      timeStart: timeStart,
      timeEnd: timeEnd,
      locationNameSnapshot: locationNameSnapshot,
      currentTeacherId: currentTeacherId,
      currentTeacherNameSnapshot: currentTeacherNameSnapshot,
      replacementTeacherId: replacementTeacherId,
      replacementTeacherNameSnapshot: replacementTeacherNameSnapshot,
      requestedById: requestedById,
      requestedByNameSnapshot: requestedByNameSnapshot,
      requesterType: requesterType,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}