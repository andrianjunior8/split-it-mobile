import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/core/router/auth_redirect.dart';
import 'package:splitit/core/router/routes.dart';
import 'package:splitit/features/auth/data/app_user.dart';

void main() {
  const newUser = AppUser(id: '1', email: 'a@b.com', username: 'andri');
  const fullUser = AppUser(
    id: '1',
    email: 'a@b.com',
    username: 'andri',
    name: 'Andrian',
  );

  String? redirect(String location, AppUser? user) =>
      authRedirect(location: location, user: user);

  test('splash is never redirected', () {
    expect(redirect(Routes.splash, null), isNull);
    expect(redirect(Routes.splash, fullUser), isNull);
  });

  group('signed out', () {
    test('can reach onboarding, login and sign up', () {
      expect(redirect(Routes.onboarding, null), isNull);
      expect(redirect(Routes.login, null), isNull);
      expect(redirect(Routes.signUp, null), isNull);
    });

    test('is sent to login from protected routes', () {
      expect(redirect(Routes.home, null), Routes.login);
      expect(redirect(Routes.register, null), Routes.login);
    });
  });

  test('signed in without profile is forced onto register', () {
    expect(redirect(Routes.home, newUser), Routes.register);
    expect(redirect(Routes.login, newUser), Routes.register);
    expect(redirect(Routes.register, newUser), isNull);
  });

  group('signed in with profile', () {
    test('auth screens bounce to home', () {
      expect(redirect(Routes.login, fullUser), Routes.home);
      expect(redirect(Routes.signUp, fullUser), Routes.home);
      expect(redirect(Routes.register, fullUser), Routes.home);
      expect(redirect(Routes.onboarding, fullUser), Routes.home);
    });

    test('app tabs are reachable', () {
      expect(redirect(Routes.home, fullUser), isNull);
      expect(redirect(Routes.history, fullUser), isNull);
    });
  });

  test('defaultName falls back to username, then email prefix', () {
    expect(newUser.defaultName, 'andri');
    expect(const AppUser(id: '2', email: 'budi@x.com').defaultName, 'budi');
  });
}
