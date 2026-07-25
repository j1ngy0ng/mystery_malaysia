import 'package:flutter/foundation.dart';

import '../../models/collaborative_travel/mission_participant.dart';

class CollaborativeTravelController extends ChangeNotifier {
  final participants = const [
    MissionParticipant(
      name: 'Aina',
      initials: 'AN',
      state: ParticipantState.ready,
      isHost: true,
      colorValue: 0xFFFF6B6B,
    ),
    MissionParticipant(
      name: 'Kumar',
      initials: 'KU',
      state: ParticipantState.nearby,
      isHost: false,
      colorValue: 0xFF6C4CE6,
    ),
    MissionParticipant(
      name: 'Mei Ling',
      initials: 'ML',
      state: ParticipantState.ready,
      isHost: false,
      colorValue: 0xFF12B8A6,
    ),
    MissionParticipant(
      name: 'Farah',
      initials: 'FA',
      state: ParticipantState.invited,
      isHost: false,
      colorValue: 0xFFFFBF3F,
    ),
  ];

  String lastInvite = '';
  bool isReady = false;

  void invite(String email) {
    lastInvite = email.trim();
    notifyListeners();
  }

  void toggleReady() {
    isReady = !isReady;
    notifyListeners();
  }
}
