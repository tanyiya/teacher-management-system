import 'package:flutter/material.dart';

import '../models/duty_assignment.dart';
import '../models/duty_swap.dart';
import '../services/duty_assignment_service.dart';
import '../services/duty_swap_service.dart';
import '../utils/duty_time_utils.dart';
import 'duty_provider.dart';

/// Implements the "Swap duties" requirement:
///  - Teachers may only swap with a colleague who either has a duty in the
///    same time slot, or has no other duty overlapping that slot.
///  - A teacher-initiated swap is `pending` until the replacement teacher
///    approves it.
///  - A principal-initiated swap applies immediately and notifies both
///    teachers without requiring approval.
///  - Swaps can only be requested/approved up to 30 minutes before the duty
///    starts (see [DutyTimeUtils.canStillSwap]).
class DutySwapProvider extends ChangeNotifier {
  DutySwapProvider({
    DutySwapService? swapService,
    DutyAssignmentService? assignmentService,
  })  : _swapService = swapService ?? DutySwapService(),
        _assignmentService = assignmentService ?? DutyAssignmentService();

  final DutySwapService _swapService;
  final DutyAssignmentService _assignmentService;

  String? _error;
  String? get error => _error;

  /// Swaps awaiting this teacher's approval.
  Stream<List<DutySwap>> pendingApprovalsFor(String teacherId) {
    return _swapService.getSwapsByTeacher(teacherId).map(
          (swaps) => swaps
              .where((s) =>
                  s.status == DutySwapStatus.pending &&
                  s.replacementTeacherId == teacherId)
              .toList(),
        );
  }

  /// Active teachers who are eligible to take over [assignment]: those with
  /// a duty covering the exact same time window, or with no duty at all
  /// overlapping that window. Now that `DutyAssignment` snapshots its own
  /// `timeStart`/`timeEnd`, this compares assignments directly and no
  /// longer needs to look anything up on `Duty`.
  Future<List<String>> eligibleSwapTeacherIds({
    required DutyAssignment assignment,
    required DutyProvider dutyProvider,
  }) async {
    final sameDayAssignments =
        await _assignmentService.getAssignmentsByDate(assignment.date).first;

    final candidates = dutyProvider.activeTeachers
        .where((t) => !assignment.teacherIds.contains(t.id))
        .toList();

    final eligible = <String>[];
    for (final teacher in candidates) {
      final teacherAssignments =
          sameDayAssignments.where((a) => a.teacherIds.contains(teacher.id));

      var hasSimilarHourDuty = false;
      var hasOverlap = false;

      for (final other in teacherAssignments) {
        if (other.timeStart == assignment.timeStart &&
            other.timeEnd == assignment.timeEnd) {
          hasSimilarHourDuty = true;
        }
        if (DutyTimeUtils.rangesOverlap(
          assignment.timeStart,
          assignment.timeEnd,
          other.timeStart,
          other.timeEnd,
        )) {
          hasOverlap = true;
        }
      }

      if (hasSimilarHourDuty || !hasOverlap) {
        eligible.add(teacher.id);
      }
    }
    return eligible;
  }

  /// Creates a swap request. Admin-initiated requests auto-approve and
  /// apply immediately; teacher-initiated requests stay `pending` until the
  /// replacement teacher approves via [approveSwap].
  Future<void> requestSwap({
    required DutyAssignment assignment,
    required String currentTeacherId,
    required String replacementTeacherId,
    required String replacementTeacherNameSnapshot,
    required String requestedById,
    required String requestedByNameSnapshot,
    required DutySwapRequesterType requesterType,
  }) async {
    try {
      _error = null;
      final isAdmin = requesterType == DutySwapRequesterType.admin;

      final swap = DutySwap(
        id: '',
        dutyAssignmentId: assignment.id,
        dutyNameSnapshot: assignment.dutyNameSnapshot,
        currentTeacherId: currentTeacherId,
        currentTeacherNameSnapshot: _nameFor(assignment, currentTeacherId),
        replacementTeacherId: replacementTeacherId,
        replacementTeacherNameSnapshot: replacementTeacherNameSnapshot,
        requestedById: requestedById,
        requestedByNameSnapshot: requestedByNameSnapshot,
        requesterType: requesterType,
        status: isAdmin ? DutySwapStatus.approved : DutySwapStatus.pending,
        createdAt: DateTime.now(),
        respondedAt: isAdmin ? DateTime.now() : null,
      );

      await _swapService.addSwap(swap);

      if (isAdmin) {
        await _applySwap(
          assignment,
          currentTeacherId,
          replacementTeacherId,
          replacementTeacherNameSnapshot,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> approveSwap(DutySwap swap, DutyAssignment assignment) async {
    try {
      _error = null;
      await _swapService.approveSwap(swap.id);
      await _applySwap(
        assignment,
        swap.currentTeacherId,
        swap.replacementTeacherId,
        swap.replacementTeacherNameSnapshot,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectSwap(String id) async {
    try {
      _error = null;
      await _swapService.rejectSwap(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelSwap(String id) async {
    try {
      _error = null;
      await _swapService.cancelSwap(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _applySwap(
    DutyAssignment assignment,
    String fromId,
    String toId,
    String toName,
  ) async {
    final teacherIds = [...assignment.teacherIds];
    final teacherNames = [...assignment.teacherNameSnapshots];
    final index = teacherIds.indexOf(fromId);
    if (index == -1) return;
    teacherIds[index] = toId;
    teacherNames[index] = toName;
    await _assignmentService.updateAssignment(
      assignment.copyWith(
        teacherIds: teacherIds,
        teacherNameSnapshots: teacherNames,
      ),
    );
  }

  String _nameFor(DutyAssignment assignment, String teacherId) {
    final index = assignment.teacherIds.indexOf(teacherId);
    if (index < 0 || index >= assignment.teacherNameSnapshots.length) {
      return teacherId;
    }
    return assignment.teacherNameSnapshots[index];
  }
}