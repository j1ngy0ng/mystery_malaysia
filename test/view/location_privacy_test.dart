import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/controller/app_dependencies.dart';
import 'package:mystery_malaysia/controller/collaborative_travel/collaborative_travel_facade_interface.dart';
import 'package:mystery_malaysia/model/collaborative_travel/mission_participant.dart';
import 'package:mystery_malaysia/view/collaborative_travel/shared_mission_view.dart';
import 'package:mystery_malaysia/theme/app_theme.dart';
import 'package:mystery_malaysia/widgets/mission_map.dart';

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
      MaterialApp(
        theme: AppTheme.bright,
        home: SharedMissionView(facade: AppDependencies.collaborativeTravel()),
      ),
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

  testWidgets('shared mission crew and long status message do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(485, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: SharedMissionView(facade: _CrewFacade()),
      ),
    );

    final layoutException = tester.takeException();
    expect(layoutException, isNull);
    expect(
      find.text('The registered traveller received an in-app invitation.'),
      findsOneWidget,
    );
  });

  testWidgets('a teammate can quit their shared mission', (tester) async {
    final facade = _CrewFacade(host: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: SharedMissionView(facade: facade),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Quit shared mission'),
      250,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Quit shared mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quit mission'));
    await tester.pumpAndSettle();

    expect(facade.left, true);
  });

  testWidgets('sending a crew invitation blocks the screen with loading', (
    tester,
  ) async {
    final facade = _CrewFacade()..pendingInvitation = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.bright,
        home: SharedMissionView(facade: facade),
      ),
    );

    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'friend@example.com');
    await tester.tap(find.text('Send invitation'));
    await tester.pump();

    expect(find.text('Sending your invitation...'), findsOneWidget);

    facade.pendingInvitation!.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Sending your invitation...'), findsNothing);
  });
}

class _CrewFacade extends ChangeNotifier implements ICollaborativeTravelFacade {
  _CrewFacade({this.host = true});

  final bool host;
  bool left = false;
  bool loading = false;
  Completer<bool>? pendingInvitation;

  @override
  String? get sessionId => 'session-1';
  @override
  String get title => 'The Cipher of the Valley Escarpment';
  @override
  String get status => 'waiting';
  @override
  bool get isHost => host;
  @override
  bool get isReady => false;
  @override
  bool get isLoading => loading;
  @override
  String? get error => null;
  @override
  String? get message =>
      'The registered traveller received an in-app invitation.';
  @override
  String? get viewerId => 'host-1';
  @override
  List<MissionParticipant> get participants => const [
    MissionParticipant(
      userId: 'host-1',
      name: 'Jessica with a deliberately long traveller name',
      initials: 'J',
      state: ParticipantState.waiting,
      isHost: true,
      colorValue: 0xFFFF6B6B,
    ),
  ];
  @override
  List<SharedMissionSummary> get sessions => const [];
  @override
  List<SharedInvitation> get invitations => const [];

  @override
  Future<void> loadLobby() async {}

  @override
  Future<bool> leave() async {
    left = true;
    return true;
  }

  @override
  Future<bool> invite(String email) async {
    loading = true;
    notifyListeners();
    final sent = await (pendingInvitation?.future ?? Future.value(true));
    loading = false;
    notifyListeners();
    return sent;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
