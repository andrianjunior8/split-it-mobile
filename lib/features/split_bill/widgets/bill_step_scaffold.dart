import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/back_link.dart';
import '../../../core/widgets/circle_next_button.dart';
import '../../../core/widgets/wave_header.dart';
import '../../bills/domain/bill_detail.dart';
import '../../bills/presentation/bill_editor_controller.dart';

/// Shared frame for the Split Bill steps: wave header, back link, content,
/// and the round "next" button. Handles loading and error states and hands
/// the loaded bill to [builder].
class BillStepScaffold extends ConsumerWidget {
  const BillStepScaffold({
    super.key,
    required this.billId,
    required this.builder,
    this.onNext,
    this.actions = const [],
  });

  final String billId;
  final List<Widget> Function(BuildContext context, BillDetail detail) builder;

  /// Shown as the round arrow button when non-null.
  final VoidCallback? onNext;

  /// Extra widgets placed right of the back link (e.g. a delete button).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(billEditorProvider(billId));

    return Scaffold(
      floatingActionButton: onNext != null && detail.hasValue
          ? CircleNextButton(onPressed: onNext)
          : null,
      body: Column(
        children: [
          const WaveHeader(height: 40),
          Expanded(
            child: switch (detail) {
              AsyncData(:final value) => ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                children: [
                  Row(
                    children: [
                      BackLink(onTap: () => context.pop()),
                      const Spacer(),
                      ...actions,
                    ],
                  ),
                  ...builder(context, value),
                ],
              ),
              AsyncError(:final error) => _Error(
                message: '$error',
                onRetry: () => ref.invalidate(billEditorProvider(billId)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackLink(onTap: () => context.pop()),
          ),
          const Spacer(),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Section label such as "Splitters" or "Menu".
class StepSectionTitle extends StatelessWidget {
  const StepSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
