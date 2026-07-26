import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../errors/api_error.dart';

class SupabaseAuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw ApiError(_authMessage(error), code: error.code);
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AppConfig.authCallbackUrl,
        data: {'username': username.trim(), 'display_name': username.trim()},
      );
      return response.session != null;
    } on AuthException catch (error) {
      throw ApiError(_authMessage(error), code: error.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authCallbackUrl,
      );
    } on AuthException catch (error) {
      throw ApiError(_authMessage(error), code: error.code);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw ApiError(_authMessage(error), code: error.code);
    }
  }

  String _authMessage(AuthException error) {
    return switch (error.code) {
      'invalid_credentials' => 'The email or password is incorrect.',
      'email_not_confirmed' => 'Confirm your email before signing in.',
      'user_already_exists' => 'An account already uses this email.',
      'weak_password' => 'Use a stronger password with at least 8 characters.',
      _ => error.message,
    };
  }
}
