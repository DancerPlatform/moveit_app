/// Ticket model matching the Supabase 'tickets' table schema.
class Ticket {
  final String id;
  final String? academyId;
  final String name;
  final int price;
  final String ticketType;
  final int? totalCount;
  final int? validDays;
  final String? classId;
  final bool isOnSale;
  final DateTime? createdAt;
  final bool isGeneral;
  final String? accessGroup;
  final bool isCoupon;

  const Ticket({
    required this.id,
    this.academyId,
    required this.name,
    this.price = 0,
    required this.ticketType,
    this.totalCount,
    this.validDays,
    this.classId,
    this.isOnSale = true,
    this.createdAt,
    this.isGeneral = false,
    this.accessGroup,
    this.isCoupon = false,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      academyId: json['academy_id'] as String?,
      name: json['name'] as String,
      price: json['price'] as int? ?? 0,
      ticketType: json['ticket_type'] as String,
      totalCount: json['total_count'] as int?,
      validDays: json['valid_days'] as int?,
      classId: json['class_id'] as String?,
      isOnSale: json['is_on_sale'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isGeneral: json['is_general'] as bool? ?? false,
      accessGroup: json['access_group'] as String?,
      isCoupon: json['is_coupon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academy_id': academyId,
      'name': name,
      'price': price,
      'ticket_type': ticketType,
      'total_count': totalCount,
      'valid_days': validDays,
      'class_id': classId,
      'is_on_sale': isOnSale,
      'is_general': isGeneral,
      'access_group': accessGroup,
      'is_coupon': isCoupon,
    };
  }
}
