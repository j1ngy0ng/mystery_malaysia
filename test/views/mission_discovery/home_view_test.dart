import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/app/app.dart';
import 'package:mystery_malaysia/views/mission_discovery/home_view.dart';
import 'package:mystery_malaysia/views/theme/app_theme.dart';

void main() {
  testWidgets('shows the mission discovery entry point', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: const Scaffold(body: HomeView()),
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
