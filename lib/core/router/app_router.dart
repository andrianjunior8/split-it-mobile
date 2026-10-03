import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/home/placeholder_tab.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/split_bill/menu_screen.dart';
import '../../features/split_bill/share/share_bill_screen.dart';
import '../../features/split_bill/split_bill_tab.dart';
import '../../features/split_bill/splitters_screen.dart';
import '../../features/split_bill/summary_screen.dart';
import 'auth_redirect.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = _StreamListenable(auth.authStateChanges());

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(location: state.matchedLocation, user: auth.currentUser),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: Routes.bill,
        builder: (_, state) =>
            SplittersScreen(billId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (_, state) =>
                MenuScreen(billId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'summary',
            builder: (_, state) =>
                SummaryScreen(billId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'share',
            builder: (_, state) =>
                ShareBillScreen(billId: state.pathParameters['id']!),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          _tab(Routes.home, const HomeScreen()),
          _tab(Routes.history, const HistoryScreen()),
          _tab(Routes.splitBill, const SplitBillTab()),
          _tab(Routes.travelMode, const PlaceholderTab(title: 'Travel Mode')),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

StatefulShellBranch _tab(String path, Widget page) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => page)],
);

/// Re-runs the router redirect whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
