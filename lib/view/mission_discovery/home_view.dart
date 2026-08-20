import 'package:flutter/material.dart';

import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../app_colors.dart';
import '../app_logo.dart';
import '../app_spacing.dart';
import '../malaysia_backdrop.dart';
import '../section_header.dart';
import '../status_pill.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    required this.profileFacade,
    required this.notificationFacade,
    super.key,
  });

  final IUserProfileFacade profileFacade;
  final INotificationFacade notificationFacade;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late final IUserProfileFacade profileFacade = widget.profileFacade;
  late final INotificationFacade notificationFacade = widget.notificationFacade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadIdentityAndNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profileFacade.dispose();
    notificationFacade.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadIdentityAndNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MalaysiaBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          Row(
            children: [
              const AppLogo(compact: true),
              const Spacer(),
              _notificationButton(),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Where will you explore next?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Hi, ${_displayName()} — uncover another side of Malaysia.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _TravelHero(
            onTap: () => Navigator.pushNamed(context, '/missions/request'),
          ),
          const SizedBox(height: 30),
          const SectionHeader(title: 'Explore Malaysia differently'),
          const SizedBox(height: 4),
          Text(
            'Travel experiences designed around discovery',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 164,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _TravelExperienceCard(
                  icon: Icons.forest_rounded,
                  title: 'Hidden gems',
                  message: 'Quieter, safe places near you',
                  color: AppColors.teal,
                ),
                SizedBox(width: 12),
                _TravelExperienceCard(
                  icon: Icons.key_rounded,
                  title: 'Clue-led trips',
                  message: 'Explore without destination spoilers',
                  color: AppColors.hibiscus,
                ),
                SizedBox(width: 12),
                _TravelExperienceCard(
                  icon: Icons.museum_rounded,
                  title: 'Local stories',
                  message: 'Culture and guidance after arrival',
                  color: AppColors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'How your mystery trip works'),
          const SizedBox(height: 12),
          const _JourneySteps(),
          const SizedBox(height: 28),
          _PassportTeaser(
            onMissions: () => Navigator.pushNamed(context, '/missions'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadIdentityAndNotifications() async {
    await Future.wait([profileFacade.load(), notificationFacade.load()]);
    if (mounted) setState(() {});
  }

  String _displayName() {
    final name = profileFacade.profile.name.trim();
    return name.isEmpty ? 'Explorer' : name;
  }

  Widget _notificationButton() {
    final unread = notificationFacade.unreadCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: () async {
            await Navigator.pushNamed(context, '/notifications');
            await notificationFacade.load();
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
        ),
        if (unread > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: AppColors.hibiscus,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TravelHero extends StatelessWidget {
  const _TravelHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Generate three mystery missions near your current location',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Ink(
            height: 330,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.straits.withValues(alpha: .24),
                  blurRadius: 28,
                  offset: const Offset(0, 13),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    child: Image.asset(
                      'assets/images/malaysia-travel-hero.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x1808172A),
                          Color(0x4D08172A),
                          Color(0xE610233F),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .38, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: StatusPill(
                    label: 'Hidden gems near you',
                    icon: Icons.location_on_rounded,
                    color: AppColors.ink,
                    background: Colors.white.withValues(alpha: .92),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See a side of Malaysia\nyou did not expect.',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.white, height: 1.05),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Turn your location, time and budget into a three-stop mystery trip.',
                        style: TextStyle(color: Colors.white, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              color: AppColors.teal,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Plan from my location',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.hibiscus,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TravelExperienceCard extends StatelessWidget {
  const _TravelExperienceCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: color.withValues(alpha: .15)),
      boxShadow: [
        BoxShadow(
          color: AppColors.night.withValues(alpha: .06),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: color, size: 27),
        ),
        const Spacer(),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.25),
        ),
      ],
    ),
  );
}

class _JourneySteps extends StatelessWidget {
  const _JourneySteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.auto_awesome_rounded, 'Generate', '3 choices'),
      (Icons.key_rounded, 'Explore', 'Follow clues'),
      (Icons.approval_rounded, 'Collect', 'Badge pieces'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const [
                      AppColors.paleMango,
                      AppColors.paleHibiscus,
                      AppColors.paleTeal,
                    ][index],
                    foregroundColor: const [
                      AppColors.straits,
                      AppColors.hibiscus,
                      AppColors.teal,
                    ][index],
                    child: Icon(steps[index].$1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index].$2,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    steps[index].$3,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (index < steps.length - 1)
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.outline,
                size: 19,
              ),
          ],
        ],
      ),
    );
  }
}

class _PassportTeaser extends StatelessWidget {
  const _PassportTeaser({required this.onMissions});

  final VoidCallback onMissions;

  @override
  Widget build(BuildContext context) {
    const badges = ['sgr', 'png', 'sbh'];
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4C7), Color(0xFFE9FFF9)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.mango.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 102,
            height: 72,
            child: Stack(
              children: [
                for (var index = 0; index < badges.length; index++)
                  Positioned(
                    left: index * 25,
                    top: index.isOdd ? 7 : 0,
                    child: Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.mango, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/state_badges/${badges[index]}.webp',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your Malaysia passport',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Every verified stop reveals one piece of a state mission badge.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: onMissions,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: const Text('View my missions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
