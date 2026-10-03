import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/feedback.dart';
import '../bills/data/bills_repository.dart';
import '../bills/domain/bill.dart';
import '../bills/domain/bill_detail.dart';
import '../bills/presentation/bills_providers.dart';

/// Done bills open on their summary; drafts continue at the first step.
void openBill(BuildContext context, BillSummary summary) {
  final id = summary.bill.id;
  context.push(
    summary.bill.status == BillStatus.done
        ? Routes.billSummary(id)
        : Routes.billSplitters(id),
  );
}

/// Asks for a title, creates the bill and opens its first step.
Future<void> startNewBill(BuildContext context, WidgetRef ref) async {
  final title = await promptText(
    context,
    title: 'New Split Bill',
    hint: 'Ex: Makan Makan Kaleyo',
    submitLabel: 'Create',
  );
  if (title == null || !context.mounted) return;

  try {
    final bill = await ref
        .read(billsRepositoryProvider)
        .createBill(title: title);
    invalidateBillLists(ref);
    if (context.mounted) context.push(Routes.billSplitters(bill.id));
  } on BillsFailure catch (e) {
    if (context.mounted) showError(context, e);
  }
}
