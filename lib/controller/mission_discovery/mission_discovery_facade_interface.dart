import 'package:flutter/foundation.dart';

import '../../model/active_mission/app_location.dart';
import '../../model/active_mission/mission_session.dart';
import '../../model/mission_discovery/mission_recommendation.dart';

abstract interface class IMissionDiscoveryFacade implements Listenable {
  String get selectedCategory;
  double get budget;
  double get duration;
  bool get isGenerating;
  bool get isLocating;
  AppLocation? get currentLocation;
  String? get locationError;
  String? get generationError;
  bool get hasLocation;
  String get locationLabel;
  List<String> get categories;
  List<MissionRecommendation> get recommendations;

  void selectCategory(String value);
  void updateBudget(double value);
  void updateDuration(double value);
  Future<void> detectCurrentLocation();
  Future<bool> generate();
  Future<MissionLaunch> startMission(String recommendationId);
  Future<String> createSharedMission(String recommendationId);
  Future<MissionRecommendation> regenerateStop(
    String recommendationId,
    int stopNumber,
  );
  void dispose();
}
