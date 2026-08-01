class UserProfile {
  const UserProfile({
    required this.name,
    required this.username,
    required this.email,
    required this.homeState,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String name;
  final String username;
  final String email;
  final String homeState;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? avatarUrl;

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
      gender: json['gender'] as String?,
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? homeState,
    String? gender,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      homeState: homeState ?? this.homeState,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
