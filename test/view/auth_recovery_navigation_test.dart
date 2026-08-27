import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/app/app.dart';
import 'package:mystery_malaysia/controller/user_profile/user_profile_facade_interface.dart';
import 'package:mystery_malaysia/view/user_profile/update_password_view.dart';
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

  testWidgets('successful password reset returns to sign in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => UpdatePasswordView(facade: _AuthenticationFacade()),
          '/auth/sign-in': (_) => const Scaffold(body: Text('Sign in again')),
        },
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Password!1');
    await tester.enterText(find.byType(TextField).last, 'Password!1');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in again'), findsOneWidget);
    expect(find.text('Choose a new password'), findsNothing);
  });
}

class _AuthenticationFacade extends ChangeNotifier
    implements IAuthenticationFacade {
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  String? get passwordError => null;
  @override
  String? get confirmationPasswordError => null;

  @override
  Future<bool> updatePassword(
    String password,
    String confirmationPassword,
  ) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
