import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controller/services/config/app_config.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(const _ConfigurationRequiredApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  final initialRoute = Supabase.instance.client.auth.currentSession == null
      ? '/'
      : '/home';
  runApp(
    MysteryMalaysiaApp(
      initialRoute: initialRoute,
      authStateChanges: Supabase.instance.client.auth.onAuthStateChange,
    ),
  );
}

class _ConfigurationRequiredApp extends StatelessWidget {
  const _ConfigurationRequiredApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Supabase configuration is missing.\n\n'
                'Paste the project URL and publishable key into '
                '.env.local.json, then start the app with '
                'tool/run_android.ps1.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
