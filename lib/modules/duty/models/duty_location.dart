class DutyLocation {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const DutyLocation({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
  });

  factory DutyLocation.fromMap(String id, Map<String, dynamic> data) {
    return DutyLocation(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      isActive: data['isActive'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }

  DutyLocation copyWith({
    String? name,
    String? description,
    bool? isActive,
  }) {
    return DutyLocation(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}