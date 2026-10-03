import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The small "← Back" text button from the design.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Back',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
