import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/search_pill.dart';
import '../bills/presentation/bill_card.dart';
import '../bills/presentation/bills_providers.dart';
import 'recent_searches_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late List<String> _recent = ref.read(recentSearchesRepositoryProvider).load();

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _query = value.trim()),
    );
  }

  Future<void> _remember(String value) async {
    final updated = await ref.read(recentSearchesRepositoryProvider).add(value);
    if (mounted) setState(() => _recent = updated);
  }

  void _useRecent(String value) {
    _debounce?.cancel();
    _controller.text = value;
    setState(() => _query = value);
    _remember(value);
  }

  Future<void> _forget(String value) async {
    final updated = await ref
        .read(recentSearchesRepositoryProvider)
        .remove(value);
    if (mounted) setState(() => _recent = updated);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SearchPill(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                setState(() => _query = v.trim());
                _remember(v);
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: BackLink(onTap: () => context.pop()),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _RecentList(
                    recent: _recent,
                    onTap: _useRecent,
                    onRemove: _forget,
                  )
                : _Results(query: _query, onOpen: () => _remember(_query)),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.recent,
    required this.onTap,
    required this.onRemove,
  });

  final List<String> recent;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          'Recent Searches',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Text(
            'No recent searches.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        for (final q in recent)
          InkWell(
            onTap: () => onTap(q),
            child: Row(
              children: [
                Expanded(child: Text(q, style: text.bodySmall)),
                IconButton(
                  onPressed: () => onRemove(q),
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onOpen});

  final String query;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return switch (ref.watch(billSearchProvider(query))) {
      AsyncData(:final value) when value.isEmpty => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No bills match "$query".', style: muted),
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => BillCard(summary: value[i], onTap: onOpen),
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Search failed: $error', style: muted),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
