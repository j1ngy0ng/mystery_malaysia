import 'package:flutter/material.dart';

import '../controller/app_dependencies.dart';
import 'active_mission/active_mission_view.dart';
import 'active_mission/mission_history_view.dart';
import 'clue_hint/clue_view.dart';
import 'collaborative_travel/shared_mission_view.dart';
import 'mission_discovery/mission_builder_view.dart';
import 'mission_discovery/recommendations_view.dart';
import 'passport_diary/diary_view.dart';
import 'user_profile/register_view.dart';
import 'user_profile/notifications_view.dart';
import 'user_profile/sign_in_view.dart';
import 'user_profile/update_password_view.dart';
import 'user_profile/welcome_view.dart';
import 'app_shell.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      '/' => (_) => const WelcomeView(),
      '/auth/sign-in' => (_) => SignInView(
        facade: AppDependencies.authentication(),
      ),
      '/auth/register' => (_) => RegisterView(
        facade: AppDependencies.authentication(),
      ),
      '/auth/update-password' => (_) => UpdatePasswordView(
        facade: AppDependencies.authentication(),
      ),
      '/notifications' => (_) => NotificationsView(
        facade: AppDependencies.notifications(),
      ),
      '/home' => (_) => const AppShell(),
      '/missions/request' => (_) => MissionBuilderView(
        facade: AppDependencies.missionDiscovery(),
      ),
      '/missions' => (_) => MissionHistoryView(
        facade: AppDependencies.missionHistory(),
      ),
      '/missions/demo/preview' => (_) => RecommendationsView(
        facade: AppDependencies.missionDiscovery(),
      ),
      '/play/demo' => (_) => ActiveMissionView(
        facade: AppDependencies.activeMission(),
      ),
      '/play/demo/clue' => (_) => ClueView(facade: AppDependencies.clueHint()),
      '/diary' => (_) => DiaryView(
        facade: AppDependencies.passportDiary(),
        sessionId: settings.arguments as String?,
      ),
      '/shared/demo' => (_) => SharedMissionView(
        facade: AppDependencies.collaborativeTravel(),
      ),
      _ => (_) => const WelcomeView(),
    };

    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }
}
