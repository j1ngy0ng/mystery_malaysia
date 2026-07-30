import 'mission_session.dart';

enum MissionHistoryFilter { all, active, paused, completed }

class MissionHistoryItem {
  const MissionHistoryItem({
    required this.sessionId,
    required this.title,
    required this.region,
    required this.dateLabel,
    required this.status,
    required this.currentStage,
    required this.totalStages,
    required this.emoji,
    this.launch,
    this.isShared = false,
  });

  final String sessionId;
  final String title;
  final String region;
  final String dateLabel;
  final MissionStatus status;
  final int currentStage;
  final int totalStages;
  final String emoji;
  final MissionLaunch? launch;
  final bool isShared;

  double get progress => currentStage / totalStages;

  factory MissionHistoryItem.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date'] as String? ?? '')?.toLocal();
    final status = missionStatusFromJson(json['status'] as String? ?? '');
    final hasClue = json['clue'] is Map;
    return MissionHistoryItem(
      sessionId: json['session_id'] as String,
      title: json['title'] as String? ?? 'Mystery mission',
      region: json['region'] as String? ?? 'Malaysia',
      dateLabel: date == null ? '' : '${date.day}/${date.month}/${date.year}',
      status: status,
      currentStage: (json['current_stage'] as num?)?.round() ?? 1,
      totalStages: (json['total_stages'] as num?)?.round() ?? 3,
      emoji: status == MissionStatus.completed ? '🏅' : '🧭',
      launch: hasClue && status != MissionStatus.completed
          ? MissionLaunch.fromSummary(json)
          : null,
      isShared: json['mode'] == 'collaborative',
    );
  }
}
