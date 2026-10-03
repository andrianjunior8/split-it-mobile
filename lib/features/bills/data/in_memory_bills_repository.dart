import '../../auth/data/app_user.dart';
import '../domain/bill.dart';
import '../domain/bill_detail.dart';
import '../domain/split_calculator.dart';
import 'bills_repository.dart';

/// Offline stand-in used when Supabase is not configured. Mirrors the rules
/// of the database (host added automatically, host cannot be removed, only
/// the host can write) so the UI behaves the same in both modes.
class InMemoryBillsRepository implements BillsRepository {
  InMemoryBillsRepository({required AppUser? Function() currentUser})
    : _currentUser = currentUser;

  final AppUser? Function() _currentUser;

  final _bills = <String, Bill>{};
  final _participants =
      <String, Participant>{}; // insertion order = added order
  final _items = <String, BillItem>{};
  final _createdOrder = <String, int>{};
  var _seq = 0;

  String _nextId(String prefix) => '$prefix-${++_seq}';

  AppUser _requireUser() {
    final user = _currentUser();
    if (user == null) throw const BillsFailure('You are not logged in.');
    return user;
  }

  Bill _requireHostedBill(String billId) {
    final user = _requireUser();
    final bill = _bills[billId];
    if (bill == null) throw const BillsFailure('Bill not found.');
    if (bill.hostId != user.id) {
      throw const BillsFailure(
        "You don't have permission to change this bill.",
      );
    }
    return bill;
  }

  bool _canRead(Bill bill, String userId) =>
      bill.hostId == userId ||
      _participants.values.any(
        (p) => p.billId == bill.id && p.userId == userId,
      );

  @override
  Future<List<BillSummary>> listBills({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final user = _requireUser();
    final q = query?.trim().toLowerCase() ?? '';
    final bills =
        _bills.values
            .where((b) => _canRead(b, user.id))
            .where((b) => q.isEmpty || b.title.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) {
            final byDate = b.billDate.compareTo(a.billDate);
            return byDate != 0
                ? byDate
                : _createdOrder[b.id]!.compareTo(_createdOrder[a.id]!);
          });
    return [for (final b in bills.skip(offset).take(limit)) _summary(b)];
  }

  BillSummary _summary(Bill bill) {
    final r = SplitCalculator.calculate(
      // Totals do not depend on who shares what, so one payer is enough.
      participantIds: const ['_'],
      items: [
        for (final i in _itemsOf(bill.id))
          SplitItem(
            id: i.id,
            qty: i.qty,
            unitPrice: i.unitPrice,
            discount: i.discount,
          ),
      ],
      serviceBps: bill.serviceBps,
      taxBps: bill.taxBps,
    );
    return BillSummary(
      bill: bill,
      subtotal: r.subtotal,
      service: r.service,
      tax: r.tax,
    );
  }

  List<BillItem> _itemsOf(String billId) {
    final items = _items.values.where((i) => i.billId == billId).toList();
    final order = {for (final (n, i) in items.indexed) i.id: n};
    return items..sort((a, b) {
      final byPosition = a.position.compareTo(b.position);
      return byPosition != 0
          ? byPosition
          : order[a.id]!.compareTo(order[b.id]!);
    });
  }

  @override
  Future<int> countBills() async {
    final user = _requireUser();
    return _bills.values.where((b) => _canRead(b, user.id)).length;
  }

  @override
  Future<BillDetail> getBill(String id) async {
    final user = _requireUser();
    final bill = _bills[id];
    if (bill == null || !_canRead(bill, user.id)) {
      throw const BillsFailure('Bill not found.');
    }
    final participants = _participants.values.where((p) => p.billId == id);
    return BillDetail(
      bill: bill,
      participants: [
        ...participants.where((p) => p.isHost),
        ...participants.where((p) => !p.isHost),
      ],
      items: _itemsOf(id),
    );
  }

  @override
  Future<Bill> createBill({required String title, DateTime? billDate}) async {
    final user = _requireUser();
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      throw const BillsFailure('Title must be 1–100 characters.');
    }
    final bill = Bill(
      id: _nextId('bill'),
      hostId: user.id,
      title: trimmed,
      billDate: billDate ?? DateTime.now(),
    );
    _bills[bill.id] = bill;
    _createdOrder[bill.id] = _seq;

