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
        'Decode civic stories through a collection shaped by local history.',
        'Follow a shaded wetland trail where migratory birds define the experience.',
        'Watch traditional metalwork techniques take form in a living craft space.',
      ],
      'stop_opening_warnings': [
        'Opening-time warning: Monday: 9:00 AM–5:00 PM.',
        'Opening-time warning: Complete this outdoor stop in daylight.',
        'Opening-time warning: Published hours are unavailable.',
      ],
    });

    expect(mission.duration, '3h 30m');
    expect(mission.difficulty, 'Moderate');
    expect(mission.stopPreviews, hasLength(3));
    expect(mission.stopOpeningWarnings, hasLength(3));
    expect(
      mission.stopOpeningWarnings,
      everyElement(startsWith('Opening-time warning:')),
    );
    expect(mission.stopPreviews.join(' '), isNot(contains('destination name')));
  });
}
