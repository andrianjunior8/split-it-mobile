import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/user_avatar.dart';
import '../bills/domain/bill.dart';
import '../bills/domain/split_calculator.dart';
import '../bills/presentation/bill_editor_controller.dart';
import 'widgets/avatar_stack.dart';
import 'widgets/bill_step_scaffold.dart';
import 'widgets/bill_title_field.dart';

/// Step 3: who pays what, service/tax settings, and finishing the bill.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.billId});

  final String billId;

  BillEditorController _editor(WidgetRef ref) =>
      ref.read(billEditorProvider(billId).notifier);

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _editCharge(
    BuildContext context,
    WidgetRef ref,
    Bill bill, {
    required bool service,
  }) async {
    final value = await promptText(
      context,
      title: service ? 'Service charge (%)' : 'Tax / PB1 (%)',
      hint: service ? 'Ex: 5' : 'Ex: 10',
      initial: bpsToInput(service ? bill.serviceBps : bill.taxBps),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      maxLength: 6,
      validator: (v) =>
          parsePercentToBps(v) == null ? 'Enter a number from 0 to 100' : null,
    );
    if (value == null || !context.mounted) return;
    final bps = parsePercentToBps(value)!;
    await _run(
      context,
      () => _editor(ref).setCharges(
        serviceBps: service ? bps : bill.serviceBps,
        taxBps: service ? bill.taxBps : bps,
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      title: 'Delete this bill?',
      message: 'All splitters and menu items will be deleted too.',
    );
    if (!ok || !context.mounted) return;
    try {
      await _editor(ref).deleteBill();
      if (context.mounted) context.go(Routes.home);
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
      actions: [
        if (canEdit)
          IconButton(
            onPressed: () => _delete(context, ref),
            tooltip: 'Delete bill',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
      ],
      builder: (context, detail) {
        final bill = detail.bill;
        final result = detail.calculate();
        final done = bill.status == BillStatus.done;

        return [
          BillTitleField(billId: billId),
          const SizedBox(height: 12),
          AvatarStack(participants: detail.participants),
          const StepSectionTitle('Charges'),
          _ChargeRow(
            label: 'Service charge',
            value: formatBps(bill.serviceBps),
            onEdit: canEdit
                ? () => _editCharge(context, ref, bill, service: true)
                : null,
          ),
          _ChargeRow(
            label: 'Tax (PB1)',
            value: formatBps(bill.taxBps),
            onEdit: canEdit
                ? () => _editCharge(context, ref, bill, service: false)
                : null,
          ),
          const StepSectionTitle('Each Pays'),
          if (detail.items.isEmpty)
            Text(
              'Add menu items to see the split.',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          else ...[
            for (final share in result.shares)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ShareCard(
                  participant: detail.participants.firstWhere(
                    (p) => p.id == share.participantId,
                  ),
                  share: share,
                ),
              ),
            const SizedBox(height: 8),
            _Totals(result: result),
          ],
          if (canEdit) ...[
            const SizedBox(height: 24),
            done
                ? OutlinedButton(
                    onPressed: () => _run(
                      context,
                      () => _editor(ref).setStatus(BillStatus.draft),
                    ),
                    child: const Text('Reopen bill'),
                  )
                : ElevatedButton(
                    onPressed: detail.items.isEmpty
                        ? null
                        : () => _run(
                            context,
                            () => _editor(ref).setStatus(BillStatus.done),
                          ),
                    child: const Text('Mark as Done'),
                  ),
          ],
        ];
      },
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({required this.label, required this.value, this.onEdit});

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style?.copyWith(fontWeight: FontWeight.w600)),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.participant, required this.share});

  final Participant participant;
  final ParticipantShare share;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final white = text.bodySmall?.copyWith(color: Colors.white);
    final hasCharges = share.service > 0 || share.tax > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          UserAvatar(name: participant.displayName, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.isHost
                      ? '${participant.displayName} (Host)'
                      : participant.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasCharges)
                  Text(
                    'Menu ${formatRupiah(share.subtotal)}'
                    '${share.service > 0 ? ' · Service ${formatRupiah(share.service)}' : ''}'
                    '${share.tax > 0 ? ' · Tax ${formatRupiah(share.tax)}' : ''}',
                    style: white,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rp ${formatRupiah(share.total)}',
            style: text.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.result});

  final SplitResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget row(String label, int amount, {bool bold = false}) {
      final style = bold
          ? text.titleMedium?.copyWith(fontWeight: FontWeight.w700)
          : text.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text('Rp ${formatRupiah(amount)}', style: style),
          ],
        ),
      );
    }

    return Column(
      children: [
        row('Subtotal', result.subtotal),
        if (result.service > 0) row('Service', result.service),
        if (result.tax > 0) row('Tax', result.tax),
        const Divider(),
        row('Total', result.total, bold: true),
      ],
    );
  }
}
