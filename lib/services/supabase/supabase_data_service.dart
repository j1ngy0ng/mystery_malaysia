import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/api_error.dart';

class SupabaseDataService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> loadOwnProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ApiError('Sign in to load your profile.');
    }

    try {
      return await _client.from('profiles').select().eq('id', user.id).single();
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<void> updateOwnProfile({
    required String displayName,
    required String username,
  }) async {
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
          })
          .eq('id', user.id);
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }
}
