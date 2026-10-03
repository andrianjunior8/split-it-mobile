/// Models mirroring `supabase/migrations/0002_bills.sql`.
library;

enum BillStatus { draft, done }

class Bill {
  const Bill({
    required this.id,
    required this.hostId,
    required this.title,
    required this.billDate,
    this.status = BillStatus.draft,
    this.serviceBps = 0,
    this.taxBps = 0,
  });

  final String id;
  final String hostId;
  final String title;
  final DateTime billDate;
  final BillStatus status;
  final int serviceBps;
  final int taxBps;

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    hostId: json['host_id'] as String,
    title: json['title'] as String,
    billDate: DateTime.parse(json['bill_date'] as String),
    status: BillStatus.values.byName(json['status'] as String),
    serviceBps: json['service_bps'] as int,
    taxBps: json['tax_bps'] as int,
  );

  /// Writable columns only; id and host_id are set by the database.
  Map<String, dynamic> toJson() => {
    'title': title,
    'bill_date': _date(billDate),
    'status': status.name,
    'service_bps': serviceBps,
    'tax_bps': taxBps,
  };

  Bill copyWith({
    String? title,
    DateTime? billDate,
    BillStatus? status,
    int? serviceBps,
    int? taxBps,
  }) => Bill(
    id: id,
    hostId: hostId,
    title: title ?? this.title,
    billDate: billDate ?? this.billDate,
    status: status ?? this.status,
    serviceBps: serviceBps ?? this.serviceBps,
    taxBps: taxBps ?? this.taxBps,
  );

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class Participant {
  const Participant({
    required this.id,
    required this.billId,
    required this.displayName,
    this.userId,
    this.isHost = false,
  });

  final String id;
  final String billId;
  final String? userId;
  final String displayName;
  final bool isHost;

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['id'] as String,
    billId: json['bill_id'] as String,
    userId: json['user_id'] as String?,
    displayName: json['display_name'] as String,
    isHost: json['is_host'] as bool,
  );
}

class BillItem {
  const BillItem({
    required this.id,
    required this.billId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
    this.position = 0,
    this.shares = const {},
  });

  final String id;
  final String billId;
  final String name;
  final int qty;
  final int unitPrice;
  final int discount;
  final int position;

  /// participantId → weight, from `item_shares`. Empty = everyone equally.
  final Map<String, int> shares;

  int get total => qty * unitPrice - discount;

  /// Expects the row selected with `item_shares(participant_id, weight)`.
  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
    id: json['id'] as String,
    billId: json['bill_id'] as String,
    name: json['name'] as String,
    qty: json['qty'] as int,
    unitPrice: json['unit_price'] as int,
    discount: json['discount'] as int,
    position: json['position'] as int,
    shares: {
      for (final s in (json['item_shares'] as List? ?? const []))
        (s as Map<String, dynamic>)['participant_id'] as String:
            s['weight'] as int,
    },
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'qty': qty,
    'unit_price': unitPrice,
    'discount': discount,
    'position': position,
  };
}
