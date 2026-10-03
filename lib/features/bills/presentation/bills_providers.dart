import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bills_repository.dart';
import '../domain/bill_detail.dart';
import 'bill_history_controller.dart';

/// Latest bills for Home's Recent Activity.
final recentBillsProvider = FutureProvider.autoDispose<List<BillSummary>>(
  (ref) => ref.watch(billsRepositoryProvider).listBills(limit: 5),
);

/// "Bills Splitted" counter on Home.
final billCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(billsRepositoryProvider).countBills(),
);

/// Bills whose title matches [query]; an empty query returns nothing.
final billSearchProvider = FutureProvider.autoDispose
    .family<List<BillSummary>, String>((ref, query) async {
      if (query.trim().isEmpty) return const [];
      return ref.watch(billsRepositoryProvider).listBills(query: query);
    });

/// Call after anything that changes bills so every list reloads.
void invalidateBillLists(WidgetRef ref) {
  ref.invalidate(recentBillsProvider);
  ref.invalidate(billCountProvider);
  ref.invalidate(billSearchProvider);
  ref.invalidate(billHistoryProvider);
}
