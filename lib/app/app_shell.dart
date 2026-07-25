import 'package:flutter/material.dart';

import '../views/collaborative_travel/invitations_view.dart';
import '../views/mission_discovery/explore_view.dart';
import '../views/mission_discovery/home_view.dart';
import '../views/passport_diary/passport_view.dart';
import '../views/user_profile/profile_view.dart';
import '../views/theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = [
    HomeView(),
    ExploreView(),
    PassportView(),
    InvitationsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.teal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(
              Icons.travel_explore_rounded,
              color: AppColors.teal,
            ),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(
              Icons.auto_stories_rounded,
              color: AppColors.teal,
            ),
            label: 'Passport',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded, color: AppColors.teal),
            label: 'Crew',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.teal),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
