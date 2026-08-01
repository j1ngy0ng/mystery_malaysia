import 'package:flutter/foundation.dart';

import 'mission_discovery_controller.dart';
import 'mission_discovery_facade_interface.dart';
import '../../model/active_mission/app_location.dart';
import '../../model/active_mission/mission_session.dart';
import '../../model/mission_discovery/mission_recommendation.dart';
import '../services/supabase/supabase_data_service.dart';

class MissionDiscoveryFacade extends ChangeNotifier
    implements IMissionDiscoveryFacade {
  MissionDiscoveryFacade({List<MissionRecommendation>? recommendations})
    : _controller = MissionDiscoveryController(
        initialRecommendations: recommendations,
      ) {
    _controller.addListener(notifyListeners);
  }

  final MissionDiscoveryController _controller;
  final SupabaseDataService _dataService = SupabaseDataService();

  @override
  double get budget => _controller.budget;
  @override
  double get duration => _controller.duration;
  @override
  double get maximumDistance => _controller.maximumDistance;
  @override
  DateTime get intendedStartAt => _controller.intendedStartAt;
  @override
  bool get isGenerating => _controller.isGenerating;
  @override
  bool get isLocating => _controller.isLocating;
  @override
  AppLocation? get currentLocation => _controller.currentLocation;
  @override
  String? get locationError => _controller.locationError;
  @override
  String? get generationError => _controller.generationError;
  @override
  bool get hasLocation => _controller.hasLocation;
  @override
  String get locationLabel => _controller.locationLabel;
  @override
  List<MissionRecommendation> get recommendations =>
      _controller.recommendations;

  @override
  void updateSchedule(DateTime value) => _controller.updateSchedule(value);
  @override
  void updateBudget(double value) => _controller.updateBudget(value);
  @override
  void updateDuration(double value) => _controller.updateDuration(value);
  @override
  void updateMaximumDistance(double value) =>
      _controller.updateMaximumDistance(value);
  @override
  Future<void> detectCurrentLocation() => _controller.detectCurrentLocation();
  @override
  Future<bool> generate() => _controller.generate();
  @override
  Future<MissionLaunch> selectMission(String recommendationId) =>
      _dataService.selectMission(recommendationId);
  @override
  Future<String> createSharedMission(String recommendationId) =>
      _dataService.createSharedMission(recommendationId);
  @override
  Future<MissionRecommendation> regenerateStop(
    String recommendationId,
    int stopNumber,
  ) => _dataService.regenerateStop(recommendationId, stopNumber);

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}
