// import 'dart:convert';
// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;

// import '../../teachers/models/teacher.dart';
// import '../models/duty.dart';

// class DutyService {
//   DutyService({FirebaseFirestore? firestore})
//       : _db = firestore ?? FirebaseFirestore.instance;

//   final FirebaseFirestore _db;

//   CollectionReference<Map<String, dynamic>> get _duties =>
//       _db.collection('duties');
//   CollectionReference<Map<String, dynamic>> get _locations =>
//       _db.collection('duty_locations');
//   CollectionReference<Map<String, dynamic>> get _swaps =>
//       _db.collection('duty_swaps');
//   CollectionReference<Map<String, dynamic>> get _notifications =>
//       _db.collection('notifications');
//   CollectionReference<Map<String, dynamic>> get _teachers =>
//       _db.collection('teachers');

//   Stream<List<Duty>> fetchDutiesByDate(DateTime date) {
//     return _duties.where('dateKey', isEqualTo: dateKey(date)).snapshots().map(
//         (snapshot) => snapshot.docs
//             .map((doc) => Duty.fromMap(doc.id, doc.data()))
//             .toList()
//           ..sort((a, b) => a.timeStart.compareTo(b.timeStart)));
//   }

//   Stream<List<Duty>> fetchUpcomingByTeacher(String teacherId, {int days = 30}) {
//     final today = DateTime.now();
//     final start = DateTime(today.year, today.month, today.day);
//     final end = start.add(Duration(days: days));
//     return _duties.snapshots().map((snapshot) {
//       final duties = snapshot.docs
//           .map((doc) => Duty.fromMap(doc.id, doc.data()))
//           .where((duty) {
//         final dutyDate =
//             DateTime(duty.date.year, duty.date.month, duty.date.day);
//         return duty.teacherIds.contains(teacherId) &&
//             !dutyDate.isBefore(start) &&
//             !dutyDate.isAfter(end);
//       }).toList()
//         ..sort((a, b) {
//           final dateCompare = a.date.compareTo(b.date);
//           return dateCompare != 0
//               ? dateCompare
//               : a.timeStart.compareTo(b.timeStart);
//         });
//       return duties;
//     });
//   }

//   Stream<List<Duty>> fetchByTeacher(String teacherId) {
//     return _duties.snapshots().map((snapshot) {
//       final duties = snapshot.docs
//           .map((doc) => Duty.fromMap(doc.id, doc.data()))
//           .where((duty) {
//         return duty.teacherIds.contains(teacherId);
//       }).toList();
//       duties.sort((a, b) => a.date.compareTo(b.date));
//       return duties;
//     });
//   }

//   Stream<List<DutyLocation>> fetchLocations() {
//     return _locations.snapshots().map(
//           (snapshot) => snapshot.docs
//               .map((doc) => DutyLocation.fromMap(doc.id, doc.data()))
//               .toList()
//             ..sort((a, b) => a.name.compareTo(b.name)),
//         );
//   }

//   Stream<List<TeacherRecord>> fetchTeachers() {
//     return _teachers.snapshots().map((snapshot) {
//       final teachers = snapshot.docs
//           .map((doc) => TeacherRecord.fromMap(doc.id, doc.data()))
//           .where((teacher) {
//         final role = teacher.role.toLowerCase();
//         return role != 'principal' && role != 'admin';
//       }).toList();
//       teachers.sort((a, b) => a.fullName.compareTo(b.fullName));
//       return teachers;
//     });
//   }

//   Future<Duty> createDuty(Duty duty) async {
//     final created = await createRecurringDuties(duty);
//     return created.first;
//   }

//   Future<List<Duty>> createRecurringDuties(Duty duty) async {
//     final dates = _recurrenceDates(duty.date, duty.recurrence);
//     final created = <Duty>[];
//     for (final date in dates) {
//       final next = await autoAssignTeachers(duty.copyWith(date: date));
//       final doc = await _duties.add(next.toMap());
//       // ---------- Debug Start ----------
//       print(jsonEncode(next.toMap()));
//       // ---------- Debug End ----------
//       created.add(next._withId(doc.id));
//     }
//     return created;
//   }

