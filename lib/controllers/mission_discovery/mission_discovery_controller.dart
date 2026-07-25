import 'package:flutter/foundation.dart';

import '../../models/mission_discovery/mission_recommendation.dart';

class MissionDiscoveryController extends ChangeNotifier {
  String selectedCategory = 'Culture';
  double budget = 120;
  double duration = 4;
  bool isGenerating = false;

  final categories = const [
    'Culture',
    'Food',
    'Nature',
    'History',
    'Hidden gems',
  ];

  final recommendations = const [
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
      stops: 4,
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

  void selectCategory(String value) {
    selectedCategory = value;
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

  Future<void> generate() async {
    isGenerating = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    isGenerating = false;
    notifyListeners();
  }
}
