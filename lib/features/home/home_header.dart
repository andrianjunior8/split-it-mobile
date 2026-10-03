import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/header_curves.dart';
import '../../core/widgets/user_avatar.dart';

/// Blue rounded header with decorative white curves, greeting and avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.onSettings,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        color: AppColors.primary,
        height: 190 + topInset,
        child: Stack(
          children: [
            const Positioned.fill(child: HeaderCurves()),
            Positioned(
              top: topInset + 4,
              right: 8,
              child: IconButton(
                onPressed: onSettings,
                tooltip: 'Settings',
                icon: const Icon(Icons.settings, color: Colors.white),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Hello, ',
                            children: [
                              TextSpan(
                                text: name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Have a Great Day!',
                          style: text.labelSmall?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: UserAvatar(
                        name: name,
                        imageUrl: avatarUrl,
                        size: 52,
                        cornerRadius: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
