import '../models/duty.dart';
import '../models/duty_task.dart';
import '../models/duty_location.dart';
import '../models/duty_assignment.dart';
import '../models/duty_task_assignment.dart';
import '../services/duty_service.dart';
import '../services/duty_task_service.dart';
import '../services/duty_location_service.dart';
import '../services/duty_assignment_service.dart';
import '../services/duty_task_assignment_service.dart';

/// Debug-only Firestore seeder for UI testing.
///
/// Populates `duty_locations`, `duties`, `duty_tasks`, `duty_assignments`
/// and `duty_task_assignments` from a fixed set of sample data. Deliberately
/// skips `duty_swaps` (not needed to exercise the screens).
///
/// Teacher assignment is a simple round-robin rotation across the seeded
/// teacher roster -- it is NOT the real fairness / no-overlap auto-scheduler
/// (that hasn't been built yet), it's just enough variety to look right in
/// the UI. Some seeded duties will legitimately overlap for a given teacher
/// on a given day; don't read anything into that.
///
/// Safe to call repeatedly: it clears previously-seeded duty data first.
class DutySeeder {
  DutySeeder._();

  static final _locationService = DutyLocationService();
  static final _dutyService = DutyService();
  static final _taskService = DutyTaskService();
  static final _assignmentService = DutyAssignmentService();
  static final _taskAssignmentService = DutyTaskAssignmentService();

  static int _rotation = 0;

  static Future<void> seedFirestore() async {
    _rotation = 0;

    await _clearExisting();

    final locationIds = await _seedLocations();
    final duties = await _seedDuties(locationIds);
    final dates = _weekdaysInRange(DateTime(2026, 7, 9), DateTime(2026, 7, 14));

    await _seedAssignments(duties, dates);
  }

  // ── Cleanup ────────────────────────────────────────────────────────────

  static Future<void> _clearExisting() async {
    // Order matters: assignments/task-assignments reference duties and
    // locations, so they go first. `deleteDuty` already cascades its own
    // `duty_tasks`.
    final taskAssignments = await _taskAssignmentService.getTaskAssignments().first;
    for (final t in taskAssignments) {
      await _taskAssignmentService.deleteTaskAssignment(t.id);
    }

    final assignments = await _assignmentService.getAssignments().first;
    for (final a in assignments) {
      await _assignmentService.deleteAssignment(a.id);
    }

    final duties = await _dutyService.getDuties().first;
    for (final d in duties) {
      await _dutyService.deleteDuty(d.id);
    }

    final locations = await _locationService.getLocations().first;
    for (final l in locations) {
      await _locationService.deleteLocation(l.id);
    }
  }

  // ── Locations ──────────────────────────────────────────────────────────

  static const List<String> _locationNames = [
    'Dining Area',
    'Nap Room & Stairs',
    'Toilet',
    'Main Door',
    'Stairs',
    'Hall 1st Floor',
    'Hall 2nd Floor',
    'Shoes Rack',
    'Full Day (Boy)',
    'Full Day (Girl)',
    'Full Day (6yo)',
    'Hall',
    'Assembly Hall',
  ];

  static Future<Map<String, String>> _seedLocations() async {
    final ids = <String, String>{};
    for (final name in _locationNames) {
      final id = await _locationService.addLocation(
        DutyLocation(id: '', name: name, description: '', isActive: true),
      );
      ids[name] = id;
    }
    return ids;
  }

  // ── Duty definitions ──────────────────────────────────────────────────

