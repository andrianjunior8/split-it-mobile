import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/wave_header.dart';
import '../auth/data/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _items = [
    'Profile',
    'Privacy',
    'Password',
    'Account',
    'Deactivate or Delete',
    'Member Plus +',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    void comingSoon(String item) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$item is coming soon')));

    return Scaffold(
      body: Column(
        children: [
          const WaveHeader(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackLink(onTap: () => context.pop()),
                ),
                const SizedBox(height: 8),
                Text(
                  'Settings',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in _items)
                  InkWell(
                    onTap: () => comingSoon(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(item, style: text.bodyMedium),
                    ),
                  ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => ref.read(authRepositoryProvider).signOut(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Log out',
                      style: text.bodyMedium?.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
