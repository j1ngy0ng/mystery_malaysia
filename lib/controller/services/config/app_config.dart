abstract final class AppConfig {
  static const authCallbackUrl = 'com.mysterymalaysia://login-callback/';

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured {
    return Uri.tryParse(supabaseUrl)?.host.endsWith('.supabase.co') == true &&
        supabasePublishableKey.isNotEmpty &&
        !supabasePublishableKey.startsWith('PASTE_');
  }
}