  static final List<_DutySeedDef> _dutySeedDefs = [
    _DutySeedDef(
      title: 'Cleaning Duty - Dining Area',
      timeStart: '16:30',
      timeEnd: '17:00',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 2,
      locationNames: ['Dining Area'],
      taskTitles: [
        'Sweep the dining area floor',
        'Mop the dining area floor',
        'Wipe and sanitize dining tables',
        "Wipe student's mirror",
        'Wash and dry the cleaning cloths',
      ],
    ),
    _DutySeedDef(
      title: 'Cleaning Duty - Nap Room & Stairs',
      timeStart: '16:30',
      timeEnd: '17:00',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 1,
      locationNames: ['Nap Room & Stairs'],
      taskTitles: [
        "Fold student's blanket neatly",
        "Place the student's blanket and pillow into their bags",
        'Sweep the stairs area',
        'Mop the stairs carefully',
        'Wipe stair handrails clean',
        'Arrange shoes neatly if any',
      ],
    ),
    _DutySeedDef(
      title: 'Cleaning Duty - Toilet',
      timeStart: '16:30',
      timeEnd: '17:00',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 1,
      locationNames: ['Toilet'],
      taskTitles: [
        'Flush all toilets properly',
        'Clean toilet bowls thoroughly',
        'Scrub and disinfect the toilet floor',
        'Refill hand soap',
        'Clean toilet doors',
        'Ensure buckets and cleaning tools are arranged neatly',
      ],
    ),
    _DutySeedDef(
      title: 'Arrival Duty',
      timeStart: '07:30',
      timeEnd: '08:00',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 1,
      locationNames: ['Main Door', 'Stairs', 'Hall 1st Floor', 'Hall 2nd Floor'],
      taskTitles: ['Supervise students during arrival'],
    ),
    _DutySeedDef(
      title: 'Dismissal Duty - Midday',
      timeStart: '12:00',
      timeEnd: '12:30',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 1,
      locationNames: ['Main Door', 'Stairs', 'Shoes Rack'],
      taskTitles: ['Supervise students during dismissal'],
    ),
    _DutySeedDef(
      title: 'Dismissal Duty - Afternoon',
      timeStart: '17:00',
      timeEnd: '17:15',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 1,
      locationNames: ['Main Door', 'Stairs', 'Shoes Rack'],
      taskTitles: ['Supervise students during dismissal'],
    ),
    _DutySeedDef(
      title: 'Half-Full Day Transition Duty',
      timeStart: '12:00',
      timeEnd: '14:30',
      recurrence: DutyRecurrence.daily,
      minTeachersPerVenue: 1,
      locationNames: ['Full Day (Boy)', 'Full Day (Girl)', 'Full Day (6yo)', 'Hall'],
      taskTitles: ['Assist students transitioning between sessions'],
    ),
    _DutySeedDef(
      title: 'Assembly Duty',
      timeStart: '08:00',
      timeEnd: '09:00',
      recurrence: DutyRecurrence.weekly,
      minTeachersPerVenue: 4,
      locationNames: ['Assembly Hall'],
      taskTitles: [
        'Introduction',
        'Song',
        'Islamic Content',
        'Words of the Week',
        'Sight Words',
      ],
    ),
  ];

  static Future<List<_SeededDuty>> _seedDuties(
    Map<String, String> locationIds,
  ) async {
    final results = <_SeededDuty>[];

    for (final seed in _dutySeedDefs) {
      final locations = seed.locationNames
          .map((name) => DutyLocation(
                id: locationIds[name]!,
                name: name,
                description: '',
                isActive: true,
              ))
          .toList();

      final duty = Duty(
        id: '',
        title: seed.title,
        timeStart: seed.timeStart,
        timeEnd: seed.timeEnd,
        isAllDay: false,
        recurrence: seed.recurrence,
        locations: locations,
        minTeachersPerVenue: seed.minTeachersPerVenue,
      );
      final dutyId = await _dutyService.addDuty(duty);

      final tasks = <_SeededTask>[];
      var sequence = 0;
      for (final taskTitle in seed.taskTitles) {
        final task = DutyTask(
          id: '',
          dutyId: dutyId,
          dutyNameSnapshot: seed.title,
          title: taskTitle,
          sequence: sequence++,
        );
        final taskId = await _taskService.addDutyTask(task);
        tasks.add(_SeededTask(id: taskId, title: taskTitle));
      }

      results.add(_SeededDuty(
        id: dutyId,
        title: seed.title,
        timeStart: seed.timeStart,
        timeEnd: seed.timeEnd,
        recurrence: seed.recurrence,
        minTeachersPerVenue: seed.minTeachersPerVenue,
        locationIds: seed.locationNames.map((n) => locationIds[n]!).toList(),
        locationNames: seed.locationNames,
        tasks: tasks,
      ));
    }

    return results;
  }

  // ── Assignments ────────────────────────────────────────────────────────

