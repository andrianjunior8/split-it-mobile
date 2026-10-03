import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/header_curves.dart';
import '../../core/widgets/search_pill.dart';
import '../bills/presentation/bill_card.dart';
import '../bills/presentation/bill_history_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(billHistoryProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: RefreshIndicator(
        // Below the pinned header, not hidden behind it.
        edgeOffset: _HeaderDelegate.minFor(topInset),
        onRefresh: () => ref.refresh(billHistoryProvider.future),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) {
              ref.read(billHistoryProvider.notifier).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  topInset: topInset,
                  onSearch: () => context.push(Routes.search),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              ...switch (history) {
                AsyncData(:final value) => _list(context, ref, value),
                AsyncError(:final error) => [
                  _message(
                    context,
                    'Could not load bills: $error',
                    onRetry: () => ref.invalidate(billHistoryProvider),
                  ),
                ],
                _ => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context, WidgetRef ref, BillHistory h) {
    if (h.bills.isEmpty) {
      return [_message(context, 'No bills yet. Tap + on Home to start one.')];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.separated(
          itemCount: h.bills.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => BillCard(summary: h.bills[i]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Center(
            child: h.loadingMore
                ? const CircularProgressIndicator()
                : h.loadMoreError != null
                ? TextButton(
                    onPressed: () => ref
                        .read(billHistoryProvider.notifier)
                        .loadMore(retry: true),
                    child: const Text('Could not load more. Retry'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }

  Widget _message(BuildContext context, String text, {VoidCallback? onRetry}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Tall blue header with curves that collapses to a slim bar holding just
/// the search box (History Page → History Page 2 in the design).
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.topInset, required this.onSearch});

  final double topInset;
  final VoidCallback onSearch;

  static const _expanded = 170.0;
  static const _collapsed = 64.0;

  static double minFor(double topInset) => _collapsed + topInset;

  @override
  double get maxExtent => _expanded + topInset;

  @override
  double get minExtent => minFor(topInset);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = math.min(1.0, shrinkOffset / (maxExtent - minExtent));
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: ColoredBox(
        color: AppColors.primary,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(opacity: 1 - t, child: const HeaderCurves()),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: SearchPill(onTap: onSearch),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.topInset != topInset || old.onSearch != onSearch;
}
