import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/malaysia_backdrop.dart';
import '../controller/services/config/app_config.dart';
import '../controller/app_dependencies.dart';
import '../controller/user_profile/user_profile_facade_interface.dart';

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
  late final IAuthenticationFacade authentication =
      AppDependencies.authentication();
  StreamSubscription<AuthState>? authSubscription;
  StreamSubscription<Uri>? linkSubscription;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.demoMode) {
      linkSubscription = AppLinks().uriLinkStream.listen((uri) {
        if (uri.host != 'mission-invite') return;
        _replaceAll(authentication.isSignedIn ? '/home' : '/auth/register');
      });
    }
    authSubscription = widget.authStateChanges?.listen((authState) {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        _replaceAll('/auth/update-password');
        return;
      }
      if (authState.event != AuthChangeEvent.signedIn ||
          authState.session == null) {
        return;
      }
      _replaceAll('/home');
    }, onError: (Object _, StackTrace _) {});
  }

  @override
  void dispose() {
    linkSubscription?.cancel();
    authSubscription?.cancel();
    authentication.dispose();
    super.dispose();
  }

  void _replaceAll(String route) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil(route, (_) => false);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mystery Malaysia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.bright,
      builder: (context, child) => MalaysiaBackdrop(child: child!),
      initialRoute: widget.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
