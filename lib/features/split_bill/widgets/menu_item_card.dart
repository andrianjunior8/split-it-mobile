import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../bills/domain/bill.dart';

const _discountRed = Color(0xFFFF6B6B);

/// Blue menu card from the design: label column on the left, values on the
/// right, discount in red.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.number,
    required this.item,
    required this.participants,
    this.onTap,
  });

  final int number;
  final BillItem item;
  final List<Participant> participants;
  final VoidCallback? onTap;

  String get _sharedBy {
    if (item.shares.isEmpty) return 'Everyone';
    final names = {for (final p in participants) p.id: p.displayName};
    return item.shares.entries
        .map((e) {
          final name = names[e.key] ?? '?';
          return e.value > 1 ? '$name ×${e.value}' : name;
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white);

    TableRow row(
      String label,
      String value, {
      Color? color,
      bool bold = false,
    }) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(
            value,
            style: style?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    );

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Table(
            columnWidths: const {0: FixedColumnWidth(80)},
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              row('No', number.toString().padLeft(3, '0')),
              row('Name', item.name),
              row('Qty', '${item.qty}'),
              row('Price', 'Rp ${formatRupiah(item.unitPrice)}'),
              row(
                'Discount',
                item.discount > 0 ? '-Rp ${formatRupiah(item.discount)}' : '-',
                color: item.discount > 0 ? _discountRed : null,
              ),
              row('Split by', _sharedBy),
              row('Total', 'Rp ${formatRupiah(item.total)}', bold: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big "+" card at the end of the menu list.
class AddMenuCard extends StatelessWidget {
  const AddMenuCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          height: 110,
          child: Center(child: Icon(Icons.add, size: 56, color: Colors.white)),
        ),
      ),
    );
  }
}
