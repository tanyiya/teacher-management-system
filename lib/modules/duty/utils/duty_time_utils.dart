/// Shared time-window rules that used to live inline in the old
/// `DutyScheduleScreen` (`_TimeX.toMinutes()` + ad-hoc checks). Pulled out
/// so both the calendar grid, list screen, detail sheet and swap dialog can
/// share the exact same "30 minutes before / after" logic.
class DutyTimeUtils {
  DutyTimeUtils._();

  /// Parses "HH:mm" into minutes-from-midnight.
  static int toMinutes(String hhmm) {
    final parts = hhmm.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    return parts[0] * 60 + (parts.length > 1 ? parts[1] : 0);
  }

  /// True if [startA]-[endA] and [startB]-[endB] (both "HH:mm") overlap.
  static bool rangesOverlap(
    String startA,
    String endA,
    String startB,
    String endB,
  ) {
    final sA = toMinutes(startA);
    final eA = toMinutes(endA);
    final sB = toMinutes(startB);
    final eB = toMinutes(endB);
    return sA < eB && sB < eA;
  }

  /// Task progress may only be updated from 30 minutes before a duty's
  /// start time until 30 minutes after its end time.
  static bool isWithinUpdateWindow(
    DateTime date,
    String timeStart,
    String timeEnd,
  ) {
    final now = DateTime.now();
    final start =
        combine(date, timeStart).subtract(const Duration(minutes: 30));
    final end = combine(date, timeEnd).add(const Duration(minutes: 30));
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Swaps must be requested/approved no later than 30 minutes before the
  /// duty starts.
  static bool canStillSwap(DateTime date, String timeStart) {
    final cutoff =
        combine(date, timeStart).subtract(const Duration(minutes: 30));
    return DateTime.now().isBefore(cutoff);
  }

  /// Combines a date with an "HH:mm" string into a concrete `DateTime`.
  /// Public so callers that need to sort/compare assignments by their
  /// actual start/end moment (e.g. "next upcoming duty") don't have to
  /// re-implement this parsing.
  static DateTime combine(DateTime date, String hhmm) {
    return DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: toMinutes(hhmm)));
  }

  static const List<String> _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// `1` (Monday) .. `7` (Sunday), matching `DateTime.weekday`, to its name.
  static String weekdayName(int weekday) {
    if (weekday < 1 || weekday > 7) return '';
    return _weekdayNames[weekday - 1];
  }

  /// `1` -> "1st", `2` -> "2nd", `3` -> "3rd", `11`-`13` -> "11th"-"13th", etc.
  static String ordinal(int day) {
    if (day % 100 >= 11 && day % 100 <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}