class MissionRecommendation {
  const MissionRecommendation({
    this.id,
    required this.title,
    required this.briefing,
    required this.matchReason,
    required this.duration,
    required this.budget,
    required this.difficulty,
    required this.stops,
    required this.colorValue,
    required this.iconKey,
  });

  final String? id;
  final String title;
  final String briefing;
  final String matchReason;
  final String duration;
  final String budget;
  final String difficulty;
  final int stops;
  final int colorValue;
  final String iconKey;

  factory MissionRecommendation.fromJson(Map<String, dynamic> json) {
    final durationMinutes =
        (json['estimated_duration_minutes'] as num?)?.round() ?? 60;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final duration = hours == 0
        ? '${minutes}m'
        : minutes == 0
        ? '${hours}h'
        : '${hours}h ${minutes}m';
    final rank = (json['recommendation_rank'] as num?)?.round() ?? 1;
    final difficulty = json['difficulty'] as String? ?? 'easy';

    return MissionRecommendation(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Mystery mission',
      briefing: json['story_hook'] as String? ?? '',
      matchReason: json['explanation'] as String? ?? '',
      duration: duration,
      budget: 'RM ${((json['estimated_budget_myr'] as num?) ?? 0).round()}',
      difficulty: '${difficulty[0].toUpperCase()}${difficulty.substring(1)}',
      stops: (json['stops'] as num?)?.round() ?? 1,
      colorValue: const [
        0xFFFF6B6B,
        0xFF12B8A6,
        0xFFFFBF3F,
      ][(rank - 1).clamp(0, 2)],
      iconKey: switch (rank) {
        2 => 'forest',
        3 => 'food',
        _ => 'lantern',
      },
    );
  }
}