  static List<DateTime> _weekdaysInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (d.weekday <= DateTime.friday) dates.add(d);
    }
    return dates;
  }

  static Future<void> _seedAssignments(
    List<_SeededDuty> duties,
    List<DateTime> dates,
  ) async {
    for (final date in dates) {
      for (final duty in duties) {
        if (duty.recurrence == DutyRecurrence.weekly &&
            date.weekday != DateTime.monday) {
          continue;
        }

        // One assignment doc per venue, each with its own dedicated
        // teacher(s) -- this is what makes "who's in charge of which
        // venue" explicit instead of two unpaired parallel lists.
        for (var i = 0; i < duty.locationIds.length; i++) {
          final locationId = duty.locationIds[i];
          final locationName = duty.locationNames[i];

          final teachers = _pickTeachers(duty.minTeachersPerVenue);

          final assignment = DutyAssignment(
            id: '',
            dutyId: duty.id,
            dutyNameSnapshot: duty.title,
            date: date,
            timeStart: duty.timeStart,
            timeEnd: duty.timeEnd,
            locationId: locationId,
            locationNameSnapshot: locationName,
            teacherIds: teachers.map((t) => t.id).toList(),
            teacherNameSnapshots: teachers.map((t) => t.name).toList(),
            status: DutyAssignmentStatus.assigned,
          );
          final assignmentId = await _assignmentService.addAssignment(assignment);

          for (final task in duty.tasks) {
            final taskAssignment = DutyTaskAssignment(
              id: '',
              dutyAssignmentId: assignmentId,
              dutyTaskId: task.id,
              taskNameSnapshot: task.title,
              teacherIds: teachers.map((t) => t.id).toList(),
              teacherNameSnapshots: teachers.map((t) => t.name).toList(),
              isCompleted: false,
              photoUrl: null,
              completedAt: null,
              completedByTeacherId: null,
            );
            await _taskAssignmentService.addTaskAssignment(taskAssignment);
          }
        }
      }
    }
  }

  // ── Teacher roster ────────────────────────────────────────────────────

  static const List<_TeacherSeed> _teachers = [
    _TeacherSeed('275HG935IIePA3sFoLardZ9cJqN2', 'Goe Jie Ying'),
    _TeacherSeed('69ZCBtDKKyc80KipkVmUFHLDHXh2', 'Tan Yi Ya'),
    _TeacherSeed('91deZJIMiVY4oLofOq2FdRRk4QF3', 'Firzana'),
    _TeacherSeed('AYMGmtgipdZFlIvmWvDCE6b5fyL2', 'Zarina binti Abdullah'),
    _TeacherSeed('Ell7vsrBnPYxsNeaWrsoucqS8Of2', 'Nurul Ain binti Hassan'),
    _TeacherSeed('Oq2YxhvhIIYqkn6hEnMgKNGPuF72', 'Sarah Jenkins'),
    _TeacherSeed('T3C7LL0ifYdtxnN5kjPSH1WcuFm2', 'Priya Devi a/p Subramaniam'),
    _TeacherSeed('b3GvlzgjW6ON9AGG0WG2PccPuVc2', 'teh2'),
    _TeacherSeed('erYcPvTM8ZatWoVZeA1IlMZeLVs2', 'Muhammad Hafiz bin Kamal'),
    _TeacherSeed('wwFCPhg6j6afpO8gbANfFu8b3W12', 'Ahmad Ali bin Razak'),
    _TeacherSeed('y9rEzRlEHEXKu929S8AmEm2ZyLG3', 'Siti Norbaya binti Zakaria'),
    _TeacherSeed('yl4YNHh3FFM4BxeVTkuvfhG4bt62', 'Rajendran a/l Pillai'),
  ];

  static List<_TeacherSeed> _pickTeachers(int count) {
    final picked = <_TeacherSeed>[];
    for (var i = 0; i < count; i++) {
      picked.add(_teachers[_rotation % _teachers.length]);
      _rotation++;
    }
    return picked;
  }
}

// ── Internal seed data holders ────────────────────────────────────────────

class _DutySeedDef {
  final String title;
  final String timeStart;
  final String timeEnd;
  final DutyRecurrence recurrence;
  final int minTeachersPerVenue;
  final List<String> locationNames;
  final List<String> taskTitles;

  const _DutySeedDef({
    required this.title,
    required this.timeStart,
    required this.timeEnd,
    required this.recurrence,
    required this.minTeachersPerVenue,
    required this.locationNames,
    required this.taskTitles,
  });
}

class _SeededDuty {
  final String id;
  final String title;
  final String timeStart;
  final String timeEnd;
  final DutyRecurrence recurrence;
  final int minTeachersPerVenue;
  final List<String> locationIds;
  final List<String> locationNames;
  final List<_SeededTask> tasks;

  const _SeededDuty({
    required this.id,
    required this.title,
    required this.timeStart,
    required this.timeEnd,
    required this.recurrence,
    required this.minTeachersPerVenue,
    required this.locationIds,
    required this.locationNames,
    required this.tasks,
  });
}

class _SeededTask {
  final String id;
  final String title;
  const _SeededTask({required this.id, required this.title});
}

class _TeacherSeed {
  final String id;
  final String name;
  const _TeacherSeed(this.id, this.name);
}