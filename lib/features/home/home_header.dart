import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
            const Positioned.fill(
              child: CustomPaint(painter: _CurvesPainter()),
            ),
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

class _CurvesPainter extends CustomPainter {
  const _CurvesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(-10, h * 0.05)
        ..quadraticBezierTo(w * 0.15, h * 0.35, w * 0.32, h * 0.12)
        ..quadraticBezierTo(w * 0.45, -h * 0.05, w * 0.55, h * 0.1),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, -10)
        ..quadraticBezierTo(w * 0.58, h * 0.25, w * 0.78, h * 0.28)
        ..quadraticBezierTo(w * 0.98, h * 0.3, w + 10, h * 0.12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
