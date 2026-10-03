import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/splitit_logo.dart';
import 'onboarding_repository.dart';

/// Logo holds, then fades from teal to a pale mint (First Screen 1 → 3).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final _color = TweenSequence<Color?>([
    TweenSequenceItem(tween: ConstantTween(AppColors.teal), weight: 45),
    TweenSequenceItem(
      tween: ColorTween(begin: AppColors.teal, end: AppColors.tealLight),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: ColorTween(begin: AppColors.tealLight, end: AppColors.mint),
      weight: 30,
    ),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_continue);
  }

  void _continue() {
    if (!mounted) return;
    final seen = ref.read(onboardingRepositoryProvider).hasSeen;
    // The router redirect sends signed-out users from home to login.
    context.go(seen ? Routes.home : Routes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.labelSmall;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _color,
                  builder: (context, _) =>
                      SplitItLogo(size: 44, color: _color.value!),
                ),
              ),
            ),
            Text('from', style: small?.copyWith(fontSize: 9)),
            Text('RSA', style: small?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
