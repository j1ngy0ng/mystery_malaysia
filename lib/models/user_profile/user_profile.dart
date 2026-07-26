class UserProfile {
  const UserProfile({
    required this.name,
    required this.username,
    required this.email,
    required this.homeState,
    required this.level,
    required this.xp,
  });

  final String name;
  final String username;
  final String email;
  final String homeState;
  final int level;
  final int xp;

  factory UserProfile.fromSupabase(
    Map<String, dynamic> json, {
    required String email,
  }) {
    final username = json['username'] as String?;
    return UserProfile(
      name: json['display_name'] as String? ?? 'Explorer',
      username: username == null || username.isEmpty ? '' : '@$username',
      email: email,
      homeState: json['hometown'] as String? ?? 'Not set',
      level: 1,
      xp: 0,
    );
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? homeState,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      homeState: homeState ?? this.homeState,
      level: level,
      xp: xp,
    );
  }
}
