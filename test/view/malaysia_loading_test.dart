import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/view/malaysia_loading.dart';

void main() {
  testWidgets('loading blocker prevents background interaction', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MalaysiaLoadingBlocker(
          loading: true,
          child: Scaffold(
            body: TextButton(
              onPressed: () => taps++,
              child: const Text('Background action'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Background action'), warnIfMissed: false);
    expect(taps, 0);
  });
}
