import 'package:flutter/foundation.dart';

import '../../models/active_mission/app_location.dart';
import '../../models/active_mission/mission_session.dart';
import '../../services/device/location_service.dart';

class ActiveMissionController extends ChangeNotifier {
  ActiveMissionController({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  static const mysteryZone = AppLocation(
    latitude: 3.14886,
    longitude: 101.69572,
  );

  final LocationService _locationService;

  MissionSession session = const MissionSession(
    title: 'Lanterns & Legends',
    region: 'Kuala Lumpur',
    currentStage: 2,
    totalStages: 3,
    distanceMetres: 420,
    status: MissionStatus.active,
  );

  AppLocation? currentLocation;
  bool isLocating = false;
  String? locationError;

  bool get canConfirmArrival =>
      currentLocation != null && session.distanceMetres <= 150;

  String get temperature {
    if (session.distanceMetres <= 120) return 'Very hot!';
    if (session.distanceMetres <= 350) return 'Getting warmer';
    return 'A little cold';
  }

  void togglePause() {
    final next = session.status == MissionStatus.paused
        ? MissionStatus.active
        : MissionStatus.paused;
    session = session.copyWith(status: next);
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    isLocating = true;
    locationError = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      currentLocation = location;
      session = session.copyWith(
        distanceMetres: _locationService.distanceMetres(location, mysteryZone),
      );
    } on LocationServiceException catch (error) {
      locationError = error.message;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  void abandon() {
    session = session.copyWith(status: MissionStatus.abandoned);
    notifyListeners();
  }
}
