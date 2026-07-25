import 'package:flutter/foundation.dart';

class AuthenticationController extends ChangeNotifier {
  bool obscurePassword = true;
  String? error;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  bool validateSignIn(String email, String password) {
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
    error = null;
    notifyListeners();
    return true;
  }
}
