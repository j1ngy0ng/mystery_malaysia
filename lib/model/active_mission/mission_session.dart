import '../clue_hint/mystery_clue.dart';

enum MissionStatus { waiting, active, paused, completed, abandoned }

MissionStatus missionStatusFromJson(String value) => switch (value) {
  'waiting' => MissionStatus.waiting,
  'paused' => MissionStatus.paused,
  'completed' => MissionStatus.completed,
  'abandoned' => MissionStatus.abandoned,
  _ => MissionStatus.active,
};

class MissionSession {
  const MissionSession({
    required this.title,
    required this.region,
    required this.currentStage,
    required this.totalStages,
    required this.distanceMetres,
    required this.status,
  });

  final String title;
  final String region;
  final int currentStage;
  final int totalStages;
  final int distanceMetres;
  final MissionStatus status;

  double get progress => currentStage / totalStages;

  MissionSession copyWith({
    int? currentStage,
    int? distanceMetres,
    MissionStatus? status,
  }) {
    return MissionSession(
      title: title,
      region: region,
      currentStage: currentStage ?? this.currentStage,
      totalStages: totalStages,
      distanceMetres: distanceMetres ?? this.distanceMetres,
      status: status ?? this.status,
    );
  }
}

class MissionLaunch {
  const MissionLaunch({
    required this.sessionId,
    required this.title,
    required this.region,
    required this.currentStage,
    required this.totalStages,
    required this.clue,
    this.status = MissionStatus.active,
  });

  final String sessionId;
  final String title;
  final String region;
  final int currentStage;
  final int totalStages;
  final MysteryClue clue;
  final MissionStatus status;

  factory MissionLaunch.fromJson(Map<String, dynamic> json) {
    final clue = Map<String, dynamic>.from(json['clue'] as Map);
    return MissionLaunch(
      sessionId: json['session_id'] as String,
      title: json['title'] as String,
      region: json['region'] as String? ?? 'Malaysia',
      currentStage: (json['current_stage'] as num).round(),
      totalStages: (json['total_stages'] as num).round(),
      status: missionStatusFromJson(json['status'] as String? ?? 'active'),
      clue: MysteryClue(
        number: (clue['number'] as num).round(),
        text: clue['text'] as String,
        hint: clue['hint'] as String? ?? '',
        hintRevealed: clue['hint_revealed'] == true,
      ),
    );
  }

  factory MissionLaunch.fromSummary(Map<String, dynamic> json) =>
      MissionLaunch.fromJson(json);
}