    final host = Participant(
      id: _nextId('participant'),
      billId: bill.id,
      userId: user.id,
      displayName: user.name ?? user.defaultName,
      isHost: true,
    );
    _participants[host.id] = host;
    return bill;
  }

  @override
  Future<void> updateBill(Bill bill) async {
    final existing = _requireHostedBill(bill.id);
    if (bill.title.trim().isEmpty) {
      throw const BillsFailure('Title must be 1–100 characters.');
    }
    // Same columns the database lets the host update.
    _bills[bill.id] = existing.copyWith(
      title: bill.title.trim(),
      billDate: bill.billDate,
      status: bill.status,
      serviceBps: bill.serviceBps,
      taxBps: bill.taxBps,
    );
  }

  @override
  Future<void> deleteBill(String id) async {
    _requireHostedBill(id);
    _bills.remove(id);
    _participants.removeWhere((_, p) => p.billId == id);
    _items.removeWhere((_, i) => i.billId == id);
  }

  @override
  Future<Participant> addParticipant({
    required String billId,
    required String displayName,
  }) async {
    _requireHostedBill(billId);
    final name = displayName.trim();
    if (name.isEmpty || name.length > 50) {
      throw const BillsFailure('Name must be 1–50 characters.');
    }
    final p = Participant(
      id: _nextId('participant'),
      billId: billId,
      displayName: name,
    );
    _participants[p.id] = p;
    return p;
  }

  @override
  Future<void> removeParticipant(String participantId) async {
    final p = _participants[participantId];
    if (p == null) return;
    _requireHostedBill(p.billId);
    if (p.isHost) return; // the database silently refuses this too
    _participants.remove(participantId);
    for (final item
        in _items.values.where((i) => i.billId == p.billId).toList()) {
      if (item.shares.containsKey(participantId)) {
        _items[item.id] = _withShares(
          item,
          {...item.shares}..remove(participantId),
        );
      }
    }
  }

  @override
  Future<BillItem> saveItem(BillItem item) async {
    _requireHostedBill(item.billId);
    if (item.name.trim().isEmpty ||
        item.qty <= 0 ||
        item.unitPrice < 0 ||
        item.discount < 0 ||
        item.total < 0) {
      throw const BillsFailure(
        'Some values are not allowed (check qty, price and discount).',
      );
    }
    final existing = item.id.isEmpty ? null : _items[item.id];
    if (item.id.isNotEmpty && existing == null) {
      throw const BillsFailure(
        'Not found, or you no longer have access to it.',
      );
    }
    final saved = BillItem(
      id: existing?.id ?? _nextId('item'),
      billId: item.billId,
      name: item.name.trim(),
      qty: item.qty,
      unitPrice: item.unitPrice,
      discount: item.discount,
      position: item.position,
      shares: existing?.shares ?? const {},
    );
    _items[saved.id] = saved;
    return saved;
  }

  @override
  Future<void> deleteItem(String itemId) async {
    final item = _items[itemId];
    if (item == null) return;
    _requireHostedBill(item.billId);
    _items.remove(itemId);
  }

  @override
  Future<void> setItemShares(String itemId, Map<String, int> shares) async {
    final item = _items[itemId];
    if (item == null) throw const BillsFailure('Item not found');
    _requireHostedBill(item.billId);
    for (final MapEntry(:key, :value) in shares.entries) {
      final p = _participants[key];
      if (p == null || p.billId != item.billId || value <= 0) {
        throw const BillsFailure(
          'Some values are not allowed (check qty, price and discount).',
        );
      }
    }
    _items[itemId] = _withShares(item, shares);
  }

  BillItem _withShares(BillItem i, Map<String, int> shares) => BillItem(
    id: i.id,
    billId: i.billId,
    name: i.name,
    qty: i.qty,
    unitPrice: i.unitPrice,
    discount: i.discount,
    position: i.position,
    shares: Map.unmodifiable(shares),
  );
}
