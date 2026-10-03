import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../domain/bill.dart';
import '../domain/bill_detail.dart';

final _date = DateFormat('d MMMM yyyy');

/// Blue bill card used on Home (Recent Activity), History and Search.
class BillCard extends StatelessWidget {
  const BillCard({super.key, required this.summary, this.onTap});

  final BillSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bill = summary.bill;
    final done = bill.status == BillStatus.done;

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bill.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _date.format(bill.billDate),
                    style: text.labelSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    done ? 'Done' : 'Draft',
                    style: text.labelSmall?.copyWith(
                      color: done ? AppColors.success : AppColors.mint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(summary.total),
                style: text.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
