import '../../../model/active_mission/app_location.dart';
import '../../../model/active_mission/destination_guide.dart';
import '../../../model/active_mission/mission_session.dart';
import '../../../model/clue_hint/mystery_clue.dart';
import '../../../model/mission_discovery/mission_recommendation.dart';
import '../../../model/user_profile/app_notification.dart';

/// Local responses used only by the installable UI-demo build.
class DemoApiManager {
  DemoApiManager._();

  static final instance = DemoApiManager._();

  final profile = <String, dynamic>{
    'display_name': 'Nur Traveller',
    'username': 'nurtraveller',
    'gender': 'female',
    'date_of_birth': '2002-08-31',
    'phone_number': '+60 12-345 6789',
    'hometown': 'Kuala Lumpur',
  };

  final recommendations = const [
    MissionRecommendation(
      id: 'demo-lantern',
      title: 'The Lantern Keeper’s Trail',
      briefing:
          'Follow cultural signals through craft, riverside stories and a quiet green finale.',
      matchReason:
          'A safe, lesser-known route that fits a relaxed Kuala Lumpur afternoon.',
      duration: '3h 45m',
      durationMinutes: 225,
      budget: 'RM 68',
      difficulty: 'Easy',
      stops: 3,
      colorValue: 0xFFFF6B6B,
      iconKey: 'lantern',
      stopPreviews: [
        'Handmade patterns preserve a riverside craft tradition.',
        'A public landmark tells an overlooked civic story.',
        'A shaded green threshold completes the final cipher.',
      ],
      stopOpeningWarnings: [
        'Open 9:00 AM–5:00 PM; arrive before the final workshop.',
        'Closes at 4:30 PM on demonstration day.',
        'Outdoor stop; daylight visit is recommended.',
      ],
    ),
    MissionRecommendation(
      id: 'demo-river',
      title: 'Echoes Behind the River',
      briefing:
          'Trace overlooked community memories through water, architecture and local art.',
      matchReason:
          'Short travel distances and staffed public attractions suit a first mystery.',
      duration: '4h',
      durationMinutes: 240,
      budget: 'RM 82',
      difficulty: 'Medium',
      stops: 3,
      colorValue: 0xFF12B8A6,
      iconKey: 'forest',
      stopPreviews: [
        'A restored gathering place reveals the city’s relationship with water.',
        'Creative details hide inside a calm cultural courtyard.',
        'The final viewpoint connects old streets with a modern skyline.',
      ],
      stopOpeningWarnings: [
        'Visitor area opens from 10:00 AM.',
        'Last admission is 5:00 PM.',
        'Best experienced before sunset.',
      ],
    ),
    MissionRecommendation(
      id: 'demo-limestone',
      title: 'Secrets of the Limestone',
      briefing:
          'Decode geology, living culture and conservation clues beyond the busiest trail.',
      matchReason:
          'A longer challenge with public access, safety checks and quieter stop timing.',
      duration: '4h 30m',
      durationMinutes: 270,
      budget: 'RM 95',
      difficulty: 'Hard',
      stops: 3,
      colorValue: 0xFFFFBF3F,
      iconKey: 'food',
      stopPreviews: [
        'A geological feature introduces the landscape without the main crowd.',
        'A community-run space explains local stewardship.',
        'A final heritage clue rewards careful observation.',
      ],
      stopOpeningWarnings: [
        'Morning visit recommended for cooler conditions.',
        'Community space closes at 4:00 PM.',
        'Allow 45 minutes before closing.',
      ],
    ),
  ];