//   Future<void> updateDuty(Duty duty) async {
//     final next = await autoAssignTeachers(duty);
//     await _duties.doc(duty.id).set(next.toMap(), SetOptions(merge: true));
//   }

//   Future<void> deleteDuty(String dutyId) async {
//     await _duties.doc(dutyId).delete();
//   }

//   Future<DutyLocation> addLocation(String name,
//       {String description = ''}) async {
//     final doc = await _locations
//         .add({'name': name.trim(), 'description': description.trim()});
//     return DutyLocation(
//         id: doc.id, name: name.trim(), description: description.trim());
//   }

//   Future<void> assignTeachers(
//       String dutyId, Map<String, List<String>> assignments) async {
//     await _duties.doc(dutyId).update({'teacherAssignments': assignments});
//   }

//   Future<Duty> autoAssignTeachers(Duty duty) async {
//     final teacherSnapshot = await _teachers.get();
//     final busySnapshot =
//         await _duties.where('dateKey', isEqualTo: dateKey(duty.date)).get();
//     final blockedIds = <String>{};
//     for (final doc in busySnapshot.docs) {
//       if (doc.id == duty.id) continue;
//       final existing = Duty.fromMap(doc.id, doc.data());
//       if (_overlaps(
//           existing.timeStart, existing.timeEnd, duty.timeStart, duty.timeEnd)) {
//         blockedIds.addAll(existing.teacherIds);
//       }
//     }

//     final available = teacherSnapshot.docs
//         .map((doc) => TeacherRecord.fromMap(doc.id, doc.data()))
//         .where((teacher) =>
//             _isAvailableTeacher(teacher) && !blockedIds.contains(teacher.id))
//         .toList();
//     if (available.isEmpty || duty.locations.isEmpty) {
//       return duty.copyWith(teacherAssignments: {}, teacherNames: {});
//     }

//     var cursor = 0;
//     final assignments = <String, List<String>>{};
//     final names = <String, String>{};
//     for (final location in duty.locations) {
//       final assigned = <String>[];
//       for (var i = 0;
//           i < duty.minTeachersPerVenue && i < available.length;
//           i++) {
//         final teacher = available[cursor % available.length];
//         assigned.add(teacher.id);
//         names[teacher.id] = teacher.fullName;
//         cursor++;
//       }
//       assignments[location.id] = assigned;
//     }
//     return duty.copyWith(teacherAssignments: assignments, teacherNames: names);
//   }

//   Future<List<String>> findEligibleTeacherIds(Duty targetDuty) async {
//     final teachers = await _teachers.get();
//     final busyDuties = await _duties
//         .where('dateKey', isEqualTo: dateKey(targetDuty.date))
//         .get();

//     final blockedIds = <String>{};
//     for (final doc in busyDuties.docs) {
//       if (doc.id == targetDuty.id) continue;
//       final duty = Duty.fromMap(doc.id, doc.data());
//       if (_overlaps(duty.timeStart, duty.timeEnd, targetDuty.timeStart,
//           targetDuty.timeEnd)) {
//         blockedIds.addAll(duty.teacherIds);
//       }
//     }

//     return teachers.docs
//         .map((doc) => TeacherRecord.fromMap(doc.id, doc.data()))
//         .where((teacher) =>
//             _isAvailableTeacher(teacher) &&
//             !blockedIds.contains(teacher.id) &&
//             !targetDuty.teacherIds.contains(teacher.id))
//         .map((teacher) => teacher.id)
//         .toList();
//   }

