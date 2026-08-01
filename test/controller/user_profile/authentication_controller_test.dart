import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/controller/services/errors/api_error.dart';
import 'package:mystery_malaysia/controller/services/supabase/supabase_auth_service.dart';
import 'package:mystery_malaysia/controller/user_profile/authentication_controller.dart';

void main() {
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
}

class _AuthService extends SupabaseAuthService {
  _AuthService({required this.registered, this.rejectPassword = false});

  final bool registered;
  final bool rejectPassword;

  @override
  Future<bool> isEmailRegistered(String email) async => registered;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (rejectPassword) {
      throw const ApiError(
        'The email or password is incorrect.',
        code: 'invalid_credentials',
      );
    }
  }
}
