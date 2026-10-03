import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class SplitItLogo extends StatelessWidget {
  const SplitItLogo({super.key, this.size = 40, this.color = AppColors.teal});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'SplitIt',
      style: GoogleFonts.lexend(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
    );
  }
}