//   Future<DutySwap> requestSwap({
//     required Duty duty,
//     required String fromTeacherId,
//     required String toTeacherId,
//     required String requestedBy,
//     required bool requestedByPrincipal,
//   }) async {
//     if (!requestedByPrincipal && !duty.teacherIds.contains(fromTeacherId)) {
//       throw StateError('Teachers can only swap their own duties.');
//     }
//     if (!requestedByPrincipal && !canRequestSwap(duty)) {
//       throw StateError('Swap requests close 1 hour before duty starts.');
//     }

//     final swap = DutySwap(
//       id: '',
//       dutyId: duty.id,
//       fromTeacherId: fromTeacherId,
//       toTeacherId: toTeacherId,
//       requestedBy: requestedBy,
//       status: requestedByPrincipal
//           ? DutySwapStatus.approved
//           : DutySwapStatus.pending,
//       createdAt: DateTime.now(),
//     );
//     final doc = await _swaps.add(swap.toMap());

//     if (requestedByPrincipal) {
//       await _applySwap(duty, fromTeacherId, toTeacherId);
//     }

//     final fromName = duty.teacherNames[fromTeacherId] ?? 'A colleague';
//     final when = '${duty.title} on ${dateKey(duty.date)}';

//     if (requestedByPrincipal) {
//       // Swap already applied — let both affected teachers know their
//       // assignment changed.
//       for (final recipientId in {fromTeacherId, toTeacherId}) {
//         await _notifications.add({
//           'userId': recipientId,
//           'type': 'swap_approved',
//           'title': 'Duty Swap Applied',
//           'message': 'Your duty "$when" has been reassigned.',
//           'relatedId': duty.id,
//           'dutyId': duty.id,
//           'fromTeacherId': fromTeacherId,
//           'toTeacherId': toTeacherId,
//           'status': swap.status.name,
//           'read': false,
//           'createdAt': Timestamp.now(),
//         });
//       }
//     } else {
//       // Pending request — notify the teacher being asked to cover the duty.
//       await _notifications.add({
//         'userId': toTeacherId,
//         'type': 'swap_request',
//         'title': 'Duty Swap Request',
//         'message': '$fromName requested you cover "$when".',
//         'relatedId': duty.id,
//         'dutyId': duty.id,
//         'fromTeacherId': fromTeacherId,
//         'toTeacherId': toTeacherId,
//         'status': swap.status.name,
//         'read': false,
//         'createdAt': Timestamp.now(),
//       });
//     }

//     return DutySwap(
//       id: doc.id,
//       dutyId: swap.dutyId,
//       fromTeacherId: swap.fromTeacherId,
//       toTeacherId: swap.toTeacherId,
//       requestedBy: swap.requestedBy,
//       status: swap.status,
//       createdAt: swap.createdAt,
//     );
//   }

//   Future<void> approveSwap(DutySwap swap, Duty duty) async {
//     await _applySwap(duty, swap.fromTeacherId, swap.toTeacherId);
//     await _swaps.doc(swap.id).update({'status': DutySwapStatus.approved.name});
//   }

//   Future<void> completeTaskWithProof({
//     required Duty duty,
//     required String taskId,
//     required String teacherId,
//     required List<int> imageBytes,
//     required String fileName,
//   }) async {
//     if (!canCompleteTask(duty)) {
//       throw StateError(
//           'Tasks can only be completed within 1 hour of duty time.');
//     }

//     final secureUrl = await uploadProofToCloudinary(imageBytes, fileName);
//     if (secureUrl == null) {
//       throw StateError('Image upload failed. Please try again.');
//     }

//     final updatedTasks = duty.tasks.map((task) {
//       if (task.id != taskId) return task;
//       return task.copyWith(
//         isCompleted: true,
//         photoUrl: secureUrl,
//         completedAt: DateTime.now(),
//         teacherId: teacherId,
//       );
//     }).toList();

//     final completed = updatedTasks.every((task) => task.isCompleted);
//     await updateDuty(duty.copyWith(
//       tasks: updatedTasks,
//       thumbnailUrl: secureUrl,
//       status: completed ? 'completed' : 'in-progress',
//     ));
//   }

