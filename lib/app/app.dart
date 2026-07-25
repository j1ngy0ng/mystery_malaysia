import 'package:flutter/material.dart';

import '../views/theme/app_theme.dart';
import 'router.dart';

class MysteryMalaysiaApp extends StatelessWidget {
  const MysteryMalaysiaApp({super.key, this.initialRoute = '/'});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mystery Malaysia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.bright,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
