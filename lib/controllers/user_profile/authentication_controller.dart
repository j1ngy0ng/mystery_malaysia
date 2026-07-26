import 'package:flutter/foundation.dart';

import '../../errors/api_error.dart';
import '../../services/supabase/supabase_auth_service.dart';

class AuthenticationController extends ChangeNotifier {
  AuthenticationController({SupabaseAuthService? authService})
    : _authService = authService ?? SupabaseAuthService();

  final SupabaseAuthService _authService;

  bool obscurePassword = true;
  bool isLoading = false;
  String? error;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      error = 'Please enter your email and password.';
      notifyListeners();
      return false;
    }
    if (!email.contains('@')) {
      error = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    return _run(() => _authService.signIn(email: email, password: password));
  }

  Future<RegistrationResult?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (username.trim().length < 3) {
      error = 'Username must contain at least 3 characters.';
      notifyListeners();
      return null;
    }
    if (!email.contains('@')) {
      error = 'Enter a valid email address.';
      notifyListeners();
      return null;
    }
    if (password.length < 8) {
      error = 'Password must contain at least 8 characters.';
      notifyListeners();
      return null;
    }

    bool hasSession = false;
    final success = await _run(() async {
      hasSession = await _authService.signUp(
        username: username,
        email: email,
        password: password,
      );
    });
    if (!success) return null;
    return hasSession
        ? RegistrationResult.signedIn
        : RegistrationResult.emailConfirmationRequired;
  }

  Future<bool> sendPasswordReset(String email) async {
    if (!email.contains('@')) {
      error = 'Enter a valid registered email address.';
      notifyListeners();
      return false;
    }
    return _run(() => _authService.sendPasswordReset(email));
  }

  Future<bool> _run(Future<void> Function() operation) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on ApiError catch (apiError) {
      error = apiError.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

enum RegistrationResult { signedIn, emailConfirmationRequired }
