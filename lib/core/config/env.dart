/// Compile-time configuration, passed with `--dart-define` (or
/// `--dart-define-from-file=env.json`).
///
/// When the Supabase values are empty the app falls back to an in-memory
/// auth repository, so the UI can be developed without a backend.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
