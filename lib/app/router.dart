import 'package:flutter/material.dart';

import '../views/active_mission/active_mission_view.dart';
import '../views/active_mission/mission_history_view.dart';
import '../views/clue_hint/clue_view.dart';
import '../views/collaborative_travel/shared_mission_view.dart';
import '../views/mission_discovery/mission_builder_view.dart';
import '../views/mission_discovery/recommendations_view.dart';
import '../views/passport_diary/diary_view.dart';
import '../views/user_profile/register_view.dart';
import '../views/user_profile/sign_in_view.dart';
import '../views/user_profile/welcome_view.dart';
import 'app_shell.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      '/' => (_) => const WelcomeView(),
      '/auth/sign-in' => (_) => const SignInView(),
      '/auth/register' => (_) => const RegisterView(),
      '/home' => (_) => const AppShell(),
      '/missions/request' => (_) => const MissionBuilderView(),
      '/missions' => (_) => const MissionHistoryView(),
      '/missions/demo/preview' => (_) => const RecommendationsView(),
      '/play/demo' => (_) => const ActiveMissionView(),
      '/play/demo/clue' => (_) => const ClueView(),
      '/diary' => (_) => const DiaryView(),
      '/shared/demo' => (_) => const SharedMissionView(),
      _ => (_) => const WelcomeView(),
    };

    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }
}
