import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/active_mission/app_location.dart';
import '../../model/mission_discovery/mission_recommendation.dart';
import '../services/device/location_service.dart';
import '../services/gemini/gemini_service.dart';

class MissionDiscoveryController extends ChangeNotifier {
  MissionDiscoveryController({
    LocationService? locationService,
    GeminiService? geminiService,
    List<MissionRecommendation>? initialRecommendations,
  }) : _locationService = locationService ?? LocationService(),
       _geminiService = geminiService ?? GeminiService(),
       recommendations = List.of(initialRecommendations ?? demoRecommendations);

  final LocationService _locationService;
  final GeminiService _geminiService;

  double budget = 120;
  double duration = 4;
  double maximumDistance = 20;
  DateTime intendedStartAt = _initialStart();
  bool isGenerating = false;
  bool isLocating = false;
  AppLocation? currentLocation;
  String? locationError;
  String? generationError;

  bool get hasLocation => currentLocation != null;

  String get locationLabel {
    final location = currentLocation;
    if (location == null) return 'Waiting for GPS';
    return '${location.coordinateLabel} • GPS detected';
  }

  static const demoRecommendations = [
    MissionRecommendation(
      title: 'Lanterns & Legends',
      briefing:
          'Follow old shophouse stories, aromatic lanes and a final riverside secret.',
      matchReason: 'Great match for culture, food and a relaxed half-day.',
      duration: '3h 40m',
      budget: 'RM 65',
      difficulty: 'Easy',
      stops: 3,
      colorValue: 0xFFFF6B6B,
      iconKey: 'lantern',
    ),
    MissionRecommendation(
      title: 'Rainforest Riddle',
      briefing:
          'Chase cool air, giant leaves and a viewpoint hiding above the city.',
      matchReason: 'Fits your outdoor mood while staying under budget.',
      duration: '4h 15m',
      budget: 'RM 90',
      difficulty: 'Medium',
      stops: 3,
      colorValue: 0xFF12B8A6,
      iconKey: 'forest',
    ),
    MissionRecommendation(
      title: 'Spice Route Secrets',
      briefing:
          'Decode a trail of local flavours, market sounds and heritage kitchens.',
      matchReason: 'A playful food-first route with short travel times.',
      duration: '2h 50m',
      budget: 'RM 78',
      difficulty: 'Easy',
      stops: 3,
      colorValue: 0xFFFFBF3F,
      iconKey: 'food',
    ),
  ];

  final List<MissionRecommendation> recommendations;

  void updateSchedule(DateTime value) {
    intendedStartAt = value;
    notifyListeners();
  }

  void updateBudget(double value) {
    budget = value;
    notifyListeners();
  }

  void updateDuration(double value) {
    duration = value;
    notifyListeners();
  }

  void updateMaximumDistance(double value) {
    maximumDistance = value;
    notifyListeners();
  }

  Future<void> detectCurrentLocation() async {
    isLocating = true;
    locationError = null;
    notifyListeners();

    try {
      currentLocation = await _locationService.getCurrentLocation();
    } on LocationServiceException catch (error) {
      locationError = error.message;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  Future<bool> generate() async {
    if (!intendedStartAt.isAfter(DateTime.now())) {
      generationError = 'Choose a start date and time in the future.';
      notifyListeners();
      return false;
    }
    final location = currentLocation;
    if (location == null) {
      generationError = 'A GPS location is required to generate missions.';
      notifyListeners();
      return false;
    }

    isGenerating = true;
    generationError = null;
    notifyListeners();
    try {
      final generated = await _geminiService.generateMissions(
        origin: location,
        categories: const [],
        availableMinutes: (duration * 60).round(),
        budgetMyr: budget,
        maximumDistanceKm: maximumDistance,
        intendedStartAt: intendedStartAt,
      );
      recommendations
        ..clear()
        ..addAll(generated);
      return true;
    } on ApiError catch (error) {
      generationError = error.message;
      return false;
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  static DateTime _initialStart() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }
}
