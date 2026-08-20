import 'package:flutter/foundation.dart';

import '../../model/user_profile/app_notification.dart';
import '../../model/user_profile/registration_result.dart';
import '../../model/user_profile/user_profile.dart';

abstract interface class IAuthenticationFacade implements Listenable {
  bool get obscurePassword;
  bool get isLoading;
  bool get canSignIn;
  bool get canRegister;
  bool get canSendPasswordReset;
  String? get error;
  String? get usernameError;
  String? get emailError;
  String? get resetEmailError;
  String? get passwordError;
  String? get confirmationPasswordError;
  String? get genderError;
  String? get dateOfBirthError;

  void togglePasswordVisibility();
  void validateEmail(String value);
  void validateResetEmail(String value);
  void validateSignInPassword(String value);
  void validateUsername(String value);
  void validateRegistrationPassword(String value);
  void validatePasswordConfirmation(String password, String confirmation);
  void validateGender(String value);
  void validateDateOfBirth(DateTime? value);
  Future<bool> signIn(String email, String password);
  Future<RegistrationResult?> register({
    required String username,
    required String email,
    required String password,
    required String confirmationPassword,
    required String gender,
    required DateTime? dateOfBirth,
  });
  Future<bool> sendPasswordReset(String email);
  Future<bool> updatePassword(String password, String confirmationPassword);
  void dispose();
}

abstract interface class IUserProfileFacade implements Listenable {
  UserProfile get profile;
  bool get editing;
  bool get isLoading;
  String? get error;

  Future<void> load();
  void toggleEditing();
  Future<bool> save({
    required String name,
    required String username,
    String? gender,
    String? phoneNumber,
  });
  Future<bool> uploadAvatar(Uint8List bytes, {required String extension});
  Future<bool> signOut();
  void dispose();
}

abstract interface class INotificationFacade implements Listenable {
  List<AppNotification> get notifications;
  bool get isLoading;
  String? get error;
  int get unreadCount;

  Future<void> load();
  Future<void> markRead(AppNotification notification);
  Future<void> markAllRead();
  void dispose();
}
