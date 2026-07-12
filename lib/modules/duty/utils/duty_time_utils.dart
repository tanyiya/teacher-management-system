/// Shared time-window rules that used to live inline in the old
/// `DutyScheduleScreen` (`_TimeX.toMinutes()` + ad-hoc checks). Pulled out
/// so both the calendar grid, list screen, detail sheet and swap dialog can
/// share the exact same "30 minutes before / after" logic. Also home to
/// the module's shared "current moment" and date/time formatting, so every
/// screen and notification message renders dates/times the same way.
class DutyTimeUtils {
  DutyTimeUtils._();

  /// The module's canonical "now". Plain device-local time -- an earlier
  /// version of this tried to force Malaysia (UTC+8) time explicitly via
  /// `DateTime.now().toUtc().add(Duration(hours: 8))`, but that doesn't
  /// just relabel the current moment: `.add()` shifts the actual instant
  /// 8 hours into the future, full stop, regardless of the device's own
  /// timezone. `combine()` below (and every `DateTime` read back from
  /// Firestore via `Timestamp.toDate()`) stays in plain device-local time,
  /// so comparing that against this artificially-shifted "now" put every
  /// duty's update window 8 hours out of sync -- which is why the camera
  /// icon disappeared for duties that were genuinely within their window.
  /// Getting *real* device-timezone-independent Malaysia time right would
  /// need a proper timezone database (the `timezone` package), not simple
  /// arithmetic; for now this assumes devices are correctly set to
  /// Malaysia time, which holds for actual phones used in Malaysia.
  static DateTime now() => DateTime.now();

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
    final start =
        combine(date, timeStart).subtract(const Duration(minutes: 30));
    final end = combine(date, timeEnd).add(const Duration(minutes: 30));
    return now().isAfter(start) && now().isBefore(end);
  }

  /// Swaps must be requested/approved no later than 30 minutes before the
  /// duty starts.
  static bool canStillSwap(DateTime date, String timeStart) {
    final cutoff =
        combine(date, timeStart).subtract(const Duration(minutes: 30));
    return now().isBefore(cutoff);
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

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

  /// `DateTime(2026, 7, 11)` -> `"11 Jul 2026"`. The module's one date
  /// format, used everywhere a duty/swap/assignment date is shown.
  static String formatDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  /// `"16:30"` -> `"4:30 PM"`. The module's one time format -- 12-hour with
  /// AM/PM, never bare 24-hour.
  static String formatTimeOfDay(String hhmm) {
    final minutes = toMinutes(hhmm);
    final hour24 = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
  }

  /// `"16:30"`, `"17:00"` -> `"4:30 PM - 5:00 PM"`.
  static String formatTimeRange(String start, String end) {
    return '${formatTimeOfDay(start)} - ${formatTimeOfDay(end)}';
  }

  /// `DateTime(2026,7,11)`, `"16:30"` -> `"11 Jul 2026, 4:30 PM"`.
  static String formatDateTime(DateTime date, String hhmm) {
    return '${formatDate(date)}, ${formatTimeOfDay(hhmm)}';
  }

  /// `DateTime(2026,7,11)`, `"16:30"`, `"17:00"` ->
  /// `"11 Jul 2026, 4:30 PM - 5:00 PM"`.
  static String formatDateTimeRange(DateTime date, String start, String end) {
    return '${formatDate(date)}, ${formatTimeRange(start, end)}';
  }

  /// `DateTime(2026,7,11,16,30)` -> `"4:30 PM"`. For actual `DateTime`
  /// values (e.g. `completedAt`) rather than the module's "HH:mm" strings.
  static String formatClockTime(DateTime dt) {
    return formatTimeOfDay(
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
    );
  }

  /// `DateTime(2026,7,11,16,30)` -> `"11 Jul 2026, 4:30 PM"`.
  static String formatDateAndClockTime(DateTime dt) {
    return '${formatDate(dt)}, ${formatClockTime(dt)}';
  }
}