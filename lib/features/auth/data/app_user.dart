class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? username;
  final String? name;
  final String? avatarUrl;

  /// A user who signed up but has not finished (or skipped) the Register step.
  bool get needsProfile => name == null || name!.trim().isEmpty;

  /// Fallback display name used when the Register step is skipped.
  String get defaultName => username ?? email.split('@').first;

  AppUser copyWith({String? name, String? avatarUrl}) => AppUser(
    id: id,
    email: email,
    username: username,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}
