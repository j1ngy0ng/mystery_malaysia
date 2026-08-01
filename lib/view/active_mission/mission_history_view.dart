import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/active_mission/active_mission_facade_interface.dart';
import '../../model/active_mission/mission_history_item.dart';
import '../../model/active_mission/mission_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/malaysia_loading.dart';
import 'active_mission_view.dart';
import '../collaborative_travel/shared_mission_view.dart';

class MissionHistoryView extends StatefulWidget {
  const MissionHistoryView({required this.facade, super.key});

  final IMissionHistoryFacade facade;

  @override
  State<MissionHistoryView> createState() => _MissionHistoryViewState();
}

class _MissionHistoryViewState extends State<MissionHistoryView> {
  late final IMissionHistoryFacade facade = widget.facade;

  @override
  void initState() {
    super.initState();
    facade.load();
  }

  @override
  void dispose() {
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My missions')),
      body: AnimatedBuilder(
        animation: facade,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
            children: [
              Text(
                'Every adventure,\nin one place.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Continue active or paused missions and revisit completed journeys.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MissionHistoryFilter.values.map((filter) {
                    final label = switch (filter) {
                      MissionHistoryFilter.all => 'All',
                      MissionHistoryFilter.active => 'Active',
                      MissionHistoryFilter.paused => 'Paused',
                      MissionHistoryFilter.completed => 'Completed',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: facade.filter == filter,
                        onSelected: (_) => facade.selectFilter(filter),
                        selectedColor: AppColors.paleTeal,
                        side: BorderSide(
                          color: facade.filter == filter
                              ? AppColors.teal
                              : AppColors.outline,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              if (facade.isLoading)
                const Center(
                  child: MalaysiaLoading(message: 'Tracing your journeys...'),
                )
              else if (facade.error != null)
                _HistoryMessage(
                  message: facade.error!,
                  action: 'Retry',
                  onPressed: facade.load,
                )
              else if (facade.visibleMissions.isEmpty)
                _HistoryMessage(
                  message:
                      'No missions here yet. Generate your first Malaysian mystery adventure.',
                  action: 'Generate mission',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/missions/request'),
                ),
              ...facade.visibleMissions.map(
                (mission) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MissionHistoryCard(
                    mission: mission,
                    onTap: () {
                      if (mission.status == MissionStatus.waiting &&
                          mission.isShared) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SharedMissionView(
                              facade: AppDependencies.collaborativeTravel(
                                sessionId: mission.sessionId,
                              ),
                            ),
                          ),
                        ).then((_) => facade.load());
                      } else if (mission.status == MissionStatus.ready ||
                          mission.status == MissionStatus.active ||
                          mission.status == MissionStatus.paused) {
                        final launch = mission.launch;
                        if (launch != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ActiveMissionView(
                                facade: AppDependencies.activeMission(
                                  launch: launch,
                                ),
                              ),
                            ),
                          ).then((_) => facade.load());
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Generate travel diaries from your Digital Passport.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    ),
  );
}

class _MissionHistoryCard extends StatelessWidget {
  const _MissionHistoryCard({required this.mission, required this.onTap});

  final MissionHistoryItem mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (mission.status) {
      MissionStatus.ready => (
        'Ready to start',
        AppColors.mango,
        Icons.flag_circle_outlined,
      ),
      MissionStatus.waiting => (
        'Waiting',
        AppColors.mango,
        Icons.groups_outlined,
      ),
      MissionStatus.active => (
        'Active',
        AppColors.green,
        Icons.play_circle_outline_rounded,
      ),
      MissionStatus.paused => (
        'Paused',
        AppColors.purple,
        Icons.pause_circle_outline_rounded,
      ),
      MissionStatus.completed => (
        'Completed',
        AppColors.straits,
        Icons.check_circle_outline_rounded,
      ),
      MissionStatus.abandoned => (
        'Abandoned',
        AppColors.secondaryText,
        Icons.cancel_outlined,
      ),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Text(
                  mission.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mission.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(label: label, color: color, icon: icon),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mission.region} • ${mission.dateLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: mission.progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                      color: color,
                      backgroundColor: color.withValues(alpha: .12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stage ${mission.currentStage} of ${mission.totalStages}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
