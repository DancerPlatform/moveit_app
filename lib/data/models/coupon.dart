/// Coupon model matching the Supabase 'coupons' table schema.
class Coupon {
  final String id;
  final String? academyId;
  final String name;
  final String? description;
  final CouponDiscountType discountType;
  final int discountValue;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? maxUses;
  final int currentUses;
  final bool isActive;
  final DateTime? createdAt;

  const Coupon({
    required this.id,
    this.academyId,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.validFrom,
    this.validUntil,
    this.maxUses,
    this.currentUses = 0,
    this.isActive = true,
    this.createdAt,
  });

  /// Returns the discount display string
  String get discountDisplay {
    if (discountType == CouponDiscountType.percent) {
      return '$discountValue%';
    } else {
      return '${discountValue.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
    }
  }

  /// Check if the coupon is valid based on date
  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (maxUses != null && currentUses >= maxUses!) return false;
    return true;
  }

  /// Returns days remaining until coupon expires
  int? get daysRemaining {
    if (validUntil == null) return null;
    final difference = validUntil!.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      academyId: json['academy_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      discountType: CouponDiscountType.fromString(json['discount_type'] as String),
      discountValue: json['discount_value'] as int,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      maxUses: json['max_uses'] as int?,
      currentUses: json['current_uses'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academy_id': academyId,
      'name': name,
      'description': description,
      'discount_type': discountType.value,
      'discount_value': discountValue,
      'valid_from': validFrom?.toIso8601String().split('T').first,
      'valid_until': validUntil?.toIso8601String().split('T').first,
      'max_uses': maxUses,
      'current_uses': currentUses,
      'is_active': isActive,
    };
  }
}

enum CouponDiscountType {
  percent('PERCENT'),
  fixed('FIXED');

  final String value;
  const CouponDiscountType(this.value);

  static CouponDiscountType fromString(String value) {
    return CouponDiscountType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => CouponDiscountType.fixed,
    );
  }
}
