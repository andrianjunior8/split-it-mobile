import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/wave_header.dart';
import '../bills/presentation/bill_card.dart';
import '../bills/presentation/bills_providers.dart';
import 'bill_navigation.dart';

/// The Split Bill tab: start a new bill or continue an unfinished one.
class SplitBillTab extends ConsumerWidget {
  const SplitBillTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppColors.textSecondary);
    final drafts = ref.watch(draftBillsProvider);

    return Scaffold(
      body: Column(
        children: [
          const WaveHeader(height: 40),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(draftBillsProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Text(
                    'Split Bill',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => startNewBill(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('New Split Bill'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Unfinished',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...switch (drafts) {
                    AsyncData(:final value) when value.isEmpty => [
                      Text('No unfinished bills.', style: muted),
                    ],
                    AsyncData(:final value) => [
                      for (final s in value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BillCard(
                            summary: s,
                            onTap: () => openBill(context, s),
                          ),
                        ),
                    ],
                    AsyncError(:final error) => [
                      Text('Could not load bills: $error', style: muted),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => ref.invalidate(draftBillsProvider),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                    _ => [
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
