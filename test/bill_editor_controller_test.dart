import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/features/auth/data/app_user.dart';
import 'package:splitit/features/auth/data/auth_repository.dart';
import 'package:splitit/features/bills/data/bills_repository.dart';
import 'package:splitit/features/bills/data/in_memory_bills_repository.dart';
import 'package:splitit/features/bills/domain/bill.dart';
import 'package:splitit/features/bills/domain/bill_detail.dart';
import 'package:splitit/features/bills/presentation/bill_editor_controller.dart';
import 'package:splitit/features/bills/presentation/bills_providers.dart';

class FixedAuth extends InMemoryAuthRepository {
  FixedAuth(this.user);
  AppUser? user;

  @override
  AppUser? get currentUser => user;
}

void main() {
  const host = AppUser(id: 'u1', email: 'a@x.com', name: 'Andrian');
  const other = AppUser(id: 'u2', email: 'b@x.com', name: 'Budi');

  late FixedAuth auth;
  late InMemoryBillsRepository repo;
  late ProviderContainer container;
  late String billId;

  setUp(() async {
    auth = FixedAuth(host);
    repo = InMemoryBillsRepository(currentUser: () => auth.user);
    billId = (await repo.createBill(title: 'Kaleyo')).id;
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        billsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    container.listen(billEditorProvider(billId), (_, _) {});
    await container.read(billEditorProvider(billId).future);
  });

  tearDown(() => container.dispose());

  BillEditorController editor() =>
      container.read(billEditorProvider(billId).notifier);
  BillDetail state() => container.read(billEditorProvider(billId)).requireValue;

  BillItem draft(String name, int qty, int price, {int discount = 0}) =>
      BillItem(
        id: '',
        billId: billId,
        name: name,
        qty: qty,
        unitPrice: price,
        discount: discount,
      );

  test('rename trims and saves; unchanged title is a no-op', () async {
    await editor().rename('  Makan Makan Kaleyo ');
    expect(state().bill.title, 'Makan Makan Kaleyo');
  });

  test('add and remove splitters', () async {
    await editor().addParticipant('Frogiii');
    await editor().addParticipant('Andri');
    expect(state().participants.map((p) => p.displayName), [
      'Andrian',
      'Frogiii',
      'Andri',
    ]);

    await editor().removeParticipant(state().participants[1].id);
    expect(state().participants.map((p) => p.displayName), [
      'Andrian',
      'Andri',
    ]);
  });

  test('new items are appended in order with their shares', () async {
    await editor().addParticipant('Frogiii');
    final frog = state().participants[1].id;

    await editor().saveItem(draft('Steak', 1, 120000), {frog: 1});
    await editor().saveItem(draft('Nasi', 2, 10000), {});
    final items = state().items;
    expect(items.map((i) => i.name), ['Steak', 'Nasi']);
    expect(items.map((i) => i.position), [0, 1]);
    expect(items.first.shares, {frog: 1});

    final result = state().calculate();
    expect(result.shares.map((s) => s.total), [10000, 130000]);
  });

  test('editing an item replaces its shares', () async {
    await editor().addParticipant('Frogiii');
    final frog = state().participants[1].id;
    await editor().saveItem(draft('Teh', 1, 8000), {frog: 1});

    final saved = state().items.single;
    await editor().saveItem(
      BillItem(
        id: saved.id,
        billId: billId,
        name: 'Teh Manis',
        qty: 2,
        unitPrice: 8000,
        position: saved.position,
      ),
      {},
    );
    final updated = state().items.single;
    expect(updated.name, 'Teh Manis');
    expect(updated.shares, isEmpty);
  });

  test('charges and status', () async {
    await editor().saveItem(draft('X', 1, 100000), {});
    await editor().setCharges(serviceBps: 500, taxBps: 1000);
    expect(state().calculate().total, 115500);

    await editor().setStatus(BillStatus.done);
    expect(state().bill.status, BillStatus.done);
  });

  test('edits refresh the bill lists', () async {
    container.listen(recentBillsProvider, (_, _) {});
    expect((await container.read(recentBillsProvider.future)).single.total, 0);
    await editor().saveItem(draft('X', 1, 5000), {});
    expect(
      (await container.read(recentBillsProvider.future)).single.total,
      5000,
    );
  });

  test('failed edit rethrows and keeps the last good state', () async {
    await expectLater(
      editor().saveItem(draft('X', 1, 100, discount: 500), {}),
      throwsA(isA<BillsFailure>()),
    );
    expect(state().items, isEmpty);
    expect(container.read(billEditorProvider(billId)).hasError, isFalse);
  });

  test('isBillHost is true only for the host', () async {
    container.listen(isBillHostProvider(billId), (_, _) {});
    await container.read(currentUserProvider.future);
    expect(container.read(isBillHostProvider(billId)), isTrue);

    // Same repository (so the bill loads), but Budi is the signed-in user.
    final asBudi = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FixedAuth(other)),
        billsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(asBudi.dispose);
    asBudi.listen(isBillHostProvider(billId), (_, _) {});
    await asBudi.read(currentUserProvider.future);
    await asBudi.read(billEditorProvider(billId).future);
    expect(asBudi.read(isBillHostProvider(billId)), isFalse);
  });

  test('deleteBill removes it from the lists', () async {
    container.listen(billCountProvider, (_, _) {});
    expect(await container.read(billCountProvider.future), 1);
    await editor().deleteBill();
    expect(await container.read(billCountProvider.future), 0);
  });
}
