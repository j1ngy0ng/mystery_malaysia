import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/mission_discovery/mission_recommendation.dart';

void main() {
  test('parses non-revealing previews for all three mystery stops', () {
    final mission = MissionRecommendation.fromJson({
      'id': 'mission-1',
      'title': 'Threads of the City',
      'story_hook': 'Follow three hidden stories.',
      'explanation': 'Fits the selected constraints.',
      'estimated_duration_minutes': 210,
      'estimated_budget_myr': 80,
      'difficulty': 'moderate',
      'recommendation_rank': 1,
      'stops': 3,
      'stop_previews': [
        'A heritage-focused stop.',
        'A green outdoor stop.',
        'A local craft stop.',
      ],
    });

    expect(mission.duration, '3h 30m');
    expect(mission.difficulty, 'Moderate');
    expect(mission.stopPreviews, hasLength(3));
    expect(mission.stopPreviews.join(' '), isNot(contains('destination name')));
  });
}
