import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/search_pill.dart';
import '../auth/data/auth_repository.dart';
import '../bills/presentation/bill_card.dart';
import '../bills/presentation/bills_providers.dart';
import 'home_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    invalidateBillLists(ref);
    await Future.wait([
      ref.read(recentBillsProvider.future),
      ref.read(billCountProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final text = Theme.of(context).textTheme;
    final sectionTitle = text.titleLarge?.copyWith(fontWeight: FontWeight.w500);
    final label = text.bodySmall?.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(Routes.splitBill),
        backgroundColor: AppColors.tealLight,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'New bill',
        child: const Icon(Icons.add, size: 36),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeHeader(
              name: user?.name ?? '',
              avatarUrl: user?.avatarUrl,
              onSettings: () => context.push(Routes.settings),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchPill(onTap: () => context.push(Routes.search)),
                  const SizedBox(height: 20),
                  Text('Overview', style: sectionTitle),
                  const SizedBox(height: 12),
                  Text('Bills Splitted', style: label),
                  const SizedBox(height: 8),
                  const _BillCountBox(),
                  const SizedBox(height: 20),
                  Text('Recent Activity', style: label),
                  const SizedBox(height: 8),
                  const _RecentActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillCountBox extends ConsumerWidget {
  const _BillCountBox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(billCountProvider);
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: switch (count) {
        AsyncData(:final value) => Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        AsyncError() => const Icon(Icons.error_outline, color: Colors.white),
        _ => const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      },
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(recentBillsProvider);
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return switch (bills) {
      AsyncData(:final value) when value.isEmpty => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No bills yet. Tap + to split your first bill.',
          style: muted,
        ),
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final summary in value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BillCard(summary: summary),
            ),
        ],
      ),
      AsyncError(:final error) => Row(
        children: [
          Expanded(child: Text('Could not load bills: $error', style: muted)),
          TextButton(
            onPressed: () => ref.invalidate(recentBillsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
