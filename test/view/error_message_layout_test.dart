import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/theme/app_theme.dart';

void main() {
  testWidgets('field errors wrap on a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: const Scaffold(
          body: TextField(
            decoration: InputDecoration(
              errorText:
                  'Use 8+ characters with uppercase, lowercase, number and symbol.',
            ),
          ),
        ),
      ),
    );

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.errorMaxLines, 4);
    expect(tester.takeException(), isNull);
  });
}
