import 'package:flutter/foundation.dart';

import 'collaborative_travel_controller.dart';
import 'collaborative_travel_facade_interface.dart';
import '../../model/active_mission/mission_session.dart';
import '../../model/collaborative_travel/mission_participant.dart';
import '../services/supabase/supabase_data_service.dart';

class CollaborativeTravelFacade extends ChangeNotifier
    implements ICollaborativeTravelFacade {
  CollaborativeTravelFacade({String? sessionId})
    : _controller = CollaborativeTravelController(sessionId: sessionId) {
    _controller.addListener(notifyListeners);
  }

  final CollaborativeTravelController _controller;
  final SupabaseDataService _dataService = SupabaseDataService();

  @override
  String? get sessionId => _controller.sessionId;
  @override
  String get title => _controller.title;
  @override
  String get status => _controller.status;
  @override
  String? get viewerId => _controller.viewerId;
  @override
  bool get isHost => _controller.isHost;
  @override
  List<MissionParticipant> get participants => _controller.participants;
  @override
  List<SharedMissionSummary> get sessions => _controller.sessions;
  @override
  List<SharedInvitation> get invitations => _controller.invitations;
  @override
  bool get isReady => _controller.isReady;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  String? get error => _controller.error;
  @override
  String? get message => _controller.message;

  @override
  Future<void> loadOverview() => _controller.loadOverview();
  @override
  Future<void> loadLobby() => _controller.loadLobby();
  @override
  Future<bool> invite(String email) => _controller.invite(email);
  @override
  Future<bool> respond(String invitationId, bool accept) =>
      _controller.respond(invitationId, accept);
  @override
  Future<bool> remove(String memberId) => _controller.remove(memberId);
  @override
  Future<bool> leave() => _controller.leave();
  @override
  Future<bool> toggleReady() => _controller.toggleReady();
  @override
  Future<bool> start() => _controller.start();
  @override
  Future<MissionLaunch?> loadCurrentMission() =>
      _dataService.loadCurrentMission();

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}
