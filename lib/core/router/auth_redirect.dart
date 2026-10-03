import '../../features/auth/data/app_user.dart';
import 'routes.dart';

const _signedOutRoutes = {Routes.onboarding, Routes.login, Routes.signUp};

/// Route guard, kept free of Flutter so it can be unit tested.
///
/// - Splash always decides for itself.
/// - Signed out: only onboarding / login / sign up are reachable.
/// - Signed in without a profile: forced onto Register.
/// - Signed in with a profile: auth screens bounce to Home.
String? authRedirect({required String location, required AppUser? user}) {
  if (location == Routes.splash) return null;

  if (user == null) {
    return _signedOutRoutes.contains(location) ? null : Routes.login;
  }
  if (user.needsProfile) {
    return location == Routes.register ? null : Routes.register;
  }
  if (_signedOutRoutes.contains(location) || location == Routes.register) {
    return Routes.home;
  }
  return null;
}
