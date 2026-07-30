import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/api_error.dart';
import '../../../model/active_mission/app_location.dart';
import '../../../model/mission_discovery/mission_recommendation.dart';

class GeminiService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<MissionRecommendation>> generateMissions({
    required AppLocation origin,
    required List<String> categories,
    required int availableMinutes,
    required double budgetMyr,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const ApiError('Sign in before generating a mission.');
    }

    try {
      final response = await _client.functions.invoke(
        'generate-mission',
        body: {
          'origin_latitude': origin.latitude,
          'origin_longitude': origin.longitude,
          'available_minutes': availableMinutes,
          'budget_myr': budgetMyr,
          'maximum_distance_km': 20,
          'categories': categories,
          'group_type': 'solo',
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw const ApiError(
          'Mission generation returned an invalid response.',
        );
      }
      final payload = Map<String, dynamic>.from(data);
      final rawRecommendations = payload['recommendations'];
      if (rawRecommendations is! List || rawRecommendations.length != 3) {
        throw ApiError(
          payload['message'] as String? ??
              'Three suitable mission choices could not be generated nearby.',
        );
      }

      return rawRecommendations
          .whereType<Map>()
          .map(
            (item) =>
                MissionRecommendation.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['message'] is String) {
        throw ApiError(details['message'] as String);
      }
      throw ApiError(error.reasonPhrase ?? 'Mission generation failed.');
    }
  }
}
