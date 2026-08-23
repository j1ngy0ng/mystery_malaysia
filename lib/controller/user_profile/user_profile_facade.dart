import 'package:flutter/foundation.dart';

import 'authentication_controller.dart';
import 'notification_controller.dart';
import 'user_profile_controller.dart';
import 'user_profile_facade_interface.dart';
import '../../model/user_profile/app_notification.dart';
import '../../model/user_profile/registration_result.dart';
import '../../model/user_profile/user_profile.dart';

class AuthenticationFacade extends ChangeNotifier
    implements IAuthenticationFacade {
  AuthenticationFacade() : _controller = AuthenticationController() {
    _controller.addListener(notifyListeners);
  }

  final AuthenticationController _controller;

  @override
  bool get obscurePassword => _controller.obscurePassword;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  bool get canSignIn => _controller.canSignIn;
  @override
  bool get isSignedIn => _controller.isSignedIn;
  @override
  bool get canRegister => _controller.canRegister;
  @override
  bool get canSendPasswordReset => _controller.canSendPasswordReset;
  @override
  String? get error => _controller.error;
  @override
  String? get usernameError => _controller.usernameError;
  @override
  String? get emailError => _controller.emailError;
  @override
  String? get resetEmailError => _controller.resetEmailError;
  @override
  String? get passwordError => _controller.passwordError;
  @override
  String? get confirmationPasswordError =>
      _controller.confirmationPasswordError;
  @override
  String? get genderError => _controller.genderError;
  @override
  String? get dateOfBirthError => _controller.dateOfBirthError;

  @override
  void togglePasswordVisibility() => _controller.togglePasswordVisibility();
  @override
  void validateEmail(String value) => _controller.validateEmail(value);
  @override
  void validateResetEmail(String value) =>
      _controller.validateResetEmail(value);
  @override
  void validateSignInPassword(String value) =>
      _controller.validateSignInPassword(value);
  @override
  void validateUsername(String value) => _controller.validateUsername(value);
  @override
  void validateRegistrationPassword(String value) =>
      _controller.validateRegistrationPassword(value);
  @override
  void validatePasswordConfirmation(String password, String confirmation) =>
      _controller.validatePasswordConfirmation(password, confirmation);
  @override
  void validateGender(String value) => _controller.validateGender(value);
  @override
  void validateDateOfBirth(DateTime? value) =>
      _controller.validateDateOfBirth(value);
  @override
  Future<bool> signIn(String email, String password) =>
      _controller.signIn(email, password);
  @override
  Future<RegistrationResult?> register({
    required String username,
    required String email,
    required String password,
    required String confirmationPassword,
    required String gender,
    required DateTime? dateOfBirth,
  }) => _controller.register(
    username: username,
    email: email,
    password: password,
    confirmationPassword: confirmationPassword,
    gender: gender,
    dateOfBirth: dateOfBirth,
  );
  @override
  Future<bool> sendPasswordReset(String email) =>
      _controller.sendPasswordReset(email);
  @override
  Future<bool> updatePassword(String password, String confirmationPassword) =>
      _controller.updatePassword(password, confirmationPassword);

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}

class UserProfileFacade extends ChangeNotifier implements IUserProfileFacade {
  UserProfileFacade() : _controller = UserProfileController() {
    _controller.addListener(notifyListeners);
  }

  final UserProfileController _controller;

  @override
  UserProfile get profile => _controller.profile;
  @override
  bool get editing => _controller.editing;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  String? get error => _controller.error;

  @override
  Future<void> load() => _controller.load();
  @override
  void toggleEditing() => _controller.toggleEditing();
  @override
  Future<bool> save({
    required String name,
    required String username,
    String? gender,
    String? phoneNumber,
  }) => _controller.save(
    name: name,
    username: username,
    gender: gender,
    phoneNumber: phoneNumber,
  );
  @override
  Future<bool> uploadAvatar(Uint8List bytes, {required String extension}) =>
      _controller.uploadAvatar(bytes, extension: extension);
  @override
  Future<bool> signOut() => _controller.signOut();

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}

class NotificationFacade extends ChangeNotifier implements INotificationFacade {
  NotificationFacade() : _controller = NotificationController() {
    _controller.addListener(notifyListeners);
  }

  final NotificationController _controller;

  @override
  List<AppNotification> get notifications => _controller.notifications;
  @override
  bool get isLoading => _controller.isLoading;
  @override
  String? get error => _controller.error;
  @override
  int get unreadCount => _controller.unreadCount;

  @override
  Future<void> load() => _controller.load();
  @override
  Future<void> markRead(AppNotification notification) =>
      _controller.markRead(notification);
  @override
  Future<void> markAllRead() => _controller.markAllRead();

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.dispose();
    super.dispose();
  }
}
