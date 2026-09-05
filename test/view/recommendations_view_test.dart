import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/controller/mission_discovery/mission_discovery_facade_interface.dart';
import 'package:mystery_malaysia/model/active_mission/app_location.dart';
import 'package:mystery_malaysia/model/active_mission/mission_session.dart';
import 'package:mystery_malaysia/model/mission_discovery/mission_recommendation.dart';
import 'package:mystery_malaysia/view/mission_discovery/recommendations_view.dart';

void main() {
  testWidgets('regenerating a stop blocks other actions until it finishes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const mission = MissionRecommendation(
      id: 'mission-1',
      title: 'Test mystery',
      briefing: 'A hidden adventure.',
      matchReason: 'It matches your preferences.',
      duration: '2h',
      budget: 'RM 50',
      difficulty: 'Easy',
      stops: 1,
      colorValue: 0xFF12B8A6,
      iconKey: 'explore',
      stopPreviews: ['The original stop preview.'],
    );
    const updatedMission = MissionRecommendation(
      id: 'mission-1',
      title: 'Test mystery',
      briefing: 'A hidden adventure.',
      matchReason: 'It matches your preferences.',
      duration: '2h',
      budget: 'RM 50',
      difficulty: 'Easy',
      stops: 1,
      colorValue: 0xFF12B8A6,
      iconKey: 'explore',
      stopPreviews: ['The regenerated stop preview.'],
    );
    final facade = _FakeMissionDiscoveryFacade(mission);

    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationsView(
          facade: facade,
          recommendations: const [mission],
        ),
      ),
    );

    await tester.tap(find.text('Test mystery').first);
    await tester.pump();
    await tester.tap(find.text('Preview Test mystery'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Regenerate mystery stop 1'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.byTooltip('Regenerate mystery stop 1'));
    await tester.pump();

    expect(find.text('Regenerating mystery stop 1...'), findsOneWidget);
    expect(facade.regenerateCalls, 1);

    await tester.tap(
      find.byTooltip('Regenerate mystery stop 1'),
      warnIfMissed: false,
    );
    await tester.tap(find.text('Choose this mission'), warnIfMissed: false);
    await tester.pump();

    expect(facade.regenerateCalls, 1);
    expect(facade.selectCalls, 0);
    expect(find.text('Regenerating mystery stop 1...'), findsOneWidget);

    facade.regeneration.complete(updatedMission);
    await tester.pumpAndSettle();

    expect(find.text('Regenerating mystery stop 1...'), findsNothing);
    expect(find.text('Mystery stop 1 was regenerated.'), findsOneWidget);
  });
}

class _FakeMissionDiscoveryFacade extends ChangeNotifier
    implements IMissionDiscoveryFacade {
  _FakeMissionDiscoveryFacade(this.mission);

  final MissionRecommendation mission;
  final regeneration = Completer<MissionRecommendation?>();
  int regenerateCalls = 0;
  int selectCalls = 0;

  @override
  double get budget => 50;

  @override
  AppLocation? get currentLocation => null;

  @override
  double get duration => 2;

  @override
  String? get generationError => null;

  @override
  bool get hasLocation => false;

  @override
  DateTime get intendedStartAt => DateTime(2026);

  @override
  bool get isGenerating => false;

  @override
  bool get isLocating => false;

  @override
  String? get locationError => null;

  @override
  String get locationLabel => 'Test location';

  @override
  double get maximumDistance => 10;

  @override
  String? get operationError => null;

  @override
  List<MissionRecommendation> get recommendations => [mission];

  @override
  Future<String?> createSharedMission(String recommendationId) async => null;

  @override
  Future<void> detectCurrentLocation() async {}

  @override
  Future<bool> generate() async => true;

  @override
  Future<MissionRecommendation?> regenerateStop(
    String recommendationId,
    int stopNumber,
  ) {
    regenerateCalls++;
    return regeneration.future;
  }

  @override
  Future<MissionLaunch?> selectMission(String recommendationId) async {
    selectCalls++;
    return null;
  }

  @override
  void updateBudget(double value) {}

  @override
  void updateDuration(double value) {}

  @override
  void updateMaximumDistance(double value) {}

  @override
  void updateSchedule(DateTime value) {}
}
