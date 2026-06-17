import 'package:cloud_firestore/cloud_firestore.dart';

enum DutyViewMode { calendar, list }

enum DutyGroupingMode { location, teacher }

enum DutyUserRole { teacher, principal }

enum DutySwapStatus { none, pending, approved, rejected }

enum DutyRecurrence { once, daily, weekly, monthly }

typedef DutyAssignment = Duty;

class DutyLocation {
  final String id;
  final String name;
  final String description;

  const DutyLocation({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory DutyLocation.fromMap(String id, Map<String, dynamic> data) {
    return DutyLocation(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description};
  }
}

class DutyTask {
  final String id;
  final String name;
  final bool isCompleted;
  final String? photoUrl;
  final DateTime? completedAt;
  final String? timeStart;
  final String? timeEnd;
  final String? teacherId;
  final String? teacherName;
  final String? locationId;
  final String? locationName;

  const DutyTask({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.photoUrl,
    this.completedAt,
    this.timeStart,
    this.timeEnd,
    this.teacherId,
    this.teacherName,
    this.locationId,
    this.locationName,
  });

  factory DutyTask.fromMap(Map<String, dynamic> data) {
    return DutyTask(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      isCompleted: data['isCompleted'] == true || data['completed'] == true,
      photoUrl: data['photoUrl']?.toString(),
      completedAt: _dateFromAny(data['completedAt'] ?? data['timestamp']),
      teacherId: data['teacherId']?.toString() ?? data['teacher']?.toString(),
      teacherName: data['teacherName']?.toString(),
      locationId:
          data['locationId']?.toString() ?? data['location']?.toString(),
      locationName: data['locationName']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'photoUrl': photoUrl,
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'locationId': locationId,
      'locationName': locationName,
    };
  }

  DutyTask copyWith({
    String? name,
    bool? isCompleted,
    String? photoUrl,
    DateTime? completedAt,
    String? teacherId,
    String? teacherName,
    String? locationId,
    String? locationName,
  }) {
    return DutyTask(
      id: id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      photoUrl: photoUrl ?? this.photoUrl,
      completedAt: completedAt ?? this.completedAt,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
    );
  }
}

class Duty {
  final String id;
  final String title;
  final DateTime date;
  final String timeStart;
  final String timeEnd;
  final bool isAllDay;
  final List<DutyLocation> locations;
  final Map<String, List<String>> teacherAssignments;
  final Map<String, String> teacherNames;
  final List<DutyTask> tasks;
  final String? thumbnailUrl;
  final DutySwapStatus swapStatus;
  final String status;
  final String type;
  final int minTeachersPerVenue;
  final DutyRecurrence recurrence;

  const Duty({
    required this.id,
    required this.title,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    this.isAllDay = false,
    this.locations = const [],
    this.teacherAssignments = const {},
    this.teacherNames = const {},
    this.tasks = const [],
    this.thumbnailUrl,
    this.swapStatus = DutySwapStatus.none,
    this.status = 'todo',
    this.type = 'Cleaning Duty',
    this.minTeachersPerVenue = 1,
    this.recurrence = DutyRecurrence.once,
  });

  bool get isCompleted =>
      tasks.isNotEmpty && tasks.every((task) => task.isCompleted);

  List<String> get teacherIds {
    return teacherAssignments.values.expand((ids) => ids).toSet().toList();
  }

  String teacherLabelForLocation(String locationId) {
    final ids = teacherAssignments[locationId] ?? const <String>[];
    if (ids.isEmpty) return 'Unassigned';
    return ids.map((id) => teacherNames[id] ?? id).join(', ');
  }

  factory Duty.fromMap(String id, Map<String, dynamic> data) {
    final rawLocations = data['locations'];
    final locations = rawLocations is List
        ? rawLocations.map((entry) {
            if (entry is Map<String, dynamic>) {
              return DutyLocation.fromMap(
                  entry['id']?.toString() ?? entry['name']?.toString() ?? '',
                  entry);
            }
            return DutyLocation(id: entry.toString(), name: entry.toString());
          }).toList()
        : <DutyLocation>[];

    final assignments = <String, List<String>>{};
    final rawAssignments =
        data['teacherAssignments'] ?? data['assignedTeachers'];
    if (rawAssignments is Map) {
      rawAssignments.forEach((key, value) {
        assignments[key.toString()] = value is List
            ? value.map((e) => e.toString()).toList()
            : <String>[];
      });
    }

    return Duty(
      id: id,
      title: data['title']?.toString() ??
          data['taskName']?.toString() ??
          'Untitled duty',
      date: _dateFromAny(data['date']) ?? DateTime.now(),
      timeStart: data['timeStart']?.toString() ?? '07:00',
      timeEnd: data['timeEnd']?.toString() ?? '08:00',
      isAllDay: data['isAllDay'] == true,
      locations: locations,
      teacherAssignments: assignments,
      teacherNames: (data['teacherNames'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString())) ??
          {},
      tasks: (data['tasks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DutyTask.fromMap)
          .toList(),
      thumbnailUrl: data['thumbnailUrl']?.toString(),
      swapStatus: _swapStatusFromString(data['swapStatus']?.toString()),
      status: data['status']?.toString() ?? 'todo',
      type: data['type']?.toString() ?? 'Cleaning Duty',
      minTeachersPerVenue:
          int.tryParse(data['minTeachersPerVenue']?.toString() ?? '') ?? 1,
      recurrence: _recurrenceFromString(data['recurrence']?.toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'dateKey': dateKey(date),
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'isAllDay': isAllDay,
      'locations': locations
          .map((location) => {'id': location.id, ...location.toMap()})
          .toList(),
      'teacherAssignments': teacherAssignments,
      'teacherNames': teacherNames,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'swapStatus': swapStatus.name,
      'status': isCompleted ? 'completed' : status,
      'type': type,
      'minTeachersPerVenue': minTeachersPerVenue,
      'recurrence': recurrence.name,
    };
  }

  Duty copyWith({
    String? title,
    DateTime? date,
    String? timeStart,
    String? timeEnd,
    bool? isAllDay,
    List<DutyLocation>? locations,
    Map<String, List<String>>? teacherAssignments,
    Map<String, String>? teacherNames,
    List<DutyTask>? tasks,
    String? thumbnailUrl,
    DutySwapStatus? swapStatus,
    String? status,
    String? type,
    int? minTeachersPerVenue,
    DutyRecurrence? recurrence,
  }) {
    return Duty(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      isAllDay: isAllDay ?? this.isAllDay,
      locations: locations ?? this.locations,
      teacherAssignments: teacherAssignments ?? this.teacherAssignments,
      teacherNames: teacherNames ?? this.teacherNames,
      tasks: tasks ?? this.tasks,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      swapStatus: swapStatus ?? this.swapStatus,
      status: status ?? this.status,
      type: type ?? this.type,
      minTeachersPerVenue: minTeachersPerVenue ?? this.minTeachersPerVenue,
      recurrence: recurrence ?? this.recurrence,
    );
  }
}

class DutySwap {
  final String id;
  final String dutyId;
  final String fromTeacherId;
  final String toTeacherId;
  final String requestedBy;
  final DutySwapStatus status;
  final DateTime createdAt;

  const DutySwap({
    required this.id,
    required this.dutyId,
    required this.fromTeacherId,
    required this.toTeacherId,
    required this.requestedBy,
    this.status = DutySwapStatus.pending,
    required this.createdAt,
  });

  factory DutySwap.fromMap(String id, Map<String, dynamic> data) {
    return DutySwap(
      id: id,
      dutyId:
          data['dutyId']?.toString() ?? data['assignmentId']?.toString() ?? '',
      fromTeacherId: data['fromTeacherId']?.toString() ?? '',
      toTeacherId: data['toTeacherId']?.toString() ?? '',
      requestedBy: data['requestedBy']?.toString() ?? 'teacher',
      status: _swapStatusFromString(data['status']?.toString()),
      createdAt: _dateFromAny(data['createdAt'] ?? data['timestamp']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyId': dutyId,
      'fromTeacherId': fromTeacherId,
      'toTeacherId': toTeacherId,
      'requestedBy': requestedBy,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class DutyTemplate {
  final String id;
  final String name;
  final String frequency;
  final List<String> checklist;

  const DutyTemplate({
    required this.id,
    required this.name,
    required this.frequency,
    this.checklist = const [],
  });
}

DateTime? _dateFromAny(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DutySwapStatus _swapStatusFromString(String? value) {
  return DutySwapStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => DutySwapStatus.none,
  );
}

DutyRecurrence _recurrenceFromString(String? value) {
  return DutyRecurrence.values.firstWhere(
    (recurrence) => recurrence.name == value,
    orElse: () => DutyRecurrence.once,
  );
}

String dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
