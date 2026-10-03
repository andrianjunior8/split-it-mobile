import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/features/bills/domain/bill.dart';
import 'package:splitit/features/bills/domain/bill_detail.dart';
import 'package:splitit/features/split_bill/share/share_text.dart';

void main() {
  BillDetail detail({
    String title = 'Makan Makan Kaleyo',
    int serviceBps = 0,
    int taxBps = 0,
  }) => BillDetail(
    bill: Bill(
      id: 'b',
      hostId: 'u1',
      title: title,
      billDate: DateTime(2025, 1, 16),
      serviceBps: serviceBps,
      taxBps: taxBps,
    ),
    participants: const [
      Participant(id: 'p1', billId: 'b', displayName: 'Yoti', isHost: true),
      Participant(id: 'p2', billId: 'b', displayName: 'Frogiii'),
    ],
    items: const [
      BillItem(
        id: 'i1',
        billId: 'b',
        name: 'Steak',
        qty: 1,
        unitPrice: 120000,
        shares: {'p2': 1},
      ),
      BillItem(id: 'i2', billId: 'b', name: 'Nasi', qty: 2, unitPrice: 10000),
    ],
  );

  test('lists each person and the total', () {
    expect(
      buildShareText(detail()),
      'Makan Makan Kaleyo\n'
      '16 January 2025\n'
      '\n'
      'Yoti: Rp 10.000\n'
      'Frogiii: Rp 130.000\n'
      '\n'
      'Total: Rp 140.000\n'
      'Split with SplitIt',
    );
  });

  test('mentions service and tax when present', () {
    final text = buildShareText(detail(serviceBps: 500, taxBps: 1000));
    expect(text, contains('Total: Rp 161.700\n(incl. service 5%, tax 10%)'));
  });

  test('shareFileName is a safe slug', () {
    expect(shareFileName(detail()), 'splitit-makan-makan-kaleyo.png');
    expect(shareFileName(detail(title: '🍜🍜')), 'splitit-bill.png');
    expect(
      shareFileName(detail(title: 'A' * 80)).length,
      'splitit-'.length + 40 + '.png'.length,
    );
  });
}
