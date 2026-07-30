import 'package:flutter/foundation.dart';

import '../services/errors/api_error.dart';
import '../../model/user_profile/registration_result.dart';
import '../services/supabase/supabase_auth_service.dart';

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
    required String confirmationPassword,
    required String gender,
    required DateTime? dateOfBirth,
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
    final strongPassword =
        password.length >= 8 &&
        password.contains(RegExp('[A-Z]')) &&
        password.contains(RegExp('[a-z]')) &&
        password.contains(RegExp('[0-9]')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'));
    if (!strongPassword) {
      error = 'Use 8+ characters with uppercase, lowercase, number and symbol.';
      notifyListeners();
      return null;
    }
    if (password != confirmationPassword) {
      error = 'Password and confirmation password do not match.';
      notifyListeners();
      return null;
    }
    if (gender.isEmpty || dateOfBirth == null) {
      error = 'Gender and date of birth are required.';
      notifyListeners();
      return null;
    }

    bool hasSession = false;
    final success = await _run(() async {
      hasSession = await _authService.signUp(
        username: username,
        email: email,
        password: password,
        gender: gender,
        dateOfBirth: dateOfBirth,
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

  Future<bool> updatePassword(
    String password,
    String confirmationPassword,
  ) async {
    final strongPassword =
        password.length >= 8 &&
        password.contains(RegExp('[A-Z]')) &&
        password.contains(RegExp('[a-z]')) &&
        password.contains(RegExp('[0-9]')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'));
    if (!strongPassword) {
      error = 'Use 8+ characters with uppercase, lowercase, number and symbol.';
      notifyListeners();
      return false;
    }
    if (password != confirmationPassword) {
      error = 'Password and confirmation password do not match.';
      notifyListeners();
      return false;
    }
    return _run(() => _authService.updatePassword(password));
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
