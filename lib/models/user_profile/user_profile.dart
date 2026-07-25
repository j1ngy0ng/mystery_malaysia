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
