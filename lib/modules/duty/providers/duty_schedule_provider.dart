import 'package:flutter/material.dart';

enum DutyViewMode { calendar, list }

enum DutyGroupingMode { location, teacher }

/// Pure UI state for the schedule screen: which view is showing, how the
/// calendar is grouped, and the active teacher/location filters. This used
/// to live as local fields on `_DutyScheduleScreenState` /
/// `_CalendarGridState` in the old screen; pulling it into a provider lets
/// the calendar, list, and filter sheet all share the same state.
class DutyScheduleProvider extends ChangeNotifier {
  DutyViewMode viewMode = DutyViewMode.calendar;
  DutyGroupingMode groupingMode = DutyGroupingMode.location;

  String? teacherFilterId;
  String? locationFilterId;

  void toggleViewMode() {
    viewMode = viewMode == DutyViewMode.calendar
        ? DutyViewMode.list
        : DutyViewMode.calendar;
    notifyListeners();
  }

  void setGroupingMode(DutyGroupingMode mode) {
    groupingMode = mode;
    notifyListeners();
  }

  void setTeacherFilter(String? id) {
    teacherFilterId = id;
    notifyListeners();
  }

  void setLocationFilter(String? id) {
    locationFilterId = id;
    notifyListeners();
  }

  static const List<Color> _palette = [
    Color(0xff2563eb),
    Color(0xff16a34a),
    Color(0xffea580c),
    Color(0xff7c3aed),
    Color(0xffdb2777),
    Color(0xff0891b2),
    Color(0xffca8a04),
    Color(0xff4f46e5),
  ];

  /// Deterministic color for a teacher/location id so a given person or
  /// venue always renders with the same block color across the grid.
  Color colorForId(String id) {
    if (id.isEmpty) return _palette.first;
    final hash = id.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }
}