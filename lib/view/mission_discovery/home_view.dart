import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/active_mission/active_mission_facade_interface.dart';
import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../../model/active_mission/mission_session.dart';
import '../active_mission/active_mission_view.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_logo.dart';
import '../malaysia_backdrop.dart';
import '../section_header.dart';
import '../status_pill.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    required this.profileFacade,
    required this.notificationFacade,
    required this.missionFacade,
    super.key,
  });

  final IUserProfileFacade profileFacade;
  final INotificationFacade notificationFacade;
  final IMissionHistoryFacade missionFacade;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late final IUserProfileFacade profileFacade = widget.profileFacade;
  late final INotificationFacade notificationFacade = widget.notificationFacade;
  late final IMissionHistoryFacade missionFacade = widget.missionFacade;
  MissionLaunch? currentMission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentMission();
    _loadIdentityAndNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profileFacade.dispose();
    notificationFacade.dispose();
    missionFacade.dispose();
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Row(
            children: [
              const AppLogo(compact: true),
              const Spacer(),
              _notificationButton(),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Hai, ${_displayName()}! 👋',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 5),
          Text(
            'Where will today’s mystery take you?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          _DiscoveryHero(
            onStart: () => Navigator.pushNamed(context, '/missions/request'),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Your missions',
            action: 'View history',
            onAction: () => Navigator.pushNamed(context, '/missions'),
          ),
          const SizedBox(height: 10),
          if (currentMission != null)
            _MissionSummaryCard(
              title: currentMission!.title,
              subtitle:
                  '${currentMission!.region} • Stage ${currentMission!.currentStage} of ${currentMission!.totalStages}',
              status: switch (currentMission!.status) {
                MissionStatus.ready => 'Ready to start',
                MissionStatus.paused => 'Paused',
                _ => 'Active',
              },
              emoji: '🧭',
              color: switch (currentMission!.status) {
                MissionStatus.ready => AppColors.mango,
                MissionStatus.paused => AppColors.purple,
                _ => AppColors.green,
              },
              progress:
                  currentMission!.currentStage / currentMission!.totalStages,
              actionLabel: switch (currentMission!.status) {
                MissionStatus.ready => 'Start mission',
                MissionStatus.paused => 'Resume mission',
                _ => 'Continue mission',
              },
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveMissionView(
                      facade: AppDependencies.activeMission(
                        launch: currentMission,
                      ),
                    ),
                  ),
                );
                _loadCurrentMission();
              },
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.explore_outlined,
                  color: AppColors.teal,
                ),
                title: const Text('No active or paused mission'),
                subtitle: const Text('Generate one when you are ready.'),
                onTap: () => Navigator.pushNamed(context, '/missions/request'),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/missions'),
            icon: const Icon(Icons.history_rounded),
            label: const Text('See all past and current missions'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCurrentMission() async {
    try {
      final mission = await missionFacade.loadCurrentMission();
      if (mounted) setState(() => currentMission = mission);
    } catch (_) {
      // Keep discovery available if mission history cannot be loaded.
    }
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

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.straits],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: .24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -6, top: -3, child: const _BadgeTrail()),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 238),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'AI mystery maker',
                  icon: Icons.auto_awesome,
                  color: AppColors.ink,
                  background: AppColors.mango,
                ),
                const SizedBox(height: 18),
                Text(
                  'Find me a mystery',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 7),
                const Text(
                  'We use your current location, time and budget to create a hidden route.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.straits,
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Build my mission'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTrail extends StatelessWidget {
  const _BadgeTrail();

  @override
  Widget build(BuildContext context) {
    const badges = ['png', 'sbh', 'mlk'];
    return SizedBox(
      width: 92,
      height: 116,
      child: Stack(
        children: [
          for (var index = 0; index < badges.length; index++)
            Positioned(
              top: index * 25,
              right: index.isEven ? 0 : 29,
              child: Transform.rotate(
                angle: index.isEven ? .08 : -.1,
                child: Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mango.withValues(alpha: .9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: .2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/state_badges/${badges[index]}.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissionSummaryCard extends StatelessWidget {
  const _MissionSummaryCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.emoji,
    required this.color,
    required this.progress,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final String emoji;
  final Color color;
  final double progress;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 66,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 31)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(label: status, color: color),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 9),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                      color: color,
                      backgroundColor: color.withValues(alpha: .12),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onTap,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(actionLabel),
                      ),
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
}
