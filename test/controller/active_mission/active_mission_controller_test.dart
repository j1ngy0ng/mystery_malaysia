import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/controller/active_mission/active_mission_controller.dart';
import 'package:mystery_malaysia/controller/services/device/location_service.dart';
import 'package:mystery_malaysia/controller/services/supabase/supabase_data_service.dart';
import 'package:mystery_malaysia/model/active_mission/app_location.dart';
import 'package:mystery_malaysia/model/active_mission/destination_guide.dart';
import 'package:mystery_malaysia/model/active_mission/mission_session.dart';
import 'package:mystery_malaysia/model/clue_hint/mystery_clue.dart';

void main() {
  test(
    'a reached GPS check verifies arrival only once for the current stage',
    () async {
      final dataService = _MissionDataService();
      final controller = ActiveMissionController(
        launch: _launch(MissionStatus.active),
        locationService: _LocationService(),
        dataService: dataService,
      );

      expect(await controller.refreshLocation(), isNotNull);
      expect(await controller.refreshLocation(), isNull);
      expect(dataService.arrivalCalls, 1);
    },
  );

  test('a saved mission starts from ready state', () async {
    final controller = ActiveMissionController(
      launch: _launch(MissionStatus.ready),
      locationService: _LocationService(),
      dataService: _MissionDataService(),
    );

    expect(await controller.start(), isTrue);
    expect(controller.session.status, MissionStatus.active);
  });
}

MissionLaunch _launch(MissionStatus status) => MissionLaunch(
  sessionId: 'session-1',
  title: 'Saved mystery',
  region: 'Selangor',
  currentStage: 1,
  totalStages: 3,
  status: status,
  clue: const MysteryClue(
    number: 1,
    text: 'Look for the bright clock.',
    hint: '',
  ),
);

class _LocationService extends LocationService {
  @override
  Future<AppLocation> getCurrentLocation() async =>
      const AppLocation(latitude: 3.1, longitude: 101.6, accuracyMetres: 8);
}

class _MissionDataService extends SupabaseDataService {
  int arrivalCalls = 0;

  @override
  Future<MissionLaunch?> loadCurrentMission() async =>
      _launch(MissionStatus.active);

  @override
  Future<String> missionProximity(
    String sessionId,
    AppLocation location,
  ) async => 'reached';

  @override
  Future<ArrivalResult> confirmArrival({
    required String sessionId,
    required AppLocation location,
  }) async {
    arrivalCalls += 1;
    return const ArrivalResult(
      arrived: true,
      message: 'Verified',
      waitingForMembers: true,
      nextStage: 1,
    );
  }

  @override
  Future<MissionLaunch> startSelectedMission(String sessionId) async =>
      _launch(MissionStatus.active);
}
