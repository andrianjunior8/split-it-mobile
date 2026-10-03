import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:splitit/core/router/routes.dart';
import 'package:splitit/features/auth/data/app_user.dart';
import 'package:splitit/features/auth/data/auth_repository.dart';
import 'package:splitit/features/bills/data/bills_repository.dart';
import 'package:splitit/features/bills/data/in_memory_bills_repository.dart';
import 'package:splitit/features/bills/domain/bill.dart';
import 'package:splitit/features/split_bill/menu_screen.dart';
import 'package:splitit/features/split_bill/splitters_screen.dart';
import 'package:splitit/features/split_bill/summary_screen.dart';

class FixedAuth extends InMemoryAuthRepository {
  @override
  AppUser? get currentUser =>
      const AppUser(id: 'u1', email: 'a@x.com', name: 'Andrian');
}

void main() {
  testWidgets('host splits a bill end to end', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final auth = FixedAuth();
    final repo = InMemoryBillsRepository(currentUser: () => auth.currentUser);
    final bill = await repo.createBill(title: 'Makan Makan Kaleyo');

    String id(GoRouterState s) => s.pathParameters['id']!;
    final router = GoRouter(
      initialLocation: Routes.billSplitters(bill.id),
      routes: [
        GoRoute(
          path: Routes.bill,
          builder: (_, s) => SplittersScreen(billId: id(s)),
          routes: [
            GoRoute(
              path: 'menu',
              builder: (_, s) => MenuScreen(billId: id(s)),
            ),
            GoRoute(
              path: 'summary',
              builder: (_, s) => SummaryScreen(billId: id(s)),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          billsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: host is listed; add a splitter.
    expect(find.text('Andrian (Host Master)'), findsOneWidget);
    await tester.tap(find.byTooltip('Add splitter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Frogiii');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Frogiii'), findsOneWidget);

    // Step 2: add two menu items.
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);

    Future<void> addItem(
      String name,
      String qty,
      String price, {
      String? onlyFor,
    }) async {
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), name);
      await tester.enterText(fields.at(1), qty);
      await tester.enterText(fields.at(2), price);
      if (onlyFor != null) {
        await tester.tap(find.widgetWithText(FilterChip, onlyFor));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    await addItem('Steak', '1', '120000', onlyFor: 'Frogiii');
    await addItem('Nasi', '2', '10000');
    expect(find.text('Steak'), findsOneWidget);
    expect(find.text('Rp 120.000'), findsWidgets);
    expect(find.text('Frogiii'), findsWidgets); // "Split by" on the steak
    expect(find.text('Everyone'), findsOneWidget); // "Split by" on the rice

    // Step 3: summary shows each person's share.
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(find.text('Each Pays'), findsOneWidget);
    expect(find.text('Rp 10.000'), findsOneWidget); // Andrian: half the rice
    expect(find.text('Rp 130.000'), findsOneWidget); // Frogiii: steak + half
    expect(find.text('Rp 140.000'), findsWidgets); // subtotal and total

    await tester.tap(find.text('Mark as Done'));
    await tester.pumpAndSettle();
    expect(find.text('Reopen bill'), findsOneWidget);
    expect((await repo.getBill(bill.id)).bill.status, BillStatus.done);
  });
}
