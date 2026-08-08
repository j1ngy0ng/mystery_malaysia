import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/api_error.dart';
import '../config/app_config.dart';
import '../demo/demo_api_manager.dart';
import '../../../model/active_mission/app_location.dart';
import '../../../model/active_mission/destination_guide.dart';
import '../../../model/active_mission/mission_history_item.dart';
import '../../../model/active_mission/mission_session.dart';
import '../../../model/collaborative_travel/mission_participant.dart';
import '../../../model/mission_discovery/mission_recommendation.dart';
import '../../../model/passport_diary/traveller_progress.dart';
import '../../../model/user_profile/app_notification.dart';

class SupabaseDataService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> loadOwnProfile() async {
    if (AppConfig.demoMode) {
      return Map<String, dynamic>.from(DemoApiManager.instance.profile);
    }
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ApiError('Sign in to load your profile.');
    }

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      final avatarPath = profile['avatar_path'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        profile['avatar_url'] = await _client.storage
            .from('avatars')
            .createSignedUrl(avatarPath, 3600);
      }
      return profile;
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<void> updateOwnProfile({
    required String displayName,
    required String username,
    String? gender,
    String? phoneNumber,
  }) async {
    if (AppConfig.demoMode) {
      DemoApiManager.instance.updateProfile(
        displayName: displayName,
        username: username,
        gender: gender,
        phoneNumber: phoneNumber,
      );
      return;
    }
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ApiError('Sign in to update your profile.');
    }

    try {
      await _client
          .from('profiles')
          .update({
            'display_name': displayName.trim(),
            'username': username.trim(),
            'gender': gender,
            'phone_number': phoneNumber?.trim().isEmpty == true
                ? null
                : phoneNumber?.trim(),
          })
          .eq('id', user.id);
    } on PostgrestException catch (error) {
      throw ApiError(
        error.code == '23505'
            ? 'This username has been used. Choose another username.'
            : error.message,
        code: error.code,
      );
    }
  }

  Future<String> uploadAvatar(
    Uint8List bytes, {
    required String extension,
  }) async {
    if (AppConfig.demoMode) return '';
    final user = _client.auth.currentUser;
    if (user == null) throw const ApiError('Sign in to update your photo.');
    final safeExtension = extension.toLowerCase() == 'png' ? 'png' : 'jpg';
    final path = '${user.id}/avatar.$safeExtension';
    try {
      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: safeExtension == 'png' ? 'image/png' : 'image/jpeg',
            ),
          );
      await _client
          .from('profiles')
          .update({'avatar_path': path})
          .eq('id', user.id);
      return await _client.storage.from('avatars').createSignedUrl(path, 3600);
    } on StorageException catch (error) {
      throw ApiError(error.message, code: error.statusCode);
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<List<AppNotification>> loadNotifications({int limit = 50}) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.loadNotifications().take(limit).toList();
    }
    final user = _client.auth.currentUser;
    if (user == null) throw const ApiError('Sign in to view notifications.');
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(AppNotification.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<void> markNotificationRead(String id, DateTime readAt) async {
    if (AppConfig.demoMode) {
      DemoApiManager.instance.markNotificationRead(id, readAt);
      return;
    }
    final user = _client.auth.currentUser;
    if (user == null) throw const ApiError('Sign in to update notifications.');
    try {
      await _client
          .from('notifications')
          .update({'read_at': readAt.toIso8601String()})
          .eq('id', id)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<void> markAllNotificationsRead(DateTime readAt) async {
    if (AppConfig.demoMode) {
      DemoApiManager.instance.markAllNotificationsRead(readAt);
      return;
    }
    final user = _client.auth.currentUser;
    if (user == null) throw const ApiError('Sign in to update notifications.');
    try {
      await _client
          .from('notifications')
          .update({'read_at': readAt.toIso8601String()})
          .eq('user_id', user.id)
          .isFilter('read_at', null);
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<MissionLaunch> selectMission(String recommendationId) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.selectMission(recommendationId);
    }
    _requireUser('Sign in before choosing a mission.');
    try {
      final response = await _client.functions.invoke(
        'start-mission',
        body: {'action': 'select', 'recommendation_id': recommendationId},
      );
      return MissionLaunch.fromJson(_responseMap(response.data));
    } on FunctionException catch (error) {
      throw ApiError(
        _functionMessage(error, 'The mission could not be saved.'),
      );
    }
  }

  Future<MissionLaunch> startSelectedMission(String sessionId) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.startSelectedMission(sessionId);
    }
    _requireUser('Sign in before starting a mission.');
    try {
      await _client.functions.invoke(
        'start-mission',
        body: {'action': 'start', 'session_id': sessionId},
      );
      final mission = await loadCurrentMission();
      if (mission == null || mission.sessionId != sessionId) {
        throw const ApiError('The started mission could not be loaded.');
      }
      return mission;
    } on FunctionException catch (error) {
      throw ApiError(_functionMessage(error, 'The mission could not start.'));
    }
  }

  Future<String> createSharedMission(String recommendationId) async {
    if (AppConfig.demoMode) return 'demo-shared';
    _requireUser('Sign in before creating a shared mission.');
    try {
      final response = await _client.functions.invoke(
        'start-mission',
        body: {'recommendation_id': recommendationId, 'mode': 'collaborative'},
      );
      return _responseMap(response.data)['session_id'] as String;
    } on FunctionException catch (error) {
      throw ApiError(
        _functionMessage(error, 'The shared mission could not be created.'),
      );
    }
  }

  Future<Map<String, dynamic>> sharedMission(Map<String, dynamic> body) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.sharedMission(body);
    }
    _requireUser('Sign in to manage shared missions.');
    try {
      final response = await _client.functions.invoke(
        'shared-mission',
        body: body,
      );
      return _responseMap(response.data);
    } on FunctionException catch (error) {
      throw ApiError(
        _functionMessage(error, 'The shared mission could not update.'),
      );
    }
  }

  Future<
    ({List<SharedMissionSummary> sessions, List<SharedInvitation> invitations})
  >
  loadSharedOverview() async {
    final data = await sharedMission({'action': 'overview'});
    List<T> parse<T>(dynamic value, T Function(Map<String, dynamic>) convert) =>
        value is List
        ? value
              .whereType<Map>()
              .map((row) => convert(Map<String, dynamic>.from(row)))
              .toList()
        : <T>[];
    return (
      sessions: parse(data['sessions'], SharedMissionSummary.fromJson),
      invitations: parse(data['invitations'], SharedInvitation.fromJson),
    );
  }

  Future<ArrivalResult> confirmArrival({
    required String sessionId,
    required AppLocation location,
  }) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.confirmArrival(sessionId, location);
    }
    _requireUser('Sign in before confirming arrival.');
    try {
      final response = await _client.functions.invoke(
        'confirm-arrival',
        body: {
          'session_id': sessionId,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy_metres': location.accuracyMetres ?? 0,
        },
      );
      return ArrivalResult.fromJson(_responseMap(response.data));
    } on FunctionException catch (error) {
      throw ApiError(_functionMessage(error, 'Arrival verification failed.'));
    }
  }

  Future<List<MissionHistoryItem>> loadMissionHistory() async {
    final data = await _missionControl({'action': 'history'});
    final raw = data['missions'];
    return raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => MissionHistoryItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const [];
  }

  Future<MissionLaunch?> loadCurrentMission() async {
    final data = await _missionControl({'action': 'current'});
    final mission = data['mission'];
    return mission is Map && mission['clue'] is Map
        ? MissionLaunch.fromSummary(Map<String, dynamic>.from(mission))
        : null;
  }

  Future<MissionStatus> updateMissionStatus(
    String sessionId,
    String action,
  ) async {
    final data = await _missionControl({
      'action': action,
      'session_id': sessionId,
    });
    return missionStatusFromJson(data['status'] as String? ?? '');
  }

  Future<String> missionProximity(
    String sessionId,
    AppLocation location,
  ) async {
    final data = await _missionControl({
      'action': 'proximity',
      'session_id': sessionId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy_metres': location.accuracyMetres ?? 999,
    });
    return data['level'] as String? ?? 'unknown';
  }

  Future<({String hint, bool alreadyUsed})> requestHint(
    String sessionId,
  ) async {
    final data = await _missionControl({
      'action': 'hint',
      'session_id': sessionId,
    });
    return (
      hint: data['hint'] as String? ?? '',
      alreadyUsed: data['already_used'] == true,
    );
  }

  Future<void> recordClueViewed(String sessionId) async {
    await _missionControl({'action': 'clue_viewed', 'session_id': sessionId});
  }

  Future<MissionRecommendation> regenerateStop(
    String recommendationId,
    int stopNumber,
  ) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.regenerateStop(
        recommendationId,
        stopNumber,
      );
    }
    _requireUser('Sign in before changing a mission.');
    try {
      final response = await _client.functions.invoke(
        'regenerate-stop',
        body: {
          'recommendation_id': recommendationId,
          'stop_number': stopNumber,
        },
      );
      final data = _responseMap(response.data);
      return MissionRecommendation.fromJson(
        Map<String, dynamic>.from(data['recommendation'] as Map),
      );
    } on FunctionException catch (error) {
      throw ApiError(_functionMessage(error, 'The stop could not be changed.'));
    }
  }

  Future<TravellerProgress> loadTravellerProgress() async {
    final data = await _passportDiary({'action': 'dashboard'});
    return TravellerProgress.fromJson(data);
  }

  Future<
    ({
      bool generated,
      bool draftSaved,
      String title,
      String content,
      String message,
    })
  >
  generateDiary(String sessionId, String reflection) async {
    final data = await _passportDiary({
      'action': 'generate_diary',
      'session_id': sessionId,
      'reflection': reflection,
    });
    return (
      generated: data['generated'] == true,
      draftSaved: data['draft_saved'] == true,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      message: data['message'] as String? ?? '',
    );
  }

  Future<void> saveDiaryReflection(String sessionId, String reflection) async {
    await _passportDiary({
      'action': 'save_reflection',
      'session_id': sessionId,
      'reflection': reflection,
    });
  }

  Future<GroupDiaryState> loadGroupDiaryState(String sessionId) async {
    final data = await _passportDiary({
      'action': 'group_diary_status',
      'session_id': sessionId,
    });
    return GroupDiaryState.fromJson(data);
  }

  Future<({DiaryMemory diary, String message})> generateGroupDiary(
    String sessionId,
  ) async {
    final data = await _passportDiary({
      'action': 'generate_group_diary',
      'session_id': sessionId,
    });
    return (
      diary: DiaryMemory.fromJson(
        Map<String, dynamic>.from(data['diary'] as Map),
      ),
      message: data['message'] as String? ?? 'Shared diary ready.',
    );
  }

  Future<String> saveDiary({
    required String sessionId,
    required String title,
    required String content,
  }) async {
    final data = await _passportDiary({
      'action': 'save_diary',
      'session_id': sessionId,
      'title': title,
      'content': content,
    });
    return data['message'] as String? ?? 'Diary saved.';
  }

  Future<Map<String, dynamic>> _passportDiary(Map<String, dynamic> body) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.passportDiary(body);
    }
    _requireUser('Sign in to view your passport.');
    try {
      final response = await _client.functions.invoke(
        'passport-diary',
        body: body,
      );
      return _responseMap(response.data);
    } on FunctionException catch (error) {
      throw ApiError(_functionMessage(error, 'Passport service unavailable.'));
    }
  }

  Future<Map<String, dynamic>> _missionControl(
    Map<String, dynamic> body,
  ) async {
    if (AppConfig.demoMode) {
      return DemoApiManager.instance.missionControl(body);
    }
    _requireUser('Sign in to manage your mission.');
    try {
      final response = await _client.functions.invoke(
        'mission-control',
        body: body,
      );
      return _responseMap(response.data);
    } on FunctionException catch (error) {
      throw ApiError(_functionMessage(error, 'The mission could not update.'));
    }
  }

  void _requireUser(String message) {
    if (_client.auth.currentUser == null) throw ApiError(message);
  }

  Map<String, dynamic> _responseMap(dynamic data) {
    if (data is! Map) {
      throw const ApiError('The server returned an invalid response.');
    }
    return Map<String, dynamic>.from(data);
  }

  String _functionMessage(FunctionException error, String fallback) {
    final details = error.details;
    return details is Map && details['message'] is String
        ? details['message'] as String
        : error.reasonPhrase ?? fallback;
  }
}
