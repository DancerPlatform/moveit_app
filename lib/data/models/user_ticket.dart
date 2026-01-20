import 'ticket.dart';

/// UserTicket model matching the Supabase 'user_tickets' table schema.
class UserTicket {
  final String id;
  final String userId;
  final String ticketId;
  final int remainingCount;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final UserTicketStatus status;
  final DateTime? createdAt;
  final Ticket? ticket;

  const UserTicket({
    required this.id,
    required this.userId,
    required this.ticketId,
    this.remainingCount = 0,
    this.startDate,
    this.expiryDate,
    this.status = UserTicketStatus.active,
    this.createdAt,
    this.ticket,
  });

  /// Returns the number of days remaining until expiry
  int get daysRemaining {
    if (expiryDate == null) return 0;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  /// Check if the ticket is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if the ticket is usable (active and not expired)
  bool get isUsable => status == UserTicketStatus.active && !isExpired && remainingCount > 0;

  factory UserTicket.fromJson(Map<String, dynamic> json) {
    return UserTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ticketId: json['ticket_id'] as String,
      remainingCount: json['remaining_count'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      status: UserTicketStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      ticket: json['tickets'] != null
          ? Ticket.fromJson(json['tickets'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ticket_id': ticketId,
      'remaining_count': remainingCount,
      'start_date': startDate?.toIso8601String().split('T').first,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'status': status.value,
    };
  }
}

enum UserTicketStatus {
  active('ACTIVE'),
  expired('EXPIRED'),
  used('USED');

  final String value;
  const UserTicketStatus(this.value);

  static UserTicketStatus fromString(String value) {
    return UserTicketStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => UserTicketStatus.active,
    );
  }
}
