import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the instance loaded at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(sharedPreferencesProvider)),
);

class OnboardingRepository {
  OnboardingRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'onboarding_seen';

  bool get hasSeen => _prefs.getBool(_key) ?? false;

  Future<void> markSeen() => _prefs.setBool(_key, true);
}
