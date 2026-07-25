import 'package:flutter/foundation.dart';

import '../../models/active_mission/mission_session.dart';

class ActiveMissionController extends ChangeNotifier {
  MissionSession session = const MissionSession(
    title: 'Lanterns & Legends',
    region: 'Kuala Lumpur',
    currentStage: 2,
    totalStages: 3,
    distanceMetres: 420,
    status: MissionStatus.active,
  );

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

  void moveCloser() {
    session = session.copyWith(
      distanceMetres: (session.distanceMetres - 90).clamp(40, 9999),
    );
    notifyListeners();
  }

  void abandon() {
    session = session.copyWith(status: MissionStatus.abandoned);
    notifyListeners();
  }
}
