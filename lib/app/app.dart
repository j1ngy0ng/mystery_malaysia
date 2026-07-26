import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../views/theme/app_theme.dart';
import 'router.dart';

class MysteryMalaysiaApp extends StatefulWidget {
  const MysteryMalaysiaApp({
    super.key,
    this.initialRoute = '/',
    this.authStateChanges,
  });

  final String initialRoute;
  final Stream<AuthState>? authStateChanges;

  @override
  State<MysteryMalaysiaApp> createState() => _MysteryMalaysiaAppState();
}

class _MysteryMalaysiaAppState extends State<MysteryMalaysiaApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();
    authSubscription = widget.authStateChanges?.listen((authState) {
      if (authState.event != AuthChangeEvent.signedIn ||
          authState.session == null) {
        return;
      }
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (_) => false);
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mystery Malaysia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.bright,
      initialRoute: widget.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
