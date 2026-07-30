import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/active_mission/app_location.dart';
import '../../model/active_mission/destination_guide.dart';
import '../../model/active_mission/mission_session.dart';
import '../../model/clue_hint/mystery_clue.dart';
import '../services/device/location_service.dart';
import '../services/supabase/supabase_data_service.dart';

class ActiveMissionController extends ChangeNotifier {
  ActiveMissionController({
    MissionLaunch? launch,
    LocationService? locationService,
    SupabaseDataService? dataService,
  }) : sessionId = launch?.sessionId,
       currentClue = launch?.clue ?? _demoClue,
       _locationService = locationService ?? LocationService(),
       _dataService = dataService ?? SupabaseDataService(),
       session = MissionSession(
         title: launch?.title ?? 'Lanterns & Legends',
         region: launch?.region ?? 'Kuala Lumpur',
         currentStage: launch?.currentStage ?? 2,
         totalStages: launch?.totalStages ?? 3,
         distanceMetres: 420,
         status: launch?.status ?? MissionStatus.active,
       );

  static const mysteryZone = AppLocation(
    latitude: 3.14886,
    longitude: 101.69572,
  );

  final LocationService _locationService;
  final SupabaseDataService _dataService;
  final String? sessionId;

  MissionSession session;
  MysteryClue currentClue;

  AppLocation? currentLocation;
  bool isLocating = false;
  bool isVerifying = false;
  String? locationError;
  String? arrivalError;
  String proximityLevel = 'unknown';
  bool isUpdatingStatus = false;

  bool get canConfirmArrival =>
      currentLocation != null &&
      (sessionId != null || session.distanceMetres <= 150);

  String get temperature {
    if (sessionId != null) {
      return switch (proximityLevel) {
        'reached' => 'Destination reached!',
        'hot' => 'Hot',
        'warm' => 'Warm',
        'cold' => 'Cold',
        'freezing' => 'Freezing',
        'poor_accuracy' => 'GPS signal is weak',
        _ => 'Checking the trail',
      };
    }
    if (session.distanceMetres <= 120) return 'Very hot!';
    if (session.distanceMetres <= 350) return 'Getting warmer';
    return 'A little cold';
  }

  String get mapStatus => sessionId == null
      ? '${session.distanceMetres} m from the mystery zone'
      : 'Only your current location is shown';

  Future<bool> togglePause() async {
    final next = session.status == MissionStatus.paused
        ? MissionStatus.active
        : MissionStatus.paused;
    isUpdatingStatus = true;
    arrivalError = null;
    notifyListeners();
    try {
      final status = sessionId == null
          ? next
          : await _dataService.updateMissionStatus(
              sessionId!,
              next == MissionStatus.paused ? 'pause' : 'resume',
            );
      session = session.copyWith(status: status);
      if (status == MissionStatus.active) await refreshLocation();
      return true;
    } on ApiError catch (error) {
      arrivalError = error.message;
      return false;
    } finally {
      isUpdatingStatus = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    isLocating = true;
    locationError = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      currentLocation = location;
      if (sessionId != null && session.status == MissionStatus.active) {
        proximityLevel = await _dataService.missionProximity(
          sessionId!,
          location,
        );
        await _syncMission();
      } else if (sessionId == null) {
        session = session.copyWith(
          distanceMetres: _locationService.distanceMetres(
            location,
            mysteryZone,
          ),
        );
      }
    } on LocationServiceException catch (error) {
      locationError = error.message;
    } on ApiError catch (error) {
      locationError = error.message;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  Future<void> _syncMission() async {
    final latest = await _dataService.loadCurrentMission();
    if (latest != null && latest.sessionId == sessionId) {
      session = session.copyWith(
        currentStage: latest.currentStage,
        status: latest.status,
      );
      currentClue = latest.clue;
      return;
    }
    final history = await _dataService.loadMissionHistory();
    MissionStatus? finishedStatus;
    for (final mission in history) {
      if (mission.sessionId == sessionId) {
        finishedStatus = mission.status;
        break;
      }
    }
    if (finishedStatus != null) {
      session = session.copyWith(status: finishedStatus);
    }
  }

  Future<ArrivalResult?> confirmArrival() async {
    final location = currentLocation;
    if (location == null) {
      arrivalError = 'Refresh your GPS location before confirming arrival.';
      notifyListeners();
      return null;
    }

    isVerifying = true;
    arrivalError = null;
    notifyListeners();
    try {
      final result = sessionId == null
          ? _demoArrival()
          : await _dataService.confirmArrival(
              sessionId: sessionId!,
              location: location,
            );
      if (!result.arrived) {
        arrivalError = result.message;
        return null;
      }
      if (result.nextClue != null) currentClue = result.nextClue!;
      session = session.copyWith(
        currentStage: result.nextStage ?? session.currentStage,
        status: result.missionCompleted ? MissionStatus.completed : null,
      );
      return result;
    } on ApiError catch (error) {
      arrivalError = error.message;
      return null;
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  Future<bool> abandon() async {
    isUpdatingStatus = true;
    arrivalError = null;
    notifyListeners();
    try {
      final status = sessionId == null
          ? MissionStatus.abandoned
          : await _dataService.updateMissionStatus(sessionId!, 'abandon');
      session = session.copyWith(status: status);
      return true;
    } on ApiError catch (error) {
      arrivalError = error.message;
      return false;
    } finally {
      isUpdatingStatus = false;
      notifyListeners();
    }
  }

  static const _demoClue = MysteryClue(
    number: 2,
    text:
        'I watch the city through petals of glass. At my feet, old stories and new skylines share the same reflection.',
    hint:
        'Look for a peaceful place of worship near a river confluence and a busy heritage district.',
  );

  ArrivalResult _demoArrival() {
    return const ArrivalResult(
      arrived: true,
      message: '',
      completedStage: 2,
      nextStage: 3,
      totalStages: 3,
      xpAwarded: 100,
      nextClue: MysteryClue(
        number: 3,
        text: 'Find a heritage roof where Malaysian colours gather.',
        hint: 'Look close to the meeting point of old trading streets.',
      ),
      guide: DestinationGuide(
        name: 'Sultan Abdul Samad Jamek Mosque',
        state: 'Kuala Lumpur',
        city: 'Kuala Lumpur',
        categories: ['Culture', 'History'],
        facts: [
          'One of Kuala Lumpur’s oldest mosques, standing where the Klang and Gombak rivers meet.',
        ],
        visitorInformation: {
          'etiquette': 'Dress respectfully and follow posted visitor guidance.',
        },
        accessibility: {},
        formattedAddress: 'Jalan Tun Perak, Kuala Lumpur',
      ),
    );
  }
}
