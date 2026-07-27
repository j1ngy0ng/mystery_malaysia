import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/views/collaborative_travel/shared_mission_view.dart';
import 'package:mystery_malaysia/views/theme/app_theme.dart';
import 'package:mystery_malaysia/views/widgets/mission_map.dart';

void main() {
  testWidgets('does not create a destination map before GPS is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: const Scaffold(body: MissionMap(currentLocation: null)),
      ),
    );

    expect(find.text('Finding your location...'), findsOneWidget);
  });

  testWidgets('shared mission has no gathering map or proximity check', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.bright, home: const SharedMissionView()),
    );

    await tester.scrollUntilVisible(
      find.textContaining('Team locations are not shown'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Gathering check'), findsNothing);
    expect(find.textContaining('Gather within'), findsNothing);
    expect(find.textContaining('Team locations are not shown'), findsOneWidget);
  });
}
