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
  String? resetEmailError;
  String? passwordError;
  String? confirmationPasswordError;
  String? genderError;
  String? dateOfBirthError;
  bool _emailValid = false;
  bool _resetEmailValid = false;
  bool _signInPasswordValid = false;
  bool _usernameValid = false;
  bool _registrationPasswordValid = false;
  bool _confirmationPasswordValid = false;
  bool _genderValid = false;
  bool _dateOfBirthValid = false;

  bool get canSignIn => _emailValid && _signInPasswordValid;
  bool get isSignedIn => _authService.isSignedIn;
  bool get canSendPasswordReset => _resetEmailValid;
  bool get canRegister =>
      _usernameValid &&
      _emailValid &&
      _registrationPasswordValid &&
      _confirmationPasswordValid &&
      _genderValid &&
      _dateOfBirthValid;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void validateEmail(String value) {
    emailError = _emailValidation(value);
    _emailValid = emailError == null;
    notifyListeners();
  }

  void validateResetEmail(String value) {
    resetEmailError = _emailValidation(value);
    _resetEmailValid = resetEmailError == null;
    notifyListeners();
  }

  void validateSignInPassword(String value) {
    passwordError = value.trim().isEmpty ? 'Password is required.' : null;
    _signInPasswordValid = passwordError == null;
    notifyListeners();
  }

  void validateUsername(String value) {
    usernameError = _usernameValidation(value);
    _usernameValid = usernameError == null;
    notifyListeners();
  }

  void validateRegistrationPassword(String value) {
    passwordError = _passwordValidation(value);
    _registrationPasswordValid = passwordError == null;
    notifyListeners();
  }

  void validatePasswordConfirmation(String password, String confirmation) {
    confirmationPasswordError = _confirmationValidation(password, confirmation);
    _confirmationPasswordValid = confirmationPasswordError == null;
    notifyListeners();
  }

  void validateGender(String value) {
    genderError = value.isEmpty ? 'Select a gender option.' : null;
    _genderValid = genderError == null;
    notifyListeners();
  }

  void validateDateOfBirth(DateTime? value) {
    dateOfBirthError = value == null ? 'Select your date of birth.' : null;
    _dateOfBirthValid = dateOfBirthError == null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _clearErrors();
    emailError = _emailValidation(email);
    if (password.trim().isEmpty) passwordError = 'Password is required.';
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
    usernameError = _usernameValidation(username);
    emailError = _emailValidation(email);
    passwordError = _passwordValidation(password);
    confirmationPasswordError = _confirmationValidation(
      password,
      confirmationPassword,
    );
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
    resetEmailError = _emailValidation(email);
    if (resetEmailError != null) {
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
      await _authService.sendPasswordReset(email);
    }, flow: 'password_reset');
  }

  Future<bool> updatePassword(
    String password,
    String confirmationPassword,
  ) async {
    _clearErrors();
    if (!_strongPassword(password)) {
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
      } else if (flow == 'password_reset') {
        resetEmailError = apiError.message;
      } else {
        error = apiError.message;
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? _emailValidation(String value) {
    if (value.trim().isEmpty) return 'Email is required.';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address, for example name@example.com.';
  }

  String? _usernameValidation(String value) {
    if (value.trim().isEmpty) return 'Username is required.';
    return value.trim().length < 3
        ? 'Username must contain at least 3 characters.'
        : null;
  }

  String? _passwordValidation(String value) {
    if (value.trim().isEmpty) return 'Password is required.';
    return _strongPassword(value)
        ? null
        : 'Use 8+ characters with uppercase, lowercase, number and symbol.';
  }

  String? _confirmationValidation(String password, String confirmation) {
    if (confirmation.isEmpty) return 'Confirm your password.';
    return password == confirmation ? null : 'The passwords do not match.';
  }

  bool _strongPassword(String value) =>
      value.length >= 8 &&
      value.contains(RegExp('[A-Z]')) &&
      value.contains(RegExp('[a-z]')) &&
      value.contains(RegExp('[0-9]')) &&
      value.contains(RegExp(r'[^A-Za-z0-9]'));

  void _clearErrors() {
    error = null;
    usernameError = null;
    emailError = null;
    resetEmailError = null;
    passwordError = null;
    confirmationPasswordError = null;
    genderError = null;
    dateOfBirthError = null;
  }
}
