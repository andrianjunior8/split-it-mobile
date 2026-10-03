import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/splitit_logo.dart';
import '../../bills/domain/bill_detail.dart';

final _date = DateFormat('d MMMM yyyy');

/// Receipt-style card that gets captured as the shared image. Fixed width
/// and its own colors so the image looks the same on every phone.
class BillReceipt extends StatelessWidget {
  const BillReceipt({super.key, required this.detail});

  final BillDetail detail;

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final result = detail.calculate();
    final names = {for (final p in detail.participants) p.id: p};
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppColors.textSecondary);

    Widget money(String label, int amount, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style ?? text.bodySmall)),
          Text('Rp ${formatRupiah(amount)}', style: style ?? text.bodySmall),
        ],
      ),
    );

    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SplitItLogo(size: 22, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  detail.bill.title,
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_date.format(detail.bill.billDate)} · '
                  'Host: ${detail.host.displayName}',
                  style: text.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Each Pays',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final share in result.shares)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            names[share.participantId]!.displayName,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Rp ${formatRupiah(share.total)}',
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Menu',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                for (final item in detail.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.qty}× ${item.name}',
                                style: text.bodySmall,
                              ),
                              Text(
                                [
                                  if (item.discount > 0)
                                    'disc. -${formatRupiah(item.discount)}',
                                  item.shares.isEmpty
                                      ? 'everyone'
                                      : item.shares.keys
                                            .map(
                                              (id) =>
                                                  names[id]?.displayName ?? '?',
                                            )
                                            .join(', '),
                                ].join(' · '),
                                style: muted?.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(formatRupiah(item.total), style: text.bodySmall),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                money('Subtotal', result.subtotal),
                if (result.service > 0)
                  money(
                    'Service ${formatBps(detail.bill.serviceBps)}',
                    result.service,
                  ),
                if (result.tax > 0)
                  money('Tax ${formatBps(detail.bill.taxBps)}', result.tax),
                const SizedBox(height: 4),
                money(
                  'Total',
                  result.total,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Split with SplitIt',
              textAlign: TextAlign.center,
              style: muted?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
