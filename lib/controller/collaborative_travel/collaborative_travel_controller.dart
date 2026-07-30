import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/collaborative_travel/mission_participant.dart';
import '../services/supabase/supabase_data_service.dart';

class CollaborativeTravelController extends ChangeNotifier {
  CollaborativeTravelController({
    this.sessionId,
    SupabaseDataService? dataService,
  }) : _dataService = dataService ?? SupabaseDataService();

  final SupabaseDataService _dataService;
  String? sessionId;
  String title = 'Shared mystery mission';
  String status = 'waiting';
  String? viewerId;
  bool isHost = false;
  List<MissionParticipant> participants = const [];
  List<SharedMissionSummary> sessions = const [];
  List<SharedInvitation> invitations = const [];
  bool isReady = false;
  bool isLoading = false;
  String? error;
  String? message;

  Future<void> loadOverview() async {
    await _run(() async {
      final result = await _dataService.loadSharedOverview();
      sessions = result.sessions;
      invitations = result.invitations;
    });
  }

  Future<void> loadLobby() async {
    if (sessionId == null) return;
    await _run(() async {
      final data = await _dataService.sharedMission({
        'action': 'lobby',
        'session_id': sessionId,
      });
      final session = Map<String, dynamic>.from(data['session'] as Map);
      final viewer = Map<String, dynamic>.from(data['viewer'] as Map);
      title = session['title'] as String;
      status = session['status'] as String;
      viewerId = viewer['user_id'] as String;
      isHost = viewer['role'] == 'host';
      participants = (data['members'] as List)
          .whereType<Map>()
          .map(
            (row) =>
                MissionParticipant.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
      isReady = participants
          .where((member) => member.userId == viewerId)
          .any((member) => member.state == ParticipantState.ready);
    });
  }

  Future<bool> invite(String email) =>
      _mutation({'action': 'invite', 'session_id': sessionId, 'email': email});

  Future<bool> respond(String invitationId, bool accept) => _mutation({
    'action': 'respond',
    'invitation_id': invitationId,
    'response': accept ? 'accepted' : 'declined',
  }, reloadOverview: true);

  Future<bool> remove(String memberId) => _mutation({
    'action': 'remove',
    'session_id': sessionId,
    'member_id': memberId,
  });

  Future<bool> toggleReady() => _mutation({
    'action': 'ready',
    'session_id': sessionId,
    'ready': !isReady,
  });

  Future<bool> start() =>
      _mutation({'action': 'start', 'session_id': sessionId});

  Future<bool> submitReflection(String reflection) => _mutation({
    'action': 'reflection',
    'session_id': sessionId,
    'reflection': reflection,
  });

  Future<bool> _mutation(
    Map<String, dynamic> body, {
    bool reloadOverview = false,
  }) async {
    var success = false;
    await _run(() async {
      final data = await _dataService.sharedMission(body);
      message = data['message'] as String?;
      if (data['session_id'] is String) {
        sessionId = data['session_id'] as String;
      }
      success = true;
      if (reloadOverview) {
        final overview = await _dataService.loadSharedOverview();
        sessions = overview.sessions;
        invitations = overview.invitations;
      } else if (sessionId != null) {
        final lobby = await _dataService.sharedMission({
          'action': 'lobby',
          'session_id': sessionId,
        });
        final session = Map<String, dynamic>.from(lobby['session'] as Map);
        final viewer = Map<String, dynamic>.from(lobby['viewer'] as Map);
        title = session['title'] as String;
        status = session['status'] as String;
        viewerId = viewer['user_id'] as String;
        isHost = viewer['role'] == 'host';
        participants = (lobby['members'] as List)
            .whereType<Map>()
            .map(
              (row) =>
                  MissionParticipant.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false);
        isReady = participants
            .where((member) => member.userId == viewerId)
            .any((member) => member.state == ParticipantState.ready);
      }
    });
    return success;
  }

  Future<void> _run(Future<void> Function() operation) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await operation();
    } on ApiError catch (apiError) {
      error = apiError.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
