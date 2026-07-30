import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/app/app.dart';
import 'package:mystery_malaysia/controller/app_dependencies.dart';
import 'package:mystery_malaysia/view/mission_discovery/home_view.dart';
import 'package:mystery_malaysia/theme/app_theme.dart';

void main() {
  testWidgets('shows the mission discovery entry point', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: Scaffold(
          body: HomeView(
            profileFacade: AppDependencies.userProfile(),
            notificationFacade: AppDependencies.notifications(),
            missionFacade: AppDependencies.missionHistory(),
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
