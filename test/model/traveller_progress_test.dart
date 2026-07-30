import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/passport_diary/traveller_progress.dart';

void main() {
  test('shows earned and locked achievements from the passport dashboard', () {
    final progress = TravellerProgress.fromJson({
      'xp': 100,
      'level': 1,
      'level_start_xp': 0,
      'next_level_xp': 500,
      'stats': {
        'completed_missions': 0,
        'visited_destinations': 1,
        'explored_states': 1,
      },
      'stamps': [
        {'place': 'Verified stop', 'state': 'Kuala Lumpur'},
      ],
      'badges': [
        {
          'name': 'First Steps',
          'description': 'Complete your first mystery mission.',
          'earned': false,
        },
        {
          'name': 'Team Spirit',
          'description': 'Complete a shared mystery mission.',
          'earned': true,
        },
      ],
      'diaries': [],
      'newly_unlocked_badges': [],
    });

    expect(progress.stamps, hasLength(1));
    expect(progress.achievements, hasLength(2));
    expect(progress.achievements.first.earned, isFalse);
    expect(progress.achievements.last.earned, isTrue);
  });

  test('builds one mission stamp from three destination pieces', () {
    const stamp = MissionStamp(
      id: 'mission-1',
      pieces: [
        PassportStamp(
          place: 'Stop one',
          state: 'Melaka',
          emoji: '',
          earned: true,
        ),
        PassportStamp(
          place: 'Stop two',
          state: 'Melaka',
          emoji: '',
          earned: true,
        ),
        PassportStamp(
          place: 'Stop three',
          state: 'Melaka',
          emoji: '',
          earned: true,
        ),
      ],
    );

    expect(stamp.earnedPieces, 3);
    expect(stamp.complete, isTrue);
    expect(stamp.name, 'Melaka Mystery Trail');
  });
}
