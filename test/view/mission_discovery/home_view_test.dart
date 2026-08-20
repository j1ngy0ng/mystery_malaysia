import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/view/app.dart';
import 'package:mystery_malaysia/controller/user_profile/user_profile_facade_interface.dart';
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
          ),
        ),
      ),
    );

    expect(find.text('Mystery MY'), findsOneWidget);
    expect(find.text('Where will you explore next?'), findsOneWidget);
    expect(find.text('Plan from my location'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Explore Malaysia differently'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Explore Malaysia differently'), findsOneWidget);
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
