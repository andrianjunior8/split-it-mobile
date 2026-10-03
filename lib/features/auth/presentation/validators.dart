class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _username = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username is required';
    if (!_username.hasMatch(v.trim())) {
      return '3–20 letters, numbers, "_" or "."';
    }
    return null;
  }

  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}
