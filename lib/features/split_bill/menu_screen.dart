import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../bills/presentation/bill_editor_controller.dart';
import 'item_editor_sheet.dart';
import 'widgets/avatar_stack.dart';
import 'widgets/bill_step_scaffold.dart';
import 'widgets/bill_title_field.dart';
import 'widgets/menu_item_card.dart';

/// Step 2: the ordered menu items.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(isBillHostProvider(billId));

    return BillStepScaffold(
      billId: billId,
      onNext: () => context.push(Routes.billSummary(billId)),
      builder: (context, detail) => [
        BillTitleField(billId: billId),
        const SizedBox(height: 12),
        AvatarStack(participants: detail.participants),
        const StepSectionTitle('Menu'),
        if (detail.items.isEmpty && !canEdit)
          Text(
            'No menu items.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        for (final (i, item) in detail.items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MenuItemCard(
              number: i + 1,
              item: item,
              participants: detail.participants,
              onTap: canEdit
                  ? () => showItemEditor(
                      context,
                      billId: billId,
                      participants: detail.participants,
                      item: item,
                    )
                  : null,
            ),
          ),
        if (canEdit)
          AddMenuCard(
            onTap: () => showItemEditor(
              context,
              billId: billId,
              participants: detail.participants,
            ),
          ),
      ],
    );
  }
}
