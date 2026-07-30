import 'package:flutter/foundation.dart';

import '../../model/active_mission/app_location.dart';
import '../../model/active_mission/destination_guide.dart';
import '../../model/active_mission/mission_history_item.dart';
import '../../model/active_mission/mission_session.dart';
import '../../model/clue_hint/mystery_clue.dart';

abstract interface class IActiveMissionFacade implements Listenable {
  String? get sessionId;
  MissionSession get session;
  MysteryClue get currentClue;
  AppLocation? get currentLocation;
  bool get isLocating;
  bool get isVerifying;
  bool get isUpdatingStatus;
  bool get canConfirmArrival;
  String? get locationError;
  String? get arrivalError;
  String get temperature;
  String get mapStatus;

  Future<void> refreshLocation();
  Future<ArrivalResult?> confirmArrival();
  Future<bool> togglePause();
  Future<bool> abandon();
  void dispose();
}

abstract interface class IMissionHistoryFacade implements Listenable {
  MissionHistoryFilter get filter;
  List<MissionHistoryItem> get visibleMissions;
  bool get isLoading;
  String? get error;

  Future<void> load();
  Future<MissionLaunch?> loadCurrentMission();
  void selectFilter(MissionHistoryFilter value);
  void dispose();
}
