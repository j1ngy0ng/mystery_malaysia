import 'active_mission/active_mission_facade.dart';
import 'clue_hint/clue_hint_facade.dart';
import 'collaborative_travel/collaborative_travel_facade.dart';
import 'mission_discovery/mission_discovery_facade.dart';
import 'passport_diary/passport_diary_facade.dart';
import 'user_profile/user_profile_facade.dart';
import 'active_mission/active_mission_facade_interface.dart';
import 'clue_hint/clue_hint_facade_interface.dart';
import 'collaborative_travel/collaborative_travel_facade_interface.dart';
import 'mission_discovery/mission_discovery_facade_interface.dart';
import 'passport_diary/passport_diary_facade_interface.dart';
import 'user_profile/user_profile_facade_interface.dart';
import '../model/active_mission/mission_session.dart';
import '../model/clue_hint/mystery_clue.dart';
import '../model/mission_discovery/mission_recommendation.dart';

abstract final class AppDependencies {
  static IAuthenticationFacade authentication() => AuthenticationFacade();

  static IUserProfileFacade userProfile() => UserProfileFacade();

  static INotificationFacade notifications() => NotificationFacade();

  static IMissionDiscoveryFacade missionDiscovery({
    List<MissionRecommendation>? recommendations,
  }) => MissionDiscoveryFacade(recommendations: recommendations);

  static IActiveMissionFacade activeMission({MissionLaunch? launch}) =>
      ActiveMissionFacade(launch: launch);

  static IMissionHistoryFacade missionHistory() => MissionHistoryFacade();

  static IClueHintFacade clueHint({MysteryClue? clue, String? sessionId}) =>
      ClueHintFacade(initialClue: clue, sessionId: sessionId);

  static IPassportDiaryFacade passportDiary() => PassportDiaryFacade();

  static ICollaborativeTravelFacade collaborativeTravel({String? sessionId}) =>
      CollaborativeTravelFacade(sessionId: sessionId);
}
