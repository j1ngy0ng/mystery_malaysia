import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/app/app.dart';

void main() {
  testWidgets('shows the mission discovery entry point', (tester) async {
    await tester.pumpWidget(const MysteryMalaysiaApp(initialRoute: '/home'));

    expect(find.text('Mystery MY'), findsOneWidget);
    expect(find.text('Find me a mystery'), findsOneWidget);
  });

  testWidgets('starts with tourism onboarding', (tester) async {
    await tester.pumpWidget(const MysteryMalaysiaApp());

    expect(find.text('Malaysia is full of secrets.'), findsOneWidget);
    expect(find.text('Start the adventure'), findsOneWidget);
  });
}
