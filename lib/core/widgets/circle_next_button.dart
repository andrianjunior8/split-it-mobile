import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CircleNextButton extends StatelessWidget {
  const CircleNextButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton.filled(
        onPressed: loading ? null : onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.tealLight,
          disabledBackgroundColor: AppColors.tealLight.withValues(alpha: 0.6),
        ),
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ),
    );
  }
}
