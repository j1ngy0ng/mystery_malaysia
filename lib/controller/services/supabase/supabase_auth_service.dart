import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/api_error.dart';

class SupabaseAuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => AppConfig.demoMode ? null : _client.auth.currentUser;
  bool get isSignedIn => AppConfig.demoMode || currentUser != null;

  Future<bool> isEmailRegistered(String email) async {
    if (AppConfig.demoMode) return true;
    try {
      return await _client.rpc<bool>(
        'is_email_registered',
        params: {'candidate': email.trim()},
      );
    } on PostgrestException catch (error) {
      throw ApiError(error.message, code: error.code);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    if (AppConfig.demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return;
    }
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
    if (AppConfig.demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return false;
    }
    try {
      if (await isEmailRegistered(email)) {
        throw const ApiError(
          'An account already uses this email. Sign in instead.',
          code: 'user_already_exists',
        );
      }
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
    if (AppConfig.demoMode) return;
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
    if (AppConfig.demoMode) return;
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw ApiError(_authMessage(error), code: error.code);
    }
  }

  Future<void> signOut() async {
    if (AppConfig.demoMode) return;
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
      'over_email_send_rate_limit' =>
        'Too many verification emails were requested. Please wait before trying again.',
      'email_rate_limit_exceeded' =>
        'Too many verification emails were requested. Please wait before trying again.',
      'over_request_rate_limit' =>
        'Too many attempts were made. Please wait before trying again.',
      'weak_password' => 'Use a stronger password with at least 8 characters.',
      _ => error.message,
    };
  }
}
