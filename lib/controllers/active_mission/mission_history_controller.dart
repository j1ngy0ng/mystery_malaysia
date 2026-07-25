import 'package:flutter/foundation.dart';

import '../../models/active_mission/mission_history_item.dart';
import '../../models/active_mission/mission_session.dart';

enum MissionHistoryFilter { all, active, paused, completed }

class MissionHistoryController extends ChangeNotifier {
  MissionHistoryFilter filter = MissionHistoryFilter.all;

  final missions = const [
    MissionHistoryItem(
      title: 'Lanterns & Legends',
      region: 'Kuala Lumpur',
      dateLabel: 'Today',
      status: MissionStatus.active,
      currentStage: 2,
      totalStages: 3,
      emoji: '🏮',
    ),
    MissionHistoryItem(
      title: 'Spice Route Secrets',
      region: 'George Town, Penang',
      dateLabel: 'Paused 20 Jul 2026',
      status: MissionStatus.paused,
      currentStage: 1,
      totalStages: 4,
      emoji: '🍜',
    ),
    MissionHistoryItem(
      title: 'Riverside Timekeeper',
      region: 'Melaka',
      dateLabel: 'Completed 18 Jul 2026',
      status: MissionStatus.completed,
      currentStage: 3,
      totalStages: 3,
      emoji: '🕰️',
    ),
    MissionHistoryItem(
      title: 'Clouds Above the City',
      region: 'Penang',
      dateLabel: 'Completed 02 Jul 2026',
      status: MissionStatus.completed,
      currentStage: 4,
      totalStages: 4,
      emoji: '☁️',
    ),
    MissionHistoryItem(
      title: 'Village Flavours',
      region: 'Kuala Lumpur',
      dateLabel: 'Completed 14 Jun 2026',
      status: MissionStatus.completed,
      currentStage: 3,
      totalStages: 3,
      emoji: '🏠',
    ),
  ];

  List<MissionHistoryItem> get visibleMissions {
    return switch (filter) {
      MissionHistoryFilter.all => missions,
      MissionHistoryFilter.active =>
        missions
            .where((mission) => mission.status == MissionStatus.active)
            .toList(),
      MissionHistoryFilter.paused =>
        missions
            .where((mission) => mission.status == MissionStatus.paused)
            .toList(),
      MissionHistoryFilter.completed =>
        missions
            .where((mission) => mission.status == MissionStatus.completed)
            .toList(),
    };
  }

  void selectFilter(MissionHistoryFilter value) {
    filter = value;
    notifyListeners();
  }
}
