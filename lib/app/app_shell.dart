import 'package:flutter/material.dart';

import '../controller/active_mission/active_mission_facade_interface.dart';
import '../controller/app_dependencies.dart';
import '../controller/collaborative_travel/collaborative_travel_facade_interface.dart';
import '../controller/passport_diary/passport_diary_facade_interface.dart';
import '../controller/user_profile/user_profile_facade_interface.dart';
import '../view/active_mission/mission_history_view.dart';
import '../theme/app_colors.dart';
import '../view/collaborative_travel/invitations_view.dart';
import '../view/mission_discovery/home_view.dart';
import '../view/passport_diary/passport_view.dart';
import '../view/user_profile/profile_view.dart';

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
  late final IMissionHistoryFacade missionFacade;
  late final IPassportDiaryFacade passportFacade;
  late final ICollaborativeTravelFacade collaborativeFacade;
  late final IUserProfileFacade profileFacade;

  @override
  void initState() {
    super.initState();
    _createHomeFacades();
    missionFacade = AppDependencies.missionHistory();
    passportFacade = AppDependencies.passportDiary();
    collaborativeFacade = AppDependencies.collaborativeTravel();
    profileFacade = AppDependencies.userProfile();
  }

  void _createHomeFacades() {
    homeProfileFacade = AppDependencies.userProfile();
    homeNotificationFacade = AppDependencies.notifications();
  }

  @override
  Widget build(BuildContext context) {
    const navigationColors = [
      AppColors.hibiscus,
      AppColors.purple,
      AppColors.mango,
      AppColors.teal,
      AppColors.straits,
    ];
    final selectedColor = navigationColors[index];
    final pages = [
      HomeView(
        key: ValueKey(homeVersion),
        profileFacade: homeProfileFacade,
        notificationFacade: homeNotificationFacade,
      ),
      MissionHistoryView(facade: missionFacade, embedded: true),
      PassportView(facade: passportFacade),
      InvitationsView(facade: collaborativeFacade),
      ProfileView(facade: profileFacade),
    ];
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: selectedColor.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: selectedColor.withValues(alpha: .18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 28,
                right: 28,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.hibiscus,
                        AppColors.mango,
                        AppColors.teal,
                        AppColors.purple,
                      ],
                    ),
                  ),
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme: Theme.of(context).navigationBarTheme
                      .copyWith(
                        indicatorColor: selectedColor.withValues(alpha: .15),
                      ),
                ),
                child: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (value) => setState(() {
                    index = value;
                    if (value == 0) {
                      _createHomeFacades();
                      homeVersion++;
                    }
                    if (value == 1) missionFacade.load();
                    if (value == 2) passportFacade.load();
                    if (value == 3) collaborativeFacade.loadOverview();
                    if (value == 4) profileFacade.load();
                  }),
                  destinations: [
                    _destination(
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'Home',
                      selectedColor,
                    ),
                    _destination(
                      Icons.flag_outlined,
                      Icons.flag_rounded,
                      'Mission',
                      selectedColor,
                    ),
                    _destination(
                      Icons.auto_stories_outlined,
                      Icons.auto_stories_rounded,
                      'Passport',
                      selectedColor,
                    ),
                    _destination(
                      Icons.groups_outlined,
                      Icons.groups_rounded,
                      'Crew',
                      selectedColor,
                    ),
                    _destination(
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'Profile',
                      selectedColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _destination(
    IconData icon,
    IconData selectedIcon,
    String label,
    Color selectedColor,
  ) => NavigationDestination(
    icon: Icon(icon),
    selectedIcon: Icon(selectedIcon, color: selectedColor),
    label: label,
  );
}
