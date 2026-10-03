import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/features/auth/data/app_user.dart';
import 'package:splitit/features/bills/data/bills_repository.dart';
import 'package:splitit/features/bills/data/in_memory_bills_repository.dart';
import 'package:splitit/features/bills/domain/bill_detail.dart';
import 'package:splitit/features/bills/presentation/bill_history_controller.dart';

/// Fails the next listBills call when [failNext] is set.
class FlakyRepo extends InMemoryBillsRepository {
  FlakyRepo() : super(currentUser: () => user);

  static const user = AppUser(id: 'u1', email: 'a@x.com', name: 'A');
  bool failNext = false;
  int calls = 0;

  @override
  Future<List<BillSummary>> listBills({
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    calls++;
    if (failNext) {
      failNext = false;
      throw const BillsFailure('offline');
    }
    return super.listBills(query: query, limit: limit, offset: offset);
  }
}

void main() {
  late FlakyRepo repo;
  late ProviderContainer container;

  setUp(() async {
    repo = FlakyRepo();
    // 45 bills, one per day, so the newest is "bill 44".
    for (var i = 0; i < 45; i++) {
      await repo.createBill(
        title: 'bill $i',
        billDate: DateTime(2025, 1, 1).add(Duration(days: i)),
      );
    }
    container = ProviderContainer(
      overrides: [billsRepositoryProvider.overrideWithValue(repo)],
    );
    // Keep the autoDispose provider alive for the whole test.
    container.listen(billHistoryProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  BillHistory read() => container.read(billHistoryProvider).requireValue;
  BillHistoryController controller() =>
      container.read(billHistoryProvider.notifier);

  test('pages through all bills newest first, without duplicates', () async {
    await container.read(billHistoryProvider.future);
    expect(read().bills, hasLength(20));
    expect(read().bills.first.bill.title, 'bill 44');
    expect(read().hasMore, isTrue);

    await controller().loadMore();
    await controller().loadMore();
    final titles = read().bills.map((s) => s.bill.title).toList();
    expect(titles, hasLength(45));
    expect(titles.toSet(), hasLength(45));
    expect(titles.last, 'bill 0');
    expect(read().hasMore, isFalse);

    final callsBefore = repo.calls;
    await controller().loadMore();
    expect(
      repo.calls,
      callsBefore,
      reason: 'no request once everything is loaded',
    );
  });

  test('concurrent loadMore calls fetch the next page only once', () async {
    await container.read(billHistoryProvider.future);
    final callsBefore = repo.calls;
    await Future.wait([controller().loadMore(), controller().loadMore()]);
    expect(repo.calls, callsBefore + 1);
    expect(read().bills, hasLength(40));
  });

  test(
    'a failed page keeps loaded bills and only retries on request',
    () async {
      await container.read(billHistoryProvider.future);
      repo.failNext = true;
      await controller().loadMore();
      expect(read().bills, hasLength(20));
      expect(read().loadMoreError, isA<BillsFailure>());

      final callsBefore = repo.calls;
      await controller().loadMore();
      expect(repo.calls, callsBefore, reason: 'scrolling must not auto-retry');

      await controller().loadMore(retry: true);
      expect(read().bills, hasLength(40));
      expect(read().loadMoreError, isNull);
    },
  );
}