  final notifications = <AppNotification>[
    AppNotification(
      id: 'demo-notification-1',
      type: 'mission_invitation',
      title: 'Jessica accepted your invitation',
      body: 'Your registered travel partner joined The Lantern Keeper’s Trail.',
      data: const {'session_id': 'demo-shared'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    AppNotification(
      id: 'demo-notification-2',
      type: 'achievement',
      title: 'Achievement unlocked',
      body: 'You earned the Culture Keeper achievement.',
      data: const {},
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      readAt: DateTime.now().subtract(const Duration(hours: 20)),
    ),
  ];

  Map<String, dynamic> currentMission = {
    'session_id': 'demo-paused',
    'title': 'Cipher of the Valley Escarpment',
    'region': 'Kuala Lumpur',
    'date': '2026-08-03T09:30:00Z',
    'status': 'paused',
    'current_stage': 2,
    'total_stages': 3,
    'mode': 'solo',
    'clue': {
      'number': 2,
      'text':
          'Find the riverside cultural centre where visitors can watch artisans shape Malaysia’s famous pewter, near Jalan Usahawan.',
      'hint':
          'Its name begins with “Royal”, and its visitor centre celebrates Selangor pewter craft.',
      'hint_revealed': false,
    },
  };

  String sharedStatus = 'waiting';
  bool viewerReady = false;
  final sharedMembers = <Map<String, dynamic>>[
    {
      'user_id': 'demo-user',
      'name': 'Nur Traveller',
      'role': 'host',
      'ready': true,
    },
    {
      'user_id': 'demo-jessica',
      'name': 'Jessica',
      'role': 'guest',
      'ready': false,
    },
    {'user_id': 'demo-amir', 'name': 'Amir', 'role': 'guest', 'ready': false},
  ];

  List<AppNotification> loadNotifications() => List.of(notifications);

  void markNotificationRead(String id, DateTime readAt) {
    final index = notifications.indexWhere((item) => item.id == id);
    if (index >= 0) {
      notifications[index] = notifications[index].markRead(readAt);
    }
  }

  void markAllNotificationsRead(DateTime readAt) {
    for (var index = 0; index < notifications.length; index++) {
      notifications[index] = notifications[index].markRead(readAt);
    }
  }

  void updateProfile({
    required String displayName,
    required String username,
    String? gender,
    String? phoneNumber,
  }) {
    profile
      ..['display_name'] = displayName.trim()
      ..['username'] = username.trim()
      ..['gender'] = gender
      ..['phone_number'] = phoneNumber;
  }

  MissionLaunch selectMission(String recommendationId) {
    final mission = recommendations.firstWhere(
      (item) => item.id == recommendationId,
      orElse: () => recommendations.first,
    );
    currentMission = {
      'session_id': 'demo-selected',
      'title': mission.title,
      'region': 'Kuala Lumpur',
      'date': DateTime.now().toUtc().toIso8601String(),
      'status': 'ready',
      'current_stage': 1,
      'total_stages': 3,
      'mode': 'solo',
      'clue': {
        'number': 1,
        'text':
            'Find the riverside cultural centre where visitors can watch artisans shape Malaysia’s famous pewter, near Jalan Usahawan.',
        'hint':
            'Its name begins with “Royal”, and it celebrates Selangor pewter craft.',
        'hint_revealed': false,
      },
    };
    return MissionLaunch.fromJson(currentMission);
  }

  MissionLaunch startSelectedMission(String sessionId) {
    currentMission['status'] = 'active';
    return MissionLaunch.fromJson(currentMission);
  }

  Map<String, dynamic> missionControl(Map<String, dynamic> body) {
    final action = body['action'];
    if (action == 'current') return {'mission': currentMission};
    if (action == 'history') {
      return {
        'missions': [
          currentMission,
          {
            'session_id': 'demo-ready',
            'title': 'The Lantern Keeper’s Trail',
            'region': 'Kuala Lumpur',
            'date': '2026-08-12T09:30:00Z',
            'status': 'ready',
            'current_stage': 1,
            'total_stages': 3,
            'mode': 'solo',
            'clue': currentMission['clue'],
          },
          {
            'session_id': 'demo-active',
            'title': 'Echoes of Old Kuala Lumpur',
            'region': 'Kuala Lumpur',
            'date': '2026-08-01T09:30:00Z',
            'status': 'active',
            'current_stage': 1,
            'total_stages': 3,
            'mode': 'solo',
            'clue': currentMission['clue'],
          },
          {
            'session_id': 'demo-completed-solo',
            'title': 'Whispers of the Jetty',
            'region': 'Selangor',
            'date': '2026-07-20T09:30:00Z',
            'status': 'completed',
            'current_stage': 3,
            'total_stages': 3,
            'mode': 'solo',
          },
        ],
      };
    }
    if (action == 'pause' || action == 'resume' || action == 'abandon') {
      currentMission['status'] = switch (action) {
        'pause' => 'paused',
        'resume' => 'active',
        _ => 'abandoned',
      };
      return {'status': currentMission['status']};
    }
    if (action == 'proximity') return {'level': 'reached'};
    if (action == 'hint') {
      return {
        'hint':
            'Its name begins with “Royal”, and it celebrates Selangor pewter craft.',
        'already_used': false,
      };
    }
    return {'status': currentMission['status']};
  }

  ArrivalResult confirmArrival(String sessionId, AppLocation location) {
    currentMission
      ..['status'] = 'active'
      ..['current_stage'] = 3
      ..['clue'] = {
        'number': 3,
        'text':
            'Find the calm green threshold where tropical plants frame an overlooked city story.',
        'hint': 'Look for a public garden near a cultural district.',
        'hint_revealed': false,
      };
    return const ArrivalResult(
      arrived: true,
      message: 'Location verified.',
      completedStage: 2,
      nextStage: 3,
      totalStages: 3,
      nextClue: MysteryClue(
        number: 3,
        text:
            'Find the calm green threshold where tropical plants frame an overlooked city story.',
        hint: 'Look for a public garden near a cultural district.',
      ),
      guide: DestinationGuide(
        name: 'Royal Selangor Visitor Centre',
        state: 'Kuala Lumpur',
        city: 'Kuala Lumpur',
        categories: ['Craft', 'Culture', 'History'],
        facts: [
          'Royal Selangor grew from a small pewter workshop founded in Kuala Lumpur in 1885.',
          'Its visitor centre demonstrates how Malaysian pewter is shaped and finished.',
        ],
        visitorInformation: {
          'opening_warning': 'Open today 9:00 AM–5:00 PM',
          'visit_tip': 'Allow 60–90 minutes for the exhibits and workshop.',
        },
        accessibility: {
          'step_free_main_entrance': true,
          'accessible_toilet': true,
        },
        weeklyHours: ['Monday–Sunday: 9:00 AM–5:00 PM'],
        culturalEtiquette: [
          'Ask before photographing artisans at work.',
          'Keep workshop walkways clear for staff and visitors.',
        ],
        safetyNotes: [
          'This is a staffed indoor visitor attraction.',
          'Follow workshop barriers and posted visitor guidance.',
        ],
        formattedAddress: '4 Jalan Usahawan 6, Setapak Jaya, Kuala Lumpur',
        googleRating: 4.5,
        googleUserRatingCount: 5800,
        openNow: true,
        safetyScore: 0.92,
      ),
    );
  }

  Map<String, dynamic> sharedMission(Map<String, dynamic> body) {
    final action = body['action'];
    if (action == 'overview') {
      return {
        'sessions': [
          {
            'id': 'demo-shared',
            'title': 'The Lantern Keeper’s Trail',
            'status': sharedStatus,
          },
        ],
        'invitations': [
          {
            'id': 'demo-invite',
            'session_id': 'demo-friend-mission',
            'title': 'Secrets of the Limestone',
          },
        ],
      };
    }
    if (action == 'remove') {
      sharedMembers.removeWhere((item) => item['user_id'] == body['member_id']);
    } else if (action == 'ready') {
      viewerReady = body['ready'] == true;
      sharedMembers.first['ready'] = viewerReady;
    } else if (action == 'start') {
      sharedStatus = 'active';
    } else if (action == 'invite') {
      return {
        'session_id': 'demo-shared',
        'message':
            'Demo invitation sent. Unregistered emails would receive an app invitation.',
      };
    }
    return {
      'session_id': 'demo-shared',
      'message': action == 'remove' ? 'Crew member removed.' : null,
      'session': {
        'id': 'demo-shared',
        'title': 'The Lantern Keeper’s Trail',
        'status': sharedStatus,
      },
      'viewer': {'user_id': 'demo-user', 'role': 'host'},
      'members': sharedMembers,
    };
  }

  Map<String, dynamic> passportDiary(Map<String, dynamic> body) {
    final action = body['action'];
    if (action == 'generate_diary') {
      return {
        'generated': true,
        'draft_saved': false,
        'title': 'Pewter, Petals and an Unexpected Kuala Lumpur',
        'content':
            'Today Kuala Lumpur felt less like a checklist and more like a story unfolding in small details. Watching Malaysian pewter craft up close made me appreciate how living heritage can remain relevant without losing its roots. The quieter stops gave us time to observe, ask questions and travel more thoughtfully. #MysteryMalaysia #VisitMalaysia',
        'message': 'Your demo diary is ready to review.',
      };
    }
    if (action == 'group_diary_status') {
      return {
        'is_host': true,
        'all_submitted': true,
        'members': [
          {
            'user_id': 'demo-user',
            'name': 'Nur Traveller',
            'role': 'host',
            'is_viewer': true,
            'reflection':
                'I enjoyed discovering Malaysian craft without rushing between crowded places.',
            'submitted_at': '2026-08-03T12:00:00Z',
          },
          {
            'user_id': 'demo-jessica',
            'name': 'Jessica',
            'role': 'guest',
            'is_viewer': false,
            'reflection':
                'The workshop story made the destination memorable and easy to share.',
            'submitted_at': '2026-08-03T12:05:00Z',
          },
        ],
      };
    }
    if (action == 'generate_group_diary') {
      return {
        'message': 'Shared demo diary generated for every crew member.',
        'diary': {
          'id': 'demo-group-diary',
          'session_id': 'demo-completed-group',
          'title': 'One Trail, Two Perspectives',
          'summary':
              'Together we followed a quieter Kuala Lumpur trail shaped by craft, conversation and shared curiosity.',
          'diary_type': 'shared',
          'updated_at': '2026-08-03T12:10:00Z',
        },
      };
    }
    if (action == 'save_diary') return {'message': 'Demo diary saved.'};
    if (action == 'save_reflection') return {'message': 'Reflection saved.'};
    return {
      'stats': {
        'completed_missions': 2,
        'visited_destinations': 6,
        'explored_states': 2,
      },
      'stamps': [
        for (var index = 1; index <= 3; index++)
          {
            'place': 'Whispers of the Jetty — piece $index',
            'state': 'Selangor',
            'name': 'Jetty Mosaic',
            'rarity': index == 3 ? 'legendary' : 'common',
            'earned_at': '2026-07-${19 + index}T10:00:00Z',
            'session_id': 'demo-completed-solo',
            'mission_title': 'Whispers of the Jetty',
          },
        {
          'place': 'Royal Selangor Visitor Centre',
          'state': 'Kuala Lumpur',
          'name': 'Pewter Petal',
          'rarity': 'rare',
          'earned_at': '2026-08-03T10:00:00Z',
          'session_id': 'demo-paused',
          'mission_title': 'Cipher of the Valley Escarpment',
        },
      ],
      'badges': [
        {
          'name': 'Trailblazer',
          'description': 'Complete your first three-stop mystery.',
          'earned': true,
          'earned_at': '2026-07-21T10:00:00Z',
        },
        {
          'name': 'Culture Keeper',
          'description': 'Learn from three Malaysian cultural destinations.',
          'earned': true,
          'earned_at': '2026-08-03T10:00:00Z',
        },
        {
          'name': 'Quiet Explorer',
          'description': 'Visit a safe lesser-known destination.',
          'earned': true,
          'earned_at': '2026-08-03T10:00:00Z',
        },
      ],
      'diaries': [
        {
          'id': 'demo-diary',
          'session_id': 'demo-completed-solo',
          'title': 'Whispers Beside the Jetty',
          'summary':
              'A thoughtful day of coastal stories, local voices and places that deserve patient exploration.',
          'diary_type': 'solo',
          'updated_at': '2026-07-21T12:00:00Z',
        },
      ],
      'eligible_diary_missions': [
        {
          'session_id': 'demo-completed-solo',
          'title': 'Whispers of the Jetty',
          'mode': 'solo',
          'completed_at': '2026-07-21T11:00:00Z',
        },
        {
          'session_id': 'demo-completed-group',
          'title': 'Shared Lantern Trail',
          'mode': 'collaborative',
          'completed_at': '2026-08-03T11:00:00Z',
        },
      ],
      'newly_unlocked_badges': const <String>[],
    };
  }

  MissionRecommendation regenerateStop(
    String recommendationId,
    int stopNumber,
  ) {
    final mission = recommendations.firstWhere(
      (item) => item.id == recommendationId,
      orElse: () => recommendations.first,
    );
    final previews = List<String>.of(mission.stopPreviews);
    previews[stopNumber - 1] =
        'A newly woven clue leads to a staffed local heritage experience.';
    return MissionRecommendation(
      id: mission.id,
      title: mission.title,
      briefing: mission.briefing,
      matchReason: mission.matchReason,
      duration: mission.duration,
      budget: mission.budget,
      difficulty: mission.difficulty,
      stops: mission.stops,
      colorValue: mission.colorValue,
      iconKey: mission.iconKey,
      durationMinutes: mission.durationMinutes,
      stopPreviews: previews,
      stopOpeningWarnings: mission.stopOpeningWarnings,
    );
  }
}
