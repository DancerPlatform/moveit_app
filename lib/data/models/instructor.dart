/// Instructor model matching the Supabase 'instructors' table schema.
class Instructor {
  final String id;
  final String? nameKr;
  final String? nameEn;
  final String? profileImageUrl;
  final String? instagramUrl;
  final DateTime? createdAt;
  final String? bio;
  final String? specialties;
  final int likeCount;

  const Instructor({
    required this.id,
    this.nameKr,
    this.nameEn,
    this.profileImageUrl,
    this.instagramUrl,
    this.createdAt,
    this.bio,
    this.specialties,
    this.likeCount = 0,
  });

  /// Returns the display name (Korean name preferred, falls back to English)
  String get displayName => nameKr ?? nameEn ?? 'Unknown Instructor';

  /// Returns list of specialties as a list of strings
  List<String> get specialtyList =>
      specialties?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];

  /// Factory constructor to create Instructor from Supabase JSON response
  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as String,
      nameKr: json['name_kr'] as String?,
      nameEn: json['name_en'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      bio: json['bio'] as String?,
      specialties: json['specialties'] as String?,
      likeCount: json['like'] as int? ?? 0,
    );
  }

  /// Convert Instructor to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_kr': nameKr,
      'name_en': nameEn,
      'profile_image_url': profileImageUrl,
      'instagram_url': instagramUrl,
      'bio': bio,
      'specialties': specialties,
      'like': likeCount,
    };
  }

  Instructor copyWith({
    String? id,
    String? nameKr,
    String? nameEn,
    String? profileImageUrl,
    String? instagramUrl,
    DateTime? createdAt,
    String? bio,
    String? specialties,
    int? likeCount,
  }) {
    return Instructor(
      id: id ?? this.id,
      nameKr: nameKr ?? this.nameKr,
      nameEn: nameEn ?? this.nameEn,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}