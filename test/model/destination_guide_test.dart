import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/active_mission/destination_guide.dart';

void main() {
  test('parses the verified destination teaching guide', () {
    final result = ArrivalResult.fromJson({
      'arrived': true,
      'mission_completed': false,
      'completed_stage': 1,
      'next_stage': 2,
      'total_stages': 3,
      'xp_awarded': 100,
      'destination': {
        'name': 'Central Market Kuala Lumpur',
        'state': 'Kuala Lumpur',
        'city': 'Kuala Lumpur',
        'categories': ['Culture', 'History'],
        'facts': ['A heritage market for Malaysian arts and crafts.'],
        'visitor_information': {
          'admission': 'Free entry',
          'cultural_etiquette': ['Ask before photographing people.'],
          'safety_notes': ['Visit during published operating hours.'],
          'educational_source': 'Google Places summary',
          'educational_sources': [
            {
              'title': 'Tourism Malaysia',
              'uri': 'https://www.malaysia.travel/',
            },
          ],
        },
        'accessibility': {'wheelchairAccessibleEntrance': true},
        'opening_hours': {
          'openNow': true,
          'weekdayDescriptions': ['Monday: 10:00 AM – 6:00 PM'],
        },
        'safety_score': 0.86,
      },
      'next_clue': {
        'number': 2,
        'text': 'Find the green heart of the city.',
        'hint': 'Look near a lake.',
      },
    });

    expect(result.arrived, isTrue);
    expect(result.guide?.learningSummary, contains('heritage market'));
    expect(result.guide?.visitorNotes, contains('Admission: Free entry'));
    expect(
      result.guide?.accessibilityNotes,
      contains('Wheelchair Accessible Entrance'),
    );
    expect(result.guide?.weeklyHours, hasLength(1));
    expect(result.guide?.culturalEtiquette, hasLength(1));
    expect(result.guide?.safetyNotes, hasLength(1));
    expect(result.guide?.educationalSources.single.title, 'Tourism Malaysia');
    expect(result.guide?.safetyScore, 0.86);
    expect(result.nextClue?.number, 2);
  });
}
