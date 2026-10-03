import 'package:flutter/material.dart';

/// Decorative white curves drawn over the blue Home / History headers.
/// Sized to the parent; place it with `Positioned.fill`.
class HeaderCurves extends StatelessWidget {
  const HeaderCurves({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _CurvesPainter());
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