//   Future<List<Duty>> generateSchedule({
//     required DateTime date,
//     required List<DutyTemplate> templates,
//     required List<DutyLocation> locations,
//   }) async {
//     final teachers = await _teachers.where('status', isEqualTo: 'active').get();
//     final activeTeachers = teachers.docs
//         .map((doc) => TeacherRecord.fromMap(doc.id, doc.data()))
//         .where(_isAvailableTeacher)
//         .toList();

//     if (activeTeachers.isEmpty || locations.isEmpty) return [];

//     var cursor = 0;
//     final generated = <Duty>[];
//     for (final template in templates) {
//       if (!_templateRunsOn(template, date)) continue;
//       final assignments = <String, List<String>>{};
//       final names = <String, String>{};
//       for (final location in locations) {
//         final teacher = activeTeachers[cursor % activeTeachers.length];
//         assignments[location.id] = [teacher.id];
//         names[teacher.id] = teacher.fullName;
//         cursor++;
//       }
//       generated.add(Duty(
//         id: '',
//         title: template.name,
//         date: date,
//         timeStart: _defaultStart(template.name),
//         timeEnd: _defaultEnd(template.name),
//         locations: locations,
//         teacherAssignments: assignments,
//         teacherNames: names,
//         tasks: template.checklist
//             .map((item) => DutyTask(
//                 id: item.toLowerCase().replaceAll(' ', '_'), name: item))
//             .toList(),
//         type: template.name,
//       ));
//     }
//     return generated;
//   }

//   Future<String?> uploadProofToCloudinary(
//       List<int> fileBytes, String fileName) async {
//     final cloudName = _env('CLOUDINARY_CLOUD_NAME');
//     final uploadPreset = _env('CLOUDINARY_UPLOAD_PRESET');
//     if (cloudName == null || uploadPreset == null) return null;

//     try {
//       final uri =
//           Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
//       final request = http.MultipartRequest('POST', uri)
//         ..fields['upload_preset'] = uploadPreset
//         ..fields['folder'] = 'duty-task-proofs'
//         ..files.add(http.MultipartFile.fromBytes('file', fileBytes,
//             filename: fileName));
//       final response = await http.Response.fromStream(await request.send());
//       if (response.statusCode < 200 || response.statusCode >= 300) return null;
//       return (jsonDecode(response.body) as Map<String, dynamic>)['secure_url']
//           ?.toString();
//     } catch (_) {
//       return null;
//     }
//   }

//   bool canCompleteTask(Duty duty, {DateTime? now}) {
//     final current = now ?? DateTime.now();
//     final start = _combine(duty.date, duty.timeStart);
//     final end = _combine(duty.date, duty.timeEnd);
//     return current.isAfter(start.subtract(const Duration(hours: 1))) &&
//         current.isBefore(end.add(const Duration(hours: 1)));
//   }

//   bool canRequestSwap(Duty duty, {DateTime? now}) {
//     final current = now ?? DateTime.now();
//     return current.isBefore(_combine(duty.date, duty.timeStart)
//             .subtract(const Duration(hours: 1))) ||
//         current.isAtSameMomentAs(_combine(duty.date, duty.timeStart)
//             .subtract(const Duration(hours: 1)));
//   }

//   bool isDutyCovering(Duty a, Duty b) {
//     return _minutes(a.timeStart) <= _minutes(b.timeStart) &&
//         _minutes(a.timeEnd) >= _minutes(b.timeEnd);
//   }

//   Future<void> _applySwap(
//       Duty duty, String fromTeacherId, String toTeacherId) async {
//     final assignments = duty.teacherAssignments.map((locationId, teacherIds) {
//       return MapEntry(
//           locationId,
//           teacherIds
//               .map((id) => id == fromTeacherId ? toTeacherId : id)
//               .toList());
//     });
//     await _duties.doc(duty.id).update({
//       'teacherAssignments': assignments,
//       'swapStatus': DutySwapStatus.approved.name,
//     });
//   }

