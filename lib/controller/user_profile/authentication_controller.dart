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
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmationPasswordError;
  String? genderError;
  String? dateOfBirthError;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _clearErrors();
    if (!_validEmail(email)) emailError = 'Enter a valid email address.';
    if (password.isEmpty) passwordError = 'Enter your password.';
    if (emailError != null || passwordError != null) {
      notifyListeners();
      return false;
    }
    return _run(() async {
      if (!await _authService.isEmailRegistered(email)) {
        throw const ApiError(
          'No account is registered with this email.',
          code: 'email_not_registered',
        );
      }
      await _authService.signIn(email: email, password: password);
    }, flow: 'sign_in');
  }

  Future<RegistrationResult?> register({
    required String username,
    required String email,
    required String password,
    required String confirmationPassword,
    required String gender,
    required DateTime? dateOfBirth,
  }) async {
    _clearErrors();
    if (username.trim().length < 3) {
      usernameError = 'Username must contain at least 3 characters.';
    }
    if (!_validEmail(email)) emailError = 'Enter a valid email address.';
    final strongPassword =
        password.length >= 8 &&
        password.contains(RegExp('[A-Z]')) &&
        password.contains(RegExp('[a-z]')) &&
        password.contains(RegExp('[0-9]')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'));
    if (!strongPassword) {
      passwordError =
          'Use 8+ characters with uppercase, lowercase, number and symbol.';
    }
    if (password != confirmationPassword) {
      confirmationPasswordError = 'The passwords do not match.';
    }
    if (gender.isEmpty) genderError = 'Select a gender option.';
    if (dateOfBirth == null) dateOfBirthError = 'Select your date of birth.';
    if (usernameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmationPasswordError != null ||
        genderError != null ||
        dateOfBirthError != null) {
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
        dateOfBirth: dateOfBirth!,
      );
    }, flow: 'registration');
    if (!success) return null;
    return hasSession
        ? RegistrationResult.signedIn
        : RegistrationResult.emailConfirmationRequired;
  }

  Future<bool> sendPasswordReset(String email) async {
    _clearErrors();
    if (!_validEmail(email)) {
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
    _clearErrors();
    final strongPassword =
        password.length >= 8 &&
        password.contains(RegExp('[A-Z]')) &&
        password.contains(RegExp('[a-z]')) &&
        password.contains(RegExp('[0-9]')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'));
    if (!strongPassword) {
      passwordError =
          'Use 8+ characters with uppercase, lowercase, number and symbol.';
      notifyListeners();
      return false;
    }
    if (password != confirmationPassword) {
      confirmationPasswordError = 'The passwords do not match.';
      notifyListeners();
      return false;
    }
    return _run(() => _authService.updatePassword(password));
  }

  Future<bool> _run(Future<void> Function() operation, {String? flow}) async {
    isLoading = true;
    _clearErrors();
    notifyListeners();
    try {
      await operation();
      return true;
    } on ApiError catch (apiError) {
      if (flow == 'registration') {
        if (apiError.code == 'duplicate_username') {
          usernameError = apiError.message;
        } else {
          emailError = apiError.message;
        }
      } else if (flow == 'sign_in') {
        if (apiError.code == 'email_not_registered' ||
            apiError.code == 'email_not_confirmed') {
          emailError = apiError.message;
        } else {
          passwordError = apiError.message;
        }
      } else {
        error = apiError.message;
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  void _clearErrors() {
    error = null;
    usernameError = null;
    emailError = null;
    passwordError = null;
    confirmationPasswordError = null;
    genderError = null;
    dateOfBirthError = null;
  }
}
