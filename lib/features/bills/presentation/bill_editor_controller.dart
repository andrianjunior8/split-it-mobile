import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/bills_repository.dart';
import '../domain/bill.dart';
import '../domain/bill_detail.dart';
import 'bills_providers.dart';

final billEditorProvider = AsyncNotifierProvider.autoDispose
    .family<BillEditorController, BillDetail, String>(BillEditorController.new);

/// Whether the signed-in user hosts this bill (only the host may edit).
final isBillHostProvider = Provider.autoDispose.family<bool, String>((
  ref,
  billId,
) {
  final userId = ref.watch(currentUserProvider).value?.id;
  final hostId = ref.watch(billEditorProvider(billId)).value?.bill.hostId;
  return userId != null && userId == hostId;
});

/// Loads one bill and applies edits to it. Every edit goes to the
/// repository first, then the bill is reloaded, so the screen always shows
/// what is actually stored. Failures are rethrown as [BillsFailure] for the
/// UI to show; the last good state is kept.
class BillEditorController
    extends AutoDisposeFamilyAsyncNotifier<BillDetail, String> {
  BillsRepository get _repo => ref.read(billsRepositoryProvider);
  BillDetail get _current => state.requireValue;

  @override
  Future<BillDetail> build(String billId) =>
      ref.watch(billsRepositoryProvider).getBill(billId);

  Future<void> _mutate(Future<void> Function(BillsRepository repo) edit) async {
    await edit(_repo);
    state = AsyncData(await _repo.getBill(arg));
    _invalidateLists();
  }

  void _invalidateLists() {
    for (final p in billListProviders) {
      ref.invalidate(p);
    }
  }

  Future<void> rename(String title) async {
    final bill = _current.bill;
    if (title.trim() == bill.title) return;
    await _mutate((r) => r.updateBill(bill.copyWith(title: title.trim())));
  }

  Future<void> setCharges({required int serviceBps, required int taxBps}) =>
      _mutate(
        (r) => r.updateBill(
          _current.bill.copyWith(serviceBps: serviceBps, taxBps: taxBps),
        ),
      );

  Future<void> setStatus(BillStatus status) =>
      _mutate((r) => r.updateBill(_current.bill.copyWith(status: status)));

  Future<void> addParticipant(String name) =>
      _mutate((r) => r.addParticipant(billId: arg, displayName: name));

  Future<void> removeParticipant(String participantId) =>
      _mutate((r) => r.removeParticipant(participantId));

  /// Inserts or updates [item] (empty id = new, appended at the end) and
  /// sets who shares it. Empty [shares] = everyone equally.
  Future<void> saveItem(BillItem item, Map<String, int> shares) =>
      _mutate((r) async {
        final toSave = item.id.isNotEmpty
            ? item
            : BillItem(
                id: '',
                billId: arg,
                name: item.name,
                qty: item.qty,
                unitPrice: item.unitPrice,
                discount: item.discount,
                position: _nextPosition(),
              );
        final saved = await r.saveItem(toSave);
        await r.setItemShares(saved.id, shares);
      });

  int _nextPosition() => _current.items.fold(
    0,
    (max, i) => i.position >= max ? i.position + 1 : max,
  );

  Future<void> deleteItem(String itemId) =>
      _mutate((r) => r.deleteItem(itemId));

  /// Deletes the whole bill. The caller should navigate away afterwards.
  Future<void> deleteBill() async {
    await _repo.deleteBill(arg);
    _invalidateLists();
  }
}