//   bool _overlaps(String aStart, String aEnd, String bStart, String bEnd) {
//     return _minutes(aStart) < _minutes(bEnd) &&
//         _minutes(bStart) < _minutes(aEnd);
//   }

//   bool _templateRunsOn(DutyTemplate template, DateTime date) {
//     final frequency = template.frequency.toLowerCase();
//     if (frequency == 'daily') return true;
//     if (frequency == 'weekly') return date.weekday == DateTime.monday;
//     if (frequency == 'monthly') return date.day == 1;
//     return true;
//   }

//   List<DateTime> _recurrenceDates(DateTime start, DutyRecurrence recurrence) {
//     final first = DateTime(start.year, start.month, start.day);
//     switch (recurrence) {
//       case DutyRecurrence.once:
//         return [first];
//       case DutyRecurrence.daily:
//         return List.generate(30, (index) => first.add(Duration(days: index)));
//       case DutyRecurrence.weekly:
//         return List.generate(
//             12, (index) => first.add(Duration(days: index * 7)));
//       case DutyRecurrence.monthly:
//         return List.generate(
//             6, (index) => DateTime(first.year, first.month + index, first.day));
//     }
//   }

//   bool _isAvailableTeacher(TeacherRecord teacher) {
//     final role = teacher.role.toLowerCase();
//     final status = teacher.status.toLowerCase();
//     if (role == 'principal' || role == 'admin') return false;
//     return status == 'active' &&
//         !status.contains('leave') &&
//         !status.contains('training');
//   }

//   String _defaultStart(String name) {
//     final lower = name.toLowerCase();
//     if (lower.contains('arrival')) return '07:00';
//     if (lower.contains('dismissal')) return '12:30';
//     if (lower.contains('assembly')) return '07:30';
//     return '10:00';
//   }

//   String _defaultEnd(String name) {
//     final lower = name.toLowerCase();
//     if (lower.contains('arrival')) return '07:45';
//     if (lower.contains('dismissal')) return '13:15';
//     if (lower.contains('assembly')) return '08:15';
//     return '10:30';
//   }

//   DateTime _combine(DateTime date, String time) {
//     final parts =
//         time.split(':').map((part) => int.tryParse(part) ?? 0).toList();
//     return DateTime(date.year, date.month, date.day, parts[0],
//         parts.length > 1 ? parts[1] : 0);
//   }

//   int _minutes(String time) {
//     final parts =
//         time.split(':').map((part) => int.tryParse(part) ?? 0).toList();
//     return parts[0] * 60 + (parts.length > 1 ? parts[1] : 0);
//   }

//   String? _env(String key) {
//     const compileTime = {
//       'CLOUDINARY_CLOUD_NAME': String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
//       'CLOUDINARY_UPLOAD_PRESET':
//           String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET'),
//     };
//     final value = compileTime[key];
//     if (value != null && value.isNotEmpty) return value;
//     try {
//       final platformValue = Platform.environment[key];
//       if (platformValue != null && platformValue.isNotEmpty) {
//         return platformValue;
//       }
//     } catch (_) {
//       return null;
//     }
//     return null;
//   }
// }

// extension on Duty {
//   Duty _withId(String id) {
//     return Duty(
//       id: id,
//       title: title,
//       date: date,
//       timeStart: timeStart,
//       timeEnd: timeEnd,
//       isAllDay: isAllDay,
//       locations: locations,
//       teacherAssignments: teacherAssignments,
//       teacherNames: teacherNames,
//       tasks: tasks,
//       thumbnailUrl: thumbnailUrl,
//       swapStatus: swapStatus,
//       status: status,
//       type: type,
//       minTeachersPerVenue: minTeachersPerVenue,
//       recurrence: recurrence,
//     );
//   }
// }
