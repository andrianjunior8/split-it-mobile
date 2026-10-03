import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bills_repository.dart';
import '../domain/bill.dart';
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

/// Unfinished bills, shown on the Split Bill tab.
final draftBillsProvider = FutureProvider.autoDispose<List<BillSummary>>(
  (ref) =>
      ref.watch(billsRepositoryProvider).listBills(status: BillStatus.draft),
);

/// Bills whose title matches [query]; an empty query returns nothing.
final billSearchProvider = FutureProvider.autoDispose
    .family<List<BillSummary>, String>((ref, query) async {
      if (query.trim().isEmpty) return const [];
      return ref.watch(billsRepositoryProvider).listBills(query: query);
    });

/// Every provider that shows a list of bills; reload them after any change.
final List<ProviderOrFamily> billListProviders = [
  recentBillsProvider,
  billCountProvider,
  draftBillsProvider,
  billSearchProvider,
  billHistoryProvider,
];

void invalidateBillLists(WidgetRef ref) {
  for (final p in billListProviders) {
    ref.invalidate(p);
  }
}
