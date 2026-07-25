enum ParticipantState { ready, nearby, invited }

class MissionParticipant {
  const MissionParticipant({
    required this.name,
    required this.initials,
    required this.state,
    required this.isHost,
    required this.colorValue,
  });

  final String name;
  final String initials;
  final ParticipantState state;
  final bool isHost;
  final int colorValue;
}
