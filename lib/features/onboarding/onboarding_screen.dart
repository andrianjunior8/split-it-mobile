import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/circle_next_button.dart';
import 'onboarding_repository.dart';

class _Page {
  const _Page({
    required this.caption,
    required this.title,
    required this.illustration,
  });

  final String caption;
  final String title;
  final Widget illustration;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  // TODO: replace the icon illustrations with the images exported from Figma.
  static const _pages = [
    _Page(
      caption: 'Stop wasting time paying Bills one by one',
      title: "I Know we've been Struggling with Bills",
      illustration: Icon(Icons.point_of_sale, size: 96, color: Colors.white),
    ),
    _Page(
      caption: '',
      title: 'We made it easier to Split The Bill!',
      illustration: _StepsGrid(),
    ),
    _Page(
      caption: 'Splitting never this easy',
      title: "Just input the orders And we'll Calculate it!",
      illustration: Icon(Icons.timer_outlined, size: 96, color: Colors.white),
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingRepositoryProvider).markSeen();
    if (mounted) context.go(Routes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 40),
                      ),
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: 8),
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index
                              ? AppColors.tealDark
                              : AppColors.mint,
                        ),
                      ),
                    const Spacer(),
                    CircleNextButton(onPressed: _next),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(child: Center(child: page.illustration)),
                if (page.caption.isNotEmpty)
                  Text(
                    page.caption,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.title,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Six steps of the flow, shown on the second intro page.
class _StepsGrid extends StatelessWidget {
  const _StepsGrid();

  static const _steps = [
    (Icons.storefront, 'Input Restaurant Name'),
    (Icons.receipt_long, 'Input Bills Quantities and Price'),
    (Icons.group_add, 'Input your Friends or Family'),
    (Icons.call_split, 'Split your Bills'),
    (Icons.history, 'Check Splited Bills'),
    (Icons.share, 'Share splited Bills Image'),
  ];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final (icon, label) in _steps)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: style,
                maxLines: 3,
              ),
            ],
          ),
      ],
    );
  }
}
