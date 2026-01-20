/// Hall model matching the Supabase 'halls' table schema.
class Hall {
  final String id;
  final String academyId;
  final String name;
  final int capacity;
  final DateTime? createdAt;

  const Hall({
    required this.id,
    required this.academyId,
    required this.name,
    this.capacity = 0,
    this.createdAt,
  });

  /// Factory constructor to create Hall from Supabase JSON response
  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      name: json['name'] as String,
      capacity: json['capacity'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert Hall to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academy_id': academyId,
      'name': name,
      'capacity': capacity,
    };
  }

  Hall copyWith({
    String? id,
    String? academyId,
    String? name,
    int? capacity,
    DateTime? createdAt,
  }) {
    return Hall(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
