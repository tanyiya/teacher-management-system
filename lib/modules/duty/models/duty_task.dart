class DutyTask {
  final String id;
  final String dutyId;
  final String dutyNameSnapshot;

  final String title;
  final String? description;

  final String? locationId;
  final String? locationNameSnapshot;

  final int sequence;

  const DutyTask({
    required this.id,
    required this.dutyId,
    required this.dutyNameSnapshot,
    required this.title,
    this.description,
    this.locationId,
    this.locationNameSnapshot,
    this.sequence = 0,
  });

  factory DutyTask.fromMap(String id, Map<String, dynamic> data,) {
    return DutyTask(
      id: id,
      dutyId:  data['dutyId']?.toString() ?? '',
      dutyNameSnapshot: data['dutyNameSnapshot']?.toString() ?? '',
      title:data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      locationId: data['locationId']?.toString(),
      locationNameSnapshot: data['locationNameSnapshot']?.toString(),
      sequence: data['sequence'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyId': dutyId,
      'dutyNameSnapshot': dutyNameSnapshot,
      'title': title,
      'description': description,
      'locationId': locationId,
      'locationNameSnapshot': locationNameSnapshot,
      'sequence': sequence,
    };
  }

  DutyTask copyWith({
    String? title,
    String? description,
    String? locationId,
    String? locationNameSnapshot,
    int? sequence,
  }) {
    return DutyTask(
      id: id,
      dutyId: dutyId,
      dutyNameSnapshot: dutyNameSnapshot,
      title: title ?? this.title,
      description: description ?? this.description,
      locationId: locationId ?? this.locationId,
      locationNameSnapshot: locationNameSnapshot ?? this.locationNameSnapshot,
      sequence: sequence ?? this.sequence,
    );
  }
}