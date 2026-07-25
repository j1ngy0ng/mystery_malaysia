class MissionRecommendation {
  const MissionRecommendation({
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

  final String title;
  final String briefing;
  final String matchReason;
  final String duration;
  final String budget;
  final String difficulty;
  final int stops;
  final int colorValue;
  final String iconKey;
}
