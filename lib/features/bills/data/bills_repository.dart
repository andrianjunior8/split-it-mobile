import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/bill.dart';
import '../domain/bill_detail.dart';
import 'in_memory_bills_repository.dart';

/// Thrown with a message that is safe to show to the user.
class BillsFailure implements Exception {
  const BillsFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class BillsRepository {
  /// Newest first. [query] matches the title, case-insensitively.
  Future<List<BillSummary>> listBills({String? query, int limit = 50});

  /// Number of bills the user hosts or takes part in.
  Future<int> countBills();

  Future<BillDetail> getBill(String id);

  /// Creates a bill hosted by the current user; the host is added as the
  /// first participant automatically.
  Future<Bill> createBill({required String title, DateTime? billDate});
  Future<void> updateBill(Bill bill);
  Future<void> deleteBill(String id);

  Future<Participant> addParticipant({
    required String billId,
    required String displayName,
  });
  Future<void> removeParticipant(String participantId);

  /// Inserts when [item] has an empty id, otherwise updates it.
  Future<BillItem> saveItem(BillItem item);
  Future<void> deleteItem(String itemId);

  /// Replaces who shares the item. An empty map means everyone equally.
  Future<void> setItemShares(String itemId, Map<String, int> shares);
}

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseBillsRepository(sb.Supabase.instance.client);
  }
  final auth = ref.watch(authRepositoryProvider);
  return InMemoryBillsRepository(currentUser: () => auth.currentUser);
});

class SupabaseBillsRepository implements BillsRepository {
  SupabaseBillsRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<List<BillSummary>> listBills({String? query, int limit = 50}) =>
      _guard(() async {
        var request = _client.from('bill_summaries').select();
        final q = query?.trim() ?? '';
        if (q.isNotEmpty) {
          request = request.ilike('title', '%${_escapeLike(q)}%');
        }
        final rows = await request
            .order('bill_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(BillSummary.fromJson).toList();
      });

  @override
  Future<int> countBills() =>
      _guard(() => _client.from('bills').count(sb.CountOption.exact));

  @override
  Future<BillDetail> getBill(String id) => _guard(() async {
    final row = await _client
        .from('bills')
        .select(
          '*, participants(*), '
          'bill_items(*, item_shares(participant_id, weight))',
        )
        .eq('id', id)
        .order('created_at', referencedTable: 'participants')
        .order('position', referencedTable: 'bill_items')
        .order('created_at', referencedTable: 'bill_items')
        .maybeSingle();
    if (row == null) throw const BillsFailure('Bill not found.');

    final participants = (row['participants'] as List)
        .cast<Map<String, dynamic>>()
        .map(Participant.fromJson);
    return BillDetail(
      bill: Bill.fromJson(row),
      participants: [
        ...participants.where((p) => p.isHost),
        ...participants.where((p) => !p.isHost),
      ],
      items: (row['bill_items'] as List)
          .cast<Map<String, dynamic>>()
          .map(BillItem.fromJson)
          .toList(),
    );
  });

  @override
  Future<Bill> createBill({required String title, DateTime? billDate}) =>
      _guard(() async {
        final draft = Bill(
          id: '',
          hostId: '',
          title: title.trim(),
          billDate: billDate ?? DateTime.now(),
        );
        final row = await _client
            .from('bills')
            .insert(draft.toJson())
            .select()
            .single();
        return Bill.fromJson(row);
      });

  @override
  Future<void> updateBill(Bill bill) => _guard(
    () => _client.from('bills').update(bill.toJson()).eq('id', bill.id),
  );

  @override
  Future<void> deleteBill(String id) =>
      _guard(() => _client.from('bills').delete().eq('id', id));

  @override
  Future<Participant> addParticipant({
    required String billId,
    required String displayName,
  }) => _guard(() async {
    final row = await _client
        .from('participants')
        .insert({'bill_id': billId, 'display_name': displayName.trim()})
        .select()
        .single();
    return Participant.fromJson(row);
  });

  @override
  Future<void> removeParticipant(String participantId) => _guard(
    () => _client.from('participants').delete().eq('id', participantId),
  );

  @override
  Future<BillItem> saveItem(BillItem item) => _guard(() async {
    final table = _client.from('bill_items');
    final row = item.id.isEmpty
        ? await table
              .insert({...item.toJson(), 'bill_id': item.billId})
              .select('*, item_shares(participant_id, weight)')
              .single()
        : await table
              .update(item.toJson())
              .eq('id', item.id)
              .select('*, item_shares(participant_id, weight)')
              .single();
    return BillItem.fromJson(row);
  });

  @override
  Future<void> deleteItem(String itemId) =>
      _guard(() => _client.from('bill_items').delete().eq('id', itemId));

  @override
  Future<void> setItemShares(String itemId, Map<String, int> shares) => _guard(
    () => _client.rpc(
      'set_item_shares',
      params: {'p_item_id': itemId, 'p_shares': shares},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on sb.PostgrestException catch (e) {
      throw BillsFailure(_message(e));
    }
  }

  static String _message(sb.PostgrestException e) => switch (e.code) {
    '23514' => 'Some values are not allowed (check qty, price and discount).',
    '42501' => "You don't have permission to change this bill.",
    'PGRST116' => 'Not found, or you no longer have access to it.',
    _ => e.message,
  };

  /// Escapes LIKE wildcards so a search for "50%" matches literally.
  static String _escapeLike(String s) =>
      s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
}
