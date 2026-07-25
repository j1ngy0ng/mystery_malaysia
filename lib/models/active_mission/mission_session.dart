enum MissionStatus { active, paused, completed, abandoned }

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
