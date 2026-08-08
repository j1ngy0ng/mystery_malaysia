import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/passport_diary/traveller_progress.dart';

void main() {
  test('shows earned and locked achievements from the passport dashboard', () {
    final progress = TravellerProgress.fromJson({
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
      'eligible_diary_missions': [
        {
          'session_id': 'mission-1',
          'title': 'Lantern Trail',
          'mode': 'solo',
          'completed_at': '2026-08-01T10:00:00Z',
        },
      ],
      'newly_unlocked_badges': [],
    });

    expect(progress.stamps, hasLength(1));
    expect(progress.achievements, hasLength(2));
    expect(progress.achievements.first.earned, isFalse);
    expect(progress.achievements.last.earned, isTrue);
    expect(progress.eligibleDiaryMissions.single.title, 'Lantern Trail');
  });

  test('builds one state mission badge from three destination pieces', () {
    const stamp = MissionStamp(
      id: 'mission-1',
      pieces: [
        PassportStamp(
          place: 'Stop one',
          state: 'Melaka',
          emoji: '',
          earned: true,
          missionTitle: 'The Clocktower Cipher',
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
    expect(stamp.name, 'The Clocktower Cipher');
    expect(stamp.state, 'Melaka');
  });

  test('maps all Malaysian state mission badges to unique codes', () {
    const states = [
      'Johor',
      'Kedah',
      'Kelantan',
      'Melaka',
      'Negeri Sembilan',
      'Pahang',
      'Pulau Pinang',
      'Perak',
      'Perlis',
      'Sabah',
      'Sarawak',
      'Selangor',
      'Terengganu',
      'Kuala Lumpur',
      'Putrajaya',
      'Labuan',
    ];

    expect(states.map(missionBadgeCode).toSet(), hasLength(16));
    expect(missionBadgeCode('Unknown'), 'MYS');
  });

  test('parses crew reflections and a participant-visible shared diary', () {
    final state = GroupDiaryState.fromJson({
      'is_host': true,
      'all_submitted': true,
      'members': [
        {
          'user_id': 'host-1',
          'name': 'Host',
          'role': 'host',
          'is_viewer': true,
          'reflection': 'I enjoyed learning together at every stop.',
        },
        {
          'user_id': 'member-1',
          'name': 'Member',
          'role': 'member',
          'is_viewer': false,
          'reflection': 'The shared clues made the journey memorable.',
        },
      ],
      'diary': {
        'id': 'diary-1',
        'session_id': 'mission-1',
        'title': 'Our Mystery Journey',
        'summary': 'We explored Malaysia together.',
        'diary_type': 'shared',
      },
    });

    expect(state.isHost, isTrue);
    expect(state.allSubmitted, isTrue);
    expect(state.members, hasLength(2));
    expect(state.viewer?.name, 'Host');
    expect(state.diary?.isShared, isTrue);
  });
}
