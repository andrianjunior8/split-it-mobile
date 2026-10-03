import 'bill.dart';
import 'split_calculator.dart';

/// A row of `bill_summaries`: a bill with its computed totals, for lists.
class BillSummary {
  const BillSummary({
    required this.bill,
    required this.subtotal,
    required this.service,
    required this.tax,
  });

  final Bill bill;
  final int subtotal;
  final int service;
  final int tax;

  int get total => subtotal + service + tax;

  factory BillSummary.fromJson(Map<String, dynamic> json) => BillSummary(
    bill: Bill.fromJson(json),
    subtotal: json['subtotal'] as int,
    service: json['service'] as int,
    tax: json['tax'] as int,
  );
}

/// Everything the Split Bill screen needs.
class BillDetail {
  const BillDetail({
    required this.bill,
    required this.participants,
    required this.items,
  });

  final Bill bill;

  /// Host first, then in the order they were added.
  final List<Participant> participants;

  /// Ordered by position.
  final List<BillItem> items;

  Participant get host => participants.firstWhere((p) => p.isHost);

  SplitResult calculate() => SplitCalculator.calculate(
    participantIds: [for (final p in participants) p.id],
    items: [
      for (final i in items)
        SplitItem(
          id: i.id,
          qty: i.qty,
          unitPrice: i.unitPrice,
          discount: i.discount,
          shares: i.shares,
        ),
    ],
    serviceBps: bill.serviceBps,
    taxBps: bill.taxBps,
  );
}
