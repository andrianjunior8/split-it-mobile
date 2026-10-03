import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/onboarding_repository.dart';

final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>(
  (ref) => RecentSearchesRepository(ref.watch(sharedPreferencesProvider)),
);

/// The last few bill searches, newest first, stored on the device.
class RecentSearchesRepository {
  RecentSearchesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'recent_searches';
  static const maxEntries = 5;

  List<String> load() => _prefs.getStringList(_key) ?? const [];

  /// Moves [query] to the top, de-duplicated case-insensitively.
  Future<List<String>> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return load();
    final updated = [
      q,
      ...load().where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(maxEntries).toList();
    await _prefs.setStringList(_key, updated);
    return updated;
  }

  Future<List<String>> remove(String query) async {
    final updated = load().where((e) => e != query).toList();
    await _prefs.setStringList(_key, updated);
    return updated;
  }
}
