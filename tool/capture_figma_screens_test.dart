import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/controller/active_mission/active_mission_facade_interface.dart';
import 'package:mystery_malaysia/controller/app_dependencies.dart';
import 'package:mystery_malaysia/controller/mission_discovery/mission_discovery_facade.dart';
import 'package:mystery_malaysia/controller/services/demo/demo_api_manager.dart';
import 'package:mystery_malaysia/model/active_mission/app_location.dart';
import 'package:mystery_malaysia/model/active_mission/destination_guide.dart';
import 'package:mystery_malaysia/model/active_mission/mission_session.dart';
import 'package:mystery_malaysia/model/clue_hint/mystery_clue.dart';
import 'package:mystery_malaysia/view/active_mission/active_mission_view.dart';
import 'package:mystery_malaysia/view/app.dart';
import 'package:mystery_malaysia/view/app_theme.dart';
import 'package:mystery_malaysia/view/collaborative_travel/shared_mission_view.dart';
import 'package:mystery_malaysia/view/malaysia_backdrop.dart';
import 'package:mystery_malaysia/view/mission_discovery/recommendations_view.dart';

const goldenDirectory = '../figma/mystery-malaysia-ui-generator/screens';

void main() {
  setUpAll(_loadAndroidFonts);

  for (final entry in const [
    ('/', '01-welcome'),
    ('/auth/sign-in', '02-sign-in'),
    ('/auth/register', '03-register'),
    ('/home', '04-home'),
    ('/missions/request', '05-build-mystery'),
    ('/play/demo', '09-active-mission'),
    ('/play/demo/clue', '10-clue'),
    ('/diary', '13-diary'),
    ('/notifications', '16-notifications'),
  ]) {
    testWidgets('capture ${entry.$2}', (tester) async {
      _configure(tester);
      await _route(tester, entry.$1, entry.$2);
    });
  }

  for (final entry in const [
    ('Mission', '08-missions'),
    ('Passport', '12-passport'),
    ('Crew', '14-crew'),
    ('Profile', '17-profile'),
  ]) {
    testWidgets('capture ${entry.$2}', (tester) async {
      _configure(tester);
      await _pump(tester, const MysteryMalaysiaApp(initialRoute: '/home'));
      await tester.tap(find.text(entry.$1).last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await _golden(tester, entry.$2);
    });
  }

  testWidgets('capture generated mystery picks', (tester) async {
    _configure(tester);
    await _recommendations(tester, preview: false);
  });

  testWidgets('capture mission preview', (tester) async {
    _configure(tester);
    await _recommendations(tester, preview: true);
  });

  testWidgets('capture mission preview actions', (tester) async {
    _configure(tester);
    await _recommendations(tester, preview: true, scrollToActions: true);
  });

  testWidgets('capture destination reveal', (tester) async {
    _configure(tester);
    await _destinationReveal(tester);
  });

  testWidgets('capture shared mission lobby', (tester) async {
    _configure(tester);
    await _pump(
      tester,
      MaterialApp(
        theme: AppTheme.bright,
        builder: (context, child) => MalaysiaBackdrop(child: child!),
        home: SharedMissionView(
          facade: AppDependencies.collaborativeTravel(sessionId: 'demo-shared'),
        ),
      ),
    );
    await _golden(tester, '15-shared-lobby');
  });
}

Future<void> _loadAndroidFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(File(path).readAsBytesSync());

  await (FontLoader('Roboto')
        ..addFont(
          bytes(
            r'C:\Flutter\flutter\bin\cache\artifacts\material_fonts\roboto-regular.ttf',
          ),
        )
        ..addFont(
          bytes(
            r'C:\Flutter\flutter\bin\cache\artifacts\material_fonts\roboto-bold.ttf',
          ),
        ))
      .load();
  await (FontLoader('MaterialIcons')..addFont(
        bytes(
          r'C:\Flutter\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
        ),
      ))
      .load();
  await (FontLoader(
    'Segoe UI Emoji',
  )..addFont(bytes(r'C:\Windows\Fonts\seguiemj.ttf'))).load();
}

