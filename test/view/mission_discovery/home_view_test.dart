import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/view/app.dart';
import 'package:mystery_malaysia/controller/active_mission/active_mission_facade_interface.dart';
import 'package:mystery_malaysia/controller/user_profile/user_profile_facade_interface.dart';
import 'package:mystery_malaysia/model/active_mission/mission_session.dart';
import 'package:mystery_malaysia/model/user_profile/user_profile.dart';
import 'package:mystery_malaysia/view/mission_discovery/home_view.dart';
import 'package:mystery_malaysia/view/app_theme.dart';

void main() {
  testWidgets('shows the mission discovery entry point', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: Scaffold(
          body: HomeView(
            profileFacade: _ProfileFacade(),
            notificationFacade: _NotificationFacade(),
            missionFacade: _MissionFacade(),
          ),
        ),
      ),
    );

    expect(find.text('Mystery MY'), findsOneWidget);
    expect(find.text('Find me a mystery'), findsOneWidget);
  });

  testWidgets('starts with tourism onboarding', (tester) async {
    await tester.pumpWidget(const MysteryMalaysiaApp());

    expect(find.text('Malaysia is full of secrets.'), findsOneWidget);
    expect(find.text('Start the adventure'), findsOneWidget);
  });
}

class _ProfileFacade extends ChangeNotifier implements IUserProfileFacade {
  @override
  UserProfile get profile => const UserProfile(
    name: 'Explorer',
    username: '',
    email: '',
    homeState: 'Not set',
  );

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NotificationFacade extends ChangeNotifier
    implements INotificationFacade {
  @override
  int get unreadCount => 0;

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MissionFacade extends ChangeNotifier implements IMissionHistoryFacade {
  @override
  Future<MissionLaunch?> loadCurrentMission() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
