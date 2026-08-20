import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/view/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('opens password update when recovery arrives before navigation', (
    tester,
  ) async {
    late StreamController<AuthState> authStates;
    authStates = StreamController<AuthState>.broadcast(
      sync: true,
      onListen: () => authStates.add(
        const AuthState(AuthChangeEvent.passwordRecovery, null),
      ),
    );
    addTearDown(authStates.close);

    await tester.pumpWidget(
      MysteryMalaysiaApp(authStateChanges: authStates.stream),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.text('Update password'), findsOneWidget);
  });

  testWidgets('opens home when email confirmation signs in before navigation', (
    tester,
  ) async {
    final session = Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      user: const User(
        id: 'confirmed-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-08-20T00:00:00Z',
      ),
    );
    late StreamController<AuthState> authStates;
    authStates = StreamController<AuthState>.broadcast(
      sync: true,
      onListen: () =>
          authStates.add(AuthState(AuthChangeEvent.signedIn, session)),
    );
    addTearDown(authStates.close);

    await tester.pumpWidget(
      MysteryMalaysiaApp(authStateChanges: authStates.stream),
    );
    await tester.pumpAndSettle();

    expect(find.text('Where will you explore next?'), findsOneWidget);
    expect(find.text('Start the adventure'), findsNothing);
  });
}
