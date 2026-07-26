import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/config/app_config.dart';

void main() {
  test('Supabase compile-time configuration is available', () {
    expect(AppConfig.isConfigured, isTrue);
  });

  test('authentication callback opens the Android app', () {
    final callback = Uri.parse(AppConfig.authCallbackUrl);

    expect(callback.scheme, 'com.mysterymalaysia');
    expect(callback.host, 'login-callback');
  });
}
