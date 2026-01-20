import 'instructor.dart';

/// DanceClass model matching the Supabase 'classes' table schema.
class DanceClass {
  final String id;
  final String academyId;
  final String? song;
  final String? title;
  final String? difficultyLevel;
  final String? genre;
  final String? classType;
  final String? thumbnailUrl;
  final int price;
  final DateTime? createdAt;
  final String? description;
  final String? instructorId;
  final String? hallId;
  final int maxStudents;
  final int currentStudents;
  final String? status;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCanceled;
  final String? videoUrl;
  final int presentStudents;
  final bool isActive;
  final Instructor? instructor;

  const DanceClass({
    required this.id,
    required this.academyId,
    this.song,
    this.title,
    this.difficultyLevel,
    this.genre,
    this.classType,
    this.thumbnailUrl,
    this.price = 0,
    this.createdAt,
    this.description,
    this.instructorId,
    this.hallId,
    this.maxStudents = 0,
    this.currentStudents = 0,
    this.status,
    this.startTime,
    this.endTime,
    this.isCanceled = false,
    this.videoUrl,
    this.presentStudents = 0,
    this.isActive = true,
    this.instructor,
  });

  /// Returns the display title (title preferred, falls back to song)
  String get displayTitle => title ?? song ?? 'Untitled Class';

  /// Factory constructor to create DanceClass from Supabase JSON response
  factory DanceClass.fromJson(Map<String, dynamic> json) {
    Instructor? instructor;
    if (json['instructors'] != null) {
      instructor = Instructor.fromJson(json['instructors'] as Map<String, dynamic>);
    }

    return DanceClass(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      song: json['song'] as String?,
      title: json['title'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      genre: json['genre'] as String?,
      classType: json['class_type'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      price: json['price'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      description: json['description'] as String?,
      instructorId: json['instructor_id'] as String?,
      hallId: json['hall_id'] as String?,
      maxStudents: json['max_students'] as int? ?? 0,
      currentStudents: json['current_students'] as int? ?? 0,
      status: json['status'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      isCanceled: json['is_canceled'] as bool? ?? false,
      videoUrl: json['video_url'] as String?,
      presentStudents: json['present_students'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      instructor: instructor,
    );
  }

  /// Convert DanceClass to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academy_id': academyId,
      'song': song,
      'title': title,
      'difficulty_level': difficultyLevel,
      'genre': genre,
      'class_type': classType,
      'thumbnail_url': thumbnailUrl,
      'price': price,
      'description': description,
      'instructor_id': instructorId,
      'hall_id': hallId,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'status': status,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_canceled': isCanceled,
      'video_url': videoUrl,
      'present_students': presentStudents,
      'is_active': isActive,
    };
  }

  DanceClass copyWith({
    String? id,
    String? academyId,
    String? song,
    String? title,
    String? difficultyLevel,
    String? genre,
    String? classType,
    String? thumbnailUrl,
    int? price,
    DateTime? createdAt,
    String? description,
    String? instructorId,
    String? hallId,
    int? maxStudents,
    int? currentStudents,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCanceled,
    String? videoUrl,
    int? presentStudents,
    bool? isActive,
    Instructor? instructor,
  }) {
    return DanceClass(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      song: song ?? this.song,
      title: title ?? this.title,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      genre: genre ?? this.genre,
      classType: classType ?? this.classType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      hallId: hallId ?? this.hallId,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCanceled: isCanceled ?? this.isCanceled,
      videoUrl: videoUrl ?? this.videoUrl,
      presentStudents: presentStudents ?? this.presentStudents,
      isActive: isActive ?? this.isActive,
      instructor: instructor ?? this.instructor,
    );
  }
}
