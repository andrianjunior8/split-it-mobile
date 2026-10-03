import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bills_repository.dart';
import '../domain/bill_detail.dart';

class BillHistory {
  const BillHistory({
    required this.bills,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<BillSummary> bills;
  final bool hasMore;
  final bool loadingMore;

  /// Set when fetching the next page failed; the loaded pages stay visible.
  final Object? loadMoreError;
}

final billHistoryProvider =
    AsyncNotifierProvider.autoDispose<BillHistoryController, BillHistory>(
      BillHistoryController.new,
    );

/// All bills, newest first, loaded one page at a time.
class BillHistoryController extends AutoDisposeAsyncNotifier<BillHistory> {
  static const pageSize = 20;

  @override
  Future<BillHistory> build() async {
    final page = await ref
        .watch(billsRepositoryProvider)
        .listBills(limit: pageSize);
    return BillHistory(bills: page, hasMore: page.length == pageSize);
  }

  /// Fetches the next page. After a failure, scrolling no longer retries on
  /// its own; pass [retry] from an explicit user action.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    if (current.loadMoreError != null && !retry) return;

    state = AsyncData(
      BillHistory(bills: current.bills, hasMore: true, loadingMore: true),
    );
    try {
      final next = await ref
          .read(billsRepositoryProvider)
          .listBills(limit: pageSize, offset: current.bills.length);
      state = AsyncData(
        BillHistory(
          bills: [...current.bills, ...next],
          hasMore: next.length == pageSize,
        ),
      );
    } catch (e) {
      state = AsyncData(
        BillHistory(bills: current.bills, hasMore: true, loadMoreError: e),
      );
    }
  }
}
