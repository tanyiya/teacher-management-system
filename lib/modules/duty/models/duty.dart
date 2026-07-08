import 'duty_location.dart';

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

  final List<DutyLocation> locations;

  final int minTeachersPerVenue;

  const Duty({
    required this.id,
    required this.title,
    required this.timeStart,
    required this.timeEnd,
    this.isAllDay = false,
    this.recurrence = DutyRecurrence.once,
    this.locations = const [],
    this.minTeachersPerVenue = 1,
  });

  factory Duty.fromMap(String id, Map<String, dynamic> data,) {
    return Duty(
      id: id,
      title: data['title']?.toString() ?? '',
      timeStart: data['timeStart']?.toString() ?? '',
      timeEnd: data['timeEnd']?.toString() ?? '',
      isAllDay: data['isAllDay'] == true,

      recurrence: DutyRecurrence.values.firstWhere(
        (e) => e.name == data['recurrence'],
        orElse: () => DutyRecurrence.once,
      ),

      locations:
          (data['locations'] as List<dynamic>? ?? [])
              .map((e) {
                return DutyLocation.fromMap(e['id'].toString(), e,);
              })
              .toList(),

      minTeachersPerVenue: data['minTeachersPerVenue'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'isAllDay': isAllDay,
      'recurrence': recurrence.name,

      'locations': locations.map((location) {
        return {'id': location.id, ...location.toMap(),
        };
      }).toList(),

      'minTeachersPerVenue': minTeachersPerVenue,
    };
  }

  Duty copyWith({
    String? title,
    String? timeStart,
    String? timeEnd,
    bool? isAllDay,
    DutyRecurrence? recurrence,
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

      locations: locations ?? this.locations,

      minTeachersPerVenue:
          minTeachersPerVenue ??
          this.minTeachersPerVenue,
    );
  }
}