import 'package:flutter/material.dart';

import '../../../core/widgets/user_avatar.dart';
import '../../bills/domain/bill.dart';

/// Row of overlapping splitter avatars shown under the bill title.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.participants, this.max = 6});

  final List<Participant> participants;
  final int max;

  static const _size = 32.0;
  static const _step = 24.0;

  @override
  Widget build(BuildContext context) {
    final shown = participants.take(max).toList();
    final extra = participants.length - shown.length;
    return SizedBox(
      height: _size,
      child: Stack(
        children: [
          for (final (i, p) in shown.indexed)
            Positioned(
              left: i * _step,
              child: Tooltip(
                message: p.displayName,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: UserAvatar(name: p.displayName, size: _size - 3),
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * _step + 8,
              top: 8,
              child: Text(
                '+$extra',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
        ],
      ),
    );
  }
}
