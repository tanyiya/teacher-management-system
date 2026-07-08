DutySwapProvider
DutySwap? _lastSwap;
DutySwap? get lastSwap => _lastSwap;

Future<List<String>> eligibleSwapTeacherIds(Duty duty) {
    return _dutyService.findEligibleTeacherIds(duty);
  }

  Future<void> requestSwap(Duty duty, String toTeacherId,
      {String? fromTeacherId}) async {
    final sourceTeacherId = fromTeacherId ??
        (isPrincipal
            ? (duty.teacherIds.isEmpty ? null : duty.teacherIds.first)
            : _currentTeacherId);
    if (sourceTeacherId == null) return;
    await _guard(() async {
      _lastSwap = await _dutyService.requestSwap(
        duty: duty,
        fromTeacherId: sourceTeacherId,
        toTeacherId: toTeacherId,
        requestedBy: _currentTeacherId ?? sourceTeacherId,
        requestedByPrincipal: isPrincipal,
      );
    });
  }

  

  bool canRequestSwap(Duty duty) {
    if (isPrincipal) return true;
    final teacherId = _currentTeacherId;
    return teacherId != null &&
        duty.teacherIds.contains(teacherId) &&
        _dutyService.canRequestSwap(duty);
  }
