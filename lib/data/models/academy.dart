/// Academy model matching the Supabase 'academies' table schema.
class Academy {
  final String id;
  final String? nameKr;
  final String? nameEn;
  final String? address;
  final String? contactNumber;
  final String? logoUrl;
  final DateTime? createdAt;
  final String? tags;
  final String? instagramHandle;
  final String? youtubeUrl;
  final String? tiktokHandle;
  final String? websiteUrl;
  final String? otherUrl;
  final List<AcademyImage> images;
  final bool isActive;
  final AcademyLocation? location;

  const Academy({
    required this.id,
    this.nameKr,
    this.nameEn,
    this.address,
    this.contactNumber,
    this.logoUrl,
    this.createdAt,
    this.tags,
    this.instagramHandle,
    this.youtubeUrl,
    this.tiktokHandle,
    this.websiteUrl,
    this.otherUrl,
    this.images = const [],
    this.isActive = true,
    this.location,
  });

  /// Returns the display name (Korean name preferred, falls back to English)
  String get displayName => nameKr ?? nameEn ?? 'Unknown Academy';

  /// Returns list of tags as a list of strings
  List<String> get tagList =>
      tags?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ?? [];

  /// Returns the primary image URL (first image or logo)
  String? get primaryImageUrl {
    if (images.isNotEmpty) {
      final sortedImages = List<AcademyImage>.from(images)
        ..sort((a, b) => a.order.compareTo(b.order));
      return sortedImages.first.url;
    }
    return logoUrl;
  }

  /// Factory constructor to create Academy from Supabase JSON response
  factory Academy.fromJson(Map<String, dynamic> json) {
    // Parse images JSONB array
    List<AcademyImage> parsedImages = [];
    if (json['images'] != null) {
      final imagesList = json['images'] as List<dynamic>;
      parsedImages = imagesList
          .map((img) => AcademyImage.fromJson(img as Map<String, dynamic>))
          .toList();
    }

    // Parse location JSONB
    AcademyLocation? parsedLocation;
    if (json['location'] != null) {
      parsedLocation = AcademyLocation.fromJson(json['location'] as Map<String, dynamic>);
    }

    return Academy(
      id: json['id'] as String,
      nameKr: json['name_kr'] as String?,
      nameEn: json['name_en'] as String?,
      address: json['address'] as String?,
      contactNumber: json['contact_number'] as String?,
      logoUrl: json['logo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      tags: json['tags'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      tiktokHandle: json['tiktok_handle'] as String?,
      websiteUrl: json['website_url'] as String?,
      otherUrl: json['other_url'] as String?,
      images: parsedImages,
      isActive: json['is_active'] as bool? ?? true,
      location: parsedLocation,
    );
  }

  /// Convert Academy to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_kr': nameKr,
      'name_en': nameEn,
      'address': address,
      'contact_number': contactNumber,
      'logo_url': logoUrl,
      'tags': tags,
      'instagram_handle': instagramHandle,
      'youtube_url': youtubeUrl,
      'tiktok_handle': tiktokHandle,
      'website_url': websiteUrl,
      'other_url': otherUrl,
      'images': images.map((img) => img.toJson()).toList(),
      'is_active': isActive,
      'location': location?.toJson(),
    };
  }

  Academy copyWith({
    String? id,
    String? nameKr,
    String? nameEn,
    String? address,
    String? contactNumber,
    String? logoUrl,
    DateTime? createdAt,
    String? tags,
    String? instagramHandle,
    String? youtubeUrl,
    String? tiktokHandle,
    String? websiteUrl,
    String? otherUrl,
    List<AcademyImage>? images,
    bool? isActive,
    AcademyLocation? location,
  }) {
    return Academy(
      id: id ?? this.id,
      nameKr: nameKr ?? this.nameKr,
      nameEn: nameEn ?? this.nameEn,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      tiktokHandle: tiktokHandle ?? this.tiktokHandle,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      otherUrl: otherUrl ?? this.otherUrl,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
    );
  }
}

/// Academy image model for the images JSONB array
class AcademyImage {
  final String url;
  final int order;

  const AcademyImage({
    required this.url,
    this.order = 0,
  });

  factory AcademyImage.fromJson(Map<String, dynamic> json) {
    return AcademyImage(
      url: json['url'] as String,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'order': order,
    };
  }
}

/// Academy location model for the location JSONB field
class AcademyLocation {
  final double? latitude;
  final double? longitude;

  const AcademyLocation({
    this.latitude,
    this.longitude,
  });

  factory AcademyLocation.fromJson(Map<String, dynamic> json) {
    return AcademyLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  bool get isValid => latitude != null && longitude != null;
}
