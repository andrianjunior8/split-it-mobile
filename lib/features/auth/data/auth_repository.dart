import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env.dart';
import 'app_user.dart';

/// Thrown with a message that is safe to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  });
  Future<void> updateProfile({required String name, File? avatar});
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.hasSupabase) {
    return SupabaseAuthRepository(sb.Supabase.instance.client);
  }
  final repo = InMemoryAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// The signed-in user, updated on login, logout and profile changes.
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final auth = ref.watch(authRepositoryProvider);
  yield auth.currentUser;
  yield* auth.authStateChanges();
});

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  static const _avatarBucket = 'avatars';

  @override
  AppUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((e) => _map(e.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) => _guard(() async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': username.trim()},
    );
    if (res.session == null) {
      throw const AuthFailure(
        'Check your email to confirm your account, then log in.',
      );
    }
  });

  @override
  Future<void> updateProfile({required String name, File? avatar}) =>
      _guard(() async {
        final user = _client.auth.currentUser;
        if (user == null) throw const AuthFailure('You are not logged in.');

        String? avatarUrl;
        if (avatar != null) {
          final path = '${user.id}/avatar.jpg';
          await _client.storage
              .from(_avatarBucket)
              .upload(
                path,
                avatar,
                fileOptions: const sb.FileOptions(upsert: true),
              );
          avatarUrl = _client.storage.from(_avatarBucket).getPublicUrl(path);
        }

        await _client.auth.updateUser(
          sb.UserAttributes(
            data: {'full_name': name.trim(), 'avatar_url': ?avatarUrl},
          ),
        );
      });

  @override
  Future<void> signOut() => _client.auth.signOut();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    } on sb.StorageException catch (e) {
      throw AuthFailure('Failed to upload photo: ${e.message}');
    }
  }

  static AppUser? _map(sb.User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      username: meta['username'] as String?,
      name: meta['full_name'] as String?,
      avatarUrl: meta['avatar_url'] as String?,
    );
  }
}

/// Offline stand-in used when Supabase is not configured.
/// Any email/password works; nothing survives an app restart.
class InMemoryAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  final _accounts = <String, ({String password, AppUser user})>{};
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _latency();
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthFailure('Incorrect Username or Password');
    }
    _set(account.user);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await _latency();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('An account with this email already exists.');
    }
    final user = AppUser(
      id: 'local-${_accounts.length + 1}',
      email: key,
      username: username.trim(),
    );
    _accounts[key] = (password: password, user: user);
    _set(user);
  }

  @override
  Future<void> updateProfile({required String name, File? avatar}) async {
    final user = _current;
    if (user == null) throw const AuthFailure('You are not logged in.');
    await _latency();
    final updated = user.copyWith(name: name.trim(), avatarUrl: avatar?.path);
    _accounts[user.email] = (
      password: _accounts[user.email]!.password,
      user: updated,
    );
    _set(updated);
  }

  @override
  Future<void> signOut() async => _set(null);

  void _set(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  void dispose() => _controller.close();
}
