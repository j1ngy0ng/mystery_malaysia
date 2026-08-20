import 'package:flutter/foundation.dart';

import '../../model/active_mission/mission_session.dart';
import '../../model/collaborative_travel/mission_participant.dart';

abstract interface class ICollaborativeTravelFacade implements Listenable {
  String? get sessionId;
  String get title;
  String get status;
  String? get viewerId;
  bool get isHost;
  List<MissionParticipant> get participants;
  List<SharedMissionSummary> get sessions;
  List<SharedInvitation> get invitations;
  bool get isReady;
  bool get isLoading;
  String? get error;
  String? get message;

  Future<void> loadOverview();
  Future<void> loadLobby();
  Future<bool> invite(String email);
  Future<bool> respond(String invitationId, bool accept);
  Future<bool> remove(String memberId);
  Future<bool> leave();
  Future<bool> toggleReady();
  Future<bool> start();
  Future<MissionLaunch?> loadCurrentMission();
  void dispose();
}