void _configure(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _route(WidgetTester tester, String route, String name) async {
  await _pump(tester, MysteryMalaysiaApp(initialRoute: route));
  await _golden(tester, name);
}

Future<void> _recommendations(
  WidgetTester tester, {
  required bool preview,
  bool scrollToActions = false,
}) async {
  await _pump(
    tester,
    MaterialApp(
      theme: AppTheme.bright,
      builder: (context, child) => MalaysiaBackdrop(child: child!),
      home: RecommendationsView(
        facade: MissionDiscoveryFacade(
          recommendations: DemoApiManager.instance.recommendations,
        ),
        recommendations: DemoApiManager.instance.recommendations,
      ),
    ),
  );
  if (!preview) {
    await _golden(tester, '06-mystery-picks');
    return;
  }
  await tester.tap(
    find.text(DemoApiManager.instance.recommendations.first.title),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(
    find.text('Preview ${DemoApiManager.instance.recommendations.first.title}'),
  );
  await tester.pump(const Duration(milliseconds: 700));
  if (scrollToActions) {
    for (var index = 0; index < 3; index++) {
      await tester.flingFrom(
        const Offset(200, 760),
        const Offset(0, -560),
        1400,
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
  }
  await _golden(
    tester,
    scrollToActions ? '07b-mission-preview-actions' : '07-mission-preview',
  );
}

Future<void> _destinationReveal(WidgetTester tester) async {
  await _pump(
    tester,
    MaterialApp(
      theme: AppTheme.bright,
      builder: (context, child) => MalaysiaBackdrop(child: child!),
      home: ActiveMissionView(facade: _ArrivalFacade()),
    ),
    wait: const Duration(milliseconds: 900),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await _golden(tester, '11-destination-revealed');
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Duration wait = const Duration(seconds: 2),
}) async {
  await tester.pumpWidget(
    RepaintBoundary(key: const ValueKey('figma-capture'), child: child),
  );
  await tester.pump();
  await tester.pump(wait);
}

Future<void> _golden(WidgetTester tester, String name) async {
  await expectLater(
    find.byKey(const ValueKey('figma-capture')),
    matchesGoldenFile('$goldenDirectory/$name.png'),
  );
}

class _ArrivalFacade extends ChangeNotifier implements IActiveMissionFacade {
  @override
  String? get sessionId => 'figma-arrival';

  @override
  MissionSession get session => const MissionSession(
    title: 'Cipher of the Valley Escarpment',
    region: 'Kuala Lumpur',
    currentStage: 2,
    totalStages: 3,
    distanceMetres: 0,
    status: MissionStatus.active,
  );

  @override
  MysteryClue get currentClue => const MysteryClue(
    number: 2,
    text:
        'Find the riverside cultural centre where artisans shape Malaysian pewter.',
    hint: 'Its name begins with Royal.',
  );

  @override
  AppLocation? get currentLocation => const AppLocation(
    latitude: 3.16312,
    longitude: 101.71208,
    accuracyMetres: 8,
  );

  @override
  bool get isLocating => false;
  @override
  bool get isVerifying => false;
  @override
  bool get isUpdatingStatus => false;
  @override
  bool get canConfirmArrival => true;
  @override
  String? get locationError => null;
  @override
  String? get arrivalError => null;
  @override
  String get temperature => 'Destination reached!';
  @override
  String get mapStatus => 'Only your current location is shown';

  @override
  Future<ArrivalResult?> refreshLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _arrival;
  }

  @override
  Future<ArrivalResult?> confirmArrival() async => _arrival;
  @override
  Future<bool> start() async => true;
  @override
  Future<bool> togglePause() async => true;
  @override
  Future<bool> abandon() async => true;

  static const _arrival = ArrivalResult(
    arrived: true,
    message: 'Location verified.',
    completedStage: 2,
    nextStage: 3,
    totalStages: 3,
    nextClue: MysteryClue(
      number: 3,
      text: 'Find the calm green threshold near a cultural district.',
      hint: 'Look for a public garden.',
    ),
    guide: DestinationGuide(
      name: 'Royal Selangor Visitor Centre',
      state: 'Kuala Lumpur',
      city: 'Kuala Lumpur',
      categories: ['Craft', 'Culture', 'History'],
      facts: [
        'Royal Selangor grew from a small pewter workshop founded in Kuala Lumpur in 1885.',
        'The visitor centre demonstrates how Malaysian pewter is shaped and finished.',
      ],
      visitorInformation: {
        'opening_warning': 'Open today 9:00 AM–5:00 PM',
        'visit_tip': 'Allow 60–90 minutes for the exhibits and workshop.',
      },
      accessibility: {
        'step_free_main_entrance': true,
        'accessible_toilet': true,
      },
      weeklyHours: ['Monday–Sunday: 9:00 AM–5:00 PM'],
      culturalEtiquette: [
        'Ask before photographing artisans at work.',
        'Keep workshop walkways clear.',
      ],
      safetyNotes: [
        'This is a staffed indoor visitor attraction.',
        'Follow workshop barriers and posted guidance.',
      ],
      formattedAddress: '4 Jalan Usahawan 6, Kuala Lumpur',
      googleRating: 4.5,
      googleUserRatingCount: 5800,
      openNow: true,
      safetyScore: 0.92,
    ),
  );
}
