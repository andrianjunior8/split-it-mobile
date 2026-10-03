import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/back_link.dart';
import '../../../core/widgets/wave_header.dart';

/// Shared layout for Login / Sign Up / Register: wave header, optional back
/// link, big centered title, then the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.bottom,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const WaveHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BackLink(onTap: onBack!),
                    ),
                  SizedBox(height: onBack != null ? 40 : 72),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
          if (bottom != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 24, 16),
                child: bottom,
              ),
            ),
        ],
      ),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}
