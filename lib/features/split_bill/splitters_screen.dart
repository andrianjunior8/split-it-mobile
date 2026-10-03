import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/user_avatar.dart';
import '../bills/domain/bill.dart';
import '../bills/presentation/bill_editor_controller.dart';
import 'widgets/bill_step_scaffold.dart';
import 'widgets/bill_title_field.dart';

/// Step 1: title, host and the people splitting the bill.
class SplittersScreen extends ConsumerWidget {
  const SplittersScreen({super.key, required this.billId});

  final String billId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await promptText(
      context,
      title: 'Add Splitter',
      hint: 'Name',
      submitLabel: 'Add',
      maxLength: 50,
    );
    if (name == null || !context.mounted) return;
    try {
      await ref.read(billEditorProvider(billId).notifier).addParticipant(name);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Participant p,
  ) async {
    final ok = await confirm(
      context,
      title: 'Remove ${p.displayName}?',
      message: 'Their share of the menu will be split among the others.',
      confirmLabel: 'Remove',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(billEditorProvider(billId).notifier)
          .removeParticipant(p.id);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(isBillHostProvider(billId));
    final text = Theme.of(context).textTheme;

    return BillStepScaffold(
      billId: billId,
      onNext: () => context.push(Routes.billMenu(billId)),
      builder: (context, detail) {
        final others = detail.participants.where((p) => !p.isHost).toList();
        return [
          BillTitleField(billId: billId),
          const SizedBox(height: 20),
          _PersonRow(
            name: detail.host.displayName,
            label: '${detail.host.displayName} (Host Master)',
          ),
          StepSectionTitle(
            'Splitters',
            trailing: canEdit
                ? IconButton(
                    onPressed: () => _add(context, ref),
                    tooltip: 'Add splitter',
                    icon: const Icon(Icons.add_circle_outline),
                  )
                : null,
          ),
          if (others.isEmpty && !canEdit)
            Text(
              'No other splitters.',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          for (final p in others)
            _PersonRow(
              name: p.displayName,
              label: p.displayName,
              trailing: canEdit
                  ? IconButton(
                      onPressed: () => _remove(context, ref, p),
                      tooltip: 'Remove ${p.displayName}',
                      icon: const Icon(Icons.delete_outline),
                    )
                  : null,
            ),
          if (canEdit)
            InkWell(
              onTap: () => _add(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: const _PersonRow(
                name: '',
                label: '....',
                placeholder: true,
              ),
            ),
        ];
      },
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.label,
    this.trailing,
    this.placeholder = false,
  });

  final String name;
  final String label;
  final Widget? trailing;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          placeholder
              ? const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.placeholder,
                )
              : UserAvatar(name: name, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
