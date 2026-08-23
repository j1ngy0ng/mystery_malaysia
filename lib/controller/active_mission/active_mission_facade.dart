import 'package:flutter/foundation.dart';

import 'active_mission_controller.dart';
import 'mission_history_controller.dart';
import 'active_mission_facade_interface.dart';
import '../../model/active_mission/app_location.dart';
import '../../model/active_mission/destination_guide.dart';
import '../../model/active_mission/mission_history_item.dart';
import '../../model/active_mission/mission_session.dart';
import '../../model/clue_hint/mystery_clue.dart';

class ActiveMissionFacade extends ChangeNotifier
    implements IActiveMissionFacade {
  ActiveMissionFacade({MissionLaunch? launch})
    : _controller = ActiveMissionController(launch: launch) {
    _controller.addListener(notifyListeners);
  }

  final ActiveMissionController _controller;

  @override
  String? get sessionId => _controller.sessionId;
  @override
  MissionSession get session => _controller.session;
  @override
  MysteryClue get currentClue => _controller.currentClue;
  @override
  AppLocation? get currentLocation => _controller.currentLocation;
  @override
  bool get isLocating => _controller.isLocating;
  @override
  bool get isVerifying => _controller.isVerifying;
  @override
  bool get isUpdatingStatus => _controller.isUpdatingStatus;
  @override
  bool get canConfirmArrival => _controller.canConfirmArrival;
  @override
  String? get locationError => _controller.locationError;
  @override
  String? get arrivalError => _controller.arrivalError;
  @override
  String get temperature => _controller.temperature;
  @override
  String get mapStatus => _controller.mapStatus;

  @override
  Future<ArrivalResult?> refreshLocation() => _controller.refreshLocation();
  @override
  Future<bool> start() => _controller.start();
  @override
  Future<ArrivalResult?> confirmArrival() => _controller.confirmArrival();
  @override
  Future<bool> togglePause() => _controller.togglePause();
  @override
  Future<bool> abandon() => _controller.abandon();

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}

class MissionHistoryFacade extends ChangeNotifier
    implements IMissionHistoryFacade {
  MissionHistoryFacade() : _controller = MissionHistoryController() {
    _controller.addListener(notifyListeners);
  }

  final MissionHistoryController _controller;

  @override
  MissionHistoryFilter get filter => _controller.filter;
  @override
  List<MissionHistoryItem> get visibleMissions => _controller.visibleMissions;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  String? get error => _controller.error;

  @override
  Future<void> load() => _controller.load();
  @override
  Future<MissionLaunch?> loadCurrentMission() =>
      _controller.loadCurrentMission();
  @override
  void selectFilter(MissionHistoryFilter value) =>
      _controller.selectFilter(value);

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}
