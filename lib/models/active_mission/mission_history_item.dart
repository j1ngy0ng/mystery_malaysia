import 'mission_session.dart';

class MissionHistoryItem {
  const MissionHistoryItem({
    required this.title,
    required this.region,
    required this.dateLabel,
    required this.status,
    required this.currentStage,
    required this.totalStages,
    required this.emoji,
  });

  final String title;
  final String region;
  final String dateLabel;
  final MissionStatus status;
  final int currentStage;
  final int totalStages;
  final String emoji;

  double get progress => currentStage / totalStages;
}
