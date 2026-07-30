enum ParticipantState { ready, waiting, invited }

class MissionParticipant {
  const MissionParticipant({
    required this.userId,
    required this.name,
    required this.initials,
    required this.state,
    required this.isHost,
    required this.colorValue,
  });

  final String userId;
  final String name;
  final String initials;
  final ParticipantState state;
  final bool isHost;
  final int colorValue;

  factory MissionParticipant.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Explorer';
    final words = name.trim().split(RegExp(r'\s+'));
    return MissionParticipant(
      userId: json['user_id'] as String,
      name: name,
      initials: words.take(2).map((word) => word[0].toUpperCase()).join(),
      state: json['ready'] == true
          ? ParticipantState.ready
          : ParticipantState.waiting,
      isHost: json['role'] == 'host',
      colorValue: const [
        0xFFFF6B6B,
        0xFF6C4CE6,
        0xFF12B8A6,
      ][name.hashCode.abs() % 3],
    );
  }
}

class SharedInvitation {
  const SharedInvitation({
    required this.id,
    required this.sessionId,
    required this.title,
  });

  final String id;
  final String sessionId;
  final String title;

  factory SharedInvitation.fromJson(Map<String, dynamic> json) =>
      SharedInvitation(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        title: json['title'] as String? ?? 'Shared mystery mission',
      );
}

class SharedMissionSummary {
  const SharedMissionSummary({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  factory SharedMissionSummary.fromJson(Map<String, dynamic> json) =>
      SharedMissionSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Shared mystery mission',
        status: json['status'] as String? ?? 'waiting',
      );
}
