import 'package:flutter/material.dart';

import '../controller/active_mission/active_mission_facade_interface.dart';
import '../controller/collaborative_travel/collaborative_travel_facade_interface.dart';
import '../controller/passport_diary/passport_diary_facade_interface.dart';
import '../controller/user_profile/user_profile_facade_interface.dart';
import '../view/collaborative_travel/invitations_view.dart';
import '../view/mission_discovery/explore_view.dart';
import '../view/mission_discovery/home_view.dart';
import '../view/passport_diary/passport_view.dart';
import '../view/user_profile/profile_view.dart';
import '../theme/app_colors.dart';
import '../controller/app_dependencies.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  int homeVersion = 0;
  late IUserProfileFacade homeProfileFacade;
  late INotificationFacade homeNotificationFacade;
  late IMissionHistoryFacade homeMissionFacade;
  late final IPassportDiaryFacade passportFacade;
  late final ICollaborativeTravelFacade collaborativeFacade;
  late final IUserProfileFacade profileFacade;

  @override
  void initState() {
    super.initState();
    _createHomeFacades();
    passportFacade = AppDependencies.passportDiary();
    collaborativeFacade = AppDependencies.collaborativeTravel();
    profileFacade = AppDependencies.userProfile();
  }

  void _createHomeFacades() {
    homeProfileFacade = AppDependencies.userProfile();
    homeNotificationFacade = AppDependencies.notifications();
    homeMissionFacade = AppDependencies.missionHistory();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeView(
        key: ValueKey(homeVersion),
        profileFacade: homeProfileFacade,
        notificationFacade: homeNotificationFacade,
        missionFacade: homeMissionFacade,
      ),
      const ExploreView(),
      PassportView(facade: passportFacade),
      InvitationsView(facade: collaborativeFacade),
      ProfileView(facade: profileFacade),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() {
          index = value;
          if (value == 0) {
            _createHomeFacades();
            homeVersion++;
          }
          if (value == 2) passportFacade.load();
          if (value == 3) collaborativeFacade.loadOverview();
          if (value == 4) profileFacade.load();
        }),
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
