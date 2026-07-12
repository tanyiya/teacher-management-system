import 'package:cloud_firestore/cloud_firestore.dart';

import 'duty_location.dart';
import '../utils/duty_time_utils.dart';

enum DutyRecurrence {
  once,
  daily,
  weekly,
  monthly,
}

class Duty {
  final String id;
  final String title;

  final String timeStart;
  final String timeEnd;

  final bool isAllDay;
  final DutyRecurrence recurrence;

  /// Which day a `weekly` duty falls on. `1` = Monday ... `7` = Sunday
  /// (matches `DateTime.weekday`). Null/ignored for other recurrences.
  final int? recurrenceDayOfWeek;

  /// Which day of the month a `monthly` duty falls on (1-31). Null/ignored
  /// for other recurrences.
  final int? recurrenceDayOfMonth;

  /// Which calendar date a `once` duty falls on -- lets the principal key
  /// in an ad hoc, one-off task for a specific day (e.g. a special event)
  /// rather than only ever being able to create recurring duties.
  /// Null/ignored for other recurrences.
  final DateTime? specificDate;

  final List<DutyLocation> locations;

  final int minTeachersPerVenue;

  /// Human-readable recurrence, spelling out the day for weekly/monthly
  /// duties (e.g. "Every Monday", "Every 1st") and the actual date for a
  /// one-time duty, since just "Weekly"/"Monthly"/"One-time" doesn't say
  /// which day it actually falls on.
  String get recurrenceLabel {
    switch (recurrence) {
      case DutyRecurrence.once:
        return specificDate != null
            ? DutyTimeUtils.formatDate(specificDate!)
            : 'One-time';
      case DutyRecurrence.daily:
        return 'Daily';
      case DutyRecurrence.weekly:
        return recurrenceDayOfWeek != null
            ? 'Every ${DutyTimeUtils.weekdayName(recurrenceDayOfWeek!)}'
            : 'Weekly';
      case DutyRecurrence.monthly:
        return recurrenceDayOfMonth != null
            ? 'Every ${DutyTimeUtils.ordinal(recurrenceDayOfMonth!)}'
            : 'Monthly';
    }
  }

  const Duty({
    required this.id,
    required this.title,
    required this.timeStart,
    required this.timeEnd,
    required this.isAllDay,
    required this.recurrence,
    this.recurrenceDayOfWeek,
    this.recurrenceDayOfMonth,
    this.specificDate,
    required this.locations,
    required this.minTeachersPerVenue,
  });

  factory Duty.fromMap(String id, Map<String, dynamic> data) {
    return Duty(
      id: id,
      title: data['title']?.toString() ?? '',
      timeStart: data['timeStart']?.toString() ?? '00:00',
      timeEnd: data['timeEnd']?.toString() ?? '00:00',
      isAllDay: data['isAllDay'] as bool? ?? false,
      recurrence: DutyRecurrence.values.firstWhere(
        (e) => e.name == data['recurrence'],
        orElse: () => DutyRecurrence.once,
      ),
      recurrenceDayOfWeek: (data['recurrenceDayOfWeek'] as num?)?.toInt(),
      recurrenceDayOfMonth: (data['recurrenceDayOfMonth'] as num?)?.toInt(),
      specificDate: (data['specificDate'] as Timestamp?)?.toDate(),
      locations: (data['locations'] as List<dynamic>? ?? [])
          .map((raw) => DutyLocation.fromMap(
                raw['id']?.toString() ?? '',
                Map<String, dynamic>.from(raw as Map),
              ))
          .toList(),
      minTeachersPerVenue: (data['minTeachersPerVenue'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'isAllDay': isAllDay,
      'recurrence': recurrence.name,
      'recurrenceDayOfWeek': recurrenceDayOfWeek,
      'recurrenceDayOfMonth': recurrenceDayOfMonth,
      'specificDate': specificDate == null ? null : Timestamp.fromDate(specificDate!),
      'locations': locations.map((l) => {'id': l.id, ...l.toMap()}).toList(),
      'minTeachersPerVenue': minTeachersPerVenue,
    };
  }

  Duty copyWith({
    String? title,
    String? timeStart,
    String? timeEnd,
    bool? isAllDay,
    DutyRecurrence? recurrence,
    int? recurrenceDayOfWeek,
    int? recurrenceDayOfMonth,
    DateTime? specificDate,
    List<DutyLocation>? locations,
    int? minTeachersPerVenue,
  }) {
    return Duty(
      id: id,
      title: title ?? this.title,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrence: recurrence ?? this.recurrence,
      recurrenceDayOfWeek: recurrenceDayOfWeek ?? this.recurrenceDayOfWeek,
      recurrenceDayOfMonth: recurrenceDayOfMonth ?? this.recurrenceDayOfMonth,
      specificDate: specificDate ?? this.specificDate,
      locations: locations ?? this.locations,
      minTeachersPerVenue: minTeachersPerVenue ?? this.minTeachersPerVenue,
    );
  }
}