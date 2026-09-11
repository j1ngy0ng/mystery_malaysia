import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/controller/services/errors/api_error.dart';
import 'package:mystery_malaysia/controller/services/supabase/supabase_auth_service.dart';
import 'package:mystery_malaysia/controller/user_profile/authentication_controller.dart';

void main() {
  test('validates local formats without querying account data', () {
    final service = _AuthService(registered: true);
    final controller = AuthenticationController(authService: service);

    controller.validateEmail('not-an-email');
    controller.validateRegistrationPassword('weak');
    controller.validateUsername('ab');

    expect(controller.emailError, contains('name@example.com'));
    expect(controller.passwordError, contains('8+ characters'));
    expect(controller.usernameError, contains('at least 3'));
    expect(service.registrationChecks, 0);
  });

  test('rejects plus-address tags during registration only', () async {
    final service = _AuthService(registered: false);
    final controller = AuthenticationController(authService: service);

    controller.validateRegistrationEmail('person+second@example.com');
    expect(controller.emailError, primaryEmailRequiredMessage);

    controller.validateEmail('person+second@example.com');
    expect(controller.emailError, isNull);

    final result = await controller.register(
      username: 'traveller',
      email: 'person+second@example.com',
      password: 'Password!1',
      confirmationPassword: 'Password!1',
      gender: 'female',
      dateOfBirth: DateTime(2000, 1, 1),
    );
    expect(result, isNull);
    expect(controller.emailError, primaryEmailRequiredMessage);
    expect(service.registrationChecks, 0);
  });

  test('places an unknown login email error under the email field', () async {
    final controller = AuthenticationController(
      authService: _AuthService(registered: false),
    );

    expect(await controller.signIn('missing@example.com', 'Password!1'), false);
    expect(controller.emailError, 'No account is registered with this email.');
    expect(controller.passwordError, isNull);
  });

  test('places invalid credentials under the password field', () async {
    final controller = AuthenticationController(
      authService: _AuthService(registered: true, rejectPassword: true),
    );

    expect(await controller.signIn('known@example.com', 'WrongPass!1'), false);
    expect(controller.emailError, isNull);
    expect(controller.passwordError, 'The email or password is incorrect.');
  });

  test('keeps an unknown reset email error under the email field', () async {
    final controller = AuthenticationController(
      authService: _AuthService(registered: false),
    );

    expect(await controller.sendPasswordReset('missing@example.com'), false);
    expect(
      controller.resetEmailError,
      'No account is registered with this email.',
    );
  });

  test('sends password reset for a registered email', () async {
    final service = _AuthService(registered: true);
    final controller = AuthenticationController(authService: service);

    expect(await controller.sendPasswordReset('known@example.com'), true);
    expect(service.resetSent, true);
  });

  test('signs out the recovery session after updating password', () async {
    final service = _AuthService(registered: true);
    final controller = AuthenticationController(authService: service);

    expect(await controller.updatePassword('Password!1', 'Password!1'), true);
    expect(service.passwordUpdated, true);
    expect(service.signedOut, true);
  });

  test('enables buttons only after every local field is valid', () {
    final controller = AuthenticationController(
      authService: _AuthService(registered: true),
    );

    expect(controller.canSignIn, false);
    controller.validateEmail('person@example.com');
    controller.validateSignInPassword('Password!1');
    expect(controller.canSignIn, true);

    expect(controller.canRegister, false);
    controller.validateUsername('traveller');
    controller.validateRegistrationPassword('Password!1');
    controller.validatePasswordConfirmation('Password!1', 'Password!1');
    controller.validateGender('female');
    controller.validateDateOfBirth(DateTime(2000, 1, 1));
    expect(controller.canRegister, true);

    expect(controller.canSendPasswordReset, false);
    controller.validateResetEmail('person@example.com');
    expect(controller.canSendPasswordReset, true);
  });
}

class _AuthService extends SupabaseAuthService {
  _AuthService({required this.registered, this.rejectPassword = false});

  final bool registered;
  final bool rejectPassword;
  bool resetSent = false;
  bool passwordUpdated = false;
  bool signedOut = false;
  int registrationChecks = 0;

  @override
  Future<bool> isEmailRegistered(String email) async {
    registrationChecks++;
    return registered;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (rejectPassword) {
      throw const ApiError(
        'The email or password is incorrect.',
        code: 'invalid_credentials',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resetSent = true;
  }

  @override
  Future<void> updatePassword(String password) async {
    passwordUpdated = true;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}
