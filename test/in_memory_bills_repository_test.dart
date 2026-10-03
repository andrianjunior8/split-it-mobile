import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/features/auth/data/app_user.dart';
import 'package:splitit/features/bills/data/bills_repository.dart';
import 'package:splitit/features/bills/data/in_memory_bills_repository.dart';
import 'package:splitit/features/bills/domain/bill.dart';

void main() {
  const andrian = AppUser(id: 'u1', email: 'a@x.com', name: 'Andrian');
  const budi = AppUser(id: 'u2', email: 'budi@x.com', username: 'budi');

  late AppUser? current;
  late InMemoryBillsRepository repo;

  setUp(() {
    current = andrian;
    repo = InMemoryBillsRepository(currentUser: () => current);
  });

  BillItem item(
    String billId,
    String name,
    int qty,
    int price, {
    int discount = 0,
  }) => BillItem(
    id: '',
    billId: billId,
    name: name,
    qty: qty,
    unitPrice: price,
    discount: discount,
  );

  test('createBill adds the host as first participant', () async {
    final bill = await repo.createBill(title: '  Makan Makan Kaleyo ');
    final detail = await repo.getBill(bill.id);
    expect(bill.title, 'Makan Makan Kaleyo');
    expect(detail.participants.single.isHost, isTrue);
    expect(detail.host.displayName, 'Andrian');
  });

  test('host stays first even after others are added', () async {
    final bill = await repo.createBill(title: 'Trip');
    await repo.addParticipant(billId: bill.id, displayName: 'Frogiii');
    await repo.addParticipant(billId: bill.id, displayName: 'Andri');
    final names = (await repo.getBill(
      bill.id,
    )).participants.map((p) => p.displayName);
    expect(names, ['Andrian', 'Frogiii', 'Andri']);
  });

  test(
    'listBills: newest date first, search by title, totals computed',
    () async {
      final old = await repo.createBill(
        title: 'Warkop Bigcon',
        billDate: DateTime(2024, 11, 29),
      );
      final recent = await repo.createBill(
        title: 'Makan Makan Kaleyo',
        billDate: DateTime(2025, 1, 16),
      );
      await repo.updateBill(recent.copyWith(serviceBps: 500, taxBps: 1000));
      await repo.saveItem(item(recent.id, 'Bebek', 1, 100000));
      await repo.saveItem(item(old.id, 'Kopi', 2, 15000, discount: 2000));

      final all = await repo.listBills();
      expect(all.map((s) => s.bill.title), [
        'Makan Makan Kaleyo',
        'Warkop Bigcon',
      ]);
      expect(all.first.total, 115500);
      expect(all.last.total, 28000);

      final found = await repo.listBills(query: 'bigCON');
      expect(found.single.bill.id, old.id);
    },
  );

  test('saveItem inserts then updates, keeping shares', () async {
    final bill = await repo.createBill(title: 'X');
    final p = await repo.addParticipant(
      billId: bill.id,
      displayName: 'Frogiii',
    );
    final saved = await repo.saveItem(item(bill.id, 'Teh', 1, 8000));
    await repo.setItemShares(saved.id, {p.id: 1});

    final updated = await repo.saveItem(
      BillItem(
        id: saved.id,
        billId: bill.id,
        name: 'Teh Manis',
        qty: 2,
        unitPrice: 8000,
      ),
    );
    expect(updated.id, saved.id);
    expect(updated.shares, {p.id: 1});
    expect((await repo.getBill(bill.id)).items.single.name, 'Teh Manis');
  });

  test('removing a participant drops their item shares', () async {
    final bill = await repo.createBill(title: 'X');
    final p = await repo.addParticipant(
      billId: bill.id,
      displayName: 'Frogiii',
    );
    final saved = await repo.saveItem(item(bill.id, 'Teh', 1, 8000));
    await repo.setItemShares(saved.id, {p.id: 1});

    await repo.removeParticipant(p.id);
    expect((await repo.getBill(bill.id)).items.single.shares, isEmpty);
  });

  test('host participant cannot be removed', () async {
    final bill = await repo.createBill(title: 'X');
    final host = (await repo.getBill(bill.id)).host;
    await repo.removeParticipant(host.id);
    expect((await repo.getBill(bill.id)).participants, hasLength(1));
  });

  test('detail.calculate splits using shares', () async {
    final bill = await repo.createBill(title: 'X');
    final p = await repo.addParticipant(
      billId: bill.id,
      displayName: 'Frogiii',
    );
    final steak = await repo.saveItem(item(bill.id, 'Steak', 1, 120000));
    await repo.saveItem(item(bill.id, 'Nasi', 2, 10000));
    await repo.setItemShares(steak.id, {p.id: 1});

    final result = (await repo.getBill(bill.id)).calculate();
    expect(result.shares.map((s) => s.total), [10000, 130000]);
  });

  test('rejects invalid values like the database does', () async {
    final bill = await repo.createBill(title: 'X');
    expect(() => repo.createBill(title: '   '), throwsA(isA<BillsFailure>()));
    expect(
      () => repo.saveItem(item(bill.id, 'X', 0, 100)),
      throwsA(isA<BillsFailure>()),
    );
    expect(
      () => repo.saveItem(item(bill.id, 'X', 1, 100, discount: 101)),
      throwsA(isA<BillsFailure>()),
    );
    final other = await repo.createBill(title: 'Other');
    final stranger = await repo.addParticipant(
      billId: other.id,
      displayName: 'S',
    );
    final saved = await repo.saveItem(item(bill.id, 'X', 1, 100));
    expect(
      () => repo.setItemShares(saved.id, {stranger.id: 1}),
      throwsA(isA<BillsFailure>()),
    );
  });

  test('other users cannot see or change the bill', () async {
    final bill = await repo.createBill(title: 'Private');
    current = budi;
    expect(await repo.listBills(), isEmpty);
    expect(() => repo.getBill(bill.id), throwsA(isA<BillsFailure>()));
    expect(
      () => repo.addParticipant(billId: bill.id, displayName: 'Hack'),
      throwsA(isA<BillsFailure>()),
    );
    expect(() => repo.deleteBill(bill.id), throwsA(isA<BillsFailure>()));
  });

  test('deleteBill removes the bill and its rows', () async {
    final bill = await repo.createBill(title: 'X');
    await repo.saveItem(item(bill.id, 'Teh', 1, 8000));
    await repo.deleteBill(bill.id);
    expect(await repo.listBills(), isEmpty);
    expect(() => repo.getBill(bill.id), throwsA(isA<BillsFailure>()));
  });

  test('requires a signed-in user', () async {
    current = null;
    expect(() => repo.listBills(), throwsA(isA<BillsFailure>()));
  });
}
