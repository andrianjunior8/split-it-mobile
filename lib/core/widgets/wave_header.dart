import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Blue gradient header with a curved bottom edge, used on the auth screens.
class WaveHeader extends StatelessWidget {
  const WaveHeader({super.key, this.height = 110});

  final double height;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height + topInset,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 20)
      ..quadraticBezierTo(w * 0.25, h, w * 0.5, h - 6)
      ..quadraticBezierTo(w * 0.8, h - 14, w, h - 30)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
