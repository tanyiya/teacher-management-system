import 'dart:async';
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
///
/// Swaps are listened to once here and cached (like the other duty
/// providers), rather than handing out a fresh `Stream` per call: an
/// earlier version built a new `.map()` stream on every
/// `pendingApprovalsFor`/`watchSwapsForAssignment` call, so any time the
/// widget holding a `StreamBuilder` rebuilt for an unrelated reason (e.g.
/// its parent screen re-watching another provider), `StreamBuilder` saw a
/// *different* stream identity, tore down its subscription, and reset to
/// `ConnectionState.waiting` -- which is why a swap request would appear
/// and then immediately disappear.
class DutySwapProvider extends ChangeNotifier {
  DutySwapProvider({
    DutySwapService? swapService,
    DutyAssignmentService? assignmentService,
  })  : _swapService = swapService ?? DutySwapService(),
        _assignmentService = assignmentService ?? DutyAssignmentService() {
    _listenSwaps();
  }

  final DutySwapService _swapService;
  final DutyAssignmentService _assignmentService;

  StreamSubscription<List<DutySwap>>? _swapSub;
  List<DutySwap> _swaps = [];

  String? _error;
  String? get error => _error;

  void _listenSwaps() {
    _swapSub = _swapService.getSwaps().listen(
      (items) {
        _swaps = items;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Swaps awaiting this teacher's approval.
  List<DutySwap> pendingApprovalsFor(String teacherId) {
    return _swaps
        .where((s) =>
            s.status == DutySwapStatus.pending && s.replacementTeacherId == teacherId)
        .toList();
  }

  /// Swaps tied to one specific assignment, so a duty card can show its
  /// swap status (e.g. "Swap pending approval").
  List<DutySwap> swapsForAssignment(String assignmentId) {
    return _swaps.where((s) => s.dutyAssignmentId == assignmentId).toList();
  }

  /// Convenience for the accept/reject inbox: looks up the swap and its
  /// assignment by id and applies it, so the UI doesn't need to fetch both
  /// itself before calling [approveSwap].
  Future<void> approveSwapById(String swapId) async {
    try {
      _error = null;
      final swap = await _swapService.getSwapById(swapId);
      if (swap == null) return;
      final assignment =
          await _assignmentService.getAssignmentById(swap.dutyAssignmentId);
      if (assignment == null) return;
      await approveSwap(swap, assignment);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Active teachers who are eligible to take over [assignment]: those with
  /// a duty covering the exact same time window, or with no duty at all
  /// overlapping that window. Returns each candidate's own duty at that
  /// time (if any), so the swap dialog can show it -- e.g. "Ahmad Ali —
  /// also on Cleaning Duty (Dining Area)" vs "Ahmad Ali — free".
  Future<List<SwapCandidate>> eligibleSwapCandidates({
    required DutyAssignment assignment,
    required DutyProvider dutyProvider,
  }) async {
    final sameDayAssignments =
        await _assignmentService.getAssignmentsByDate(assignment.date).first;

    final candidates = dutyProvider.activeTeachers
        .where((t) => !assignment.teacherIds.contains(t.id))
        .toList();

    final eligible = <SwapCandidate>[];
    for (final teacher in candidates) {
      final teacherAssignments =
          sameDayAssignments.where((a) => a.teacherIds.contains(teacher.id));

      DutyAssignment? sameHourDuty;
      var hasOverlap = false;

      for (final other in teacherAssignments) {
        if (other.timeStart == assignment.timeStart &&
            other.timeEnd == assignment.timeEnd) {
          sameHourDuty = other;
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

      if (sameHourDuty != null || !hasOverlap) {
        eligible.add(SwapCandidate(
          teacherId: teacher.id,
          teacherName: teacher.fullName,
          conflictingAssignment: sameHourDuty,
        ));
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
        date: assignment.date,
        timeStart: assignment.timeStart,
        timeEnd: assignment.timeEnd,
        locationNameSnapshot: assignment.locationNameSnapshot,
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

  /// Applies a swap on [assignment]: [fromId] steps out, [toId] steps in.
  ///
  /// If [toId] already had their own assignment in the exact same time
  /// slot (the "same-hour duty" eligibility case), this is a genuine
  /// trade: [fromId] is placed into that assignment in turn, so both
  /// teachers end up exactly where the other one was instead of [toId]
  /// ending up double-booked and [fromId] ending up with nothing. If
  /// [toId] was simply free at the time, there's no assignment to trade
  /// into -- it's just a one-way handoff.
  Future<void> _applySwap(
    DutyAssignment assignment,
    String fromId,
    String toId,
    String toName,
  ) async {
    final fromName = _nameFor(assignment, fromId);

    await _swapTeacherOnAssignment(assignment, fromId, toId, toName);

    final sameDayAssignments =
        await _assignmentService.getAssignmentsByDate(assignment.date).first;
    final reciprocal = sameDayAssignments.where((a) =>
        a.id != assignment.id &&
        a.teacherIds.contains(toId) &&
        a.timeStart == assignment.timeStart &&
        a.timeEnd == assignment.timeEnd);

    if (reciprocal.isNotEmpty) {
      await _swapTeacherOnAssignment(reciprocal.first, toId, fromId, fromName);
    }
  }

  Future<void> _swapTeacherOnAssignment(
    DutyAssignment assignment,
    String outgoingId,
    String incomingId,
    String incomingName,
  ) async {
    final teacherIds = [...assignment.teacherIds];
    final teacherNames = [...assignment.teacherNameSnapshots];
    final index = teacherIds.indexOf(outgoingId);
    if (index == -1) return;
    teacherIds[index] = incomingId;
    teacherNames[index] = incomingName;
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

  @override
  void dispose() {
    _swapSub?.cancel();
    super.dispose();
  }
}

/// An active teacher who's eligible to take over a swap, plus whichever of
/// their own assignments conflicts with the target time slot (null = they
/// were simply free at that time).
class SwapCandidate {
  final String teacherId;
  final String teacherName;
  final DutyAssignment? conflictingAssignment;

  const SwapCandidate({
    required this.teacherId,
    required this.teacherName,
    this.conflictingAssignment,
  });
}