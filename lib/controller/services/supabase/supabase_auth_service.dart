import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/api_error.dart';

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
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    try {
      final available = await _client.rpc<bool>(
        'is_username_available',
        params: {'candidate': username.trim()},
      );
      if (!available) {
        throw const ApiError(
          'This username has been used. Choose another username.',
          code: 'duplicate_username',
        );
      }
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AppConfig.authCallbackUrl,
        data: {
          'username': username.trim(),
          'display_name': username.trim(),
          'gender': gender,
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        },
      );
      return response.session != null;
    } on ApiError {
      rethrow;
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

  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
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
