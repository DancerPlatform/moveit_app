import 'coupon.dart';

/// UserCoupon model matching the Supabase 'user_coupons' table schema.
class UserCoupon {
  final String id;
  final String userId;
  final String couponId;
  final bool isUsed;
  final DateTime? usedAt;
  final DateTime? createdAt;
  final Coupon? coupon;

  const UserCoupon({
    required this.id,
    required this.userId,
    required this.couponId,
    this.isUsed = false,
    this.usedAt,
    this.createdAt,
    this.coupon,
  });

  /// Check if the coupon is usable (not used and valid)
  bool get isUsable => !isUsed && (coupon?.isValid ?? false);

  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    return UserCoupon(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      couponId: json['coupon_id'] as String,
      isUsed: json['is_used'] as bool? ?? false,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      coupon: json['coupons'] != null
          ? Coupon.fromJson(json['coupons'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coupon_id': couponId,
      'is_used': isUsed,
      'used_at': usedAt?.toIso8601String(),
    };
  }
}
