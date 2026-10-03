import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/core/utils/formatters.dart';
import 'package:splitit/features/bills/domain/bill.dart';

void main() {
  test('Bill round-trips the writable columns', () {
    final bill = Bill.fromJson({
      'id': 'b1',
      'host_id': 'u1',
      'title': 'Makan Makan Kaleyo',
      'bill_date': '2025-01-16',
      'status': 'done',
      'service_bps': 500,
      'tax_bps': 1000,
    });
    expect(bill.status, BillStatus.done);
    expect(bill.toJson(), {
      'title': 'Makan Makan Kaleyo',
      'bill_date': '2025-01-16',
      'status': 'done',
      'service_bps': 500,
      'tax_bps': 1000,
    });
  });

  test('BillItem reads nested item_shares', () {
    final item = BillItem.fromJson({
      'id': 'i1',
      'bill_id': 'b1',
      'name': 'Paket Bebek',
      'qty': 2,
      'unit_price': 25000,
      'discount': 5000,
      'position': 0,
      'item_shares': [
        {'participant_id': 'p1', 'weight': 1},
        {'participant_id': 'p2', 'weight': 2},
      ],
    });
    expect(item.total, 45000);
    expect(item.shares, {'p1': 1, 'p2': 2});
  });

  test('formatRupiah uses Indonesian thousand separators', () {
    expect(formatRupiah(86300), '86.300');
    expect(formatRupiah(1637690), '1.637.690');
  });
}
